# TC-004 — Response loss, reconciliation, and refusal classifications

Uses the still-open fork PR (`FORK_PR`, head `FORKED`). The `fj` keys file
lives at `${XDG_DATA_HOME:-$HOME/.local/share}/forgejo-cli/keys.json` —
call it `$KEYS`.

## Goals

### Goal 1 — Missing credentials classify as authentication

1. `mv "$KEYS" /tmp/keys-e2e-backup.json`, then
   `bin/ace-git pr ready $FORK_PR --expected-head $FORKED --server
   e2e-forgejo --format json` → `ready-no-token.json` plus `.exit`.
   Expected: nonzero exit, category `authentication`, no mutation.
2. Restore: `mv /tmp/keys-e2e-backup.json "$KEYS"`.

### Goal 2 — An unreachable server cannot produce a receipt

3. `docker stop ace-e2e-forgejo`, then
   `bin/ace-git pr ready $FORK_PR --expected-head $FORKED --server
   e2e-forgejo --format json` → `ready-server-down.json` plus `.exit`.
   Expected: nonzero exit with a read/classified failure (no success
   claim). Record the exact category.
4. `docker start ace-e2e-forgejo` and wait until
   `curl -sf $FORGEJO_URL/api/v1/version` succeeds again (up to ~60s).

### Goal 3 — Reconciliation after restore: one outcome, no duplicates

5. With the server back, run the ready command again →
   `ready-recovered.json`. Expected: exit 0, `operation: ready`,
   `draft: false`.
6. Prove no duplicate was created for the fork identity:
   `curl -s -H "Authorization: token $(cat /tmp/ace-e2e-lab-token)"
   '$FORGEJO_URL/api/v1/repos/e2e-lab/base/pulls?state=open'` →
   `open-pulls-final.json`. Expected: exactly one open pull request with
   head repo `e2e-fork/base` and ref `feature/forked` (the canonical
   branch's open pull request, if any, is separate and expected).
7. `bin/ace-git pr show $FORK_PR --server e2e-forgejo --format json` →
   `show-final.json`. Expected: `draft: false`, head `$FORKED`.

### Goal 4 — Read-only paths mutate nothing

8. `bin/ace-git pr show $FORK_PR --server e2e-forgejo --format json` and
   `bin/ace-git pr show $FORK_PR --server e2e-forgejo` (text) →
   `show-final-text.stdout`. Expected: both exit 0; the server's open PR
   count is unchanged (re-run the listing from Goal 3 step 6 →
   `open-pulls-readonly.json`, identical content).
