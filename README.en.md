# claude-ops

> Personal Claude Code rule system — layered pipeline, hard gates, enforced guards, evidence-first.
>
> [中文 README](./README.md)

A rule system that keeps Claude Code from concluding "should work" when doing engineering or research tasks. Core idea in one line: **L0 is the brain, not the hands** — the main loop only thinks, plans, supervises, and closes; the grunt work goes to cheaper or better-suited models by tier, and L0 makes the final call with actual evidence in hand.

## What this repo is

The **rule body** of my `~/.claude/`, no runtime data.

56 files, by directory:

| Directory | Files | Content |
|---|---|---|
| `ops/` | 14 | One source of truth for each hard gate (never reconstruct commands from memory) |
| `hooks/` | 13 | The enforcement layer (PreToolUse / Stop / SessionStart hook scripts) |
| `workflows/` | 9 | Workflow scripts (`deep-research.js`, the `finding-loop/` Python module, `_retired/`) |
| `docs/` | 8 | Historical task archives under `docs/superpowers/{journal,plans,specs}/` (kept as examples) |
| `bin/` | 5 | CLI helpers (`newproj` / `mem-check` / `mistakes` / `l2` / `exp-index`) |
| `agents/` | 1 | Currently only `fable-readonly-advisor.md` (Fable5 advisor subagent definition) |
| top level | 6 | `CLAUDE.md` (13 iron laws + 4 chapters), `README.md` / `README.en.md`, `RTK.md`, `settings.json`, `.gitignore` |

**Not included**: `projects/` (session data), `plugins/` (cache), `backups/`, `sessions/`, `tasks/`, machine-local overrides (`settings.local.json`) — all runtime, never committed (see `.gitignore`).

## Why it looks this way

Because the single most common failure in long sessions is **"felt like I did it" = "actually did it"**. This rule system turns every step where I've slipped into a **hard gate** — **a few high-frequency slip paths are backed by hooks** (direct push to `main`, review call missing `-s read-only`, quantifier claim without a search command this turn, "I'll…" promise without a matching action) — **the rest of the hard gates still rely on L0 to execute the rule and leave a paper trail**. CLAUDE.md explicitly says "guards do not replace any hard gate."

Three failure modes I keep hitting, each with a specific answer:

| Failure mode | The rule that catches it |
|---|---|
| **The plan is wrong, so every strict later review is building on a wrong foundation** | Plan-Gate: any spec/plan that will drive delegation must pass a Codex heterogeneous adversarial review (standard pipeline: before delegation; empirical flow: step ⑧ after the experiments produce data) |
| **Same-family models can share blind spots** | Frontier review is always Codex `gpt-5.6-sol` (assuming L0 is a Claude-family model) — the model doing all the judgment doesn't get to sign off on itself |
| **"Should be fine" slides straight into the conclusion** | Evidence has three tiers (first-hand / second-hand / zeroth — "zeroth" = a number that is true by protocol or construction, looks like data but carries zero information); a Stop hook blocks quantifier claims ("21 total", "all N passed") when no search command actually ran this turn |

## Two routes: standard pipeline vs empirical flow

Route the task first. One-line test: **could I build two versions, run them, and let numbers decide?**

- **Yes** → **empirical flow**: build prototypes in parallel → **actually run them and produce data** → adversarial review **afterwards** (so the frontier model evaluates facts, not claims)
- **No** (only one path exists; or the output itself IS the final artifact, e.g. spec text, architecture verdict) → **standard pipeline** (next section)
- **Not sure** → default to standard pipeline

**The empirical flow has four entry criteria — all four must hold** (miss one → standard pipeline):

1. At least two candidates whose **key mechanisms differ substantively** (rename / re-parameterize / an obviously-worse strawman doesn't count), all runnable on the same interface, data, resource budget, and measurement pipeline
2. This choice will directly change downstream spec, implementation direction, or resource commitment; at least one main metric or hard constraint **can only be known by actually running it**
3. **Before results are seen**, L0 has written a decision table (which result region → which action, with at least two regions driving different actions)
4. Every candidate leaves traceable raw data, config, code hash, and lets you estimate noise

**The nine-step flow** (details in `ops/empirical-flow.md`; skeleton only here):

```
① Pre-register (candidate list + metric contract + decision table + shared measurement code, passing golden samples)
② Design review (advisory, non-blocking) → unfair measurement → back to ①
③ Fan out N L1s writing prototypes (spike; narrow exception: allowed to dispatch before Gate)
④ Prototype quick review (cross-family; if the author is codex, Claude reviews; advisory)
⑤ Actually run → runs/YYYY-MM-DD-<slug>-<candidate>/
⑥ Blind analysis (⑥A Codex sol ultra evidence ledger ‖ ⑥B Claude fresh-context independent review)
⑦ L0 personally reads raw data → forms disagreement list → writes spec/plan
⑧ Plan-Gate (hard gate, same sol-ultra four-dimension single review as standard pipeline)
⑨ Six-step productization protocol → PR-GATE
```

**Why is adversarial review pushed to the back?** With Plan-Gate up front, the reviewer is judging a spec that hasn't been built yet — it can only guess vulnerabilities by reasoning. On the 2026-08-03 CLAUDE.md refactor, four Plan-Gate rounds produced 64 items, and **more than half of rounds 2–4 were induced by the review itself** (fixing r1 spawned r2, fixing r2 spawned r3, fixing r3 spawned r4); the subsequent **7 L3 rounds on the same task caught 36 items**, including the pre-existing `plan-gate-direction.js` fail-open surfaced in r4/r5 — because L3 was reading the finished code, not guessing. A separate task on 2026-08-07 — a six-file empirical-flow rework — went to post-implementation L3 and the **first round already surfaced 5 blocking items**, reinforcing the same pattern.

⚠️ **Both routes still pass Plan-Gate and L3 — only Plan-Gate's timing differs**: standard pipeline runs it **before the spec/plan is used to drive delegation**; the empirical flow runs it **after the experiments produce data and L0 has written the spec/plan** (step ⑧). Plan-Gate wasn't removed, only moved.

⚠️ **Steps ⑥/⑦ have a hard requirement: model reports are only advisory, L0 must personally read the raw data** — don't just copy ⑥A/⑥B's conclusions. Even a fully-executed nine-step flow **cannot eliminate shared blind spots** (common metric definitions, shared measurement code, thinking patterns common to a model family); after ⑨ productization, run L2/L3 on the same hash and rerun tests + review on any substantive change.

Narrow exception: ① shared measurement code and ③ candidate prototypes may be dispatched before Gate (only when all four boundary conditions hold; see the comparison table in `ops/empirical-flow.md` §2③) — **probing may run early, delivery may not**; the productized spec/plan from ⑦ still has to pass ⑧ before implementation can be dispatched.

## Layered structure

```
L0 brain (this session itself)     ← think, split, define acceptance criteria, close
   ↓ delegate
L1 execution (codex luna / Sonnet 5 / Haiku 4.5)
   ↓ output
L2 quick review (cheap cross-family coarse pass, fail-non-blocking, cannot replace L3)
   ↓
L3 final review (Codex gpt-5.6-sol xhigh, read-only)  ← hard gate
   ↓
L0 closes (read L3 → verify each item → call it)
```

**Plan-Gate** (single sol-ultra process, four-dimension single review) reviews the spec + plan, not the code. **Its trigger point splits by route**: standard pipeline fires it **before the spec/plan is used to drive delegation**; the empirical flow fires it at step ⑧ (after the experiments produce data). This front-loads "heterogeneous perspective" to the foundation, where mistakes are cheapest to catch.

**Fable 5** does **not** sit in the execution/review tiers — it's a **read-only advisor** for Plan-Gate architecture deadlocks only, narrowly triggered, requiring live user consent each time.

## The hard gates

| Anchor | Purpose | When it fires |
|---|---|---|
| `[PLAN-GATE]` | Any spec/plan that will drive delegation must pass adversarial review (standard: before delegation; empirical: step ⑧) | Any planning artifact that will drive execution |
| `[OWNERSHIP]` | Intent and go/no-go belong to L0 | Always |
| `[EVIDENCE-FIRST]` | Every tier verifies; evidence tiered into three levels (first-hand / second-hand / zeroth) | Always |
| `[SELF-CONTAINED-BRIEF]` | Delegation briefs must stand on their own | Every subagent call |
| `[DELEGATION-BAND]` | Single delegation ≤400 LOC target, ≤600 hard cap (implementation code; tests excluded) | Every delegation / when L0 codes directly |
| `[GRANT-PERMISSIONS]` | Grant enough permissions in one shot; reviewers stay read-only | Every codex / subagent call |
| `[DIAGNOSE-FAILURE]` | Diagnose failures before retrying — locate the cause, then rewrite the brief / escalate / take over | Any tier producing poor output |
| `[SKILL-PIPELINE]` | Coding/research always starts with `brainstorming` | Any coding or research task |
| `[PR-GATE]` | GitHub changes go through PR only, must pass Codex final review | Any change destined for GitHub |
| `[PRIMARY-SOURCE]` | External material that needs an original source must go through codex; `WebSearch` snippets are never quotable as source | Any external citation |
| `[PLAIN-LANGUAGE]` | Don't coin dense jargon | Any human-facing output |
| `[FABLE-ADVISOR]` | Fable 5 as read-only advisor, break-glass only | Extremely narrow trigger |
| `[ENGINE-ASSIGNMENT]` | Frontier review is Codex-only | Always |

## The enforcement layer (hooks)

Rules on paper don't stop humans from forgetting. So the rules themselves get script backup:

- 🔴 **PreToolUse hard-block**: direct PR merge, push to default branch, review call missing `-s read-only` — blocks **recognizable direct call forms** (known gap in MISTAKES.md E006: `VAR=val cmd ...` assignment prefix bypasses the prefix globs; deferred, not patched)
- 🟡 **Stop evidence gate**: reply contains a quantifier claim ("21 total", "all passed", "no such case") but no search command ran this turn — bounced
- 🟡 **Stop promise gate**: reply contains a first-person future promise ("I'll…", "I'll add… next") without a matching tool call this turn — bounced
- **SessionStart / PreCompact / Stop journal hooks**: assistance only — SessionStart injects the list of ongoing journals, PreCompact writes a `.precompact/` snapshot, Stop reminds the model and provides a fact draft; **the canonical event stream still relies on L0's discipline** (see the "Memory and task journal" section)

Two kill-switch mechanisms, they work differently, don't mix them up:
- **`GUARD_OFF=1`**: must be **pre-exported before Claude Code starts** (`GUARD_OFF=1 claude ...`); PreToolUse runs **before** the command executes, so writing `export GUARD_OFF=1 && <cmd>` in a single call is ineffective — the `export` hasn't taken effect when the hook already fires
- **`touch ~/.claude/.guard-off`**: works mid-session too, but **you must declare the reason live and `rm -f` immediately when done**; forgetting to delete it silently disables the whole guard layer (learned the hard way on 2026-08-07)

Kill switch ≠ exemption from any hard gate — Plan-Gate, L3, PR-GATE all remain in force; the guards are only their reminder layer.

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

## Memory and task journal

Beyond hard gates and hooks, the rule system also dictates what L0 **must remember, how, and where** — because the thing that most reliably vanishes across sessions is "the mistake I made last time."

**Three memory tiers** (one-line test: **would this still be useful on a different project?**)

| Tier | Location | What goes here | Committed? |
|---|---|---|---|
| Global | `~/.claude/projects/<encoded-cwd>/memory/*.md` + `MEMORY.md` index in the same dir (on this machine: `projects/-Users-macbookpro/memory/`) | Cross-project reusable lessons / preferences / methodologies (index auto-loads at session start) | This repo's `.gitignore` excludes top-level `projects/` — not committed |
| Project | `<project>/docs/superpowers/memory/*.md` + that project's `MEMORY.md` | State and details that only matter inside one project; read the project's `MEMORY.md` on entry | **Each project decides for itself**; this repo's `.gitignore` does NOT auto-exclude it |
| Timeline | `<project>/docs/superpowers/journal/YYYY-MM-DD-<slug>.md` | One file per task; header status snapshot (overwritten each turn) + event stream (**append-only, never rewritten** — otherwise unfavorable records get "tidied away" and the journal loses its evidence value) | Same as above |

**When to create a journal** (any trigger fires it): complex task going through brainstorm+plan; entering Plan-Gate; a single implementation delivery >400 LOC; a spec/plan has been produced and is going to be executed; committing to the empirical flow (entry criteria conclusions + decision table must be logged **before any pre-Gate implementation dispatch** — retroactive logging doesn't count). Plain conversation, small fact lookups, and ordinary ≤400 LOC delegations do NOT create a journal.

**Mistake log `<project>/docs/superpowers/journal/MISTAKES.md`**: project-specific traps only (cross-project lessons go into global `memory/`). Before delegating, `bin/mistakes [keyword]` prints ready-to-paste lesson snippets for subagent briefs (subagents have no conversation memory — a file path won't help them).

**Memory entry shape**: frontmatter with `name` / `description` / `type` (user | feedback | project | reference); body uses `[[name]]` for cross-links. Scan for an existing entry that already covers the same thing before writing — update the old one rather than adding a duplicate; delete outright when something turns out to be wrong.

**Healthcheck / tools**:
- `bin/mem-check [dir]` — 5 **purely structural** checks (dangling `[[links]]`, `MEMORY.md` index consistency, orphan notes, missing frontmatter fields, near-duplicates); **does NOT judge whether content should be demoted** — that's a human call
- `bin/mistakes [keyword]` — extracts active items from MISTAKES.md into a brief snippet
- **Hooks only assist**: `SessionStart` injects the list of ongoing journals, `PreCompact` writes a `.precompact/` snapshot, `Stop` reminds the model to update the journal and provides a fact draft — **the canonical event stream itself still relies on L0's discipline** (`ops/journal.md` explicitly says "event-stream content still relies on discipline, no machine enforcement")

⚠️ **This repo ships the mechanism, not the contents**: global memory entries live under `~/.claude/projects/`, excluded by this repo's top-level `projects/` in `.gitignore`; project memory and journals live under each project's own `docs/superpowers/`, and whether they get committed is that project's call. **Don't clone my global memory and reuse it** — it's mine, accumulated from my own mistakes, and adopting it wholesale would pollute your judgment. Grow your own.

## What a run looks like

A standard-pipeline typical task (empirical flow ①–⑦ see the earlier section; from ⑧ onward, resume with steps 3 onward below):

1. `brainstorming` skill to clarify intent → get user approval (HARD-GATE: no approval, no code)
2. `spec` + `plan` skill to split with explicit acceptance criteria
3. **Plan-Gate** (single sol-ultra process, four-dimension single review, presumption of guilt): fire it via the complete script in `ops/plan-gate.md`; NO-GO items go to L0 for triage — **go/no-go belongs to L0** (an objection verified as a false positive may be released with a written reason; non-critical suggestions are L0's call)
4. Delegate to L1 (default codex luna; deeply coupled changes → Sonnet 5; mechanical batch → Haiku 4.5), self-contained brief + explicit permission grant + verbatim inclusion of the "environment and threat model" block from `ops/plan-gate.md` §🔻
5. L1 implements (start with `test` writing a failing test → `build` incremental implementation → `review` author self-check)
6. **L2 quick review** (cheap cross-family coarse pass, fail-non-blocking, cannot replace L3; see `ops/l2.md`)
7. **L3 final review**: use the call form in `ops/plan-gate.md`, e.g. `codex exec -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -s read-only review --uncommitted`
8. L0 triages → fixes each item → **re-run L3 on the FROZEN final state** (moving-target trap, §2.6; a GO on each round only holds for that round's moving target, not for the final state) → after frozen-state L3 passes, **L0 calls it**
9. To land on GitHub: read `ops/pr-merge.md` first → `gh pr create` → codex reviews the PR + head/base dual-OID binding + clean-worktree three-gate → re-fetch remote OIDs and match against the paper trail before merge → **the user (not L0) performs the merge** (L0 only issues a go/no-go recommendation and never runs `gh pr merge`)

## Who can use this

I built this from mistakes I made in my own long tasks. **Default is single-machine, single-user use** — paths are hardcoded to `/Users/macbookpro/...`.

⚠️ **The default threat model is "local single-user development, no untrusted input, output does not serve external parties"** (see `ops/plan-gate.md` §🔻 — every codex brief carries this block verbatim to override codex's default public-internet multi-tenant product model). **If the output will go online, serve external parties, process other people's data, or enter a public repo, you MUST rewrite this threat model block** — otherwise an outside reader using these rules to review an outward-facing product will follow the instruction and ignore inputs and permissions genuinely reachable in that environment.

To reuse cross-machine:

1. A different username means rewriting paths (or switching them to `$HOME`)
2. `settings.json` has my personal proxy tokens and base URLs — replace with your own
3. `Fable 5` / `Codex gpt-5.6-sol / gpt-5.6-luna` are model names exposed by my local proxy — the names in your environment will differ
4. This repo **does not ship skill packs** — the skills explicitly mentioned in `CLAUDE.md` (`brainstorming`, `spec`, `plan`, `build`, `incremental-implementation`, `test`, `review`, `ship`, `systematic-debugging`, `debugging`, `writing-plans`, `dispatching-parallel-agents`, `using-agent-skills`, `using-superpowers`) are distributed by the marketplaces listed under `enabledPlugins` / `extraKnownMarketplaces` in `settings.json` — Addy's `agent-skills`, `superpowers-marketplace`, `openai-codex`, `ralph-loop`. If you have other private local skills to wire in, configure your own marketplace or symlink; this repo does not provide them

## License

Rule text: do whatever you want, no warranty — this is my personal workflow, not a product.

## Cite

If this rule system inspires yours, the repo lives at:

```
https://github.com/yiyang774/claude-ops
```
