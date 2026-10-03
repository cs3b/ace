# Task issue linkage — usage

Local create, show, update, and hierarchy commands work without forge setup.
The following commands use configured `git.servers` and a selected provider's
credentials only when an issue link is involved.

## Link to named Forgejo
`ace-task create "Fix regression" --issue 42 --server forgejo-lab`
Expected: local task plus validated exact remote_issue identity and ACE tracking; unrelated issue content survives.

Output: `Created task <id>` with its local path. `ace-task show <id> --content`
displays the complete persisted `remote_issue` mapping.

## Replay deferred synchronization
`ace-task issue-sync --pending`
Expected: exact stored servers are used regardless of changed default; per-task results, nonzero if any remain unresolved. No pending tasks yields successful zero count.

Output for an empty queue: `Issue sync: synced 0, failed 0, pending 0, skipped 0`.

## Link conflict
`ace-task issue-link TASK --issue 43 --server forgejo-lab`
Expected when already linked to 42: conflict without local/remote mutation. Explicit successful clear is required before another association.

Output: nonzero error explaining that the existing link must be cleared.

## Clear failure
`ace-task issue-link TASK --clear`
Expected when provider is unavailable: nonzero with retained link/pending recovery identity; unrelated content and issue state remain unchanged.

Output: classified provider error. After restoring provider access, run the
same `--clear` command again; the stored identity determines the target.
