#!/usr/bin/env python3
"""真实历史回放：D08 —— 本模块存在的唯一理由。

D08 是本会话真实发生的一条 Plan-Gate 意见：
  「replay/覆盖率不能证明相对基线的改进」
它被提了 9 次、横跨 r1–r4 四轮，**每轮 Opus 都写「采纳」、每轮都真改了东西**
（r1 加 replay 验收 → r2 加诚实声明 → r3 加留出验证 → r4 加前瞻指标表），
问题却一次没消失。原因：没有任何机制知道「这是同一条 D08」。

本测试回放那段真实事件流，验证本模块会不会走出不同结果。
**可证伪性**：若模块无效，D08 会像历史上一样永远 fix_pending、永不裁定。

数据来源：.plangate/finding-replay/findings.md（跨轮身份归并）
         .plangate/finding-loop-r2/ledger-derived.md（逐轮 disposition 与实际动作）
"""
import pytest
from finding_loop import reducer as R

# ══ 真实历史：D08 在四轮里的处置与实际动作 ══
D08_HISTORY = [
    (1, "accept", "加 replay 验收 V7（70% 阈值）"),
    (2, "accept", "加「诚实声明：这是事后拟合」"),
    (3, "accept", "加留出验证（B1/B2 归纳测 B3）"),
    (4, "accept", "加前瞻指标表（触发率/误报/成本）"),
]
DK = ("replay不能证明相对基线改进", "criterion:需基线对照实验", "rev1")


def _accept_payload(action):
    return dict(missing_artifact="与简单基线的对照实验",
                acceptance_criterion="报告图 vs 基线的错误拦截率差异",
                rationale=f"采纳；本轮动作：{action}")


def _unsat_payload(rnd, action):
    return dict(evidence=f"r{rnd} 做了「{action}」，但仍无基线对照",
                verify_key=f"k{rnd}", gap="缺基线对照实验", dispute_key=DK)


def test_history_reproduces_the_stall():
    """回放真实历史：四轮全 accept + 验证全不满足 → 永远 fix_pending，永不裁定。

    这是【历史实况】的复现，也是本测试的对照组：
    若模块什么都没改变，D08 就该停在这里。
    """
    ob, ledger = R.new_ob("observed"), {}
    for rnd, _, action in D08_HISTORY:
        assert R.apply(ob, "DISPOSED.accept", "L0_Opus", _accept_payload(action),
                       rnd, f"k{rnd}", ledger) == "fix_pending"
        assert R.apply(ob, "VERIFIED.unsatisfied", "verifier", _unsat_payload(rnd, action),
                       rnd, f"k{rnd}", ledger) == "fix_pending"

    assert ob["st"] == "fix_pending", "四轮 accept 后仍未闭合——与历史一致"
    assert R.cycles(ob, DK) == 0, "全程无 dispute，故争议轮次为 0（历史正是如此）"


def test_module_provides_the_missing_exit():
    """本模块提供的出口：Opus 可在 fix_pending 上转 dispute，进而两轮后强制裁定。

    历史上不存在这条路径——那正是 D08 空转四轮的原因。
    """
    ob, ledger = R.new_ob("observed"), {"ledger://adj/d08": {}}

    # r1–r2：与历史相同，采纳并修复，但验证不满足
    for rnd in (1, 2):
        R.apply(ob, "DISPOSED.accept", "L0_Opus", _accept_payload("同历史"), rnd, f"k{rnd}", ledger)
        R.apply(ob, "VERIFIED.unsatisfied", "verifier", _unsat_payload(rnd, "同历史"), rnd, f"k{rnd}", ledger)
    assert ob["st"] == "fix_pending"

    # r3：Opus 不再机械采纳，改为 dispute（历史上没有这一步）
    assert R.apply(ob, "DISPOSED.dispute", "L0_Opus",
                   dict(rationale="我认为『加更多验收条款』不是这条要的东西", dispute_key=DK),
                   3, "k3", ledger) == "disputed"
    R.apply(ob, "VERIFIED.unsatisfied", "verifier", _unsat_payload(3, "转争议"), 3, "k3", ledger)
    assert R.cycles(ob, DK) == 1, "第 3 轮：双边同轮都表态 → 计 1 轮"

    # r4：仍分歧
    R.apply(ob, "DISPOSED.dispute", "L0_Opus", dict(rationale="仍不认同", dispute_key=DK), 4, "k4", ledger)
    R.apply(ob, "VERIFIED.unsatisfied", "verifier", _unsat_payload(4, "仍无基线"), 4, "k4", ledger)
    assert R.cycles(ob, DK) == 2, "两轮双边分歧 → 达到 CLAUDE.md 的『最多两轮』上限"

    # 达标即可升级并强制裁定
    assert R.apply(ob, "ESCALATE", "系统", dict(cycles=2, dispute_key=DK), 4, "k4", ledger) == "awaiting_adj"
    assert R.apply(ob, "ADJUDICATED.dismissed", "L0_Opus",
                   dict(rationale="确认无法用现有数据证明相对基线的改进，判定为设计范围外",
                        dispute_key=DK, cycle_evidence=[3, 4], ts="2026-07-28",
                        ledger_ref="ledger://adj/d08"),
                   4, "k4", ledger) == "closed_adjudicated"

    assert ob["st"] == "closed_adjudicated", "D08 终于有了结局——历史上它空转到第九次"
    assert ledger["ledger://adj/d08"]["sealed"], "裁定已封存留痕"


def test_escalation_is_impossible_without_real_disagreement():
    """反面：只有 Opus 单方 dispute（verifier 从未表态），不得升级。

    这防的是「假装有争议来跳过修复」。
    """
    ob, ledger = R.new_ob("observed"), {}
    for rnd in (1, 2, 3):
        R.apply(ob, "DISPOSED.dispute", "L0_Opus",
                dict(rationale="单方声称有争议", dispute_key=DK), rnd, f"k{rnd}", ledger)
    assert R.cycles(ob, DK) == 0, "verifier 未表态 → 一轮都不算，不得升级"


def test_criterion_change_does_not_launder_the_cycle_count():
    """反面：轻改 criterion 试图重置轮次 —— 记录为已知风险，本测试锁定当前行为。

    spec §8.2 已登记：dispute_key 由调用方给，criterion 轻改即可重置轮次（未根治）。
    本测试如实断言这个【缺陷仍然存在】，防止它被误以为已修。
    """
    ob, ledger = R.new_ob("observed"), {}
    dk_a = ("同一命题", "criterion:v1", "rev1")
    dk_b = ("同一命题", "criterion:v2", "rev1")      # 只改了 criterion

    for rnd, dk in ((1, dk_a), (2, dk_a)):
        R.apply(ob, "DISPOSED.dispute", "L0_Opus", dict(rationale="r", dispute_key=dk), rnd, "k", ledger)
        R.apply(ob, "VERIFIED.unsatisfied", "verifier",
                dict(evidence="e", verify_key="k", gap="g", dispute_key=dk), rnd, "k", ledger)
    assert R.cycles(ob, dk_a) == 2

    R.apply(ob, "DISPOSED.dispute", "L0_Opus", dict(rationale="r", dispute_key=dk_b), 3, "k", ledger)
    R.apply(ob, "VERIFIED.unsatisfied", "verifier",
            dict(evidence="e", verify_key="k", gap="g", dispute_key=dk_b), 3, "k", ledger)

    assert R.cycles(ob, dk_b) == 1, "改 criterion 后轮次从 1 重新起算 —— 这是已知未根治缺陷"
