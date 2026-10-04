# TC-003 — Merge: server-enforced heads, methods, and refusals

Preparation (real pushes, keep evidence):

1. In `work-base`: `git checkout main && git checkout -b feature/squash &&
   printf 'squash\n' > squash.txt && git add squash.txt && git commit -m
   'squash work' && git push -u origin feature/squash`; record
   `SQUASH=$(git rev-parse feature/squash)`.
2. Same pattern for `feature/merge` (`merge.txt`) and `feature/rebase`
   (`rebase.txt`); record `MERGE_SHA`, `REBASE_SHA`.
3. Create non-draft PRs for all three branches with
   `bin/ace-git pr create ... --no-draft --server e2e-forgejo --format
   json`; record their numbers as `SQUASH_PR`, `MERGE_PR`, `REBASE_PR`
   (they are created ready-to-merge; `draft: false` expected).

## Goals

### Goal 1 — A draft PR cannot be merged (classified refusal)

4. The fork PR from TC-001 (`FORK_PR`) is still a draft. Run
   `bin/ace-git pr merge $FORK_PR --expected-head $FORKED --method merge
   --server e2e-forgejo --format json` → `merge-draft-refusal.json`.
   Expected: nonzero exit, category `unsupported_capability`, message
   about work in progress.

### Goal 2 — Server rejects a stale head atomically (raw API evidence)

5. `curl -s -o merge-stale.json -w "%{http_code}" -X POST -H
   "Authorization: token $(cat /tmp/ace-e2e-lab-token)" -H 'Content-Type:
   application/json' -d '{"Do":"squash","head_commit_id":
   "0000000000000000000000000000000000000000"}'
   $FORGEJO_URL/api/v1/repos/e2e-lab/base/pulls/$SQUASH_PR/merge` — save
   the HTTP status to `merge-stale.exit` and the body to
   `merge-stale.json`. Expected: HTTP 409 with message `head out of
   date` (the server enforced the expected head; no merge happened).
6. Prove the provider maps exactly that refusal:
   `bin/ace-git pr merge $SQUASH_PR --expected-head
   0000000000000000000000000000000000000000 --method squash --server
   e2e-forgejo --format json` → `merge-stale-provider.json`. Expected:
   nonzero exit with category `expected_head_conflict`.

### Goal 3 — Each requested method merges with proof

7. Ready `$SQUASH_PR`, then
   `bin/ace-git pr merge $SQUASH_PR --expected-head $SQUASH --method
   squash --server e2e-forgejo --format json` → `merge-squash.json`.
   Expected: exit 0, `operation: merge`, `state: merged`, non-null
   `merge_commit`, head = `$SQUASH`.
   Note: Forgejo computes mergeable state asynchronously; a merge may be
   refused with a transient `unreachable` error whose message says
   "try again later". That is a definitive no-mutation refusal — record
   it as `merge-squash-transient.json`, wait ~10 seconds, and repeat the
   identical command until it succeeds (record the successful attempt as
   `merge-squash.json`).
8. Same for `$MERGE_PR` with `--method merge` → `merge-merge.json`
   (same transient-retry rule if needed).
9. Same for `$REBASE_PR` with `--method rebase` → `merge-rebase.json`
   (same transient-retry rule if needed).

### Goal 4 — An already-merged result is reusable with authoritative evidence

10. Repeat the squash merge command from Goal 3 → `merge-squash-replay.json`.
    Expected: exit 0, `operation: merge`, `state: merged`, the same
    `merge_commit` as `merge-squash.json` (no second mutation; no error).
