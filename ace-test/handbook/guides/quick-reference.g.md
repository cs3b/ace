---
doc-type: guide
title: Testing Quick Reference
purpose: Testing quick reference
ace-docs:
  last-updated: 2026-01-23
  last-checked: 2026-03-21
---

# Testing Quick Reference

## TL;DR

- **Flat structure**: `test/atoms/`, `test/molecules/` - no deep nesting
- **Naming**: `*_test.rb` suffix, descriptive names
- **No IO in unit tests**: Use MockGitRepo, WebMock stubs, method stubbing
- **ENV testing**: Protected method pattern for parallel-safe tests
- **Fixtures**: YAML files in `test/fixtures/`, create via `yaml_fixture`
- **HTTP mocking**: VCR cassettes or WebMock stubs
- **File isolation**: `with_temp_dir` for filesystem tests
- **Run tests**: `ace-test atoms` or `ace-test path/to/test.rb`

## Performance Targets Quick View

| Test Layer | Target Time | Hard Limit |
|------------|-------------|------------|
| Unit (atoms) | <10ms | 50ms |
| Unit (molecules) | <50ms | 100ms |
| Unit (organisms) | <100ms | 200ms |
| Integration | <500ms | 1s |
| E2E | <2s | 5s |

## Key Patterns

- **E2E Rule**: Keep ONE E2E test per integration file, convert rest to mocked
- **Zombie Mocks**: Stubs that don't match actual code paths - profile regularly
- **Composite Helpers**: Reduce 6-7 level nesting to single helper calls
- **Sleep Stubbing**: Stub `Kernel.sleep` in retry tests

## Related Guides

- [Testing Philosophy](guide://testing-philosophy) - Pyramid, IO isolation
- [Test Organization](guide://test-organization) - Flat structure, naming
- [Mocking Patterns](guide://mocking-patterns) - Git, HTTP, subprocess, ENV
- [Test Performance](guide://test-performance) - Targets, optimization
- [Testable Code Patterns](guide://testable-code-patterns) - Status codes, exceptions