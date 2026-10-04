# TC-004 Verify — Response loss and reconciliation goals

### Goal 1 - Missing credentials classify as authentication

- **Verdict**: PASS only if `ready-no-token.exit` is nonzero with
  category `authentication` and no token material appears in any message.

### Goal 2 - An unreachable server cannot produce a receipt

- **Verdict**: PASS only if `ready-server-down.exit` is nonzero with a
  classified (parseable) error and no success claim.

### Goal 3 - Reconciliation after restore

- **Verdict**: PASS only if `ready-recovered.exit` is 0 with
  `draft: false`, `open-pulls-final.json` shows exactly one open pull
  request for the fork identity (`e2e-fork/base` + `feature/forked`);
  an open canonical-branch pull request alongside it is expected and not
  a failure, and
  `show-final.json` reports `draft: false` at the fork head SHA.

### Goal 4 - Read-only paths mutate nothing

- **Verdict**: PASS only if both show invocations exit 0 and
  `open-pulls-readonly.json` is content-identical to
  `open-pulls-final.json`.
