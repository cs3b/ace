## 🌐 High-Level Action Plan (Task 39)

Grouped and prioritised actions derived from the code-review findings in **cr.final.md**.
The list deliberately skips the “low test coverage” remarks (our coverage is already > 90 %).
Tasks **#1** and **#2** below were pre-defined—keep them unchanged and address them within the wider roadmap.

### 🔴 Priority 1 – Naming & Unified CLI
1. Align provider naming throughout the codebase (use **`google`** instead of **`gemini`**)
   • Rename executables & directories (`exe/llm-gemini-query` → alias, primary `exe/llm-query`)
   • Update constants, YAML model metadata, fixtures, and specs
   • Relocate command class from `llm/query` to `google/query`; register legacy alias for backward-compatibility
   • Patch CI, docs, and changelog to reflect the new naming scheme
2. Introduce unified entry-point `llm-query <provider>:<model> <prompt>`
   • Remove the `--model` flag; parse provider & model from the first positional argument
   • Ship popular shorthand aliases (`gflash`, `gpro`, `o3`, `o4-mini`, etc.) for ergonomic use
   • Provide thin wrapper scripts (`llm-gemini-query`, …) that delegate to `llm-query` until v1.0 to ease migration

### 🔴 Priority 2 – Refactor for DRYness
3. Introduce `BaseChatCompletionClient` / `BaseClient` hierarchy and refactor all provider clients to inherit
4. Extract `BaseQueryCommand`; register provider commands dynamically to remove duplication
5. Consolidate fallback model constants into a single configuration source

### 🔴 Priority 3 – Security & Runtime Hardening
6. Harden File-IO layer
   • Sanitise paths in `FileIoHandler` to block traversal
   • Add `--force` / confirmation flag before overwriting files
7. Provide missing `Atoms::JSONFormatter` implementation
8. Scrub API keys from any debug / log output

### 🟡 Subsequent Enhancements
9. Extend `MetadataNormalizer` with token/usage parsing for every provider
10. Honour `XDG_CACHE_HOME` for cached data and add retry/back-off middleware for HTTP 429/5xx
