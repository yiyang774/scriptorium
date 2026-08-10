"""Single-entry reducer for the obligation lifecycle graph.

The edge table is the only source of transition semantics.  ``apply`` owns
all guards that can reject an event and commits mutations only after every
check has passed.
"""

from itertools import product
from typing import Any, Dict, List, Mapping, MutableMapping, Optional, Tuple

OPEN = {"observed", "fix_pending", "disputed", "awaiting_adj"}
CLOSED = {"resolved", "closed_adjudicated"}
STATES = sorted(OPEN | CLOSED)

Edge = Tuple[str, str, Optional[str], Dict[str, str], str, Optional[str], Optional[str], Tuple[str, ...]]

EDGES: List[Edge] = [
    ("N_review", "lenses_ok", None, {}, "N_triage", None, None, ()),
    ("N_review", "*", None, {}, "ABORT", None, None, ()),
    ("N_triage", "has_linked", "LINKED", {"observed": "observed", "fix_pending": "fix_pending", "disputed": "disputed", "resolved": "fix_pending"}, "N_dispose", None, "L0_Opus", ("obs_id",)),
    ("N_triage", "*", None, {}, "N_route", None, None, ()),
    ("N_dispose", "choose_accept", "DISPOSED.accept", {"observed": "fix_pending", "fix_pending": "fix_pending", "disputed": "fix_pending"}, "N_route", "dispose", "L0_Opus", ("missing_artifact", "acceptance_criterion", "rationale")),
    ("N_dispose", "*", "DISPOSED.dispute", {"observed": "disputed", "fix_pending": "disputed", "disputed": "disputed"}, "N_route", "dispose", "L0_Opus", ("rationale", "dispute_key")),
    ("N_verify", "verify_ok", "VERIFIED.satisfied", {"fix_pending": "resolved", "disputed": "resolved", "resolved": "resolved"}, "N_route", "verify", "verifier", ("evidence", "verify_key")),
    ("N_verify", "*", "VERIFIED.unsatisfied", {"fix_pending": "fix_pending", "disputed": "disputed", "resolved": "fix_pending"}, "N_route", "verify", "verifier", ("evidence", "verify_key", "gap", "dispute_key")),
    ("N_escalate", "*", "ESCALATE", {"disputed": "awaiting_adj"}, "N_adjudicate", None, "系统", ("cycles", "dispute_key")),
    ("N_adjudicate", "uphold", "ADJUDICATED.upheld", {"awaiting_adj": "fix_pending"}, "N_route", "adjudicate", "L0_Opus", ("missing_artifact", "acceptance_criterion", "rationale", "dispute_key", "cycle_evidence", "ts", "ledger_ref")),
    ("N_adjudicate", "*", "ADJUDICATED.dismissed", {"awaiting_adj": "closed_adjudicated"}, "N_route", "adjudicate", "L0_Opus", ("rationale", "dispute_key", "cycle_evidence", "ts", "ledger_ref")),
    ("N_fix", "*", None, {}, "N_review", None, None, ()),
    ("N_route", "escalatable", None, {}, "N_escalate", None, None, ()),
    ("N_route", "verify_debt", None, {}, "N_verify", None, None, ()),
    ("N_route", "has_open", None, {}, "N_fix", None, None, ()),
    ("N_route", "need_review", None, {}, "N_review", None, None, ()),
    ("N_route", "*", None, {}, "DONE", None, None, ()),
]

GUARD_DEF = {
    "lenses_ok": "三视角均过 fail-closed 三闸",
    "has_linked": "本轮有 observation 关联到该义务",
    "choose_accept": "L0 判定该 observation 应被采纳（互斥于 dispute）",
    "verify_ok": "verifier 判定验收标准已满足",
    "escalatable": "status=='disputed' AND cycles(dispute_key) >= 2",
    "verify_debt": "status in {fix_pending,disputed,resolved} AND vkey != current_key",
    "has_open": "status in OPEN",
    "need_review": "last_reviewed_key != current_key",
}


def derive() -> Tuple[Dict[Tuple[str, str], str], Dict[str, List[Tuple[str, str]]], Dict[str, List[str]], Dict[str, str], Dict[str, str], Dict[str, Tuple[str, ...]]]:
    """Derive lookup tables from ``EDGES``."""
    transitions: Dict[Tuple[str, str], str] = {}
    graph: Dict[str, List[Tuple[str, str]]] = {}
    produce: Dict[str, List[str]] = {}
    choice: Dict[str, str] = {}
    actor: Dict[str, str] = {}
    payload: Dict[str, Tuple[str, ...]] = {}
    for node, guard, event, effect, next_node, ch, ac, required in EDGES:
        graph.setdefault(node, []).append((guard, next_node))
        if event:
            produce.setdefault(node, []).append(event)
            choice[event], actor[event], payload[event] = ch, ac, required
            for state, new_state in effect.items():
                transitions[(state, event)] = new_state
    return transitions, graph, produce, choice, actor, payload


T, GRAPH, PRODUCE, CHOICE, ACTOR, PAYLOAD = derive()
EVENTS = sorted({event for _, _, event, *_ in EDGES if event})


def apply(ob: MutableMapping[str, Any], ev: str, actor: str, payload: Mapping[str, Any], rnd: int, cur_key: str, ledger: MutableMapping[str, MutableMapping[str, Any]]) -> str:
    """Apply one event, returning the new state or ``REJECT: ...``.

    All six rejection checks happen here.  No mutation occurs until all checks
    pass, making rejected calls transactional.
    """
    new = T.get((ob["st"], ev))
    if new is None:
        return f"REJECT: {ob['st']} 收不到 {ev}"

    need = ACTOR.get(ev)
    if need and actor != need:
        return f"REJECT: {ev} 需 actor={need}，实为 {actor}"

    missing = [key for key in PAYLOAD.get(ev, ()) if not payload.get(key)]
    if missing:
        return f"REJECT: {ev} 缺必填 {missing}"

    group = CHOICE.get(ev)
    if group:
        logged = ob["choice_log"].get((rnd, group))
        if logged is not None and logged != ev:
            return f"REJECT: 第 {rnd} 轮 '{group}' 组已发 {logged}"

    ref = payload.get("ledger_ref", "")
    if ev.startswith("ADJUDICATED"):
        if not payload.get("cycle_evidence"):
            return "REJECT: 裁定缺两轮争议证据"
        if not ref.startswith("ledger://") or ref not in ledger:
            return "REJECT: 裁定未真正落盘"
        if ledger[ref].get("sealed"):
            return "REJECT: 裁定记录不可覆盖"

    dispute_key = payload.get("dispute_key")
    if ev == "ESCALATE" and cycles(ob, dispute_key) < 2:
        return "REJECT: 同一争议未满两轮"

    if group:
        ob["choice_log"][(rnd, group)] = ev
    if ev.startswith("ADJUDICATED"):
        ledger[ref]["sealed"] = True
    if ev == "DISPOSED.dispute" and dispute_key:
        ob["disputed_at"].setdefault(dispute_key, set()).add(rnd)
    elif ev == "VERIFIED.unsatisfied" and dispute_key:
        ob["unsat_at"].setdefault(dispute_key, set()).add(rnd)
    if ev.startswith("VERIFIED"):
        ob["vkey"] = payload["verify_key"]
    if ev == "ADJUDICATED.upheld":
        ob["episode"] += 1
        ob["disputed_at"].clear()
        ob["unsat_at"].clear()
    ob["st"] = new
    return new


def cycles(ob: Mapping[str, Any], dispute_key: str) -> int:
    """Return same-round, same-key dispute cycles."""
    return len(set(ob["disputed_at"].get(dispute_key, set())) & set(ob["unsat_at"].get(dispute_key, set())))


def new_ob(st: str = "observed") -> Dict[str, Any]:
    """Create a fresh obligation record."""
    return {"st": st, "episode": 0, "vkey": None, "choice_log": {}, "disputed_at": {}, "unsat_at": {}}


def no_bypass() -> List[str]:
    """Check that the single-entry function contains all required checks."""
    import inspect
    source = inspect.getsource(apply)
    return [needle for needle in ("ACTOR.get", "PAYLOAD.get", "CHOICE.get", "cycle_evidence", "ledger_ref", "sealed", "dispute_key") if needle not in source]
