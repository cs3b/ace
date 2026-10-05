# Remaining-consumer readiness review — round two

Exact candidate: `baa96cbe51b808085d0a5545fee9a2766f3ba53a`, clean `codex-endcap-remaining-specs` author worktree. Independently reread the complete delta from `764df1e61d46338087b78d36381341a8f8aa8f47` and checked it against the existing JournalMutation generation owner and surrounding consumer contracts. Round-one REQUEST CHANGES remains preserved in `xz9-remaining-consumer-readiness.md`.

## xz9.0: APPROVE readiness; promotion eligible YES

The sole verified round-one blocker is resolved. `remaining-consumer-contract.md:38–44` now specifies the exact attempt-local authority_generation derived from filtered canonical events and supplied by status, retaining the existing owner and counter. It also distinguishes public mutation generation from the inbox descriptor's verified claim generation. Usage, stop contract and test map repeat the same distinction, including sibling mutations not advancing this attempt's counter. No new verified issue was introduced by the repair.

The previously reviewed closed decisions remain intact: fixed deployment inbox contexts; authenticated transport roles distinct from signer purpose; exact two-part signed proof framing; immutable canonical receipt/signature provenance; supported Herdr-before-qjl replay repair with changed-claim/native refusal; exact-attempt recovery; finish admission bound to accepted 9c2 positive original-scope proof; terminal CAS before release; and preserved full-service startup and installed acceptance gates.

Promotion eligibility is a specification readiness verdict. Unfinished 09j and unimplemented 9c2 remain implementation dependencies, and source/installed Linux/macOS/Lab acceptance remains required before delivery. Their unmet implementation status does not reopen the now-closed xz9.0 behavioral decisions.

## xz9.2: remain DRAFT; promotion eligible NO

The precise open question remains: which native prompt operation and exact parameter/acknowledgment contract proves admission to the intended live original worker, and how is the desired bounded text transported without exceeding the Authority's 16 KiB control-header bound? A fixed bounded body or an explicitly smaller exact text bound must be selected together with canonical driver observation and replay semantics. Desired usage currently makes no implementation-readiness claim. The closed stop/scope portion does not close this native prompt question.

No tests, native/VM/privilege probes, source edits, task status changes or promotion were performed. This is independent spec readiness review only.
