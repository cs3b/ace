# Source implementation and verification

Root source714f6636b preserves actual execution success through sequential aggregation, final TestResult, terminal formatters and saved reports. This follow-up completes the pinned real CLI matrix and preserves in-process execution deadlines and operator interruption across Minitest's internal exception handling. A no-stdout failed execution now records zero completed errors instead of inventing one per file. Both per-file aggregation paths now consume exact per-execution stdout from the executor rather than inferring boundaries from runner headers. The real CLI matrix asserts exact combined partial/completed counts in both component orders and through explicit-file and by-target entrypoints.

The private ExecutionTimeout control-flow exception passes through Minitest's documented source SystemExit exception boundary and is caught by the in-process runner as deadline failure. Operator SIGINT is tracked during Minitest execution, re-raised to the CLI before report creation, and the previous signal handler is restored. No deadlines were raised and process-tree cleanup remains outside this slice.

## Verification coverage

Actual checkout bin/ace-test fixtures pin by-target --direct and --subprocess; continue-after-failure versus fail-fast markers; explicit --subprocess --per-file; --run-in-single-batch --subprocess; and --fail-fast precedence over batch. Controlled partial stdout contains passing counts but unsuccessful exit9. Passing text mentioning timeout remains successful; genuine assertion failure remains failed. Target deadlines run in both direct/subprocess with/without fail-fast. Child TERM is unsuccessful without invented completed errors. Operator SIGINT in both modes produces exit130 and no new completed report, preserving prior artifact bytes. Summary JSON, report JSON, Markdown status and terminal exit agree. Actual bin/ace-test-suite consumes the failed package report.

Existing three baseline fixture failures were repaired faithfully: ProcessMonitor expectations now include the already-existing RbConfig.ruby -rbundler/setup launcher; hermetic suite fixtures explicitly bootstrap checkout dependencies and eval the exact checkout Gemfile for disposable packages. Poisoned environment, fixture HOME isolation and parent environment immutability assertions remain enforced.

Root fail-before receipt8x42pq and repaired component8x42q4 (15/38) remain retained. Follow-up initial CLI8x42vc exposed missing fixture Gemfile plus direct SIGINT loss;8x42yj demonstrated direct timeout becoming a normal test error before the owner control-flow repair. Fixture-only targeted8x42wl:10 tests/54 assertions green. Full source8x42zm:255 tests/895 assertions green. Full8x432h:256 tests/901 assertions green, including actual suite consumer; final exact-count full package8x433i:256 tests/905 assertions, zero failures/errors, terminal exit0. No live test sessions remain.

Task remains in progress for independent source review. No main mutation, merge, push, publication, or done claim. Qjz remains frozen at a2cdb5804 while root owns its separate repair/review.

## Independent review round 1 repairs

Independent Sol 6.1 review `review-8x435i` rejected candidate `b2cf8b06a` with two Medium findings. Root reproduced both with receipt `8x43a5`: 2 tests, 9 assertions, 2 failures. No-stdout failure retained a synthetic `LoadError` failure detail despite zero completed error counts; passing stdout preceding headerless partial output lost counts. Both findings were verified through ace-review-feedback (`8x439mlu`, `8x439mlv`). The repair removes fabricated failure details and carries exact execution output boundaries through both aggregation consumers. Maintained CLI cases cover absent stdout, both component orders, and both entrypoints. Independent original probes now pass `8x43bu`: 2 tests, 9 assertions. A transient missing renamed local in raw-output projection was caught by the full rerun and corrected before candidate handoff.

The review also mentioned reverse-only task document changes because the original subject compared the older branch directly against newer main. Those are not branch deletions and must not be applied during integration. Subsequent review uses the verified common ancestor as its base.

Final repaired full package run `bin/ace-test ace-test-runner all --timeout 120`: receipt `8x43d1`, 258 tests, 987 assertions, zero failures/errors/skips, exit 0. Timeout remains the existing 120 seconds. Independent re-review is required before integration.
