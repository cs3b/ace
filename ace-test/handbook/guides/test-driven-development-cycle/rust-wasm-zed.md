---
name: tdd-rust-wasm-zed
description: Task cycle for Rust Wasm Zed extension development
doc-type: guide
purpose: TDD workflow for Zed extensions
search_keywords:
  - rust
  - wasm
  - zed
  - wit
  - extension
update:
  frequency: on-change
  last-updated: '2026-01-23'
---

# Implementing Task Cycle: Rust→Wasm Zed Extension

This details specific steps and commands for the task cycle when developing Rust-based Zed editor
extensions compiled to Wasm.

1. Define the interface in `.wit`; run `wit_bindgen_rust` to generate bindings.
2. Implement logic following the [Test -> Code -> Refactor cycle](./testing-tdd-cycle.g.md).
3. Build with `cargo build --target wasm32-unknown-unknown --release`.
4. Optimize size with `wasm-snip` if needed.
5. Smoke‑test by loading the generated `.wasm` file into the Zed sandbox environment.
