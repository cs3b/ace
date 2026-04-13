# E2E Review + Change Plan: ace-monorepo-e2e

Generated for task `8r9.t.i05.r`.

## Review Summary

- Scenarios reviewed: 2
- Test cases reviewed: 8
- Deterministic layer changes required: no
- Decision: keep package scenario-only for this slice

## Coverage Matrix (Current State)

| Feature | Unit Coverage | E2E Coverage | Status |
|---|---|---|---|
| RubyGems install verification (`bundle install`, fallback handling) | Not meaningfully unit-testable in-package (network/registry behavior) | TS-MONO-001 TC-001..004 | E2E-only, justified |
| Quick-start workflow execution across tools (`ace-idea`, `ace-task`, `ace-bundle`, `ace-nav`, config bootstrap) | Partial deterministic coverage exists in package-level fast/feat tests of participating tools | TS-MONO-002 TC-001..004 | Keep E2E for cross-tool integration |

## Classification (Plan Changes)

### TS-MONO-001-rubygems-install

- `TC-001-discover-gems`: `KEEP`
  - Reason: validates generated Gemfile + real discovery behavior against published gems.
- `TC-002-sandbox-install`: `KEEP`
  - Reason: requires real install execution in sandbox, not unit-reproducible.
- `TC-003-fullindex-fallback`: `KEEP`
  - Reason: verifies fallback behavior under registry/index conditions that need live environment.
- `TC-004-classify-result`: `KEEP`
  - Reason: scenario-level proof synthesis for release-facing install verification.

### TS-MONO-002-quickstart-local

- `TC-001-idea-capture`: `MODIFY`
  - Change: refresh `unit-coverage-reviewed` paths to current `fast`/`feat` locations.
- `TC-002-task-create`: `MODIFY`
  - Change: refresh `unit-coverage-reviewed` paths to current `fast`/`feat` locations.
- `TC-003-protocol-nav`: `MODIFY`
  - Change: refresh `unit-coverage-reviewed` paths to current `fast`/`feat` locations.
- `TC-004-config-cascade`: `MODIFY`
  - Change: refresh `unit-coverage-reviewed` paths to current `fast`/`feat` locations.

No `REMOVE`, `CONSOLIDATE`, or `ADD` actions were selected for this package in this slice.

## Rewrite Outcome

- Applied metadata rewrite to `TS-MONO-002-quickstart-local/scenario.yml` (`unit-coverage-reviewed` paths).
- Updated package README contract text to remove stale legacy-path migration guidance.
- Deterministic tests were not promoted into `ace-monorepo-e2e/test/fast` or `test/feat` because this slice found no approved promotion candidates.
