---
doc-type: guide
title: "Implementing Task Cycle: Rust CLI"
purpose: TDD workflow for Rust CLI apps
ace-docs:
  last-updated: 2026-01-23
  last-checked: 2026-03-21
---

# Implementing Task Cycle: Rust CLI

This details specific steps and commands for the task cycle when working on a Rust command-line application within this project.

* Follow the standard [Test -> Code -> Refactor cycle](./testing-tdd-cycle.g.md).
* Use `cargo test` for running tests.
* Use `cargo clippy --all-targets` for linting.
* Use `cargo fmt --check` (or `cargo fmt` to apply) for formatting.
* Matrix CI from GitHub template exercises stable/beta/nightly.