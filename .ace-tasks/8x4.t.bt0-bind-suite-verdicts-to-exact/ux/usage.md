# Exact test invocation evidence

## Suite and concurrent focused test

Run `bin/ace-test-suite --timeout 300`. While its llm-providers-cli child is complete but other packages continue, run `bin/ace-test ace-llm-providers-cli molecules ace-llm-providers-cli/test/fast/molecules/safe_capture_test.rb` in another terminal. Both receive separate concrete report paths. The suite retains its full selected package counts and that child's report link after the focused run changes latest; no total is recalculated from that pointer.

## Missing current evidence

In the controlled integration fixture, let the selected child exit before producing its bound report while a successful older package report remains at latest. The suite identifies missing current execution evidence, reports that entry as failed/unverifiable and exits nonzero. It neither borrows the old pass nor reports an unverified zero-test success.

## Same package selected twice

A suite configuration containing two distinct entries for the same package executes and records both independently, including with an identical allocation clock. Their report locations and execution identities differ. Updating latest with a third run changes neither completed entry. No user flag is needed to opt into correct attribution.

## Report saving disabled and zero selection

Run the existing package CLI with `--no-save-reports`, or a suite entry using `save_reports: false`. The exact invocation still produces machine completion evidence and correct counts/outcome for its caller. No detailed/human/raw report files are persisted, and output does not fabricate a report path. A concurrent saved run cannot replace this result.

If that exact invocation completed discovery and selected zero files, its explicit zero-selection result is valid and contributes zero tests. An early child exit with no completion evidence instead fails verification even when its exit status is zero or latest has an old successful report.
