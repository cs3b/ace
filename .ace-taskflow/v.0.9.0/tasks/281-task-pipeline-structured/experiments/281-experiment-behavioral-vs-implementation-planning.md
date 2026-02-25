# Experiment: Behavioral Spec vs. Implementation Planning (Task 282)

## Setup

**Task 282** (Auto-Convert Parent to Orchestrator on Child Operations) was drafted as a behavioral spec following the 3-Question Delegation Brief approach from task 281. The spec covered user experience, interface contract, expected behavior, error handling, edge cases, and success criteria.

A Codex Mini agent was then given the behavioral spec and asked to produce an implementation plan. This experiment compares what the spec provided vs. what the planning agent produced, looking for intent loss at the **spec → planning agent** handoff.

## What the Spec Captured That the Plan Used Correctly

The behavioral spec provided strong guardrails that the planning agent followed faithfully:

- **Two call sites** (`create_subtask` and `demote_to_subtask`) — the plan correctly identified both
- **Auto-convert pattern** — the plan replaced the error-return guard with a convert-then-retry pattern, matching the spec's intent
- **Error propagation** — conversion failures pass through clearly, as specified
- **Test updates** — the plan updated the existing negative test to expect success, matching the spec's success criteria
- **Documentation updates** — `draft.wf.md` and `draft-batch.wf.md` Pattern B simplification, as called out in the spec

The spec's interface contract (CLI output examples, error messages) gave the planning agent a concrete target to code toward. This is the behavioral spec working as intended.

## What the Plan Added Beyond the Spec

The planning agent introduced implementation details not mentioned in the spec:

1. **`parent_dir` re-resolution** — after auto-conversion moves files, the parent directory path changes. The plan added `parent_dir = find_parent_task_directory(...)` after conversion. This is a correct implementation necessity the spec didn't need to describe.

2. **Helper method extraction** — the plan showed the exact guard-replacement pattern for both call sites, making the duplication visible. A reviewer could decide whether to extract a shared helper.

3. **CHANGELOG / documentation ordering** — the plan suggested updating handbook docs as a separate step after code changes. Reasonable sequencing the spec doesn't cover.

These additions are expected — a behavioral spec describes *what*, and the planning agent fills in *how*. No intent was lost on these.

## What the Spec Missed: Dry-Run Mode

The key finding: **the spec said nothing about dry-run mode**, and the planning agent silently worked around it.

The existing `selfimprove` plan (in the sibling experiment file) included the full code diff with `--dry-run` considerations already baked in. But the behavioral spec for task 282 focused entirely on the happy path and error cases — it never asked: "Should auto-conversion support `--dry-run`? What should happen if the user runs `ace-task create --child-of 100 --dry-run`?"

The planning agent didn't flag this gap. It simply produced a plan that would work for the non-dry-run case. This is the **silent workaround problem**: when a spec has a gap, the planning agent fills it with the simplest assumption (skip the mode) rather than reporting the gap back.

This matters because:
- Dry-run mode is a cross-cutting concern across ACE CLI commands
- If the auto-conversion runs in dry-run mode, it should simulate the conversion without modifying files
- The spec's success criteria had no checkbox for dry-run behavior
- A reviewer checking the spec against the plan would not catch this because neither document mentions it

## Conclusion

The behavioral spec → planning agent handoff has a specific failure mode: **specs that omit operating modes (dry-run, verbose, force, quiet) produce plans that silently skip those modes**. The planning agent treats the spec as complete and doesn't report what it didn't find.

This suggests three pipeline improvements:

1. **Spec writing prompt** — add "Operating Modes Covered" as an explicit section or checklist item, prompting spec writers to think about modes like `--dry-run`, `--force`, `--verbose`, `--quiet`
2. **Review gate** — add "Operating Modes Covered" to the spec review readiness checklist so reviewers check for mode coverage before approving
3. **Planning agent instruction** — tell the planning agent to flag behavioral gaps it discovers (e.g., "The spec doesn't mention dry-run behavior — should I assume it's unsupported, or is this a gap?") rather than silently working around them

These three changes become subtask 281.04.

## Full Pipeline Results (PR #215)

Task 282 completed the full pipeline: behavioral spec → plan → implement → 4 review sessions → PR #215 with 1391 passing tests, in ~40 minutes. This section documents findings from the complete experiment beyond the dry-run omission above.

### Finding: Self-Demotion Edge Case (Degenerate Inputs)

Review session 2 discovered that `demote_to_subtask(X, X)` — demoting a task to be a subtask of itself — was unhandled. Auto-conversion deletes the original task file, then the code tries to read it as the parent, causing state corruption.

The spec's Edge Cases section didn't prompt the author to think about *degenerate inputs* — cases where the same entity appears in both argument positions (source = target). Neither the planner nor the implementer caught it either; only a reviewer did.

**Pipeline improvement**: The Edge Cases section (and the review gate) needs a "Degenerate Inputs" prompt: does the spec consider identity operations (X=Y), empty inputs, and self-referential calls?

### Finding: Reviewers Contradicted the Spec (Missing Spec Context)

Review session 3 (review-8pooad) produced 3 invalid findings and 3 skipped items. One invalid finding (item 8pooeg9e) called archived-task conversion "significant" and wanted to block it — but spec line 86 explicitly said "status is orthogonal to structure," meaning archived tasks should convert like any other.

Two more false positives in the same session: a missing test that actually existed, and a cache invalidation concern that doesn't apply to the file-based architecture.

The root cause: review agents had project context (README, architecture, vision docs) but NOT the task's behavioral spec. They invented constraints that the spec had already decided.

**Pipeline improvement**: The review pipeline should include the task's behavioral spec as context for review agents. This becomes subtask 281.05.

### Finding: Asymmetric Implementation Across Parallel Code Paths

The spec said "Same behavior for `ace-task move`" with one example flow. The implementer handled `create_subtask` and `demote_to_subtask` as separate code paths and got the `subtask_num` guard right in one but missed it in the other.

When a spec covers multiple code paths with "same behavior" shorthand, it creates an asymmetry risk: the implementer writes one path correctly and assumes the other follows, but each path has unique edge cases (guard logic, error handling, parameter differences).

**Pipeline improvement**: When a spec covers multiple code paths with "same behavior," the planning workflow should enumerate each path and note per-path variations (dry-run interaction, guard logic, error handling differences). The review gate should include a "Per-Path Variations" check.

### Observation: Review Value Curve Is Front-Loaded

| Sessions | Valid Issues Found | Invalid/Skipped |
|----------|-------------------|-----------------|
| 1–2 | 5 (all fixed in releases) | 0 |
| 3–4 | 1 (comment-level) | 10 |

Sessions 1–2 found all substantive issues. Sessions 3–4 produced diminishing returns with a high false-positive rate. This suggests the review pipeline should front-load effort (deeper initial sessions) rather than running many shallow passes.
