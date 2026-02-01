# ACE Testing Guide Index

Navigation index for all testing guides in the ace-test package.

## Core Testing Guides

| Guide | Protocol | Description |
|-------|----------|-------------|
| Quick Reference | `guide://quick-reference` | TL;DR of testing patterns - flat structure, naming, IO isolation |
| Testing Philosophy | `guide://testing-philosophy` | Testing pyramid, IO isolation principle, when real IO is allowed |
| Test Organization | `guide://test-organization` | Flat directory structure, naming conventions, layer boundaries |
| Mocking Patterns | `guide://mocking-patterns` | MockGitRepo, WebMock, subprocess stubbing, ENV testing patterns |
| Test Performance | `guide://test-performance` | Performance targets by layer, composite helpers, zombie mocks detection |
| Testable Code Patterns | `guide://testable-code-patterns` | Avoiding exit calls, returning status codes, exception patterns |
| Testing Guide | `guide://testing` | General testing guidelines and best practices |
| TDD Cycle | `guide://testing-tdd-cycle` | Test-driven development implementation cycle |
| Embedded Testing | `guide://embedded-testing-guide` | Embedded testing in workflows |

## Test Strategy & Planning

Decision frameworks for test design and layer assignment.

| Guide | Protocol | Description |
|-------|----------|-------------|
| Testing Strategy | `guide://testing-strategy` | Fast/Slow loop strategy for high-performance test suites |
| Test Layer Decision | `guide://test-layer-decision` | Decision matrix for unit vs integration vs E2E |
| Test Responsibility Map | `guide://test-responsibility-map` | Map behaviors to test layers to avoid redundant coverage |

## Test Quality & Health

Patterns for maintaining test suite quality and performance.

| Guide | Protocol | Description |
|-------|----------|-------------|
| Test Mocking Patterns | `guide://test-mocking-patterns` | Behavior testing, zombie mock detection, contract testing |
| Test Suite Health | `guide://test-suite-health` | Metrics, CI integration, periodic audits |
| Test Review Checklist | `guide://test-review-checklist` | Quick checklist for reviewing test PRs |

## Technology-Specific Guides

### Testing by Technology

| Guide | File | Description |
|-------|------|-------------|
| RSpec Patterns | `testing/ruby-rspec.md` | Ruby RSpec-specific testing patterns |
| RSpec Config Examples | `testing/ruby-rspec-config-examples.md` | RSpec configuration examples |
| Rust Testing | `testing/rust.md` | Rust testing patterns |
| TypeScript/Bun | `testing/typescript-bun.md` | Bun test patterns for TypeScript |
| Vue/Vitest | `testing/vue-vitest.md` | Vue + Vitest testing patterns |
| Vue/Firebase Auth | `testing/vue-firebase-auth.md` | Vue with Firebase authentication testing |
| Test Maintenance | `testing/test-maintenance.md` | Test maintenance and refactoring guidelines |

## TDD Cycle Guides

### Test-Driven Development by Platform

| Guide | File | Description |
|-------|------|-------------|
| Ruby Gem TDD | `test-driven-development-cycle/ruby-gem.md` | TDD workflow for Ruby gems |
| Ruby Application TDD | `test-driven-development-cycle/ruby-application.md` | TDD workflow for Ruby applications |
| Rust CLI TDD | `test-driven-development-cycle/rust-cli.md` | TDD for Rust CLI tools |
| Rust WASM/Zed TDD | `test-driven-development-cycle/rust-wasm-zed.md` | TDD for Rust WASM/Zed extensions |
| TypeScript Vue TDD | `test-driven-development-cycle/typescript-vue.md` | TDD for Vue applications |
| TypeScript Nuxt TDD | `test-driven-development-cycle/typescript-nuxt.md` | TDD for Nuxt applications |
| Meta Documentation TDD | `test-driven-development-cycle/meta-documentation.md` | TDD for documentation projects |

## Access Guides via ace-nav

```bash
# Quick reference
ace-nav guide://quick-reference

# Testing philosophy
ace-nav guide://testing-philosophy

# Mocking patterns
ace-nav guide://mocking-patterns

# TDD cycle
ace-nav guide://testing-tdd-cycle

# New test strategy guides
ace-nav guide://testing-strategy
ace-nav guide://test-layer-decision
ace-nav guide://test-mocking-patterns
ace-nav guide://test-suite-health
ace-nav guide://test-responsibility-map
ace-nav guide://test-review-checklist
```

## See Also

- [Workflows](../workflow-instructions/) - Testing-related workflows
- [Agents](../agents/) - Testing automation agents
- [Templates](../templates/) - Test case templates
