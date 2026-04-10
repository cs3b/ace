---
id: 8r9i04
title: synthesis-restart-e2e-architecture-and-migration
type: standard
tags: [synthesis, e2e, testing, migration, restart]
created_at: "2026-04-10 12:00:46"
status: active
---

# synthesis-restart-e2e-architecture-and-migration

Date: 2026-04-10
Context: Synthesis of branch retros plus origin/main..HEAD commit history to extract the bugs, migration regressions, and replacement architecture for the E2E restart.
Source retros: 8qki2c, 8quwjc, 8r0fgq, 8r0omn, 8r7tq6, 8r7x6l, 8r80q1, 8r8e8n, 8r8erl, 8r8j9h, 8r8jc5, 8r8m9r, 8qqgs1, 8r6w7t

## What Went Well

- The retros were consistent about the core diagnosis: most red E2E failures came from contract drift, synthetic evidence, and harness ambiguity, not from widespread product breakage.
- The branch proved that ace-test-runner already had the right generic target model; we do not need a second custom deterministic execution stack.
- Existing work around commands.ndjson, tc.start.json, tc.final.json, and fail-closed demo recording gives the restart a solid evidence model for agent scenarios.

## What Could Be Improved

- The branch mixed three concerns into one stream of work: runner and harness fixes, scenario-contract cleanup, and deterministic coverage migration. That made progress look better than it was.
- The migration deleted deterministic TCs faster than it recreated them.
- The branch kept trying to repair the custom design instead of resetting the design around the simpler ace-test and ace-test-suite model.

## Package Bug Catalog

### Harness and cross-cutting bugs

- ace-test-runner-e2e
  - deterministic integration reporting could show 0/0 case(s) after real execution
  - suite visibility could hide deleted deterministic coverage behind a small remaining scenario count
- ace-task
  - create can generate duplicate task IDs when called multiple times inside one second
- ace-retro
  - create can generate duplicate retro IDs when called multiple times inside one second

### Product and scenario-contract bugs found on this branch

- ace-assign: stale hierarchy and lifecycle expectations, ambiguous assignment-id resolution, over-strict synthetic evidence checks
- ace-bundle: verifier depended on transformed README literal text instead of semantic behavior
- ace-docs: docs discovery verification depended on stale fallback capture assumptions
- ace-git: status scenario needed more explicit command-state evidence
- ace-git-worktree: stale lifecycle and task-aware expectations, insufficient cwd evidence, prune cleanup drift
- ace-idea: lifecycle tests needed real archive filesystem proof
- ace-lint: no-report and cache-diff expectations drifted from current artifact names and doctor output
- ace-llm: provider fallback isolation and model-selection scenario assumptions drifted from the active provider stack
- ace-llm-providers-cli: provider subprocesses needed sandbox env passed explicitly
- ace-monorepo-e2e: quick-start fixture and source-root assumptions were incomplete and task-id extraction needed normalization
- ace-overseer: prune workflow assumptions and sandbox fixture source-root assumptions drifted from implementation
- ace-review: prepared-session execution changed the valid verification surface
- ace-sim: success oracle drift between copied synthesis artifacts, run-tree proof, and optional outputs
- ace-support-nav: nav checks needed resolved workflow-path proof rather than weaker artifact assumptions
- ace-support-models: seeded cache shape assumptions drifted from wrapped provider cache output
- ace-task: smoke flow needed exact task-ref preservation
- ace-test-runner: suite verification and failure-propagation assertions drifted from actual emitted artifacts and grouped output

## Deterministic Migration Regression Matrix

| Package | Deleted deterministic TCs | Current branch replacement methods | Migration bug summary |
| --- | ---: | ---: | --- |
| ace-assign | 10 | 3 | Coverage collapsed; needs full TC parity restart |
| ace-b36ts | 8 | 8 | Pilot parity restored on branch; use as restart reference |
| ace-bundle | 5 | 2 | Coverage collapsed; restore all 5 TCs in test/e2e |
| ace-compressor | 4 | 2 | Coverage collapsed; restore all 4 TCs in test/e2e |
| ace-demo | 4 | 2 | Coverage collapsed; restore all 4 TCs in test/e2e |
| ace-docs | 4 | 2 | Coverage collapsed; restore all 4 TCs in test/e2e |
| ace-git | 6 | 2 | Coverage collapsed; restore all 6 TCs in test/e2e |
| ace-git-commit | 6 | 2 | Coverage collapsed; restore all 6 TCs in test/e2e |
| ace-git-secrets | 8 | 2 | Coverage collapsed; restore all 8 TCs in test/e2e |
| ace-git-worktree | 13 | 3 | Largest regression; restore both suites in test/e2e |
| ace-handbook | 3 | 2 | One deterministic behavior lost |
| ace-idea | 4 | 2 | Coverage collapsed |
| ace-lint | 7 | 2 | Coverage collapsed |
| ace-llm-providers-cli | 3 | 2 | One deterministic behavior lost |
| ace-overseer | 5 | 2 | Coverage collapsed |
| ace-prompt-prep | 4 | 4 | Parity restored on branch |
| ace-retro | 4 | 2 | Coverage collapsed |
| ace-search | 4 | 0 | Deterministic coverage effectively disappeared |
| ace-sim | 6 | 2 | Coverage collapsed |
| ace-support-models | 4 | 4 | Parity restored on branch |
| ace-support-nav | 5 | 2 | Coverage collapsed |
| ace-task | 4 | 2 | Coverage collapsed |
| ace-test-runner | 5 | 7 | Branch parity over-restored; still relocate to test/e2e |
| ace-test-runner-e2e | 4 | 5 | Branch parity over-restored; still relocate to test/e2e |
| ace-tmux | 3 | 2 | One deterministic behavior lost |

## Restart Decision

- Pilot first on ace-b36ts with full deterministic parity, one real agent scenario, and all global testing docs, workflows, and skills updates.
- Then migrate the rest through package-specific subtasks only.
- The restart target is:
  - test/e2e for deterministic sandboxed Minitest
  - test-e2e/scenarios for agent scenarios only
  - ace-test <pkg> e2e and ace-test-suite --target e2e for deterministic execution
  - ace-test-e2e <pkg> for scenario execution only

## Action Items

- Execute pilot task 8r9.t.hzr first and treat it as the architecture spike.
- Refresh all package subtasks from pilot outcomes before implementation starts.
- Patch ID generation in ace-task and ace-retro before relying on batched drafting automation again.
