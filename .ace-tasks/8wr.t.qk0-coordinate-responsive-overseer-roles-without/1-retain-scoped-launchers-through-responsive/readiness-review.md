# Readiness review — 2026-10-07

Reviewed against ACE `ae45519d0`. Decision: **remain draft, needs_review=true**. This review does not block independently approved qk0.0.

The child preserves the intended source outcome: real foreground launcher ownership, responsive role coordination, canonical prompt/stop, bounded proposal resolution, and removal of LabClient. The pinned inventory generation resolves the parent/child kernel-birth distinction without widening private control permissions. Physical protected workspace cleanup is explicitly owned by qk0.2.

Two public consumer contracts still need concrete specification before implementation:

1. **Mode and target selection.** Define which public input selects protected versus ordinary local execution, the default backend in each mode, and the behavior when project/agent/attempt selection is omitted or ambiguous. Current `ace-overseer/cli/commands/work_on.rb` defaults to tmux and only has the old lab branch; current prompt/stop accept a Work ID. The new usage supplies an assignment alone, while the reviewed inventory deliberately allows multiple attempts and mapping associations. An implementer must not silently choose the newest attempt, an arbitrary mapping, or local execution after protected resolution fails. Add usage for explicit disambiguation and missing/ambiguous selection.

2. **Public operation identity and reconciliation.** Define how the caller obtains and retains the exact prompt/stop operation identity before any write, how it is supplied for an explicit retry/status lookup after CLI loss, and how changed input is refused. The existing Assign `launch_steering.rb` requires exact mapping/assignment/attempt and mutation identity; `prompt_status` is keyed by the original mutation. Its immutable owner records do not by themselves tell a fresh overseer CLI invocation which operation the caller means. Choose a concrete caller-visible token/input contract using these existing records, without a second authority ledger or implicit prompt resend. Include lost-reply/restart and changed-input scenarios in usage and SC2.

These are consumer specification gaps, not missing xz9.2 producer behavior and not installed-only gad.2 checks. Resolve them through the existing CLI conventions and current owners; independent review of the amended exact contract is required before promotion. No native, installed or runtime tests were performed for this documentation review.
