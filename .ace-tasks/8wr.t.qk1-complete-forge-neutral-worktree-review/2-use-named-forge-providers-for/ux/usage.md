# Task issue linkage — usage

## Link to named Forgejo
`ace-task create "Fix regression" --issue 42 --server forgejo-lab`
Expected: local task plus validated exact remote_issue identity and ACE tracking; unrelated issue content survives.

## Replay deferred synchronization
`ace-task issue-sync --pending`
Expected: exact stored servers are used regardless of changed default; per-task results, nonzero if any remain unresolved. No pending tasks yields successful zero count.

## Link conflict
`ace-task issue-link TASK --issue 43 --server forgejo-lab`
Expected when already linked to 42: conflict without local/remote mutation. Explicit successful clear is required before another association.

## Clear failure
`ace-task issue-link TASK --clear`
Expected when provider is unavailable: nonzero with retained link/pending recovery identity; unrelated content and issue state remain unchanged.
