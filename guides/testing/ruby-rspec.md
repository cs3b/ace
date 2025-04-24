# Ruby RSpec Testing Guide

This guide provides best practices and conventions for writing tests in Ruby using RSpec, tailored for the coding-agent-workflow-toolkit project.

## 1. Directory Structure

```
project-root/
└── spec/
    ├── unit/
    ├── integration/
    ├── e2e/
    └── support/
```

Follow the mirrored structure of `lib/` when placing unit tests. Keep integration and E2E tests in their respective folders.

## 2. Configuration (`spec/spec_helper.rb`)
- Load `simplecov` when the `COVERAGE` env var is present.
- Enable the `--only-failures` and `--next-failure` flags via `.rspec`.
- Configure `rspec-mocks` to verify double constants.

## 3. Factories & Fixtures
- Use `FactoryBot` for building domain objects.
- Place YAML/JSON fixtures in `spec/fixtures/`.

## 4. Mocking External Services
- Use `WebMock` and `VCR` to record HTTP interactions.
- Filter sensitive data with `config.filter_sensitive_data`.

## 5. Tag Conventions
| Tag | Purpose |
| --- | ------- |
| `:unit` | Fast unit tests (default) |
| `:integration` | Tests requiring multiple components |
| `:e2e` | End-to-end flows |
| `:slow` | Any test > 1s |

## 6. Running Tests

```bash
bundle exec rspec            # full suite
bundle exec rspec spec/unit  # subset
```

Add `bin/rspec` wrapper for convenience.

## 7. CI Integration
- Ensure the CI pipeline runs `bundle exec rspec` and uploads coverage.

## 8. Linting Specs
Use `rubocop-rspec` to enforce spec style.
