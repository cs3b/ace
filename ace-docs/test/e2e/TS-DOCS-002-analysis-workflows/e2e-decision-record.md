# E2E Decision Record - TS-DOCS-002 Analysis Workflows

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-005 analyze doc drift | KEEP | Verifies end-to-end single-doc analysis command contract including operator-visible outcome paths and persisted session artifacts. | `test/fast/cli/commands/analyze_test.rb` |
| TC-006 analyze consistency report | KEEP | Verifies cross-document analysis command contract for report-path output and persisted report artifacts in real CLI execution. | `test/fast/cli/commands/analyze_consistency_test.rb`, `test/fast/organisms/cross_document_analyzer_test.rb` |
