# E2E Decision Record - TS-SEARCH-001

## Scope

Task: `8r9.t.i05.h`
Package: `ace-search`
Goal: align with `fast` / `feat` / `e2e` contract.

## Decisions

| Artifact | Decision | Notes |
|---|---|---|
| `TS-SEARCH-001-search-workflow` scenario | KEEP | Retains workflow-value checks across real CLI execution paths. |
| `TC-001-content-search` | KEEP | Verifies real content-search behavior against filesystem/project data. |
| `TC-002-file-search` | KEEP | Verifies real file-discovery mode and path/glob behavior. |
| `TC-003-count-mode` | KEEP | Verifies real count-mode CLI behavior and artifacts. |
| `TC-004-json-output` | KEEP | Verifies real JSON output contract through CLI execution. |

## Deterministic Coverage Promotion

- Legacy deterministic integration coverage moved to `test/feat/cli_integration_test.rb`.
- Deterministic atom/command/model/molecule/organism/top-level tests moved to `test/fast/**`.
- `scenario.yml` unit coverage references updated to `test/feat` and `test/fast` paths.

## Guardrails

- No deterministic `*_test.rb` files under `test/e2e/`.
- Keep `test/e2e/` focused on workflow-value scenario checks only.
