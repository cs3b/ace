# 9c2 pre-child provisioning readiness review

Exact candidate `60161e10ff8b4098b70a95776bcadfe3e7e88258`, branch `codex/scope-provisioning-spec`. Reviewed five-file delta and complete new normative amendment against accepted 9c2/09j contracts and current LaunchLifecycle abort/reservation/release/state projection. Spec-only: no code, tests, probes, delegation, promotion or status changes.

**REQUEST CHANGES** — one verified sequencing contradiction.

## Finding

**[P2] Close the parent-start/service-start ordering against the retained Wants dependency.** `provisioning-scope-lineage-amendment.md:18–20` requires committing parent scope_bound before starting the native service or creating readiness baseline. The retained normative `scope-owner-proposal.md:49–55` specifies the parent slice's fixed Wants on its service and explicitly accounts for fresh parent activation starting that child. The amendment only supersedes full-binding-before-layout ordering; it does not remove or change that activation dependency. Ordinary parent StartUnit can therefore start native service/baseline before the newly required parent commit. An author cannot satisfy both contracts as written.

Select and specify one concrete ordering: permit the parent activation's fixed child start as cleanup-only provisioning (no native/child admission or layout/release until parent binding), with lost reply handled by the stated exact-origin/held rules; or supply a reviewed manager invocation/unit mechanism that activates the parent without starting its Wants child while retaining the required metadata/GC properties. Do not claim ordinary parent start is process-free or manufacture parent binding before observing its actual incarnation. Preserve seal ordering, bounded exact units and unknown-start ownership in either repair.

## Reviewed closed decisions

Separating immutable parent/native/genuine-child events removes the circular need to assert child identity before layout. The proof payload no longer fabricates service/child identity when those stages are absent. Bound-parent whole-scope cleanup retains recursive emptiness, seal/no-activation and boundary checks; unknown/unbound parent origin cannot be repaired by same-name adoption or inactivity. Native/child provenance remains mandatory before release.

The guarded abort kind is a selector into canonical positive parent proof, not a caller populated boolean. It expressly checks absence of release_launch/possibly-executed history and independently settled service/inbox evidence. It extends the existing abort owner with narrowly guarded reserved-to-failed admission rather than inventing process_start, globally widening the state machine or duplicating consumer finish. Release-before-reuse is owned and included, including crash after failed transition before release. Exact roles, ticket, CAS, historical replay, errors and no stop/release repeat are specified. No other verified readiness issue in this bounded amendment.

This verdict does not approve implementation, installed proof or whole 9c2 delivery. The prior full-binding reader correction remains pending a closed final amendment/source freeze.
