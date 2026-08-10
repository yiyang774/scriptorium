import copy

import pytest

from finding_loop import reducer as R


def payload(event):
    values = {
        "LINKED": {"obs_id": "o"},
        "DISPOSED.accept": {"missing_artifact": "m", "acceptance_criterion": "c", "rationale": "r"},
        "DISPOSED.dispute": {"rationale": "r", "dispute_key": "D"},
        "VERIFIED.satisfied": {"evidence": "e", "verify_key": "k"},
        "VERIFIED.unsatisfied": {"evidence": "e", "verify_key": "k", "gap": "g", "dispute_key": "D"},
        "ESCALATE": {"cycles": 2, "dispute_key": "D"},
        "ADJUDICATED.upheld": {"missing_artifact": "m", "acceptance_criterion": "c", "rationale": "r", "dispute_key": "D", "cycle_evidence": [1, 2], "ts": "t", "ledger_ref": "ledger://x"},
        "ADJUDICATED.dismissed": {"rationale": "r", "dispute_key": "D", "cycle_evidence": [1, 2], "ts": "t", "ledger_ref": "ledger://x"},
    }
    return dict(values[event])


def ready_ob(state, event):
    ob = R.new_ob(state)
    if event == "ESCALATE":
        ob["disputed_at"]["D"] = {1, 2}
        ob["unsat_at"]["D"] = {1, 2}
    return ob


@pytest.mark.parametrize("state,event,new_state", [(s, e, d) for (s, e), d in R.T.items()])
def test_all_19_legal_transitions(state, event, new_state):
    ledger = {"ledger://x": {}}
    result = R.apply(ready_ob(state, event), event, R.ACTOR.get(event), payload(event), 1, "k", ledger)
    assert result == new_state


@pytest.mark.parametrize("state,event", [(s, e) for s in R.STATES for e in R.EVENTS if (s, e) not in R.T])
def test_all_29_illegal_pairs_reject(state, event):
    result = R.apply(R.new_ob(state), event, R.ACTOR.get(event), payload(event), 1, "k", {"ledger://x": {}})
    assert result == f"REJECT: {state} 收不到 {event}"


def test_each_of_six_checks_has_specific_rejection():
    cases = [
        (R.new_ob("observed"), "DISPOSED.accept", "verifier", payload("DISPOSED.accept"), "REJECT: DISPOSED.accept 需 actor=L0_Opus，实为 verifier"),
        (R.new_ob("observed"), "LINKED", "L0_Opus", {}, "REJECT: LINKED 缺必填 ['obs_id']"),
        (R.new_ob("observed"), "DISPOSED.accept", "L0_Opus", payload("DISPOSED.accept"), "REJECT: 第 1 轮 'dispose' 组已发 DISPOSED.dispute"),
        (R.new_ob("awaiting_adj"), "ADJUDICATED.dismissed", "L0_Opus", {**payload("ADJUDICATED.dismissed"), "ledger_ref": "file:x"}, "REJECT: 裁定未真正落盘"),
        (R.new_ob("disputed"), "ESCALATE", "系统", payload("ESCALATE"), "REJECT: 同一争议未满两轮"),
    ]
    choice_ob = cases[2][0]
    choice_ob["choice_log"][(1, "dispose")] = "DISPOSED.dispute"
    for ob, event, actor, data, expected in cases:
        assert R.apply(ob, event, actor, data, 1, "k", {"ledger://x": {}}) == expected

    audit_ob = R.new_ob("awaiting_adj")
    assert R.apply(audit_ob, "ADJUDICATED.dismissed", "L0_Opus", {**payload("ADJUDICATED.dismissed"), "cycle_evidence": []}, 1, "k", {"ledger://x": {}}).startswith("REJECT: ")  # M1 后空值在必填检查即被拒


def test_transactionality_on_choice_and_ledger_rejection():
    ob = R.new_ob("observed")
    ob["choice_log"][(1, "dispose")] = "DISPOSED.dispute"
    before = copy.deepcopy(ob)
    ledger = {"ledger://x": {}}
    assert R.apply(ob, "DISPOSED.accept", "L0_Opus", payload("DISPOSED.accept"), 1, "k", ledger).startswith("REJECT:")
    assert ob == before
    assert ledger == {"ledger://x": {}}

    ob = R.new_ob("awaiting_adj")
    ledger = {"ledger://x": {"sealed": True}}
    before = copy.deepcopy(ob)
    assert R.apply(ob, "ADJUDICATED.dismissed", "L0_Opus", payload("ADJUDICATED.dismissed"), 1, "k", ledger) == "REJECT: 裁定记录不可覆盖"
    assert ob == before
    assert ledger == {"ledger://x": {"sealed": True}}


def test_same_key_only_counts_same_round_and_upheld_resets_episode():
    ob = R.new_ob()
    ob["disputed_at"] = {"D": {1, 2}, "OTHER": {1}}
    ob["unsat_at"] = {"D": {1}, "OTHER": {2}}
    assert R.cycles(ob, "D") == 1
    assert R.cycles(ob, "OTHER") == 0


def test_reducer_self_check_is_wired():
    assert R.no_bypass() == []
