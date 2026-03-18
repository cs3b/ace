# ACE Test Gem

> **[!NOTE]** **Workflow Package Only** - This is a pure documentation package (no CLI tool). For the `ace-test` CLI command, see [ace-test-runner](https://github.com/cs3b/ace/tree/main/ace-test-runner).

Testing workflows, guides, and patterns for ACE (Agentic Coding Environment). This pure workflow package contains comprehensive testing documentation, mocking patterns, and best practices for writing fast, reliable tests.

## Note

This gem provides **testing documentation and resources only**. For the actual test execution CLI (`ace-test` command), see [ace-test-runner](https://github.com/cs3b/ace/tree/main/ace-test-runner).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ace-test', group: [:development, :test]
```

And then execute:
```bash
bundle install
```

Or install it yourself as:
```bash
gem install ace-test
```

## Usage

The ace-test gem provides testing resources that should be loaded directly with `ace-bundle`:

### Guide Access

```bash
# Quick reference
ace-bundle guide://quick-reference

# Testing philosophy and pyramid
ace-bundle guide://testing-philosophy

# Test organization patterns
ace-bundle guide://test-organization

# Mocking patterns (Git, HTTP, subprocess, ENV)
ace-bundle guide://mocking-patterns

# Performance targets and optimization
ace-bundle guide://test-performance

# Testable code patterns
ace-bundle guide://testable-code-patterns

# General testing guidelines
ace-bundle guide://testing

# TDD implementation cycle
ace-bundle guide://testing-tdd-cycle

# Embedded testing in workflows
ace-bundle guide://embedded-testing-guide
```

### Workflow Access

```bash
# Create test cases for features
ace-bundle wfi://test/create-cases

# Fix failing tests systematically
ace-bundle wfi://test/fix
```

Use `ace-nav` only when you need discovery or to resolve an agent path.

## Guide Descriptions

### Core Testing Guides

1. **quick-reference.g.md**: TL;DR of testing patterns - flat structure, naming, IO isolation
2. **testing-philosophy.g.md**: Testing pyramid, IO isolation principle, when real IO is allowed
3. **test-organization.g.md**: Flat directory structure, naming conventions, layer boundaries
4. **mocking-patterns.g.md**: MockGitRepo, WebMock, subprocess stubbing, ENV testing patterns
5. **test-performance.g.md**: Performance targets by layer, composite helpers, zombie mocks detection
6. **testable-code-patterns.g.md**: Avoiding exit calls, returning status codes, exception patterns

### Technology-Specific Guides

- **testing/ruby-rspec.md**: RSpec-specific patterns
- **testing/rust.md**: Rust testing patterns
- **testing/typescript-bun.md**: Bun test patterns
- **testing/vue-vitest.md**: Vue + Vitest patterns

### TDD Cycle Guides

- **test-driven-development-cycle/ruby-gem.md**: TDD for Ruby gems
- **test-driven-development-cycle/rust-cli.md**: TDD for Rust CLI tools
- **test-driven-development-cycle/typescript-vue.md**: TDD for Vue apps

## Architecture

This is a **pure workflow package** following the ACE gem patterns:

- **No CLI interface**: Resources are consumed through `ace-bundle` protocols; use `ace-nav` for discovery
- **No Ruby dependencies**: Contains only markdown workflow/guide files
- **Auto-discovery**: ace-nav automatically discovers resources from installed gems
- **Consolidated testing knowledge**: Single source of truth for testing patterns

## File Structure

```
ace-test/
├── lib/ace/test.rb                    # Gem entry point
├── lib/ace/test/version.rb            # Version constant
├── handbook/
│   ├── guides/                        # Testing guides
│   │   ├── quick-reference.g.md
│   │   ├── testing-philosophy.g.md
│   │   ├── test-organization.g.md
│   │   ├── mocking-patterns.g.md
│   │   ├── test-performance.g.md
│   │   ├── testable-code-patterns.g.md
│   │   ├── testing.g.md
│   │   ├── testing-tdd-cycle.g.md
│   │   ├── embedded-testing-guide.g.md
│   │   ├── testing/                   # Technology-specific
│   │   └── test-driven-development-cycle/
│   ├── workflow-instructions/         # Workflows
│   │   ├── create-test-cases.wf.md
│   │   └── fix-tests.wf.md
│   ├── agents/                        # Test agents
│   │   ├── test.ag.md
│   │   ├── mock.ag.md
│   │   └── profile-tests.ag.md
│   └── templates/                     # Test templates
├── .ace-defaults/nav/protocols/       # Protocol registration
├── README.md
├── CHANGELOG.md
├── ace-test.gemspec
└── Rakefile
```

## Key Testing Patterns

### Performance Targets

| Test Layer | Target Time | Hard Limit |
|------------|-------------|------------|
| Unit (atoms) | <10ms | 50ms |
| Unit (molecules) | <50ms | 100ms |
| Unit (organisms) | <100ms | 200ms |
| Integration | <500ms | 1s |
| E2E | <2s | 5s |

### IO Isolation

- **No file system in unit tests**: Use MockGitRepo or inline strings
- **No network**: Use WebMock stubs
- **No subprocesses**: Use method stubs
- **No sleep**: Stub Kernel.sleep in retry logic

### E2E Rule

Keep exactly ONE E2E test per integration test file. Convert all other tests to use mocked versions.

## Development

After checking out the repo, run `bin/setup` to install dependencies.

To install this gem onto your local machine, run:
```bash
bundle exec rake install
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cs3b/ace.

## License

The gem is available as open source under the terms of the MIT License.

## Testing Guidance

### Strategy & Planning Guides

| Guide | Purpose |
|-------|---------|
| [Test Layer Decision](handbook/guides/test-layer-decision.g.md) | Decide unit vs integration vs E2E |
| [Testing Strategy](handbook/guides/testing-strategy.g.md) | Fast/Slow loop architecture |
| [Test Responsibility Map](handbook/guides/test-responsibility-map.g.md) | Map behaviors to test layers |

### Quality & Health Guides

| Guide | Purpose |
|-------|---------|
| [Test Mocking Patterns](handbook/guides/test-mocking-patterns.g.md) | Behavior testing, zombie mock detection |
| [Test Suite Health](handbook/guides/test-suite-health.g.md) | Metrics, CI integration, periodic audits |
| [Test Review Checklist](handbook/guides/test-review-checklist.g.md) | Quick checklist for reviewing test PRs |

### Testing Workflows

| Skill | Purpose |
|-------|---------|
| `/ace-test-plan` | Plan test coverage before coding |
| `/ace-test-verify-suite` | Audit test suite health (quick/standard/deep) |
| `/ace-test-optimize` | Profile and fix slow tests |
| `/ace-test-performance-audit` | Profile tests and document slow cases with actionable fixes |
| `/ace-test-review` | Review test PR for quality |
| `/ace-e2e-setup-sandbox` | Set up safe E2E environment |

Load guides via: `ace-bundle guide://test-layer-decision`

See [handbook/guides/SUMMARY.md](handbook/guides/SUMMARY.md) for the complete navigation index.

## ACE Integration

This gem is part of the ACE (Agentic Coding Environment) ecosystem. For more information:

- [ACE Documentation](https://github.com/cs3b/ace)
- [ace-nav Protocol](https://github.com/cs3b/ace)
