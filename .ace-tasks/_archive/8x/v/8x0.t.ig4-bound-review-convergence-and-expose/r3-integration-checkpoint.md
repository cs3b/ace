# R3 integration checkpoint — 2026-10-08

Base: `c910f13318006e2bf4f98fbae0370e2e55b981ca`. Isolated worktree:
`/tmp/ace-finish-r3`, branch `codex/finish-r3-campaign`.

CampaignManager/Store now persist finite initial bounds and authorized phases;
record/collect/assignment admission cannot exceed the completed-round budget.
CampaignPolicy supplies the same search, recurrence and retry decisions to status
and finish. Required Medium findings block acceptance independently of convergence.
Severity corrections and evidenced repair attempts are append-only audit events;
canonical findings retain independent sources. LlmExecutor reserves calls durably
before transmission and disables hidden fallback; the single and multi-model
review entrypoints supply campaign binding. Each selection permits at most initial
plus two transient retries; running/uncertain original calls cannot be retried.

Result identity includes profile, bounds, phases and execution history. R2 compact
snapshots include exact retained phase/execution prefixes. Current acceptance and
historical retained verification use the existing manager. ReceiptVerifier's local
fallback now delegates compact/full validation to the same manager; the protected
Endcap callback already delegates through that owner.

## Executed deterministic evidence

- `bin/ace-test ace-review fast`: 989 tests, 3219 assertions, zero failures/errors;
  report `.ace-local/test/reports/review/52a77318-e98e-44cb-a8d6-333732adb11d/`.
- `bin/ace-test ace-review feat ace-review/test/feat/campaign_phase_cli_test.rb`:
  1 test, 26 assertions; report
  `.ace-local/test/reports/review/af6f39c3-63da-4ecb-8f94-bf6741f57977/`.
- `bin/ace-test ace-assign fast` with receipt verifier, campaign execution,
  round transfer and execution evidence files: 34 tests, 163 assertions;
  report `.ace-local/test/reports/assign/3bc38af3-4ed5-4065-bd86-b5198baa3aee/`.
- ReceiptVerifier after its added compact-snapshot delegation case: 21 tests,
  95 assertions; report
  `.ace-local/test/reports/assign/005faec6-5814-411d-a790-b2c61d34278f/`.

SC1: `CampaignConvergenceTest#test_discovery_exports_known_defects_but_cannot_be_accepted_or_reset`.
SC2: existing manager history/High repair/current-approval cases, including the
previous silent sixth-round test now requiring explicit additional-phase authority.
SC3: `test_medium_converges_but_blocks_acceptance_and_exhausted_phase_requires_authorized_resume`.
SC4: verified correction and evidenced recurrence cases in CampaignConvergenceTest,
plus original canonical/history cases.
SC5: actual executor entrypoint test observes the durable running reservation before
its deterministic provider stub and proves the fourth retry never reaches it.
SC6: real Git/public subprocess phase flow exercises failure status, finish refusal,
nonmutating dry-run, explicit phase authorization, replay and fresh-process restart;
command tests cover public assess refusal and policy identity; compact snapshot
cases exercise current/historical owner verification and corrupted-prefix refusal.

## Remaining source/verification boundaries

No task-done, independent-review, publish, main-merge or live-provider readiness claim.
The combined root independent review remains required. The full `ace-review all`,
`ace-assign all` and monorepo suite were not run in this slice; no giant fixture was
repeated. R2's large canonical result-flow performance remains open after its prior
30-second timeout and root-owned operation-local inventory fix. These small tests
do not establish that protected end-to-end runtime flow at the final combined source.

A persisted uncertain original execution remains stopped; no new public operation
claims to manufacture its terminal authority. Provider retry tests use deterministic
stubs, and no live model/root/native/Lab probe was performed. The commit-workflow
bundle internally displayed ambient forge PR metadata; no explicit forge probe or
remote mutation was issued by this slice.
