## E2E Change Plan: ace-sim

### Impact Summary
- **Current:** 1 scenario, 4 TCs
- **Proposed:** 1 scenario, 6 TCs
- **Net change:** +2 TCs (targeted expansion, no removals)
- **Cost impact:** smoke tier retained; added TCs include one deterministic validation path

### Classification Decisions

#### KEEP
- `TC-001-help-survey`
  - Keep baseline binary help command coverage.
- `TC-002-preset-contract`
  - Keep default `validate-idea` preset contract coverage.
- `TC-004-full-chain-synthesis`
  - Keep full-chain synthesis aggregation and recorded failure/success path coverage.

#### MODIFY
- `TC-001-help-survey.verify.md`
  - Add assertions for `--dry-run` and `--writeback` to lock current run-help option surface.
- `TC-003-run-chain-artifacts.verify.md`
  - Tighten explicit single-step (`draft` only) assertions and absence of plan/work artifacts.
- `scenario.yml`
  - Extend `sandbox-layout` for TC-005 and TC-006 output directories.
- `runner.yml.md`
  - Include TC-005 and TC-006 in ordered runner bundle.
- `verifier.yml.md`
  - Include TC-005 and TC-006 in ordered verifier bundle and update final results denominator.

#### REMOVE
- None.

#### CONSOLIDATE
- None.

#### ADD
- `TC-005-validate-task-preset.runner.md`
  - Exercise `validate-task` preset through real CLI run and capture run artifacts.
- `TC-005-validate-task-preset.verify.md`
  - Verify `validate-task` session/synthesis contract and expected chain structure.
- `TC-006-synthesis-provider-guard.runner.md`
  - Execute invalid option pairing (`--synthesis-provider` without workflow) and capture failure evidence.
- `TC-006-synthesis-provider-guard.verify.md`
  - Verify deterministic non-zero exit and expected validation message.

### Proposed Scenario Structure
1. Goal 1: Help survey (`TC-001`, modified verifier)
2. Goal 2: Default preset contract (`TC-002`, keep)
3. Goal 3: Explicit override one-step behavior (`TC-003`, modified verifier)
4. Goal 4: Full-chain synthesis aggregation (`TC-004`, keep)
5. Goal 5: Alternate preset contract (`TC-005`, new)
6. Goal 6: Validation guard behavior (`TC-006`, new)

### Execution Notes for Rewrite
- Keep numbering contiguous and update all bundle references.
- Preserve runner/verifier split: runner captures execution artifacts, verifier renders verdicts.
- Keep setup ownership in `scenario.yml`; do not move setup into TC runners.
