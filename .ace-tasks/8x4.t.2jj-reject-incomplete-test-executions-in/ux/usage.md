# Aggregate execution verdicts

1. `bin/ace-test FIXTURE_PACKAGE all --timeout 1`: fixture fast target passes, feat exceeds the deadline. Expect nonzero exit, timeout diagnostic, saved `success: false`; completed fast counts remain visible.
2. `bin/ace-test FIXTURE_PACKAGE all --fail-fast`: a target exits nonzero after printing a passing summary. Expect failure and no later target execution.
3. `bin/ace-test FIXTURE_PACKAGE all`: all targets exit successfully, one logs the word timeout. Expect success; text alone does not classify failure.

Use disposable isolated fixtures, never ambient Lab state. These are acceptance scenarios, not claims that current behavior meets them.
