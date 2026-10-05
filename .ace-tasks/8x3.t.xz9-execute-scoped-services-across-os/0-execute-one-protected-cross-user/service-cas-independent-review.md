# Protected service CAS checkpoint — independent review

2026-10-05. Exact frozen source: `a422f2347a40b670915bdc0663db044c00c4a292` (source checkpoint `62575ce9b`). **REJECT: two verified medium correctness findings.** This is a partial source checkpoint, not acceptance of the public receiver or xz9.0.

Independent reviewer: GPT-6.1 Sol high, unique session `endcap-a422-service-cas-round1-files`, terminal exit 0. Reviewed Endcap service admission/completion, JournalMutation, EvidenceJournal, and canonical ServiceEvidence. Root inspected findings and reproduced both.

| Feedback | Finding | Required result |
| --- | --- | --- |
| `8x45r8q6` | Existing-request replay returns `service_projection` without original `generation` and `journal_commit`. | Exact replay recovers canonical acceptance metadata needed by subsequent mutations. |
| `8x45r8q7` | Existing-request shortcut returns before canonical mutation-ID binding validation. | An ID already bound to another operation/input/assignment/attempt conflicts even when the service request itself exists. |

Validation:
- Root maintained atomic service test: **10 tests / 131 assertions, zero failures**, receipt `assign/8x45k6`.
- Independent reviewer added disposable replay probes; root read and reran through `bin/ace-test`: **12 tests / 139 assertions, two expected reproducing failures, zero errors**, receipt `assign/8x45sg`.
- The failing cases assert exact accepted metadata and reuse of an ID previously bound to the fixture operation. Both fail on the frozen source.
- Feedback items marked valid/pending. Repair delegated to the author in a separate continuation worktree; the reviewed original remains unchanged.

The initial filtered diff subject invocation failed before prompt generation and produced no verdict. The successful review used explicit file subjects and recorded exact head/tree hashes. No source has been merged based on this partial checkpoint; prior narrow codec/policy approvals retain their original scope.

Temporary reports and probes reside in `.ace-local`; this record preserves the task-owned decision and reproduction evidence. Installed receiver, real cross-UID behavior, final combined source review and package gates remain open.

## Repair round — accepted narrow checkpoint

Exact repair `c5c7f5d9b044f488cd0f67b059bd8e996c043812`, recorded at continuation `559f2bbdb`. Independent Sol6.1 delta session `endcap-c5c7-replay-round2-exact` completed exit 0 with no findings; root read the report and confirmed the empty feedback list. Root inspected the delta and independently executed the maintained replay regressions: **14 tests / 157 assertions, zero failures/errors**, receipt `assign/8x460c`. Reviewer independently executed the same suite successfully.

Every mutation now passes the canonical journal owner. Exact retry preserves original acceptance generation/commit while projecting current retained service state; new-ID reuse follows expected-generation checks and cannot create another service claim or grant invocation. `claim:created/retained` is explicitly not invocation permission. Both previous findings are resolved. The initial abbreviated parent reference failed before review generation; the accepted round used the exact commit-parent range.

**APPROVE for this replay repair only.** Public receiver/composition, proposed read-only authorization interface, final combined dependency review and installed cross-user acceptance are still open. No full package gate or installed proof is inferred from these focused tests.
