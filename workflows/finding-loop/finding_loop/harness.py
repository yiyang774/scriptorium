"""Graph executor and reachability helper; reducer is the sole event authority."""

import inspect
import re
from typing import Any, Callable, Dict, List, Tuple

from . import reducer as R
from .reducer import ACTOR, EVENTS, GRAPH, OPEN, PRODUCE, STATES, T, cycles, new_ob

PL_STUB = {
    "LINKED": {"obs_id": "o1"},
    "DISPOSED.accept": {"missing_artifact": "m", "acceptance_criterion": "c", "rationale": "r"},
    "DISPOSED.dispute": {"rationale": "r", "dispute_key": "D1"},
    "VERIFIED.satisfied": {"evidence": "e", "verify_key": "k"},
    "VERIFIED.unsatisfied": {"evidence": "e", "verify_key": "k", "gap": "g", "dispute_key": "D1"},
    "ESCALATE": {"cycles": 2, "dispute_key": "D1"},
    "ADJUDICATED.upheld": {"missing_artifact": "m", "acceptance_criterion": "c", "rationale": "r", "dispute_key": "D1", "cycle_evidence": [1, 2], "ts": "t", "ledger_ref": "ledger://a"},
    "ADJUDICATED.dismissed": {"rationale": "r", "dispute_key": "D1", "cycle_evidence": [1, 2], "ts": "t", "ledger_ref": "ledger://a"},
}


def run(init_st: str, decide: Callable[..., bool], steps: int = 40) -> Tuple[Dict[str, Any], List[Any]]:
    """Execute graph edges and stop immediately on any reducer rejection."""
    ob, node, rnd, key, reviewed, path = new_ob(init_st), "N_review", 0, "k0", None, []
    ledger = {"ledger://a": {}}
    for _ in range(steps):
        path.append(node)
        if node == "N_review":
            rnd += 1
            reviewed = key
        if node == "N_fix":
            key = f"k{rnd}.{len(path)}"
        selected = next((event for n, guard, event, *_ in R.EDGES if n == node and event and (guard == "*" or {"choose_accept": decide("_acc", ob, key, None), "verify_ok": decide("_vok", ob, key, None), "has_linked": decide("_link", ob, key, None), "uphold": decide("_uphold", ob, key, None), "lenses_ok": True}.get(guard))), None)
        if selected and decide(node, ob, key, selected):
            payload = dict(PL_STUB[selected])
            payload["verify_key"] = key
            result = R.apply(ob, selected, ACTOR.get(selected), payload, rnd, key, ledger)
            if str(result).startswith("REJECT"):
                path.append(result)
                break
        guards = {"lenses_ok": True, "has_linked": decide("_link", ob, key, None), "choose_accept": decide("_acc", ob, key, None), "verify_ok": decide("_vok", ob, key, None), "escalatable": ob["st"] == "disputed" and cycles(ob, "D1") >= 2, "verify_debt": ob["st"] in {"fix_pending", "disputed", "resolved"} and ob["vkey"] != key, "has_open": ob["st"] in OPEN, "need_review": reviewed != key}
        nxt = next((destination for guard, destination in GRAPH.get(node, []) if guard == "*" or guards.get(guard)), None)
        if nxt in (None, "DONE", "ABORT"):
            path.append(nxt or "STUCK")
            break
        node = nxt
    return ob, path


def bfs() -> List[Tuple[str, str]]:
    """Probe every state/event pair through ``apply``."""
    fired = set()
    for state in STATES:
        for event in EVENTS:
            ob = new_ob(state)
            if event == "ESCALATE":
                ob["disputed_at"]["D1"] = {1, 2}
                ob["unsat_at"]["D1"] = {1, 2}
            payload = dict(PL_STUB[event])
            payload["verify_key"] = "k"
            ledger = {payload.get("ledger_ref", "x"): {}}
            result = R.apply(ob, event, ACTOR.get(event), payload, 1, "k", ledger)
            if not str(result).startswith("REJECT"):
                fired.add((state, event))
    return sorted(set(T) - fired)


def no_second_semantics() -> List[str]:
    """Detect obvious duplicated transition/check semantics in this module."""
    source = inspect.getsource(inspect.getmodule(run))
    bad = []
    for pattern, reason in [(r"\bT\[", "直接读转移表"), (r"ACTOR\[", "自行校验 actor"), (r"\bst\s*==\s*['\"]\w+['\"].*→", "自写状态转移")]:
        if re.search(pattern, source):
            bad.append(reason)
    return bad
