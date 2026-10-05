# Protected Endcap implementation checkpoints

This is partial source implementation evidence, not full child acceptance.
The public Lab composition, actual receiver execution, business result/finish,
recovery/inbox consumers and installed distinct-UID/native proof remain open.
No successful native origin is synthesized by the mechanism fixtures.

## Accepted dependency integration

Accepted main `4f869451fd9f8e90ec2d6c927dfecc94916a1a64` includes qjz and
the test-runner execution-verdict repair. The final integration ancestry is
`a42badb5f399272225175da35f4cd122b878f8ca`, with parents
`b7fdfda965a6755689062b6f02b0a9e52af8d13b` and that exact main revision.
`git merge-base --is-ancestor 4f869451f HEAD` succeeded.

The scoped ACE commit helper split the initially resolved merge into commits
and removed its merge metadata. All accepted auto-merged source and task paths
were retained in scoped commits, then the already-applied main ancestry was
recorded. A clean-tree comparison to the exact accepted main showed only the
known Endcap and provisional 09j source/test paths and the Endcap task amendments;
there was no remaining delta in the accepted qjz, HITL, Overseer or runner files.
Future active merges will be completed with native Git after scoped conflict
resolution rather than using that helper during an active merge.

The substantive source conflict was EvidenceJournal#update_service_request:
the shared prepare_service_update owner was retained instead of duplicating
the old inline writer. It keeps initial proposal_authorize! inside each lock/CAS
retry, authorization uniqueness, exact expected-record checks, terminal receipt
verification and byte-preserving record staging. Main's ProposalJournal require
and include were retained. Final independent review must cover this combined
journal/ProposalJournal boundary, not only the isolated Endcap delta.

09j source imports remain explicitly provisional until its repaired accepted
candidate is adopted and verified. No source or installed acceptance is inferred
from that development dependency.

## Tested source slices

- `66071e716`: Lab policy snapshots freeze validated input, canonical binding and
  operation values. Adapter/grant checks: 20 tests, 73 assertions, PASS `8x44v7`.
- `f9ddecb5d`: retained approval revalidates canonical imported bytes, candidate
  and independent reviewer. Real Git checks: 3/33 PASS `8x4518`.
- `24b1d4e17`: fixed receiver claim and one-time begin planning. Removing replay
  permission sanitization produced 1 failure in 7/67 (`8x457f`); repair passed
  7/68 (`8x457x`). A cached permission is returned as already_started.
- `c6426359e`: atomic executor completion and original-body validation before
  replay lookup. Affected exact files: 17/121 PASS `8x45br`.
- Lower-CAS ephemeral original input context: at most one matching request/update,
  1..64 KiB, immutable copied bytes, never persisted. Direct protected fresh
  writes without that context refuse. Exact mechanism checks: 19/169 PASS
  `8x45gr`; subsequent completion-revocation/replay checks: 10/131 PASS `8x45i2`.

An accidental broad feat run `44115` was interrupted with owned SIGINT at the
captain's request, exit 130. It is not acceptance evidence. Subsequent runs name
the exact absolute test files. No broad restart or timeout change was made.

## Retained service invariants and open gates

Original structured input is validated before replay lookup and recomputed by
the same Lab owner at every fresh claim/begin CAS boundary. Only digest/target
and immutable canonical claim fields persist. Fixed executor UID, native worker
birth/ticket/reservation, current candidate, imported review and current policy
are required for new effects. Repeated begin never returns invocation permission.

Completion verifies exact recorded executor and claim, receipt and artifact
identity. It imports evidence, record transition and reply atomically. Changed
completion content conflicts; a succeeded completion requires dispatch_started.
Worker visibility revocation or expired invocation lease does not discard
executor-attributed outcome truth. Completion grants no fresh effect permission.

Generic post-dispatch no-effect settlement remains uncertain unless a fixed
domain reconciliation owner proves exact target/effect absence and no surviving
handler writer using a fresh bound challenge. A timestamp or Boolean is not
proof. The authority has no native ACL and must not issue direct native queries;
protected prompt/stop belongs to the separately drafted xz9.2 contract.

## Service replay independent review repair

Original checkpoint `a422f2347` remains frozen in its original worktree. Independent
review rejected two medium defects: exact request replay lost its accepted
generation/commit, and an existing-record shortcut bypassed canonical mutation-ID
conflict validation. The independent PoCs were ported unchanged in expectation
to `endcap_service_replay_test.rb`. They failed before repair: 12/139, two failures,
no errors, `8x45uc`. The initial repair passed the same 12/139 (`8x45w4`).

Every supplied mutation now passes JournalMutation#mutate. An identical existing
request has no service update/effect in its plan. An exact retry retains original
mutation acceptance metadata beside sanitized current service truth; a new ID
obeys the current expected-generation gate and has its own acceptance metadata.
Typed created/retained claim results never authorize invocation. Additional real
Git checks cover new-ID generation refusal/no second claim and a later canonical
failure followed by original claim replay: 14/157 PASS `8x45x8`.

Continuation is isolated in `codex/wave5-protected-endcap-continuation`. The new
Lab AuthorityComposition uses the same server/router/origin/journals and policy
owner; a required-operation completeness check refuses before construction when
any full-service operation is missing. Its negative startup unit checks passed
2/5 (`8x45od`). It is not an installed listener/product acceptance claim.
