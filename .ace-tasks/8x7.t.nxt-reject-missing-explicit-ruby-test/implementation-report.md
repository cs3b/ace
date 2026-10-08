# Missing literal Ruby test selector refusal

Uncovered scope, separate from completed `jeo` file:line selection work. Task
`8x7.t.nxt` remains in-progress pending the combined independent review.

## Reproduction and owner

The root's `bin/ace-test ace-assign fast test/fast/authority/endcap_campaign_snapshot_test.rb`
used a nonexistent whole file. CliArgumentParser silently ignored it because
`@target` was already set, broadening execution to 86/152 fast files. The root stopped
that owned run (exit 130); the correct `campaign_result_snapshot_test.rb` selected
one file and passed (root report `1236ae94`).

The owner is `ace-test-runner`'s CliArgumentParser, before TestOrchestrator. A literal
`.rb` argument that is neither an existing direct/package-relative file nor a glob
now raises `ArgumentError` with `File not found`. First-position Ruby literals are
also excluded from package-name classification. Existing targets, Ruby globs and
valid package-prefixed, absolute and relative selectors retain their parsing paths.
No file:line protocol or orchestration fallback was added.

## Executed evidence

- Before source fix, the added parser regression failed: 18 tests, 56 assertions,
  one failure, zero errors. Report
  `.ace-local/test/reports/test-runner/b54d4cbf-e7a8-4d89-8614-1c1efda3434a/`.
- After source fix, scoped parser tests passed: 18 tests, 70 assertions, zero
  failures/errors. Report
  `.ace-local/test/reports/test-runner/9a1e4856-6dbc-415c-a76f-4e6f772b3d78/`.
- Public process refusal test uses one temporary safe probe test; it verifies a
  nonzero missing-file error, no suite execution marker, no runner-start output and
  no report-directory creation: 1 test, 7 assertions passed in 280.23 ms. Report
  `.ace-local/test/reports/test-runner/b4069a34-ab1e-4948-8dc8-986d4da716dd/`.

No broad suite, environment/native/Lab probe, model call, remote metadata lookup,
publication or merge was performed. Source base `3f1a79911`; isolated worktree
`/tmp/ace-test-missing-file`, branch `codex/test-missing-file-refusal`.
