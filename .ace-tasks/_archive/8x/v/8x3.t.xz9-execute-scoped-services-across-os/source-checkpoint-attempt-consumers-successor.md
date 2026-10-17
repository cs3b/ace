# Attempt consumer historical-proof successor

This corrects the independent review finding in checkpoint 938fe2344. Fresh
succeeded finish required approved_review!, but historical terminal selection
previously authenticated result/scope/settlement without the actual independent
canonical acceptance. Receipt metadata alone is insufficient.

The existing approved_review! owner now accepts an internally pinned commit.
Fresh finish supplies its CAS prefix; historical finish calls the same owner via
finished_review_evidence! at the original terminal introduction prefix, using the
original mapping and authenticated finish candidate selectors. Canonical receipt
artifact reads stay at that prefix. Other existing current calls retain their
current-ref default. No new acceptance ledger, proof boolean or wire field.

## Executed controlled checks

- Actual failed finish, real canonical reservation release, public pure released
  recovery and unchanged exact historical finish replay: PASS 1/32, 50.64s,
  `fce772b8-3fbf-4dfc-b6b4-d196451f0e53` (test source line203 when selected).
- Actual succeeded finish with independent imported/accepted review, original
  replay and a structurally valid lower-journal forged finish on the authentic
  pre-review-acceptance canonical prefix: PASS 1/16, 37.2s,
  `f06ebab2-2de1-4d0c-bd09-8cef2ecd0675` (line267). The same genuine normalized
  succeeded result receipt cannot authorize terminality without canonical
  independent acceptance; the maintained historical owner rejects it.
- Prior complete five-case run after proof fix: 4/5 passed, aggregate5/72,
  `9fde1c3b-838f-430c-940a-23ad0bf59b4f`; only released fixture boot artifact
  prerequisite failed. Other running/dead/bind paths passed in that run.

Retained failed release evidence: `0dcc03b4` public sanitized refusal;
`06d048ba` diagnosed actual historical boot ENOENT at synthetic fixture ref;
`9a04eb76` and `9fde1c3b` refused synthetic installer ref through /etc's symlink.
The fixture now retains actual boot and original installer bytes/SHA before
reservation, using the maintained ArtifactSet/ExecutionBootBaseline and injected
OS protection only. Production historical proof was never weakened or stubbed.
Final production source stayed unchanged during both final selected checks.

## Remaining source and evidence obligations

Public Authority::Client/Server handlers are delivered by this checkpoint, but
public CLI/role/workflow adoption remains actual SOURCE work: attempt/base still
constructs local coordinator, finish consumes local receipt and reconcile uses
local cache; inbox-reconcile also remains local. The reviewed CLI-adoption
candidate must be independently approved and implemented using the one existing
ProtectedAssignmentContext owner, never a fallback or a duplicated classifier.
See protected-attempt-cli-adoption-candidate.md. Actual pending service/Inbox
public recovery classification and fresh sealed bind refusal still need composed
coverage. No installed/native/root/systemd test or whole-family closure claim.
Independent source verdict remains required before integration.

## Main integration

Independent reviewer `/root/audit_runtime_delivery_status` approved frozen `938fe2344` plus repair `8243e70ae`; exact-prefix independent-review finding resolved. Integrated as `64cda42e9` and `623aa67e4`; main Server event-read wrapper retained with new bodyless operation list. On unchanged `623aa67e4`, the actual five-case consumer file plus ReceiptVerifier and event-read-operation files passed **30 tests / 205 assertions**, seed19121,151.64833s, zero skips: `assign/0d0ba03b-e6b1-4e9c-9d71-171fb9c35818`. This remains controlled source evidence; CLI/role adoption, pending service/Inbox and sealed-binding gates remain open.
