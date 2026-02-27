# Phase 1 Happy Path (No Package Code)

## Goal

Prove runnable step-chained simulation behavior and evidence capture before creating `ace-sim` package code.

## Preconditions

- Source item exists (`<ref>` idea/task shortcut)
- LLM provider credentials available for `google:gflash` and `codex:mini`
- Task-local proof files exist under `ux/proof/`
- Read-only run intent (no source writeback allowed in phase 1)

## Command Sequence

```bash
# 1) Generate run-id (copy output value as <run-id>)
mise exec -- ace-b36ts encode now

# 2) Render draft prompt from source input
mise exec -- ace-bundle -f .ace-taskflow/v.0.9.0/tasks/296-build-sim-ace/ux/proof/proof-bundle.yml --output cache

# 3) Execute draft stage
mise exec -- ace-llm google:gflash --system .ace-taskflow/v.0.9.0/tasks/296-build-sim-ace/ux/proof/draft.system.md --prompt .cache/ace-sim/proof/<run-id>/draft.prompt.md --output .cache/ace-sim/proof/<run-id>/draft-output.yml

# 4) Re-render bundle after draft output exists to build chained plan prompt
mise exec -- ace-bundle -f .ace-taskflow/v.0.9.0/tasks/296-build-sim-ace/ux/proof/proof-bundle.yml --output cache

# 5) Execute plan stage with provider B
mise exec -- ace-llm codex:mini --system .ace-taskflow/v.0.9.0/tasks/296-build-sim-ace/ux/proof/plan.system.md --prompt .cache/ace-sim/proof/<run-id>/plan.prompt.md --output .cache/ace-sim/proof/<run-id>/plan-output.yml

# 6) Repeat plan stage on provider A for variance check
mise exec -- ace-llm google:gflash --system .ace-taskflow/v.0.9.0/tasks/296-build-sim-ace/ux/proof/plan.system.md --prompt .cache/ace-sim/proof/<run-id>/plan.prompt.md --output .cache/ace-sim/proof/<run-id>/plan-repeat-output.yml

# 7) Produce synthesis artifact explicitly
mise exec -- ace-llm codex:mini --system .ace-taskflow/v.0.9.0/tasks/296-build-sim-ace/ux/proof/synthesis.system.md --prompt .cache/ace-sim/proof/<run-id>/synthesis.prompt.md --output .cache/ace-sim/proof/<run-id>/synthesis.yml

# 8) Produce comparison artifact explicitly
mise exec -- ace-llm codex:mini --system .ace-taskflow/v.0.9.0/tasks/296-build-sim-ace/ux/proof/comparison.system.md --prompt .cache/ace-sim/proof/<run-id>/comparison.prompt.md --output .cache/ace-sim/proof/<run-id>/comparison.yml
```

## Step-Chaining Proof Requirement

- `plan.prompt.md` must include content derived from `.cache/ace-sim/proof/<run-id>/draft-output.yml`.
- Reviewers verify this by checking that draft-generated fields are present in the plan prompt for the same `<run-id>`.

## Expected Artifacts

- `.cache/ace-sim/proof/<run-id>/draft.prompt.md`
- `.cache/ace-sim/proof/<run-id>/draft-output.yml`
- `.cache/ace-sim/proof/<run-id>/plan.prompt.md`
- `.cache/ace-sim/proof/<run-id>/plan-output.yml`
- `.cache/ace-sim/proof/<run-id>/plan-repeat-output.yml`
- `.cache/ace-sim/proof/<run-id>/synthesis.yml`
- `.cache/ace-sim/proof/<run-id>/comparison.yml`

## Evidence Matrix

| provider | step | run | artifact | status |
|---|---|---|---|---|
| google:gflash | draft | 1 | `.cache/ace-sim/proof/<run-id>/draft-output.yml` | required |
| codex:mini | plan | 1 | `.cache/ace-sim/proof/<run-id>/plan-output.yml` | required |
| google:gflash | plan | 2 | `.cache/ace-sim/proof/<run-id>/plan-repeat-output.yml` | required |

## Pass Criteria

- At least one successful run per required provider
- One repeated run on the same provider (`google:gflash`)
- Step chain verified (`draft-output` is consumed by plan input)
- `synthesis.yml` and `comparison.yml` are command-produced
- Failures are classified as `implementation failure`, `provider unavailable`, or `environment issue`

## Error Handling

- Provider unavailable: record failure classification, keep produced artifacts, rerun same `<run-id>` only if prompt chain remains intact.
- Malformed output schema: classify as `implementation failure`, update prompt contract, rerun full chain.
- Missing chained input in `plan.prompt.md`: classify as `implementation failure`; do not proceed to phase 2.
