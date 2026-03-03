---
id: 8q0zc6
title: "Synthesis: 8p-Era Development Patterns (Feb 2026)"
type: standard
tags: [synthesis]
created_at: "2026-03-01 23:33:32"
status: active
---

# Synthesis: 8p-Era Development Patterns (Feb 2026)

**Date**: 2026-03-01
**Context**: Consolidated synthesis of 35 retros from the 8p-era (Feb 2026), covering E2E testing infrastructure, assignment-driven workflows, CLI architecture, spec quality, and agent discipline patterns.
**Author**: Claude Opus 4.6
**Type**: Standard [synthesis]
**Sources**: 35 retros (8p2ozm through 8prv7e)

## What Went Well

- **E2E testing matured significantly**: Block-budget timing model established (90s overhead + blocks/2.5 x 25s per turn), TS-format directory migration completed across 10+ packages, E2E test suite restructuring reduced cost by 70% (31 TCs to 9 in ace-lint). Identified in 12/35 retros.
- **Assignment fork-run delegation at scale**: 93-97% success rate for fork-run batch delegation across multiple large tasks (273, 274, 278, 296). Tasks with 14-26 parallel subtrees completed successfully. Identified in 8/35 retros.
- **Three-tier review cycle consistently effective**: code-valid/code-fit/code-shine reviews caught real bugs at each tier — ATOM layer misplacements, security issues (command injection), nil-safety gaps, interface drift. Each round had diminishing but real returns. Identified in 10/35 retros.
- **Proof-then-implement approach validated**: Two-phase approach (proof contracts first, then implementation) in ace-sim prevented wasted design effort and produced accurate contracts. Identified in 3/35 retros.
- **ATOM architecture adherence strong**: New gems (ace-idea, ace-retro, ace-sim) consistently followed atoms/molecules/organisms/models layering. Identified in 8/35 retros.
- **Commit reorganization workflow reliable**: `ace-git-commit` consistently grouped messy intermediate commits into clean, scope-based logical commits. Identified in 5/35 retros.

## What Could Be Improved

### 1. Spec Quality and Consistency (Identified in 9/35 retros)

The most impactful recurring theme. Spec contradictions, under-specified contracts, and missing consumer audits caused the most rework across the 8p era.

- **Spec self-contradictions**: Task 227 said "replace synthesis" in the Overview but "preserve synthesis" in Design Decisions. This single contradiction caused the entire implementation to go in the wrong direction. The root cause was misdiagnosed — 40 hours spent on architectural changes when actual issue was a ~30-line JSON parsing bug.
- **Artifact chain contracts under-specified**: Task 296 shipped a YAML-oriented chain while the final intent was markdown-first. Required unplanned phase-3 rewrite because artifact filenames, handoff semantics, and source input types were left implicit.
- **Pilot validation scope mismatch**: Task 280's pilot validated format viability but not migration completeness. The experiment architecture was never implemented in production code, leading to false positive test results.
- **Interface contract drift**: Method signatures in specs didn't match implementation (e.g., `extract_from_multiple` vs `synthesize`). Specs became inaccurate documentation.
- **Missing consumer audits**: Output format changes didn't list all workflow consumers needing updates, causing agents to follow stale workflows.

### 2. E2E Testing Pain Points (Identified in 15/35 retros)

E2E testing consumed the most engineering effort during the 8p era but also saw the most improvement.

- **System path destruction incident**: /opt/homebrew destroyed during parallel E2E execution due to `--dangerously-skip-permissions` without guardrails. Remediated with system path protection hooks.
- **Premature expensive reruns**: Full suite reruns triggered before all known fixes were batched, wasting 10+ minute cycles with low signal.
- **Environment bootstrapping failures**: Missing package resolution, Git baseline assumptions, docs sandbox discovery state — most regressions were infrastructure issues, not code logic failures.
- **Report directory mismatch**: Two independent actors (Ruby `short_id` regex and LLM agent) computing the same directory name differently. Independent computation by multiple actors is a design smell — compute once, pass explicitly.
- **Scenario spec drift**: Under-specified setup constraints, ambiguous command forms, and implicit sandbox assumptions caused false negatives.

### 3. Assignment Workflow Gaps (Identified in 8/35 retros)

- **Fork subtrees leave uncommitted artifacts**: Fork-run completes but leaves proof/work files uncommitted, requiring manual `git status` checkpoint.
- **Missing phase start command**: No CLI command to transition phase from `pending` to `in_progress` — required manual phase file editing.
- **Skill vs CLI invocation confusion**: `ace-release` treated as executable instead of skill workflow. Phase instructions need explicit skill references.
- **Fork-run not treated as mandatory**: Fork subtree detection was treated as advisory rather than mandatory delegation trigger, causing context window exhaustion.
- **Idle orchestrator time wasted**: 60% of orchestrator time spent polling during fork-runs with no productive parallel work.

### 4. Agent Behavior Discipline (Identified in 6/35 retros)

- **False completion claims**: Presenting diffs or proposed changes as "applied" without actually running the edits. Simulation results framed as already baked into specs when files were still draft.
- **Freeform instructions produce incomplete work**: When coworker jobs used "Implement task X" instead of `/ace:work-on-task X`, agents built isolated components without loading context, skipped acceptance criteria, and reported "done" incorrectly.
- **ATOM layer misplacement recurring**: Classes performing File I/O placed in atoms/ instead of molecules/. This was caught by reviews, not at implementation time. The #1 recurring review finding.
- **Opportunistic changes outside task scope**: Fork-run agents sometimes modified files unrelated to their assigned task.

### 5. CLI and Ruby Technical Debt (Identified in 7/35 retros)

- **dry-cli `type: :integer` doesn't coerce**: Values arrive as strings regardless of type declaration. Caused silent failures when strings reached strict consumers (Faraday).
- **dry-cli repeated flags broken**: Ruby OptionParser Array converter overwrites rather than accumulates. Required ArgvCoalescer workaround at ARGV level.
- **In-process vs subprocess CLI testing**: Fork-run agents wrote CLI tests using `Open3.capture3` (1-7s per test) instead of `invoke_cli` (0.004s). Performance regression of 267-1585x.
- **Minor version bumps have large blast radius**: Bumping ace-support-core from 0.24 to 0.25 required updating 14 gemspecs across the monorepo.
- **Ruby constant resolution is lexical-first**: Module extraction breaks when extracted module references host class constants unqualified. Requires explicit prefixing.
- **Boolean/nil conflation**: `if options[:key]` treats `false` as "not provided" — must use `!options[:key].nil?` when `false` is a valid filter value.

## Key Learnings

### Spec Writing

1. **"Replace" means remove** — No config toggles for the old behavior. Add explicit "What Gets Removed" section. (3/35 retros)
2. **Interface contracts are commitments** — If spec defines a method signature, implementation must match or spec must be updated first. (2/35 retros)
3. **Consumer audit is required** — Any output format change must list ALL consuming workflows, configs, and docs as explicit subtasks. (3/35 retros)
4. **Problem diagnosis before architecture** — Verify root cause with targeted debugging before proposing architectural changes. (2/35 retros)
5. **Artifact chain contracts must be explicit** — For pipeline tools, filenames/extensions and handoff semantics are public behavior. (2/35 retros)
6. **Proof-before-code only works when proof artifacts are acceptance gates** — An experiment that validates architecture is not a substitute for implementing that architecture. (2/35 retros)

### E2E Testing

7. **Bash block count is the true sizing metric** — Not test case count. Budget: 8-12 blocks for ~180s target, hard max ~14 blocks. (3/35 retros)
8. **Two-component timing model** — `total_time = 90s (overhead) + (blocks / 2.5) * 25s`. Agent merges ~2-3 blocks per LLM turn. (2/35 retros)
9. **E2E failures must be classified first** — `code-issue`, `test-issue`, `runner-infrastructure-issue`. Never fix before classifying. (3/35 retros)
10. **Independent computation by multiple actors is a design smell** — Compute once, pass explicitly. When Ruby code and LLM agents independently compute the same value, disagreement is inevitable. (1/35 retros, but high impact)
11. **System path protection is a mandatory safety layer** — Not optional, especially with `--dangerously-skip-permissions` and parallel agents. (1/35 retros, critical incident)
12. **Self-contained E2E files > shared setup** — Each split file creates its own environment. Provides independence, parallel execution, simpler debugging. (2/35 retros)

### Assignment & Orchestration

13. **Fork subtree detection is a mandatory delegation trigger** — Not advisory. Prevents context window exhaustion. (3/35 retros)
14. **Skill invocations are load-bearing** — They load task specs, acceptance criteria, dependency context, and verification steps. Freeform instructions skip all of this. (1/35 retros, but high impact)
15. **Phase instructions need explicit skill references** — Generic instructions like "update PR description" lead to ad-hoc execution. Name the skill. (2/35 retros)

### Ruby & CLI Patterns

16. **Always use `!opt.nil?` for boolean flags** — Ruby's `false` and `nil` are both falsy but carry different intent. (2/35 retros)
17. **Never use bare `rescue`** — Use `rescue StandardError` at minimum. Bare rescue catches `SystemExit` and `Interrupt`. (1/35 retros)
18. **In-process CLI testing is 267-1585x faster** — Use `invoke_cli(CLI, args)` not `Open3.capture3`. (1/35 retros, but affects all gems)
19. **E2E test execution is an agent task, not a completion task** — API providers hallucinate results. When tests require filesystem/command execution, you need tool-use capabilities. (1/35 retros)
20. **Error classes must be defined before requires** — Ruby evaluates `require_relative` eagerly. Define error hierarchy in a separate block before loading components. (1/35 retros)

## Action Items

### Stop Doing

- Writing specs with "backward compatibility" hedges when the intent is replacement (3/35 retros)
- Running full E2E suite repeatedly during active fix iteration — use `--only-failures` or scenario scope (3/35 retros)
- Placing classes that perform File I/O in atoms/ directory (3/35 retros)
- Generating coworker jobs with freeform instructions instead of skill invocations (1/35 retros)
- Proceeding inline when fork subtree detection fires — always delegate via `ace-assign fork-run` (3/35 retros)
- Writing CLI tests using `Open3.capture3` when `invoke_cli` is available (1/35 retros)
- Assuming `type: :integer` in dry-cli coerces values (2/35 retros)
- Presenting proposed changes as "already applied" without verification (2/35 retros)
- Using simple `block_count x 28s` model — use two-component formula instead (1/35 retros)
- Trusting agent self-reported "done" status without skill-enforced verification (1/35 retros)

### Continue Doing

- Three-tier review cycle (code-valid/code-fit/code-shine) — catches real issues at appropriate severity levels (10/35 retros)
- Fork-run delegation for repetitive batch tasks — 93-97% success rate validates the pattern (8/35 retros)
- ATOM architecture for all new gems — testable, well-structured (8/35 retros)
- Evidence-first E2E failure classification before applying fixes (3/35 retros)
- Using `ace-git-commit` scoped grouping for commit reorganization (5/35 retros)
- Self-contained E2E test files with independent setup/cleanup (2/35 retros)
- Proof-then-implement approach for new packages (2/35 retros)
- Per-package `ace-test` runs after each change before moving to next item (3/35 retros)
- Using `.ace-defaults/` config cascade for provider defaults (2/35 retros)

### Start Doing

- **Spec consistency check**: Before implementation, verify Overview aligns with Design Decisions. Add contradiction detection to `ace-review --preset spec`. (3/35 retros)
- **Consumer audit checklist**: For any output format change, list ALL workflows/configs/docs that reference changed outputs as explicit subtasks. (3/35 retros)
- **Artifact chain contract section**: Required in task drafts for pipeline features — define input/output filenames, bundle format, prompt format, handoff rules. (2/35 retros)
- **Post-fork commit checkpoint**: Run `git status` after every fork-run completion; consider `--commit-on-complete` flag. (3/35 retros)
- **ATOM purity pre-flight check**: Before committing new classes, verify: "Does this class call File.read/Dir.glob/IO/shell? If yes, it's a molecule." (3/35 retros)
- **E2E analyze-first gate**: Require failure classification before fix execution. Enforce "fix-all-known, rerun-once" policy. (3/35 retros)
- **Phase instruction skill binding**: Phase definitions should declare required skills (e.g., `skill: ace-git-update-pr-desc`). (2/35 retros)
- **Explicit `.to_i`/`.to_f` coercion**: Add to all numeric `options.fetch()` calls in atoms that receive CLI options. (2/35 retros)
- **E2E block count pre-flight**: Before finalizing any E2E test file, count bash blocks with `grep -c` — target max 12. (2/35 retros)
- **Cross-platform file system notes**: Flag OS assumptions explicitly in specs for file system operations. (1/35 retros)

## Technical Details

### E2E Timing Model (Validated Across 3 Retros)

```
total_time = 90s (workflow overhead) + (block_count / 2.5) * 25s

Quick reference:
  3-6 blocks   -> 120-150s  (comfortable)
  7-10 blocks  -> 160-190s  (target zone)
  11-14 blocks -> 200-230s  (watch zone)
  15+ blocks   -> 240s+     (likely exceeds 300s timeout)
```

### E2E Block Consolidation Patterns (Validated)

| Pattern | Before | After | Savings |
|---------|--------|-------|---------|
| Run + verify exit code | 2 blocks | 1 block | 1 block |
| Multiple greps on same file | N blocks | 1 block | N-1 blocks |
| Create config + run tool | 2 blocks | 1 block | 1 block |
| Run + verify output + verify file | 3 blocks | 1 block | 2 blocks |

### Ruby Error-First Loading Pattern

```ruby
# Define error classes BEFORE loading components
module Ace::Bundle
  class Error < StandardError; end
  class SectionValidationError < Error; end
end
require_relative 'bundle/organisms/bundle_loader'
```

### Command Injection Prevention

```ruby
# BEFORE (vulnerable):
system("which #{cli_name} > /dev/null 2>&1")
# AFTER (safe — array form):
system("which", cli_name, out: File::NULL, err: File::NULL)
```

### CLI Testing Performance

| Method | Time per test | Use for |
|--------|--------------|---------|
| `Open3.capture3` (subprocess) | 1-7s | Never for routing tests |
| `invoke_cli` (in-process) | 0.004-0.008s | All CLI routing tests |

### Boolean/Nil Filter Pattern

```ruby
# WRONG — treats false as "not provided":
if options[:task_associated]
# RIGHT — distinguishes false from nil:
if !options[:task_associated].nil?
```

## Source Retros (35 total)

| ID | Title | Key Theme |
|----|-------|-----------|
| 8p2ozm | Task 227 Spec Contradiction | Spec contradictions |
| 8p2rl7 | Task 227 Process Improvements | Spec-to-implementation gaps |
| 8p30la | Task 227 Divergence Analysis | Root cause misdiagnosis |
| 8p5jzi | ace-e2e-test Command | Agent vs completion task distinction |
| 8p6xkk | Performant E2E Test Modules | Block-budget model |
| 8p6ylo | E2E Timing Analysis Round 2 | Two-component timing model |
| 8p72uv | Splitting Oversized E2E Tests | Block-budget validation |
| 8p9z60 | First E2E Migration (ace-lint) | TS-format migration learnings |
| 8paevs | Coworker Job Generation Failure | Skill invocations are load-bearing |
| 8pap55 | ace-lint E2E Restructuring | Coverage overlap analysis |
| 8pb29b | TS-Format E2E Migration | Legacy format removal |
| 8pbiz3 | /opt/homebrew Destroyed | System path protection |
| 8pgdyj | Task 235 Assign-Drive | Assignment execution patterns |
| 8pjo0c | Task 273 Namespace Migration | Fork-run at scale |
| 8pke7r | E2E Test Fixes — Patch Releases | Boolean/nil, sandbox isolation |
| 8pkg3z | ace-b36ts Scenario ID Mismatch | test-id must match directory |
| 8pkgym | E2E Test Fixes | Multi-pass fix cycles |
| 8pknmg | E2E Report Directory Mismatch | Independent computation smell |
| 8pknml | Commit Reorganization | ace-git-commit scoped grouping |
| 8pletv | Task 274 CLI Help Formatter | Monkey-patch dry-cli, fork-run |
| 8ply25 | Task 278 DWIM Removal | Fork-run at scale, CLI testing perf |
| 8plyrw | Task 278 Review Cycles | Multi-model review, phase advancement |
| 8pm3wi | PR #213 Codebase Improvements | Ruby patterns, error loading |
| 8pn47m | Task 280 Pilot Direction | Pilot validation scope |
| 8pne61 | Task 280 Post-Delivery | Experiment != implementation |
| 8pnrrf | E2E Analyze-First Policy | Rerun discipline |
| 8po3x0 | E2E Failure Analysis | Runner hardening |
| 8po4al | E2E Three-Session Analysis | Progressive stability |
| 8pp34w | Task 283 Assignment Drive | Phase start command gap |
| 8ppuau | Task 289 ArgvCoalescer | dry-cli array flag fix |
| 8pqo8o | Task 296 ace-sim Rebuild | Proof-then-implement |
| 8pqwbj | Task 296 Contract Drift | Artifact chain contracts |
| 8pr2h1 | ace-sim Validation Session | dry-cli type coercion bug |
| 8prlzl | Task 291 ace-idea gem | Cross-platform File.rename |
| 8prv7e | ace-idea Polish | Migration classify-on-arrival |

## Additional Context

- **Time span**: 2026-02-03 to 2026-02-28 (26 days)
- **Major tasks covered**: 227, 235, 255, 261, 262, 273, 274, 278, 280, 283, 289, 291, 296
- **Key PRs**: #189, #193, #194, #196, #197, #207, #210, #211, #212, #213, #217, #222, #223
- **Prior synthesis retros**: 8q0z2p (Testing), 8q0z3f (CLI/Config), 8q0z3i (Git/PR), 8q0z3l (Agent/Process)
- **This synthesis covers the period immediately following those earlier syntheses**
