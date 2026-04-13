# ace-monorepo-e2e

Cross-cutting E2E test scenarios for monorepo-level concerns.

This is **not** a Ruby gem. It is a container for E2E scenarios that span multiple packages or verify monorepo-wide behavior (install verification, quick-start doc validation, etc.).

Scenarios here are auto-discovered by `ace-test-e2e-suite` from `test/e2e/TS-*/scenario.yml`.

This package remains E2E-focused unless an approved review/rewrite explicitly promotes deterministic coverage to `test/fast/` or `test/feat/`.

## Running

```bash
ace-test-e2e ace-monorepo-e2e               # run all monorepo scenarios
ace-test-e2e ace-monorepo-e2e TS-MONO-001   # run specific scenario
ace-test-e2e-suite --tags quickstart        # cross-package quickstart sweep
```

## Scenarios

| ID | Title | Cost Tier | Tags |
|----|-------|-----------|------|
| TS-MONO-001 | RubyGems Install Verification | deep | release, rubygems, install-verify |
| TS-MONO-002 | Quick-Start Local Validation | happy-path | quickstart, docs-verify |
