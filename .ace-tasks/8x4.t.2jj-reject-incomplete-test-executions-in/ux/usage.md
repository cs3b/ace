# Aggregate execution verdicts

1. `bin/ace-test FIXTURE_PACKAGE all --timeout 1`: fixture fast target passes, feat exceeds the deadline. Expect nonzero exit, timeout diagnostic, saved `success: false`; completed fast counts remain visible.
2. `bin/ace-test FIXTURE_PACKAGE all --fail-fast`: a target exits nonzero after printing a passing summary. Expect failure and no later target execution.
3. `bin/ace-test FIXTURE_PACKAGE all`: all targets exit successfully, one logs the word timeout. Expect success; text alone does not classify failure.

Use disposable isolated fixtures, never ambient Lab state. These are acceptance scenarios, not claims that current behavior meets them.

4. Pin `--subprocess --per-file --no-fail-fast` with fixture target fail-fast disabled: failed first file followed by a marker-producing passing file. Marker must exist, overall exit/report still fail. With `--fail-fast`, marker must be absent.
5. Run a controlled long fixture through the CLI and deliver operator SIGINT. Expect exit 130, interruption diagnostic and no freshly published successful artifact. Do not reuse an earlier report as this invocation's result.

Implemented source contract: normal reports retain `execution_success` and
`execution_error` separately from completed assertion counts. An unsuccessful
process or deadline produces nonzero CLI exit and `summary.json` success false,
including after a green partial stdout summary. No-stdout process failure records
zero completed test errors rather than inventing one error per selected file.
Operator Ctrl-C preserves exit130 and creates no normal completed report; earlier
artifacts remain untouched. In-process Minitest deadlines and operator interrupts
pass back to the runner owner rather than becoming ordinary test failures.
