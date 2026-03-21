---
doc-type: guide
title: Rust Testing Guide
purpose: Rust testing conventions
ace-docs:
  last-updated: 2026-01-23
  last-checked: 2026-03-21
---

# Rust Testing Guide

This guide provides best practices for testing Rust code in the context of the coding-agent-workflow-toolkit project.

## 1. Test Types

- **Unit Tests**: Inline `#[cfg(test)]` modules next to implementation.
- **Integration Tests**: Files in `tests/` directory.
- **Doc Tests**: Ensure examples in doc comments compile and run.

## 2. Directory Layout

```text
project-root/
├── src/
│   └── lib.rs
├── tests/
│   └── integration.rs
```

## 3. Running Tests

```bash
cargo test            # all tests
cargo test my_test    # specific
```

Use `-- --nocapture` to see stdout.

## 4. Mocking & Fakes

- Use crates like `mockall` for trait-based mocking.
- For HTTP interactions, use `wiremock` crate.

## 5. Coverage

```bash
cargo tarpaulin --out Html
```

## 6. CI Integration

Ensure job uses `cargo test --all --locked`.