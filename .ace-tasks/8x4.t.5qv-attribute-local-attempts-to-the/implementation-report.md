# Kernel account identity repair

The local Assign resolver now resolves the effective UID's OS account, requires equal real/effective UIDs, and verifies credentials remain unchanged before and after native binding resolution. Missing, empty, wrong-UID or failed account lookup refuses with the existing UnauthorizedIdentity classification. Service identity parsing and canonical historical ownership are unchanged.

Independent root readiness approved draft1aa514050, promoted by a4dcc79eb. Implementation follows that decision-complete contract and the test responsibility map. Task plan generation first used the default gpt-6-sol unexpectedly and was stopped (owned process exit130); the explicit codex:gpt-6.1-sol retry reached its120s deadline without a plan. No generated plan is claimed; the approved scope and test-plan.md provide the bounded JIT checklist.

## Executed receipts

| Stage | Receipt | Result |
| --- | --- | --- |
| Original focused baseline | Assign8x45za | 7 tests/25 assertions, pass |
| Resolver fail-before | Assign8x4609 | 11/23, 5 failures/1 error |
| Real Unix peer/canonical owner fail-before | HITL8x461n | 1/4, one failure: peermc vs foreign terminal login |
| Canonical refusal fail-before | Assign8x462k | 53/240, one failure: invalid credentials admitted |
| Repaired resolver final | Assign8x463p | 12/37, pass |
| Repaired real Unix peer/owner | HITL8x4633 | 1/7, pass |
| Repaired canonical refusal/coordinator | Assign8x464m | 53/244, pass |

The real Unix scenario uses actual socket peer authentication, current OS account, Git evidence journal, coordinator and existing HITL AssignmentBinding exclusion. It verifies account agreement, permits the authenticated recorded owner, refuses the foreign requester and preserves ownership. It does not claim native reverse-address or a complete installed service scenario.

An accidentally broad baseline fast run was interrupted by its owner with exit130 when its selection was recognized. It is incomplete, not a passing gate. An initial explicit feature-file invocation lacked a test_helper search path (HITL8x461f, zero tests); the maintained regression uses require_relative and its genuine fail-before/after receipts above. A method-name --filter attempt selected no files and is not evidence. Subsequent targeted commands use absolute file paths.

Independent source review approved b73a64b40 with zero findings; see source-review.md for its exact scope and independently executed checks. Full Assign and affected-package verification remain pending incoming accepted main and the parent's heavy-slot handoff. The installed qjz SC3 run8x45o5 remains failed; its fixture is isolated in /tmp/ace-qjz-installed-sc3. Rebuild exact integrated gems and rerun that separate acceptance after this repair is integrated. No task completion, native launch, multiUID, or live Telegram acceptance is claimed here.
