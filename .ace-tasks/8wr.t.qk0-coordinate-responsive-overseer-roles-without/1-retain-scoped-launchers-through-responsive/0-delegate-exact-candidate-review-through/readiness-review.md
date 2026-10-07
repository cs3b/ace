# Independent readiness review — 2026-10-07

Verdict: needs changes. Keep qk0.1.0 draft with needs_review true; parent qk0.1 is not ready for promotion. This review covers the draft introduced by da257edd5 against source integrated at 0f3c2fce2. No implementation or installed acceptance is claimed.

The decomposition correctly gives actual original-launcher review delegation a real child task. Independent reviewer credentials, immutable candidate export, maintained ReviewManager, canonical receipts, immutable first replies and exact original launcher identity are appropriate existing owners. One fresh protected tab with one pane is a valid concrete layout within the four-pane limit; no packing scheduler is needed.

## Required contract repairs

- [ ] Define the exact expected_generation passed by the original Driver to assign_review after request_review has itself advanced the journal. Endcap dispatch passes this field into JournalMutation (endcap.rb:119). Pinning the candidate alone does not resolve a concurrent attempt-generation advance. Specify the refusal/recovery behavior without implicitly refreshing a caller's mutation inputs.
- [ ] Define canonical recovery of a pending delegation after the requesting reviewer dies. The draft both refuses another pending delegation and permits a new explicit request after death. Name the evidence, owner and atomic transition that release or supersede that reservation; time passing or a new caller alone cannot replace a live assignment. Preserve the previous request and immutable response.
- [ ] Apply the same reservation rule to every assign_review path. Current endcap.rb:132-145 accepts an authenticated original launcher and generates a new review_id; assigned_review selects the latest assignment event. Guarding only request_review leaves direct assign_review able to replace the delegated purpose. Specify one canonical CAS owner and explicit supersession rules, without another ledger.

These are technical contract gaps for autonomous repair and another independent review, not unanswered Captain policy questions. Required verification includes request-to-assignment generation races, dead versus live reviewer replacement, direct versus delegated assignment races, and retry after each canonical transition. Existing SC2 and SC3 own these scenarios.

## Readiness result

The child has a distinct observable outcome, consumers, interface proposal, bounded transfers, success criteria and usage scenarios. Decision completeness, recovery semantics and concurrency coverage do not yet pass. Reviewed children: 1; promoted: 0. Parent promotion deferred. Existing cleanup implementation and prepared-input work can continue independently.
