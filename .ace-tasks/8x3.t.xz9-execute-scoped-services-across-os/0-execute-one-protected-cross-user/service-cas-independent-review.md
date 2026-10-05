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
