# Execution verdict test responsibility map

Fast owner tests preserve execution success through target aggregation and final result/report data, independently of stdout words and assertion counts. Existing root regressions establish fail-before/pass-after.

Feature tests invoke the actual checkout bin/ace-test against disposable, fixture-owned packages. Pin direct target, subprocess target, subprocess per-file, and subprocess single-batch modes; test fail-fast precedence, continue-after-failure marker, timeout, child signal, genuine assertion failure, passing timeout text and operator SIGINT exit130/no fresh success artifact. Use real process status and saved JSON/report, never mocked CLI exit codes. Existing package fixture repairs keep the complete checkout dependency surface and Ruby/bundler launcher contract.

Run targeted new feature cases, affected suite fixtures, then ace-test-runner all without deadline changes. Parent root retains independent review responsibility and task completion.
