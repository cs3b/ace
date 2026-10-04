# Forgejo delivery scenarios (proven acceptance contract)

Proven 2026-10-04 against a disposable Forgejo 8.0.3 instance by
TS-FORGEJO-001 (16/16 goals PASS; see task-report-2026-10-04.md).
Minimum supported server: Forgejo 8.0 (version-probed before mutations).


Use the existing `ace-git pr` command forms documented by `ace-git/docs/usage.md`; supply the named Forgejo server, source repository/ref, base ref and full expected SHA. No new option spelling is invented here.

1. Create a draft from a canonical source, then a same-server fork source into the selected base. JSON must report that base, exact head repository/ref/SHA and draft=true. A second request returns the same object; draft disagreement is a conflict.
2. `ace-git pr show NUMBER --server NAME --format json` shows the same identity. Ready on that exact head clears draft; repeating ready is safe. Move the head during ready: no accepted stale receipt.
3. Merge with the reviewed expected SHA while another writer changes the branch. Only the server-accepted matching SHA may merge; the stale contender returns conflict. No force or alternative server retry.
4. Lose a response after create/ready/merge. Status/reconciliation reads the selected remote: report verified applied or unresolved uncertainty. Repeating a mutation without evidence is forbidden.
5. On a server lacking atomic merge support, show a classified capability error. This is safe failure, but the delivery acceptance row remains failed.
6. Missing credentials, wrong fork/server, ambiguous PR or malformed output yields a parseable non-success; secret credentials never appear in output. Read-only/dry-run performs zero mutations.
