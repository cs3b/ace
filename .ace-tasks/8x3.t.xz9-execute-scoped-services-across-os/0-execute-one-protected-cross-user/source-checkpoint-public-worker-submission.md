# Public original worker submission checkpoint

This candidate implements registered submit-candidate, submit-result and protected
inbox-reconcile commands through the existing authority clients. Input reads are
bounded regular-file reads; result receipt identity, supported fields and ordered
artifact bytes are checked before transfer. Canonical acceptance remains owned by
Endcap. Exact retries retain original arguments, generation and bytes.

The maintained worker instructions distinguish CURRENT_CANDIDATE (status counter,
zero when null) from the returned REVIEWED_CANDIDATE used by review/result. Each
distinct operation selects authority generation; exact retries never refresh it.

Executed controlled evidence:

* 435cbf05-321d-4957-aec7-69a88bf7b18e: 1 test / 60 assertions, 42.99s.
  Actual managed preparation, registration, released original worker, PreparedQueue
  and Executor; public candidate CLI; registered Overseer review and ProtectedReview;
  original Driver control channel; actual independent canonical review acceptance;
  original worker public status and model receipt submission with immutable replay.
  Provider/OS facts are injected; this is not native or installed evidence.
* eb9b59e7-e649-437f-812b-59ab038cc567: 4 tests / 172 assertions, 184.325s.
  Actual public candidate counters/refusals, succeeded/failed result and finish,
  signed Inbox reconciliation and recovery. Its worker review used direct canonical
  review; the later 435cbf05 case supplies the maintained requester composition.
* 37aa43c1-70a6-4898-9dc0-e2061178be44: 1 test / 14 assertions.
  Registered parser preserves repeated ordered artifact flags; malformed identity,
  unsupported receipt fields, changed artifact, duplicate JSON and symlink refuse.

Retained failures: c1a347b4 masked fixture CLI error with socket teardown IOError;
0c0033a5 identified nonexistent Overseer CLI.start (fixed to maintained Runner);
d9a2a865 incorrectly required empty stderr despite actual synthesis diagnostics.
Earlier dc269545 and bdfb4155 established the separately reviewed candidate replay
repair, now integrated by root. No deadlines were increased.

Independent source review and integrated verification are pending for this producer
candidate. Protected prepared delivery adoption, physical cleanup, installed/native
verification and whole-family closure are not claimed by this checkpoint.

Review correction: the changed-artifact negative now supplies both declared parts,
so it reaches the exact typed hash/declaration refusal rather than a count mismatch.
Client calls remain unchanged. Executed 9bb11e3d-9c99-4675-bb7f-465a141097b1:
1 test / 16 assertions, 20.1ms. This supersedes the hash-specific claim of 37aa43c1.

### Formal-review corrections

The successor registers both submission commands in public help, derives the local receipt vocabulary from the same ExecutionReceipt model as Endcap, corrects top-level usage prefixes, and tests malformed Inbox registration/receipt/signature inputs before any send or local coordinator construction. Model-known campaign serialization does not grant campaign authority: the maintained public wire test observes the unchanged Endcap campaign refusal before the first accepted result and proves the canonical ref unchanged.

Executed source-only checks: registered fast submission/Inbox cases **3/43 PASS**, report `ea50034a-9ade-40dd-bbb2-b8a30912867e`; actual public succeeded finish/campaign-owner refusal **1/60 PASS in 24.05s**, report `e4b48738-f539-470b-a6cd-bf3cd9c02419`. Retained failures: `37b6ceae` placed the campaign negative after accepted result and incorrectly expected an internal reason through the sanitized wire; `aae6cd39` expected an authority exception for an empty argument rejected earlier by the public parser. Corrections preserve production error disclosure and canonical ownership. Delivery-child composition remains a separate open gate.
