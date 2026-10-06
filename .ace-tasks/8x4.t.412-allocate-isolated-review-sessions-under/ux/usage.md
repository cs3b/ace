# Concurrent review sessions

Start independent source and spec reviews in the same checkout. Each automatic
invocation prints its own session directory, even with equal clocks. Use each
reported path with `bin/ace-review-feedback list --session PATH`; findings remain
attributable to that review in either completion order.

```bash
bin/ace-review --preset code-valid --subject diff:BASE..HEAD --auto-execute
# Output includes: Session directory: /project/.ace-local/review/sessions/review-<id>
bin/ace-review-feedback list --session /project/.ace-local/review/sessions/review-<id>
# Output lists only findings from this invocation.
```

For an explicit session, choose a fresh path or an unclaimed empty directory.
Exactly one concurrent invocation can own it. A persistent `.review-session-claim`
remains after completion, failure or interruption; later invocations refuse before
writing artifacts or starting a reviewer. Occupied directories, files and symlinks
are preserved. An automatic collision instead chooses another owned location.

```bash
bin/ace-review --preset code-valid --subject diff:BASE..HEAD --session-dir .ace-local/review/source-round-2
# Output includes: Review session prepared: .ace-local/review/source-round-2
```

A repeated command with that path exits nonzero with `Cannot allocate review
session`. Choose a new path. Existing dedicated campaign/delta/evidence operations
retain their own contracts. Release report copies also remain separate when two
same-model reviews complete at the same clock reading.
