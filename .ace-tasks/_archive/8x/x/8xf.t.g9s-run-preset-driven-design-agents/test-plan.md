# Runner test responsibility map

The accepted conversation plan is the implementation specification.

| Behavior | Risk | Owner / layer |
| --- | --- | --- |
| Preset cascade, slots, model/prompt overrides, invalid inputs before execution | medium | design fast config tests with real temporary YAML |
| Snapshot shared input, prepare once, independent duplicate-model workers, bounded concurrency | high | design feature runner tests; inject only the LLM boundary |
| Failure/resume, immutable fixtures, revision preservation and selection invalidation | high | design feature runner tests with real files |
| CLI repeatable arguments, installed discovery and dry-run without credentials | high | installed CLI feature tests |
| Variable-count gallery and preview allowlist | high | real Node/browser feature tests |
| Provider cancellation and timeout process cleanup | high | CLI-provider feature test at subprocess boundary |
| Real generation and B-only revision | high | manual three-worker smoke via public CLI; inspect real rendered output |

No model calls in deterministic tests. Real smoke uses the configured coding-agent role, records actual outcomes and hashes, and does not claim a production audit. Run ace-test for every changed package and ace-test-suite once after integration. Independent ace-review before delivery.
