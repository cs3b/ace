# E2E Review - ace-review

Reviewed package: `ace-review`
Scope: `TS-REVIEW-001-review-workflow`
Workflow: `ace-bundle wfi://e2e/review`

## Coverage Matrix

| Feature | Deterministic Coverage | E2E Coverage | Status | Notes |
| --- | --- | --- | --- | --- |
| CLI help and option survey | `test/fast/commands/feedback/*`, docs command coverage | `TC-001-help-survey` (pre-migration) | Overlap | No real external dependency; low E2E value. |
| Preset discovery/composition and dry-run behavior | `test/fast/molecules/preset_manager_test.rb`, `test/fast/molecules/context_composer_test.rb` | `TC-002`, `TC-003` (pre-migration) | Overlap | Deterministic coverage already exercises resolution/assembly paths. |
| Subject parsing and dry-run subject routing | `test/fast/molecules/subject_extractor_test.rb`, `test/fast/molecules/subject_strategy_test.rb` | `TC-004` (pre-migration) | Overlap | Deterministic behavior with no unique runtime dependency. |
| Validation/error handling for preset/config issues | `test/fast/molecules/preset_manager_test.rb`, `test/feat/*` | `TC-005` (pre-migration) | Overlap | Better represented as deterministic contract checks. |
| Single-model real review execution | `test/fast/organisms/review_manager_test.rb` (logic only) | `TC-006` (pre-migration) | Keep E2E | Requires real provider call + session artifact persistence. |
| Multi-model/reviewer-format execution | `test/fast/organisms/review_manager_test.rb` (logic only) | `TC-007` (pre-migration) | Keep E2E | Requires real orchestration and output file generation. |

## Findings

- `TC-001` through `TC-005` are deterministic-overlap and fail the E2E value gate.
- Real execution paths (`single` and `multi/reviewers`) retain strong E2E value and should remain.
- Scenario should be rewritten to 2 retained TCs with refreshed deterministic references in `unit-coverage-reviewed`.
