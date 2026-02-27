# Phase 1 Happy Path (No Package Code)

## Goal

Prove runnable simulation behavior and evidence capture before creating `ace-sim` package code.

## Preconditions

- Source item exists (`<ref>` idea/task shortcut)
- LLM provider credentials available
- Read-only run intent (`--no-writeback`)

## Command Sequence

```bash
mise exec -- ace-taskflow review-next-phase --source <ref> --modes draft,plan --no-writeback --verbose
mise exec -- ace-taskflow review-next-phase --source <ref> --modes draft,plan --no-writeback --verbose --model <providerA:model>
mise exec -- ace-taskflow review-next-phase --source <ref> --modes draft,plan --no-writeback --verbose --model <providerB:model>
mise exec -- ace-taskflow review-next-phase --source <ref> --modes draft,plan --no-writeback --verbose --model <providerA:model>
```

## Expected Artifacts

- `.cache/ace-taskflow/simulations/<run-id>/session.yml`
- `.cache/ace-taskflow/simulations/<run-id>/synthesis.yml`
- `.cache/ace-taskflow/simulations/<run-id>/writeback-preview.md`

## Pass Criteria

- At least one successful run per selected provider
- One repeated run on the same provider
- Step output contract present for both `draft` and `plan`
- Failure classification recorded for any non-success run
