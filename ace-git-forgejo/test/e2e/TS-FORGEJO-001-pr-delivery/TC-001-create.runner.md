# TC-001 — Create: canonical and fork drafts with exact identity

Work in the workspace root; the pushed branch facts:

- `feature/canonical` at the SHA recorded by
  `git -C work-base rev-parse feature/canonical` (call it `CANON`)
- `feature/forked` (pushed to the fork) at
  `git -C work-base rev-parse feature/forked` (call it `FORKED`)

## Goals

### Goal 1 — Canonical draft create, replay, and show

1. `bin/ace-git pr create --head feature/canonical --base main
   --expected-head $CANON --title "Ship canonical" --draft --server
   e2e-forgejo --format json` → save as `create-canonical.json` plus
   `.stdout`/`.exit`.
2. Repeat the identical command → `create-canonical-replay.json`.
3. `bin/ace-git pr show <number-from-step-1> --server e2e-forgejo
   --format json` → `show-canonical.json`.

Expected observations (record, do not judge): first create exits 0 with
`idempotency: created`, `draft: true`, a `WIP: `-prefixed title, exact
`head`/`head_ref`/`base_ref`/`base_repository`; the replay exits 0 with
`idempotency: existing` and the same PR number; show reports the same
identity.

### Goal 2 — Same-server fork draft create

4. `bin/ace-git pr create --head feature/forked --base main
   --expected-head $FORKED --title "Ship forked" --draft
   --head-repo http://127.0.0.1:24417/e2e-fork/base --server e2e-forgejo
   --format json` → `create-fork.json`.

Expected observations: exits 0, `idempotency: created`, `draft: true`,
`head_repository` is the fork URL while `base_repository` stays the base
repository.

### Goal 3 — Cross-host head refuses before any mutation

5. `bin/ace-git pr create --head feature/forked --base main
   --expected-head $FORKED --title "Cross host"
   --head-repo https://github.com/octocat/base --server e2e-forgejo
   --format json` → `create-cross-host.json` plus `.exit`.

Expected observations: exits nonzero; the JSON error category is
`unsupported_capability`; the message names the refused head repository.
Then verify no new PR appeared:
`curl -s -H "Authorization: token $(cat /tmp/ace-e2e-lab-token)"
'$FORGEJO_URL/api/v1/repos/e2e-lab/base/pulls?state=open'` → save as
`open-pulls-after-refusal.json`; it must list exactly two open PRs.

### Goal 4 — Draft:false with a WIP title is a conflict

6. `bin/ace-git pr create --head feature/canonical --base main
   --expected-head $CANON --title "WIP: contradictory" --no-draft
   --server e2e-forgejo --format json` → save as
   `create-draft-conflict.json` plus `.exit`.

Note: this request matches the existing open PR #1 (same head/base) whose
draft state is true — the expected observation is a nonzero exit with a
draft disagreement conflict (category `conflicting_matches`), NOT a silent
ready publication and NOT a second PR.

### Goal 5 — Wrong same-owner source refuses before POST

7. Request `feature/forked` at `$FORKED` with `--head-repo http://127.0.0.1:24417/e2e-fork/unrelated`, the same server/base and draft flags as Goal 2. Record `create-wrong-source.json` and exit. The unrelated repository has the actual fork's branch and SHA, but is not the repository selected by Forgejo's fork resolver.
8. List open PRs by raw API. Record `open-pulls-after-wrong-source.json`. The create exits nonzero with `identity_mismatch`; the list still contains exactly the two earlier PRs, with no unrelated source.
