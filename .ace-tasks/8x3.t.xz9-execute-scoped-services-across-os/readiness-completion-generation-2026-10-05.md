# Completion generation readiness amendment

Status: draft, independent readiness review required before source protocol change.

The existing status contract requires current project visibility and purpose for every role, including executor. Late exact outcome completion remains available independently of visibility/lease/attempt terminality. An interleaved Endcap mutation can stale the executor's begin acceptance generation, so completion must not require obtaining a broad status read after revocation.

The companion contract specifies one fixed completion-only generation mode: no caller expected_generation or mode field on complete_service; existing canonical mutation owner resolves current generation and reruns all immutable completion guards on each CAS retry. All other mutations retain caller expected-generation admission. No new operation, journal, policy dialect, effect capability or grant is introduced. Strict mutation identity, canonical import atomicity, exact replay and contradiction refusal remain.

Usage and test plan cover interleaving plus absent/revoked visibility, late completion, CAS loss, hostile modes, stale ordinary mutations and unchanged original replay metadata. Source adjustment is not implemented in this amendment.

Independent root readiness review: APPROVE exact acf1190d5..b398d015e. Approval covers the bounded contract only, not implementation or installed acceptance. Every retry revalidates retained effect, not current candidate/new grant; caller generation selectors remain forbidden.
