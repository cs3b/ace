# ace-monorepo-e2e

Cross-cutting E2E test scenarios for monorepo-level concerns.

[Release Install Verification](docs/release-install-verification.md) | Part of [ACE](https://github.com/cs3b/ace)

This is **not** a Ruby gem. It is a container for E2E scenarios that span multiple packages or verify monorepo-wide behavior (install verification, quick-start doc validation, etc.).

Scenarios here are auto-discovered by `ace-test-e2e-suite` from `test/e2e/TS-*/scenario.yml`.

This package remains E2E-focused unless an approved review/rewrite explicitly promotes deterministic coverage to `test/fast/` or `test/feat/`.

## Running

```bash
ace-test-e2e ace-monorepo-e2e                          # run all monorepo scenarios
ace-test-e2e ace-monorepo-e2e TS-MONO-001              # run specific scenario
ace-test-e2e-suite --tags quickstart        # cross-package quickstart sweep
```

## Guides

- `docs/release-install-verification.md` maps the post-release install proof workflow
  to `TS-MONO-001` (`SAFE`, `LAG_DETECTED`, `METADATA_BROKEN`).
- The guide is the public contract reference for the release/install proof flow; use it
  alongside `ace-test-e2e ace-monorepo-e2e TS-MONO-001` when validating a release.

## Scenarios

| ID | Title | Cost Tier | Tags |
|----|-------|-----------|------|
| TS-MONO-001 | RubyGems Install Verification | deep | release, rubygems, install-verify |
| TS-MONO-002 | Quick-Start Local Validation | happy-path | quickstart, docs-verify |
