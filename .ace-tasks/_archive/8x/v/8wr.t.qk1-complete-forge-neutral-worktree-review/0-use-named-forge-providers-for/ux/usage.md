# Worktree and neutral PR lifecycle — usage

## Exact PR checkout
`ace-git-worktree create --pr 25 --server forgejo-lab --dry-run`
Expected: source/base repository, exact head and planned path; no mutation. Remove dry-run only for authorized creation.

## Draft PR for pushed branch
`ace-git pr create --server forgejo-lab --head feature --head-repo https://forge.example/team/repo --base main --expected-head CANDIDATE_SHA --title "Feature" --body-file /tmp/pr-body.md --draft --format json`
Expected: exact draft PR identity/head; repeating unchanged identity returns the existing open PR.

## Stale merge
`ace-git pr merge 25 --server forgejo-lab --expected-head OLD_SHA --method squash`
Expected: head-conflict error, no merge. Lack of provider atomic head support is unsupported capability, not an unsafe fallback.

## Cleanup proof
`ace-git-worktree cleanup --target main --remote origin --server forgejo-lab --format json`
Expected: report-only candidates and exact provider proof; unavailable proof remains distinct from merged. No extra force can override missing proof.
