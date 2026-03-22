---
id: 8qlzgt
title: batch-yaml-demo-migration
type: standard
tags: [ace-demo, yaml, batch, assignment]
created_at: "2026-03-22 23:38:41"
status: active
---

# Batch YAML Demo Migration Retrospective

Covers assignment 8qlwdo — 4 sequential tasks (8ql.t.tt6.0 through 8ql.t.tt6.3), 3 review cycles, and 28 reorganized commits across 25 packages.

## What Went Well

- **Spike-first approach validated design before investment**: Task tt6.0 proved the full pipeline (parse → sandbox → compile → record → teardown) in one focused spike, preventing wasted effort on an approach that might not work.
- **Fork-run delegation worked smoothly**: All 4 task subtrees plus 3 review cycles and E2E verification completed end-to-end via Codex fork-run without manual intervention.
- **Review cycles caught real issues**: Valid cycle found 6 actionable items (sandbox cleanup, nil guards, YAML format passthrough). Fit cycle eliminated duplicate pipeline code and replaced hard-coded IDs with runtime capture.
- **Sequential batch preserved dependency chain**: Tasks with explicit dependencies (tt6.0 → tt6.1 → tt6.2 → tt6.3) executed in correct order.
- **Migration was formulaic**: All 23 package tape migrations followed the same pattern, making the large task manageable.

## What Could Be Improved

- **Fork-run agents didn't commit all changes**: Subtree 010.03 (migration) and 015 (E2E) left significant uncommitted files. The driver had to manually stage and commit 81 files of demo migration content and E2E verifier fixes that the fork agents produced but didn't commit. This created risk of lost work.
- **Duplicate YAML pipeline survived into review**: The spike (tt6.0) created `YamlTapeParser`/`YamlTapeContentGenerator`/`DemoSetupExecutor`/`YamlDemoRecorder`, and the engine task (tt6.1) created the "production" versions (`DemoYamlParser`/`VhsTapeCompiler`/`DemoSandboxBuilder`/`DemoTeardownExecutor`). The fit review had to clean up the duplication — the engine task should have refactored the spike code rather than adding parallel implementations.
- **Release step evaluated but deferred correctly**: Step 020 (batch release) recognized that subtree releases already covered all code changes. Good judgment, but the number of patch releases per review cycle (5 packages in valid, 5 in fit) could be excessive for what are ultimately polish fixes.

## Key Learnings

- **Driver-as-guard is essential**: Without reviewing fork subtree reports before continuing, quality issues in one subtree would propagate silently. The report review step caught the uncommitted changes issue.
- **Pre-existing test failures need tracking**: Both ace-lint (unit) and ace-test-runner E2E had pre-existing failures unrelated to this work. These should be tracked as separate tasks rather than discovered during verification steps.
- **Commit reorganization benefits from auto-grouping**: 42 commits reorganized into 28 via ace-git-commit's scope-based auto-grouping produced cleaner history with minimal manual intervention.

### Review Cycle Analysis

- Valid (code-valid): 8 items → 6 implemented, 2 deferred. Found real correctness issues (sandbox cleanup, nil guards).
- Fit (code-fit): 7 items → 6 implemented, 1 archived. Caught architectural duplication and hard-coded demo IDs.
- Shine (code-shine): Polish items applied, ace-demo v0.17.3 released. Lighter cycle as expected.
- Cross-cycle pattern: No items recurred across cycles, suggesting each preset catches distinct issue categories.

## Action Items

- **Continue**: Spike-first approach for new features; fork-run delegation for batch work
- **Improve**: Ensure fork-run agents commit all produced artifacts (investigate whether Codex auto-commit scope can be configured)
- **Improve**: Track pre-existing test failures as dedicated tasks to avoid surprise during verification
- **Start**: When engine task follows a spike, explicitly require spike code refactoring rather than parallel implementation

