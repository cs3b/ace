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

# 1b) Export run-id and source ref for proof-bundle rendering
export ACE_SIM_RUN_ID=<run-id>
export ACE_SIM_SOURCE_REF=<ref>

# 2) Render prompts from source input (writes draft/plan/synthesis/comparison prompts)
mise exec -- ace-bundle -f .ace-taskflow/v.0.9.0/tasks/296-build-sim-ace/ux/proof/proof-bundle.yml --output cache

# 3) Execute draft stage
mise exec -- ace-llm google:gflash --system .ace-taskflow/v.0.9.0/tasks/296-build-sim-ace/ux/proof/draft.system.md --prompt .cache/ace-sim/proof/<run-id>/draft.prompt.md --output .cache/ace-sim/proof/<run-id>/draft-output.yml

# 4) Re-render bundle after draft output exists to build chained plan prompt
mise exec -- ace-bundle -f .ace-taskflow/v.0.9.0/tasks/296-build-sim-ace/ux/proof/proof-bundle.yml --output cache

# 4b) Verify plan prompt includes same-run draft output
rg -n "Draft Output \(same run-id\)|objective_summary|acceptance_targets" .cache/ace-sim/proof/<run-id>/plan.prompt.md

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
- Reviewers verify this by checking draft-generated fields are present in the plan prompt for the same `<run-id>`.

## Expected Artifacts

- `.cache/ace-sim/proof/<run-id>/draft.prompt.md`
- `.cache/ace-sim/proof/<run-id>/draft-output.yml`
- `.cache/ace-sim/proof/<run-id>/plan.prompt.md`
- `.cache/ace-sim/proof/<run-id>/plan-output.yml`
- `.cache/ace-sim/proof/<run-id>/plan-repeat-output.yml`
- `.cache/ace-sim/proof/<run-id>/synthesis.prompt.md`
- `.cache/ace-sim/proof/<run-id>/synthesis.yml`
- `.cache/ace-sim/proof/<run-id>/comparison.prompt.md`
- `.cache/ace-sim/proof/<run-id>/comparison.yml`

## Evidence Matrix

| provider | step | run | artifact | status |
|---|---|---|---|---|
| google:gflash | draft | 1 | `.cache/ace-sim/proof/<run-id>/draft-output.yml` | required |
| codex:mini | plan | 1 | `.cache/ace-sim/proof/<run-id>/plan-output.yml` | required |
| google:gflash | plan | 2 | `.cache/ace-sim/proof/<run-id>/plan-repeat-output.yml` | required |
| codex:mini | synthesis | 1 | `.cache/ace-sim/proof/<run-id>/synthesis.yml` | required |
| codex:mini | comparison | 1 | `.cache/ace-sim/proof/<run-id>/comparison.yml` | required |

## Latest Sample Run

- Run ID: `8pqmbl`
- Source reference: `v.0.9.0+task.296.01`
- Chain proof check:
  - `rg -n "Draft Output \\(same run-id\\)|objective_summary|acceptance_targets" .cache/ace-sim/proof/8pqmbl/plan.prompt.md`
  - Observed fields from draft output in plan prompt: `objective_summary`, `acceptance_targets`
- Produced artifacts:
  - `.cache/ace-sim/proof/8pqmbl/draft-output.yml`
  - `.cache/ace-sim/proof/8pqmbl/plan-output.yml`
  - `.cache/ace-sim/proof/8pqmbl/plan-repeat-output.yml`
  - `.cache/ace-sim/proof/8pqmbl/synthesis.yml`
  - `.cache/ace-sim/proof/8pqmbl/comparison.yml`
- Provider classification notes:
  - `google:gflash` failed in this environment (`provider unavailable`: model alias `gflash` resolved to unsupported model)
  - Fallback command used for Google provider evidence:
    - `mise exec -- ace-llm google --model gemini-2.5-flash --system ... --prompt ... --output ...`

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
