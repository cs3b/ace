# Local inbox source checkpoints — 2026-10-05

- [x] 0b53a8d0a: exact two-part bounded receipt/signature transfer framing;
  independent review and 16 tests / 94 assertions passed. Integrated in 5f78b0d49.
- [x] 8fbd090a7: corrected fixed-context contract independently approved. Native
  identity comes from the original canonical attempt stage. Retained consumed
  signed proof can settle after native shutdown without an endpoint request.
- [x] 802324209: static Deployment context and installed artifact/ACL validation;
  independent 9 / 43 and related 16 / 80 passed. No global configuration fallback.
- [x] b9ae6a1b3: protected Herdr inbox factory and bounded explicit environment;
  independent 13 / 66, existing queue 11 / 39 and environment 2 / 8 passed.
  Integrated in 37c486928. Root `bin/ace-test ace-herdr all` passed 476 / 1628,
  execution 6d043e18-2286-461a-b10d-90fe71889def.
- [ ] Canonical reconcile_inbox handler, imported-proof readers, crash repair and
  exact replay for already registered events.
- [ ] Seal-aware bind, recovery, finish and complete startup composition after
  the real scope owner interfaces are integrated and verified.
- [ ] Installed distinct-account/native acceptance after publication.

Independent reports and immutable receipts are retained beside this document.
Combined source verification is recorded in the 9c2 task's
staged-lineage-verification.md: complete Assign verification for lineage/framing,
focused verification of later Deployment changes, full Herdr, and the exact
37c486928 monorepo fast suite (11234 passed, 24 skipped, zero failures/errors).
The explicit 300-second author feature timeout is retained under
evidence/inbox-transfer-framing/initial-300s-timeout and was not treated as a pass.

These are bounded source checkpoints. Full services startup remains refused;
constructing a factory is not canonical proof admission. Status remains
in-progress. No gem publication or Lab operation was performed.
