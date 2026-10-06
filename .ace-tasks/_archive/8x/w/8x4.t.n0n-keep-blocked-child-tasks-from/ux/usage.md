# Parent completion — usage contract

`bin/ace-task update CHILD --set status=done` completes only that child when another required sibling is blocked. The parent remains visible and nonterminal, and `bin/ace-task show PARENT` reports the blocked sibling.

When every required child is terminal under the reviewed policy, legitimate archival still returns the requested child ID; `show CHILD` resolves its archived record. No post-move not-found error is accepted after a successful update.

Eligible terminal child outcomes are `done`, `skipped`, and `cancelled`. Every task descendant must have one of these outcomes before automatic family completion. Historical evidence files are not task descendants.

`bin/ace-task update PARENT --set status=done --move-to archive` prints a refusal note when a descendant remains blocked or unfinished. It leaves requested fields and family paths unchanged; resolve the unfinished child first. Standalone tasks retain their existing explicit archive behavior.

Doctor reports scope inconsistencies but skips archive moves that would carry unfinished descendants and skips changing an archived nonterminal task to done based only on its location. Review the lifecycle state manually instead.
