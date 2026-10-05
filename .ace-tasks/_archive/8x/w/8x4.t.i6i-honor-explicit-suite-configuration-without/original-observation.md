# Explicit suite config ignored — local observation

Source: main dd7681099 (product equals verified consumer07ee). Intended hermetic retry:
`bin/ace-test-suite --config .ace-local/test/assign-suite-retry.yml --timeout 300 --parallel 1`.
The temporary YAML was derived from committed `.ace/test/suite.yml` and selected exactly one unchanged ace-assign entry; all environment/test options were preserved.

Observed output: `Test mode: deterministic (hermetic environment)` followed by `Running tests for 51 packages...`.
Inspection of ace-test-runner/exe/ace-test-suite confirms `options[:config]` is parsed but unused; configuration always comes from `Ace::Core.get("test", file: "suite")`.

Root stopped only its own exact invocation, PID18970, with SIGINT. Tool session65180 completed exit130 after17.93s; no completed report. This invocation supplies no test-pass evidence. No repository configuration or product code was changed by the attempted retry. A bounded source repair with CLI regression tests is delegated to canonical_result_source_review, independently reviewed by root before integration.
