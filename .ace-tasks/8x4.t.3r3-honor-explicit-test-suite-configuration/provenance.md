# Investigation provenance

This is a pre-existing bug, separate from the qjz source repair and Lab acceptance gates.

Root reported an actual invocation of `bin/ace-test-suite --config .ace-local/lab-readiness/assign-suite-isolation.yml --parallel 1` selecting 51 packages instead of the isolated configuration. Root interrupted only its owned run (session 52048, PID 72170) with SIGINT; terminal status was 130. This is interrupted failure evidence, not a passing gate. This draft does not claim an independent execution reproduction of that run.

Independent source inspection at draft base `6c672e6db` verifies `ace-test-runner/exe/ace-test-suite:29–30` accepts the flag into `options[:config]`, while line 91 loads `Ace::Core.get("test", file: "suite")` unconditionally. The parsed path is never read by configuration loading. Lines 93–96 diagnose only the default path. Package selection and overrides then act on the default configuration. Public `ace-test-runner/docs/usage.md:82` advertises a suite config path and examples at lines 96–98 rely on it.

Investigation was read-only for package source. No tests or suite executions were run in this specs-only draft lane; the task's maintained real-CLI selection tests belong to implementation after readiness review. Root uses an isolated working-directory gate to avoid this bug on the current critical path.
