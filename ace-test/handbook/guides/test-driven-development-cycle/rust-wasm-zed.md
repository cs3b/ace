---
doc-type: guide
title: "Implementing Task Cycle: Rust→Wasm Zed Extension"
purpose: TDD workflow for Zed extensions
ace-docs:
  last-updated: 2026-01-23
  last-checked: 2026-03-21
---

# Implementing Task Cycle: Rust→Wasm Zed Extension

This details specific steps and commands for the task cycle when developing Rust-based Zed editor
extensions compiled to Wasm.

1. Define the interface in `.wit`; run `wit_bindgen_rust` to generate bindings.
2. Implement logic following the [Test -> Code -> Refactor cycle](./testing-tdd-cycle.g.md).
3. Build with `cargo build --target wasm32-unknown-unknown --release`.
4. Optimize size with `wasm-snip` if needed.
5. Smoke‑test by loading the generated `.wasm` file into the Zed sandbox environment.