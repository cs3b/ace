# Selected historical test timeout cleanup evidence

Controlled source run `bin/ace-test ace-assign feat test/feat/authority/historical_rotation_test.rb:428 --timeout 480`, session29278, receipt `e373d173-7921-45b1-8008-a107db3c95b2`, timed out with zero reported tests/assertions. Open3 capture readers reported `stream closed in another thread`, but the exact selected Ruby child continued Git verification past the deadline. Authoritative runner completion required narrowly terminating that owned child (PID48550, parent CLI48525); total elapsed10m46s. No native or installed probe was involved.

`ace-test-runner/lib/ace/test_runner/molecules/test_executor.rb` wraps `Open3.capture3` in `Timeout.timeout` and rescues Timeout::Error without explicit child process-group termination/reaping. Capture timeout therefore did not promptly stop this controlled test lineage. This is retained evidence for the existing bys runner follow-up, not a runner repair or task promotion.

Separate settlement provenance batching addresses repeated authenticated Git history work without raising the timeout or removing checks. A subsequent same-budget historical run is tracked in the settlement source receipt. The earlier timeout remains a failure.

The first selector-batched run, session22241, also crossed480s with the same capture-reader errors. Exact owned selected child88770 under runner88759 was terminated after confirmed deadline/noncompletion; authoritative receipt `ee80c0d4-7f0c-4cdb-a66b-a215b380d0b6` reports timeout, zero tests/assertions,9m02s. Stage trace had reached actual historical retirement at372.74s with17,980 Git commands. This run is not green; subsequent per-read blob batching is a separate measured repair.
