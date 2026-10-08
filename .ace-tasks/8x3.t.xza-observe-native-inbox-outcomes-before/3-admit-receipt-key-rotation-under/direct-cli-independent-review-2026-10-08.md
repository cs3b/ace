# Direct Inbox adoption: independent integration review

Reviewed source: `ba47eb2add54b9ed3a02072bf24aff3c67c59170`.
Executed review session `review-8x71j2` completed successfully. The coordinating
reviewer independently checked the actionable error path against source.
Verdict: **changes required**, not whole-family acceptance.

- [ ] Normalize selector-child `Timeout::Error` before downstream dispatch.
  `BoundedProcess` raises it at its deadline; `ProtectedInboxSelection` does not
  classify it. Preserve downstream exceptions after dispatch. Feedback
  `8x71u09h` is verified pending; require a regression proving typed refusal.
- [ ] Add Assign and Herdr changelog entries for the public additions.
  Feedback `8x71u09i` is verified pending.
- [ ] Review the repair and execute the relevant controlled integration tests.
- [ ] Complete actual selected-child subprocess and maintained Lab producer
  composition; current injected child dispatch is not evidence for this join.
- [ ] Complete protected canonical reconciliation and exact replay.
- [ ] Prove unknown direct admission recovery and explicit signed-supersession
  retry, with exact original claim binding rather than any later generation.
- [ ] Supply the maintained context-service producer and exact containment proof
  for recovery after a crash before durable issuer return. An absent process,
  elapsed timeout or unrelated worker cleanup proof is insufficient.

The returned-issuer recovery amendment was independently reviewed separately:
actual claim and owner must be persisted before native submission, and confirmed
settlement must match that exact invocation. Its readiness approval is not an
implementation verdict. Pre-return crash recovery remains mandatory source work.

The review also reported low-priority defensive key normalization, a duplicated
blank line and help wording. These do not replace the source acceptance gates
above. The full local report is
`.ace-local/review/sessions/review-8x71j2/review-report-review-default.md`.
No installed Lab, process-containment or publication readiness is claimed.
