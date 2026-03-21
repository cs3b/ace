---
doc-type: guide
title: Ruby RSpec Testing Guide
purpose: Ruby RSpec testing conventions
ace-docs:
  last-updated: 2026-01-23
  last-checked: 2026-03-21
---

# Ruby RSpec Testing Guide

This guide provides best practices and conventions for writing tests in Ruby using RSpec, tailored for the
coding-agent-workflow-toolkit project.

## 1. Directory Structure

```text
project-root/
└── spec/
    ├── unit/
    ├── integration/
    ├── e2e/
    └── support/
```

Follow the mirrored structure of `lib/` when placing unit tests. Keep integration and E2E tests in their respective
folders.

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

Typically, you run your RSpec tests using Bundler to ensure the correct gem versions are used:

```bash
# Run all specs
bundle exec rspec

# Run specs in a specific file
bundle exec rspec spec/models/user_spec.rb

# Run a specific example (by line number)
bundle exec rspec spec/models/user_spec.rb:25
```

## 7. Checking Test Coverage

If you have set up a coverage tool like SimpleCov, you might run it via an environment variable:

```bash
# Run specs and generate coverage report
COVERAGE=true bundle exec rspec
```

Refer to your project's specific setup (e.g., `spec_helper.rb` or `rails_helper.rb`) and the coverage tool's
documentation for configuration details.

## 8. CI Integration

- Ensure the CI pipeline runs `bundle exec rspec` and uploads coverage.

## 9. Linting Specs

Use `rubocop-rspec` to enforce spec style.