# Remaining bulk-update regression evidence — 2026-10-05

Implementation reviewed/tested source: `1e868bf84a68cc2edffe6023b0702ab742d25980`, based on `7957a306d`.

## Plan and scope

1. Preserve the delivered Tempfile.create fixture ownership repair and historical forced-GC failure evidence.
2. Read persisted YAML from both documents after the count-2 bulk update; assert the requested value in the `ace-docs` namespace.
3. Exercise missing, valid and nil paths together after forced GC; assert count 1, persisted frontmatter on the valid file, and absence of the missing file.
4. Execute targeted, docs-all and default fast monorepo gates; obtain independent review before closure by the integration owner.

Only `ace-docs/test/fast/molecules/frontmatter_manager_test.rb` changes. Product semantics and historical evidence are preserved. Both bulk cases explicitly call `GC.start` after fixture creation. The missing path lives inside the test-owned directory, so ambient filesystem state cannot supply it.

`bin/ace-task plan 8ws.t.ibl` produced no plan during its bounded wait and was cancelled with exit 130; only its prompt artifacts exist under `.ace-local/task/8ws.t.ibl/prompts/8x4c7f-*`. The concrete plan above follows the ready task's remaining SC2/SC3 scope.

## Executed package gates

Working directory: `/Users/mc/Ps/ace/.ace-wt/ibl-docs-evidence`.

- `bin/ace-test ace-docs ace-docs/test/fast/molecules/frontmatter_manager_test.rb`: exit 0, 16 tests / 60 assertions, 0 failures/errors/skips; seed 39628. Actual report: `.ace-local/test/reports/docs/8x4c81/report.json`; seed/raw receipt: `raw_output.txt` alongside it.
- `bin/ace-test ace-docs all`: exit 0, 214 tests / 584 assertions, 0 failures/errors/skips. Actual report: `.ace-local/test/reports/docs/8x4c8g/report.json`; raw receipt: `raw_output.txt` alongside it. Seeds: atoms 60038; molecules 55254; organisms 40210; models 47254; commands 63294; cli 56977; prompts 19388; feat 19172.

These gates ran against the exact final source diff before its commit. The only intervening parent merge changed task status; no source changed between these gates and the frozen SHA.

An initial `--filter test_update_documents` command selected no files (exit 0); it is not a test receipt. The explicit file command above corrected selection and exercised the forced-GC cases.

## Independent review and full-suite gate

The integration owner reported independent review of exact SHA `1e868bf84a68cc2edffe6023b0702ab742d25980`: APPROVE, no findings. The reviewer independently reran the target: report `.ace-local/test/reports/docs/8x4c9i/report.json`, 16 tests / 60 assertions, seed 30546, pass. Review completed before the broad suite started.

`bin/ace-test-suite --timeout 300` executed the default fast suite at that SHA and exited 0: terminal aggregate 51 packages passed / 0 failed, 11204 tests passed / 0 failed / 24 skipped, 34182 assertions, 170.81 seconds. Assign took 167.44 seconds, validating the explicit timeout override. No package configuration changed and no concurrent targeted command ran in this worktree during the suite.

The suite's docs invocation has its own actual report `.ace-local/test/reports/docs/8x4cas/report.json`: 208 tests / 573 assertions, 0 failures/errors/skips; seed 36955. Its raw output confirms one batch containing both forced-GC bulk cases. This is fast coverage; the separate docs-all gate above includes feat coverage.

Durable copies of the four docs reports and raw receipts are in `evidence/2026-10-05/docs-<invocation>/`. `evidence/2026-10-05/suite-package-receipts.json` records unique invocation paths and actual summaries for all report-producing package invocations (excluding mutable `latest` aliases). Zero-test package invocations emit no report. The terminal aggregate repeats ace-lab in its skipped list, so its totals are reported as displayed, not represented as independently reconciled unique counts; the saved unique receipts retain the underlying truth. This known runner aggregation limitation does not alter the exact docs receipt or the executed exit-0 gate.

SC2 is demonstrated by persisted reads and mixed-path count assertions. SC3 has executed package/suite gates plus independent approval. Task status and checkboxes remain owned by the integration agent; this report does not mark the task done.
