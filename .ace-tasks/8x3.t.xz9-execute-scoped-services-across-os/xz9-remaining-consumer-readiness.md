# Independent remaining-consumer readiness review

Candidate: `764df1e61d46338087b78d36381341a8f8aa8f47`, clean author worktree `codex-endcap-remaining-specs`. Reviewed the eight changed spec/usage/test-map files against accepted 9c2, delivered xz9.3, and current JournalMutation, AttemptCoordinator/AttemptReconciler, Authority transport, CanonicalEvidence and Herdr Inbox owners. Spec-only review; no implementation, test execution, native probes, promotion or installed acceptance.

## xz9.0 verdict: REQUEST CHANGES

- **[P2] Preserve the attempt-local CAS generation.** `remaining-consumer-contract.md:38–39` says expected_generation compares canonical assignment generation. The existing owner explicitly selects events for the requested attempt before calculating authority_generation (`ace-assign/lib/ace/assign/molecules/journal_mutation.rb:51–54`); status exposes that same attempt-local value for the next expected_generation. With multiple attempts in one assignment, an assignment count differs and would either reject a legitimate status-derived mutation or introduce a new generation owner contrary to this amendment. Specify the selected attempt's canonical JournalMutation.authority_generation, including the returned generation, without changing the existing owner.

The remaining reviewed decisions are complete: fixed deployment-selected contexts and exact registration; worker-only live binding ordered with sealing; supervisor/launcher transport identity distinguished from signer descriptor purpose; exactly two bounded signed receipt/signature parts; original Herdr proof semantics; canonical private imports and retained provenance; exact-attempt recovery without assignment-wide resume; and finish's positive original-scope proof with terminal CAS preceding release-before-reuse. Full-service startup and installed OS dependency gates remain closed.

Herdr-before-qjl repair is supported by current `Inbox.reconcile`: completed/queued identical retained receipts are replay candidates, expected registration and claim/native binding/signature are checked again, and no transition occurs on verified replay (`ace-herdr/lib/ace/herdr/organisms/inbox.rb:241–320`). Superseded replacement targets are freshly verified. A later claim or changed native target can refuse; the candidate explicitly requires this fail-closed behavior rather than promising unconditional crash repair. Lock order matches current coordinator assignment exclusion then Herdr event lock.

Recovery deliberately records observation and at most a legal running-to-uncertain transition. It cannot manufacture terminality; normal finish and the separately gated stop contract own terminal admissions. No additional recovery terminal path is required by the reviewed scope.

## xz9.2 verdict: remain DRAFT

The amendment honestly retains unresolved native prompt acknowledgment and bounded framing as a high-priority readiness gate. Desired prompt usage does not assert implementation or acceptance. Its stop contract binds the accepted 9c2 scope owner and original reply replay without loosening dependencies. Do not promote xz9.2 until the native prompt contract is closed and independently reviewed.

Readiness approval would establish a specification decision only. It would not deliver 9c2/09j implementation, installed Linux/macOS proof, or real Lab acceptance.
