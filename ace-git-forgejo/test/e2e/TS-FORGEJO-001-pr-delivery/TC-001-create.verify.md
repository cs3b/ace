# TC-001 Verify — Create goals

### Goal 1 - Canonical draft create, replay, and show

- **Verdict**: PASS only if `create-canonical.json` shows exit-0 receipt
  with `idempotency: "created"`, `draft: true`, title starting `WIP:`,
  `head` equal to the canonical branch SHA, `base_repository` = base repo
  URL; `create-canonical-replay.json` shows `idempotency: "existing"`
  with the same number; `show-canonical.json` reports the same identity.

### Goal 2 - Same-server fork draft create

- **Verdict**: PASS only if `create-fork.json` shows `draft: true`,
  `head_repository` = `http://127.0.0.1:24417/e2e-fork/base`,
  `base_repository` = `http://127.0.0.1:24417/e2e-lab/base`.

### Goal 3 - Cross-host head refuses before any mutation

- **Verdict**: PASS only if `create-cross-host.exit` is nonzero,
  the error category is `unsupported_capability`, and
  `open-pulls-after-refusal.json` lists exactly two open pull requests
  (no wrong-repository write).

### Goal 4 - Draft:false with a WIP title is a conflict

- **Verdict**: PASS only if `create-draft-conflict.exit` is nonzero with
  category `conflicting_matches` or an explicit draft-disagreement
  message, and no new PR exists (open count still two in any later
  listing).
