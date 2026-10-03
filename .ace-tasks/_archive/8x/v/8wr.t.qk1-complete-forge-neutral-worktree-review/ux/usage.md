# Shared forge selection — usage

## Explicit named Forgejo
`ace-git pr show 25 --server forgejo-lab --format json`
Expected: exact configured repository/server/provider/PR/head evidence; no GitHub CLI execution.

## Explicit default
`ace-git pr show 25 --default-server`
Expected: the single configured default, or classified missing/multiple-default failure. No implicit default on failed remote resolution.

## Invalid identity
`ace-git pr show https://other.example/team/repo/pulls/25 --server forgejo-lab`
Expected: repository/server mismatch before mutation. A changed default does not retarget stored links.

## Local-only operation
`ace-git status --no-pr`
Expected: local result with all provider tools/network/config unavailable.
