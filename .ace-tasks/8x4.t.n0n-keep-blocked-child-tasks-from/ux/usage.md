# Parent completion — usage contract

`bin/ace-task update CHILD --set status=done` completes only that child when another required sibling is blocked. The parent remains visible and nonterminal, and `bin/ace-task show PARENT` reports the blocked sibling.

When every required child is terminal under the reviewed policy, legitimate archival still returns the requested child ID; `show CHILD` resolves its archived record. No post-move not-found error is accepted after a successful update.
