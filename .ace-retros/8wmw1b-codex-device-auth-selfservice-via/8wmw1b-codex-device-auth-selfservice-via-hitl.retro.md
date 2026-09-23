---
id: 8wmw1b
title: codex-device-auth-selfservice-via-hitl
type: self-improvement
tags: [process-fix, codex, auth, llm, hitl]
created_at: "2026-09-23 21:20:00"
status: active
---

# codex-device-auth-selfservice-via-hitl

Date: 2026-09-23
Context: During the HITL task batch session, `ace-git-commit` message
generation failed because the Codex token had expired (401 on all retries;
google/zai fallbacks unavailable). The agent only reported "worth refreshing
codex login" and moved on. The Captain then fixed it himself via
`codex login --device-auth` (device link + one-time code). Auth is restored;
this retro captures the correct agent behavior for next time.
Author: architect agent (pi)
Type: Self-Improvement

## What Went Well

- Root cause was correctly identified (token expiry, not a code defect), and
  the fallback commit path (`--only-staged --no-split -m`) kept work moving.
- Recovery once triggered was fast: `codex login --device-auth` prints a link
  and a 15-minute one-time code; the Captain completed it in one step.

## What Could Be Improved

- The agent escalated an auth failure as a manual "please log in" note
  instead of self-remediating: the device-auth flow is fully agent-runnable.
- The one thing genuinely needing the human (opening the browser link and
  entering the one-time code) is exactly what ace-hitl `ask` exists for —
  the agent should have asked the Captain through HITL with the link + code,
  not left it as ambient advice in a summary.

## Key Learnings

- Provider auth expiry (codex 401 / `token_expired`) is a routine, automatable
  recovery — not an environmental dead end:
  1. run `codex login --device-auth`;
  2. parse the printed URL (`https://auth.openai.com/codex/device`) and the
     one-time code;
  3. `ace-hitl ask` to the Captain with link + code (kind=auth — same shape
     as the OTP answer flow planned for A5);
  4. on answer, retry the command that failed (`ace-git-commit`, ...) and
     only then report done.
- "Human-in-the-loop" means routing the specific interactive step through
  HITL — not annotating the failure for later human discovery.
- This is the first concrete template for the ace-hitl ask pattern before the
  A1–A5 pipeline lands: small, self-contained ask → answer → verify → retry.

## Action Items

### Stop doing

- Ending a turn with "worth refreshing login" style advice when the failure
  is self-remediable via a CLI flow plus a single HITL question.
- Treating provider auth errors as out-of-scope environmental issues.

### Start doing

- On codex auth errors: run `codex login --device-auth`, extract link + code,
  and deliver them via `ace-hitl ask` (future) — until ace-hitl ask ships,
  ask the Captain directly in chat with the code and wait.
- After auth is restored, re-run the failed command to confirm recovery
  before reporting completion.

## Technical Details

- Failure signature: `codex_login::auth::manager: Failed to refresh token:
  401 Unauthorized ... invalid_refresh_token / token_expired`.
- Command: `codex login --device-auth` → prints
  `https://auth.openai.com/codex/device` + one-time code (15 min TTL).

## Additional Context

- Follow-up to retro 8wmvwb (hitl-task-batch-skipped-commit-and-external-review),
  which flagged the same incident as environmental.
- Aligns with pilot task 8wm.t.vs3 (A5): OTP-as-HITL-answer — same ask /
  answer / verify loop, different payload kind.
