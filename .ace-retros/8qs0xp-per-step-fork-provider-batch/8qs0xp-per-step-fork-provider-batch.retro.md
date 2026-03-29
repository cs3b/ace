---
id: 8qs0xp
title: per-step-fork-provider-batch
type: standard
tags: [ace-assign, fork, assignment]
created_at: "2026-03-29 00:37:28"
status: active
---

# per-step-fork-provider-batch

## What Went Well

- **Clean vertical slice**: The implementation threaded through a clear chain (Step model → parser → scanner → writer → fork-run → status → docs) with no unexpected coupling. Each layer was easy to test in isolation.
- **Review cycles caught real bugs**: The code-valid cycle found that catalog `context.fork` overrides for explicit skill steps were silently dropped. The code-fit cycle found that scoped `ace-assign status` wasn't propagating the fork root's provider to active child steps. Both were genuine correctness issues, not nits.
- **Three-cycle review process with reorganized commits**: 17 review-patch commits folded cleanly into 5 logical scope commits via `ace-git-commit -i`. The history is readable and the scope grouping is correct.
- **Demo tape worked first try**: `ace-demo record --dry-run` validated paths without incident; the recording ran cleanly via asciinema.
- **Full monorepo suite stayed green**: 7795 tests, 0 failures after all changes — no cross-package regressions introduced.

## What Could Be Improved

- **Scoped status fork-provider gap found late**: The behavior of scoped `ace-assign status` (showing effective provider from the fork root when the current child has no local provider) was not in the original spec. It was caught in code-fit rather than being designed upfront. The task spec should have included a `status --assignment <id>@<root>` example.
- **ace-overseer release needed re-checking**: The dependency constraint bump on `ace-overseer` required a separate patch release to align `~> 0.41` after the initial `~> 0.40` was set. This could have been caught before the first release commit with a `bundle exec gem dependency` check.
- **Symbol key vs string key lookup**: The dead symbol-key path in `Step#fork_provider` was found in code-fit — a sign that the initial implementation wasn't tested for the full frontmatter deserialization path (YAML keys are always strings after load).

## Key Learnings

- **Provider priority chain as a first-class spec concern**: When adding per-step config overrides, always spec the full priority chain (CLI > step > config > default) with explicit examples for each level. The status JSON contract (`fork_provider` field) and the scoped-status propagation rule should both be in the spec.
- **Scoped status is a separate behavior mode**: When the assignment is scoped (`--assignment id@root`), the current_step context may be inside a subtree whose root carries the fork provider. Status must walk up to the fork root to resolve the effective provider, not just read from the active child step's frontmatter.

### Review Cycle Analysis

| Cycle | Preset | Models | Duration | Valid Findings | False Positives |
|-------|--------|--------|----------|----------------|-----------------|
| 040 (valid) | code-valid | 3 (opus, codex, gemini) | 141.85s | 1 | 3 |
| 070 (fit) | code-fit | 3 (opus, codex, gemini) | 155.98s | 3 | 2 |
| 100 (shine) | code-shine | 2 (opus, codex) | 139.13s | 3 | 2 |

- The code-valid cycle had the highest false-positive rate (3/4 findings were invalid) but caught the most critical bug (catalog fork override drop).
- The code-fit cycle was the most productive: 3 valid, 2 invalid, all actionable.
- The code-shine cycle found refactoring and clarity improvements that were worth applying.
- Codex consistently had the longest run time; opus was consistently fastest.

## Action Items

- **Add scoped-status fork-provider example to task spec template** for fork-provider features: always include `ace-assign status --assignment <id>@<root>` expected output.
- **Check `~> minor` constraint before initial release** when releasing a gem that others depend on: run `bundle exec gem dependency` to verify constraint is forward-compatible.
- **Test YAML string-key deserialization paths** explicitly in model tests: one test case that loads from a YAML string (not a Ruby symbol hash) catches string vs symbol key bugs early.
