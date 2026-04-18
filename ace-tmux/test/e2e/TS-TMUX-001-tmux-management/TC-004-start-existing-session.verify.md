# Goal 4 — Existing Session Start Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. A run-scoped target session name is explicitly recoverable from one of:
   - `results/tc/04/session-name.txt`, or
   - `results/tc/02/session-name.txt`, or
   - the shared session name visible across `initial-start.stdout`,
     `reuse-start.stdout`, and `force-start.stdout`.
2. Evidence shows one explicit branch:
   - `existing-session-skip.md` with explicit reason (`no preset`,
     `tmux unavailable`, or comparable environment limitation), or
   - command artifacts for `initial-start`, `reuse-start`, and `force-start`.
3. In execution branch, all three command artifact sets reference the same
   recovered run-scoped session name to prove lifecycle continuity.
4. In execution branch, all three `.exit` files are present. Distinct wording is
   not required; reuse vs force may legitimately share the same public success
   message as long as the session continuity and successful lifecycle attempts are
   visible.
5. If any attempted start command exits non-zero, `existing-session-failure.md`
   exists and cites the related artifacts.

## Verdict

- **PASS**: Existing-session lifecycle behavior is explicitly evidenced through
  command artifacts or explicit constrained-execution evidence.
- **FAIL**: Missing lifecycle branch artifacts or missing run-scoped continuity
  evidence.
