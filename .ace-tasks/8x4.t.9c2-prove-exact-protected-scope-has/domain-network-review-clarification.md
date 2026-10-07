# Domain network implementation review clarification

Root reread the accepted `network-installation-evidence-amendment.md`, especially its domain procedures, against the evolving lab-config:gad.b topology candidate on 2026-10-07. The original requirement remains unchanged: independently controlled attempted ingress, successful sender/setup evidence, matched enforcement observations, exhaustive effective-policy comparison, and actual allowed egress/DNS responses. A timeout alone is never denial evidence.

The domain candidate introduced an additional requirement for remote responder-side absence and then a new mTLS observation service. Neither is required by the accepted ACE contract. Do not create or deploy that extra service merely to satisfy this added design assumption. Ground the concrete sender and packet/enforcement correlation in the existing selected producer and test harness; independent installed verification remains gad.2. Any actual inability to collect the required evidence must remain incomplete/refused, never a fabricated passing summary.

Two concrete implementation review constraints remain:

- A per-slot nftables accept verdict does not establish the final outcome across all base chains. Scope each rule to its slot and inspect the relevant effective hook graph without rewriting unrelated policy. See the [official chain documentation](https://wiki.nftables.org/wiki-nftables/index.php/Configuring_chains).
- IPv6 neighbour discovery cannot be restricted to link-local source addresses alone. The selected interface's assigned unicast address is also valid; fixtures must cover this and duplicate-address detection while maintaining exact interface/address isolation. See [RFC 4861, sections 4.3, 4.4 and 7.2.2](https://www.rfc-editor.org/rfc/rfc4861).

This clarification is not topology readiness approval, source completion or an installed test result. The domain author is correcting the candidate and must preserve support for the intended Codex/Pi credential modes rather than close the task with only a static-key subset.
