import pytest

from finding_loop import harness as H
from finding_loop import reducer as R


def payload(ev):
    """各事件的合法 payload（与 test_reducer 同源语义）"""
    base = {"obs_id": "o1", "missing_artifact": "m", "acceptance_criterion": "c",
            "rationale": "r", "dispute_key": "D1", "evidence": "e", "verify_key": "k",
            "gap": "g", "cycles": 2, "cycle_evidence": [1, 2], "ts": "t",
            "ledger_ref": "ledger://x"}
    return {k: base[k] for k in R.PAYLOAD.get(ev, ())}


def decision(acc=True, vok=False, link=True):
    def decide(node, ob, key, event):
        if node == "_link": return link
        if node == "_acc": return acc
        if node == "_vok": return vok
        if node == "N_triage": return link
        if node == "N_dispose": return ob["st"] in {"observed", "fix_pending", "disputed"}
        if node == "N_verify": return ob["vkey"] != key and ob["st"] in {"fix_pending", "disputed", "resolved"}
        if node == "N_escalate": return ob["st"] == "disputed" and R.cycles(ob, "D1") >= 2
        if node == "N_adjudicate": return ob["st"] == "awaiting_adj"
        return False
    return decide


@pytest.mark.parametrize("state,kwargs", [("observed", dict(acc=True, vok=True)), ("fix_pending", dict(acc=False, vok=False)), ("disputed", dict(acc=False, vok=False)), ("resolved", dict(link=False, vok=True))])
def test_four_liveness_paths_close(state, kwargs):
    ob, path = H.run(state, decision(**kwargs))
    assert path[-1] == "DONE"
    assert ob["st"] in {"resolved", "closed_adjudicated"}


def test_harness_is_fail_closed(monkeypatch):
    def reject(*args, **kwargs):
        return "REJECT: injected"

    monkeypatch.setattr(R, "apply", reject)
    ob, path = H.run("observed", decision())
    assert path[-1] == "REJECT: injected"


def test_actor_mutation_is_caught(monkeypatch):
    """真突变：把 ACTOR 表清空（等价于删掉 actor 检查），越权调用应从 REJECT 变成放行。

    L2 逮到原实现是空壳：wrapper 先把坏 actor 洗白再调真 apply，
    删掉源码检查它照样通过（已实证）。
    """
    ob = R.new_ob("awaiting_adj")
    pl = payload("ADJUDICATED.dismissed")
    # 未突变：越权必须被拒
    assert R.apply(ob, "ADJUDICATED.dismissed", "verifier", pl, 1, "k",
                   {"ledger://x": {}}).startswith("REJECT: ")
    # 突变：清空 ACTOR 表 → 检查失效 → 越权被放行（证明该检查确实在起作用）
    monkeypatch.setattr(R, "ACTOR", {})
    ob2 = R.new_ob("awaiting_adj")
    assert not str(R.apply(ob2, "ADJUDICATED.dismissed", "verifier", pl, 1, "k",
                           {"ledger://x": {}})).startswith("REJECT: ")

def test_choice_is_per_obligation_not_global(monkeypatch):
    first, second = R.new_ob(), R.new_ob()
    first["choice_log"][(1, "dispose")] = "DISPOSED.dispute"
    global_log = first["choice_log"]
    real_apply = R.apply

    def global_choice(ob, *args, **kwargs):
        original = ob["choice_log"]
        ob["choice_log"] = global_log
        try:
            return real_apply(ob, *args, **kwargs)
        finally:
            ob["choice_log"] = original

    monkeypatch.setattr(R, "apply", global_choice)
    with pytest.raises(AssertionError):
        assert R.apply(second, "DISPOSED.accept", "L0_Opus", H.PL_STUB["DISPOSED.accept"], 1, "k", {"ledger://x": {}}) == "fix_pending"


def test_harness_has_no_second_semantics_and_bfs_accounts_for_reachable_pairs():
    assert H.no_second_semantics() == []
    assert H.bfs() == []
