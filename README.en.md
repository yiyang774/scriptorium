# claude-ops

> Personal Claude Code rule system — layered pipeline, hard gates, enforced guards, evidence-first.
>
> [中文 README](./README.md)

A rule system that keeps Claude Code from concluding "should work" when doing engineering or research tasks. Core idea in one line: **L0 is the brain, not the hands** — the main loop only thinks, plans, supervises, and closes; the grunt work goes to cheaper or better-suited models by tier, and L0 makes the final call with actual evidence in hand.

## What this repo is

The **rule body** of my `~/.claude/`, no runtime data.

57 files:
- `CLAUDE.md` — global working rules (13 iron laws + 4 chapters of layered discipline)
- `ops/*.md` — the one source of truth for each hard gate (never reconstruct commands from memory)
- `hooks/` — the enforcement layer (PreToolUse / Stop / SessionStart hooks)
- `bin/` — CLI helpers (new project scaffolding, mistake search, memory healthcheck)
- `agents/`, `workflows/`, `docs/` — subagent definitions, workflow scripts, shared docs
- `settings.json` — Claude Code's model routing and hook registration
- `RTK.md` — index for Rust Token Killer (a command proxy that saves 60-90% dev tokens)

**Not included**: `projects/` (session data), `plugins/` (cache), `backups/`, `sessions/`, `tasks/`, machine-local overrides (`settings.local.json`) — all runtime, never committed (see `.gitignore`).

## Why it looks this way

Because the single most common failure in long sessions is **"felt like I did it" = "actually did it"**. This rule system turns every step where I've slipped into a **hard gate**: what must be reviewed gets reviewed, what must be run gets run, and skipping trips a hook.

Three failure modes I keep hitting, each with a specific answer:

| Failure mode | The rule that catches it |
|---|---|
| **The plan is wrong, so every strict later review is building on a wrong foundation** | Plan-Gate: spec/plan must pass a Codex heterogeneous adversarial review before delegation |
| **Same-family models can't see their own blind spots** | Frontier review is always Codex `gpt-5.6-sol` (assuming L0 is a Claude-family model) — the model doing all the judgment doesn't get to sign off on itself |
| **"Should be fine" slides straight into the conclusion** | Evidence has three tiers (first-hand / second-hand / zeroth); a Stop hook blocks quantifier claims ("21 total", "all N passed") when no search command was actually run this turn |

## Layered structure

```
L0 brain (this session itself)     ← think, split, define acceptance criteria, close
   ↓ delegate
L1 execution (codex luna / Sonnet 5 / Haiku 4.5)
   ↓ output
L2 quick review (cross-family coarse pass, non-blocking)
   ↓
L3 final review (Codex gpt-5.6-sol xhigh, read-only)  ← hard gate
   ↓
L0 closes (read L3 → verify each item → call it)
```

**Plan-Gate** (single sol-ultra review, covers four dimensions) fires **before** delegation — it reviews the spec + plan, not the code. This front-loads "heterogeneous perspective" to the foundation, where mistakes are cheapest to catch.

**Fable 5** does **not** sit in the execution/review tiers — it's a **read-only architecture advisor** for Plan-Gate deadlocks, narrowly triggered, and requires live user consent each time.

## The hard gates

| Anchor | Purpose | When it fires |
|---|---|---|
| `[PLAN-GATE]` | Spec/plan must pass adversarial review before delegation | Any planning artifact that will drive execution |
| `[OWNERSHIP]` | Intent and go/no-go belong to L0 | Always |
| `[EVIDENCE-FIRST]` | Every tier verifies; evidence tiered into three levels | Always |
| `[SELF-CONTAINED-BRIEF]` | Delegation briefs must stand on their own | Every subagent call |
| `[DELEGATION-BAND]` | Single delegation ≤400 LOC target, ≤600 hard cap (implementation code) | Every delegation / when L0 codes directly |
| `[GRANT-PERMISSIONS]` | Grant enough permissions in one shot; reviewers stay read-only | Every codex / subagent call |
| `[SKILL-PIPELINE]` | Coding/research always starts with `brainstorming` | Any coding or research task |
| `[PR-GATE]` | GitHub changes go through PR only, must pass Codex final review | Any change destined for GitHub |
| `[PRIMARY-SOURCE]` | Fetching primary sources requires codex; `WebSearch` snippets are never quotable as source | Any external citation |
| `[PLAIN-LANGUAGE]` | Don't coin dense jargon | Any human-facing output |
| `[FABLE-ADVISOR]` | Fable 5 as read-only advisor, break-glass only | Extremely narrow trigger |
| `[ENGINE-ASSIGNMENT]` | Frontier review is Codex-only | Always |

## The enforcement layer (hooks)

Rules on paper don't stop humans from forgetting. So the rules themselves get script backup:

- 🔴 **PreToolUse hard-block**: direct PR merge, push to default branch, review call missing `-s read-only` — fails outright
- 🟡 **Stop evidence gate**: reply contains a quantifier claim ("21 total", "all passed", "no such case") but no search command ran this turn — bounced
- 🟡 **Stop promise gate**: reply contains a first-person future promise ("I'll…", "I'll add… next") without a matching tool call this turn — bounced
- **SessionStart / PreCompact / Stop journal hooks**: automatically record session-boundary events (so I can't "forget" to leave a paper trail)

Kill switch: `export GUARD_OFF=1` (single call) or `touch ~/.claude/.guard-off` (persistent, but **you must declare it live and delete immediately when done**). The kill switch does NOT exempt any hard gate — it only silences the hook reminder layer.

## `ops/` files are the one source of truth

`CLAUDE.md` only holds pointers, never copies. For every hard gate, the **runnable command, argument order, failure handling, and battle-scars** live in `ops/<name>.md`:

- `ops/plan-gate.md` — Plan-Gate command + subagent type comparison + L3 fan-out data
- `ops/l2.md` — L2 quick review: model selection, format, fail-non-blocking details
- `ops/pr-merge.md` — PR three-gate (head/base dual-OID binding + clean worktree)
- `ops/enforcement.md` — guard hook self-test, adding rules, temporary disable
- `ops/preflight.md` — one-shot checklist before running experiments / connecting remotes / using GPU
- `ops/journal.md` — seven event types that must be logged, dual-status field in mistake log
- `ops/line-count.md` — mechanical LOC verification for `[DELEGATION-BAND]`
- `ops/empirical-flow.md` — empirical flow (when the task splits into ≥2 comparable candidates)
- `ops/project-layout.md` — project skeleton / slug naming / experiment index conventions
- `ops/fable5.md` — Fable5 advisor's four-item record and live consent fail-closed rules
- `ops/codegraph.md` — code location and blast-radius analysis

**Read the corresponding ops file before firing a hard gate** — reconstructing arguments from memory either silently fails or gets blocked by a hook, and I've paid for that lesson.

## What a run looks like

A typical complex task:

1. `brainstorming` skill to clarify intent → get user approval (HARD-GATE: no approval, no code)
2. `spec` + `plan` skill to split with explicit acceptance criteria
3. **Plan-Gate**: `codex exec -m gpt-5.6-sol -c model_reasoning_effort="ultra" -s read-only` four-dimension single review → NO-GO bounces spec/plan back for revision + re-review
4. Delegate to L1 (default codex luna; deeply coupled changes → Sonnet 5; mechanical batch → Haiku 4.5), self-contained brief + explicit permission grant
5. L1 implements (start with `test` writing a failing test → `build` incremental implementation → `review` five-dimension self-check)
6. **L2 quick review** (relief funnel, non-blocking)
7. **L3 final review**: `codex exec -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -s read-only`
8. L0 closes: read L3 → verify each item → fix or accept → call it → **re-run final review on the frozen state** (moving-target trap)
9. To land on GitHub: `gh pr create` → codex reviews the PR head SHA → **user (not L0) merges**

## Who can use this

I built this from mistakes I made in my own long tasks. **Default is single-machine use** — paths are hardcoded to `/Users/macbookpro/...`. To reuse cross-machine:

1. Different username means rewriting paths (or switching them to `$HOME`)
2. `settings.json` has my personal proxy tokens and base URLs — replace with your own
3. `Fable 5` / `Codex gpt-5.6-sol / gpt-5.6-luna` are model names exposed by my local proxy — the names in your environment will differ
4. This repo **does not ship skill packs** — the skills mentioned in `CLAUDE.md` (`brainstorming`, `autoresearch`, `innovation-hunt`, `oral-review`, Addy's agent-skills, the superpowers suite, etc.) come from Claude Code's plugin marketplace or standalone repos; follow the `enabledPlugins` and `extraKnownMarketplaces` sections in `settings.json` to obtain them

## License

Rule text: do whatever you want, no warranty — this is my personal workflow, not a product.

## Cite

If this rule system inspires yours, the repo lives at:

```
https://github.com/yiyang774/claude-ops
```
