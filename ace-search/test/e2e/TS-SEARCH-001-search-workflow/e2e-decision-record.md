# E2E Decision Record - TS-SEARCH-001

## Scope

Task: `8rd.t.bzp.k`
Package: `ace-search`
Goal: rewrite retained E2E coverage to public-surface goal-style workflows.

## Decisions

| Artifact | Decision | Notes |
|---|---|---|
| `TS-SEARCH-001-search-workflow` scenario | KEEP + EXPAND | Retain workflow-value scenario and expand with preset + git-scope public journeys. |
| `TC-001-content-search` | KEEP | Valid goal-style baseline proving content-search behavior. |
| `TC-002-file-search` | REWRITE | Reframed to workspace-relative user file-discovery path instead of hard-coded package path probes. |
| `TC-003-count-mode` | REWRITE | Reframed around clear user-observable list/count outcomes without internal-path coupling. |
| `TC-004-json-output` | REWRITE | Validates JSON contract through public query/path behavior, not implementation token coupling. |
| `TC-005-preset-driven-search` | ADD | Covers documented preset entrypoint behavior as public workflow. |
| `TC-006-git-scope-search` | ADD | Covers tracked-file scoped search behavior via public flags. |

## Deterministic Coverage Promotion

- Deterministic integration coverage remains in `test/feat/cli_integration_test.rb`.
- Deterministic atom/command/model/molecule/organism/top-level tests remain in `test/fast/**`.
- `test/e2e/` remains focused on user-workflow value checks.

## Guardrails

- No deterministic `*_test.rb` files under `test/e2e/`.
- E2E goals must be executable from public CLI surface (`ace-search/docs/usage.md` + `--help`).
- Prefer impact-first evidence from sandbox artifacts and user-visible command outcomes.
