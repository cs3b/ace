# Concurrent review sessions — draft usage

Two operators start `bin/ace-review --preset code-valid --subject diff:BASE..HEAD --auto-execute` and a spec review in the same checkout at the same instant. Each command reports its own session directory. Listing feedback with each exact directory returns only findings from that review, independent of finish order.

An operator starts a new review with `--session-dir .ace-local/review/sessions/already-used`. Expected: nonzero refusal before reviewer startup; existing metadata, reports and findings are unchanged. Choose a fresh explicit location for the new invocation.

Two concurrent invocations request one empty explicit directory. Expected: exactly one owner; the other refuses without writing into that session. An automatic allocation collision instead selects a different isolated directory. These are behavioral requirements, not current implementation claims.
