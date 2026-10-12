---
id: 8xa.t.nh0
status: draft
priority: high
created_at: "2026-10-12 00:30:00"
estimate:
dependencies: [8x9.t.xz9]
tags: [ace-hitl, ace-hitl-hermes, gad8, transport]
needs_review: true
---

# ace-hitl/ace-hitl-hermes: shared-Hermes multi-project transport delivery (G-A/G-B/G-D)

## Behavioral Specification

Deliver the smallest ace-hitl + ace-hitl-hermes changes enabling the
Captain-approved shared-Hermes topology (answer h1a12b713f57-2eea27): ALL
communication through ONE Hermes bot; each project its own Telegram group,
bidirectional; migration away from Python. The tracked normative topology is below.
The host audit and `.ace-local/evidence/gad8-hitl/shared-transport-topology-contract.md`
are provenance only, not durable authority (corrected per one-Hermes; G-C dropped).

## Durable normative topology contract — draft, needs review

1. Exactly one Hermes bot polls Telegram. Every served project has a distinct
   registered group/channel, while one transport process may route all channels.
   The gateway Telegram consumer stays disabled for that bot; there is no second
   poller, token-sharing exception or project-global default route.
2. Each repository/authority has its own lifecycle service instance, private store
   root, socket/endpoint and dedicated narrow-access group. The lifecycle root is
   not a shared directory containing legacy Lab control sockets. A project's group
   grants access only to its lifecycle endpoint; it does not grant another project,
   legacy labd, host administration or arbitrary filesystem access.
3. Each channel registry entry selects its exact project set, lifecycle endpoint
   and service-identity credential reference. The global `hitl_socket` is only an
   explicit default for channels in the same admitted authority; it never collapses
   distinct project authorities. Requests, replies, pending messages and
   instructions retain channel/project/correlation binding in both directions.
4. Within one runtime, an authority-side Unix connection uses the existing verified
   kernel peer credentials. Across the host/Incus boundary, Unix peer UID/GID does
   not establish remote identity. The crossing connection must terminate at the
   authority-side lifecycle service and authenticate a deployment-selected,
   project-scoped service credential on that connection; the Hermes channel maps to
   only its configured endpoint and credential reference. The service validates the
   authenticated connection identity against the selected project before reading or
   mutating lifecycle state. A configured UID, request field or simulated boundary
   is not identity proof. No cross-VM HTTP route is currently available or implied.
5. Before activation, register every existing Lab and host project group, start all
   per-authority lifecycle services, validate the complete channel-to-authority map,
   then activate the sole Hermes poller. Retire a legacy Python poller only after
   its groups pass that cutover. Late/unregistered chat IDs create a durable informed
   coverage gap through the existing generation/coverage mechanism; offsets never
   silently discard them.
6. Existing request/answer/effect receipts, restart/unknown-result behavior,
   sixteen-hour confirmed-delivery policy and OTP vault protections remain the sole
   behavior. This topology introduces no credential distribution, result ledger or
   authority bypass.

### G-A (ace-hitl-hermes, required)

Channel→lifecycle-socket mapping with per-project explicit service identity:

- config: per-channel `hitl_socket` override (global `hitl_socket` remains
  the default); lifecycle clients instantiated per distinct socket, lazily
  and cached;
- each channel's requests/replies/instructions resolve ONLY to the project
  authority bound to that channel's socket — no cross-project leakage in
  either direction (ask/reply/pending flows all carry the channel's project);
- locality: a socket crossing the host/Incus boundary MUST use explicit
  service identity (configured per-project service credential/binding) —
  never assumed SO_PEERCRED identity; within one runtime the existing peer
  auth stays.

### G-B (ace-hitl, required)

Serve CLI `--group` option passed through to `Service(group:)`
(service.rb:36 already parameterized) + dedicated-directory guidance in the
`verify_socket_directory!` error message. Narrow socket access; no
lab-control/legacy-labd exposure by default.

### G-D (ace-hitl-hermes, optional if trivial)

Durably record skipped-unregistered chat_ids in the journal; surface them at
registration time (informed coverage gap via existing generation machinery).
Cutover MUST NOT silently drop existing Lab/host groups (register both
before activation).

### Existing protections unchanged

Receipt/restart/unknown-result semantics and OTP protections remain the
store's existing behavior. `verify_polling_owner!` gateway-Telegram-disabled
guard stays (one Hermes bot = only polling owner; G-C dropped).

### Release preparation

Version bumps + changelogs for both changed gems (ace-hitl,
ace-hitl-hermes) in this branch. Publication is separately authorized and
executed post-integration with exact-artifact manifest; this branch only
prepares.

### Verification plan

- New tests: per-channel socket mapping (two channels → two sockets, no
  leakage); explicit service identity across a simulated locality boundary
  (no peer-uid reliance); `--group` passthrough; G-D journal record if
  implemented.
- Source acceptance must exercise the actual authenticated connection selected for
  the host/Incus boundary, not only configure a UID or label a simulated boundary.
  Valid project-scoped identity reaches only its bound authority; missing, forged,
  mismatched-project and cross-channel identity are refused before lifecycle reads
  or writes. Same-runtime peer authentication remains separately tested.
- Full suites: `bin/ace-test ace-hitl all` and `bin/ace-test
  ace-hitl-hermes all` green at final head.

### Acceptance criteria

- [ ] G-A/G-B implemented with tests; G-D if trivial; G-C absent.
- [ ] Both suites green at final head.
- [ ] Release prep (versions/changelogs) included.
- [ ] Independent exact-head review APPROVED; PR via AGit citing this task
      + the topology contract; STOP at approved PR.
- [ ] Host `gad.8/gad.b/gad.2` separately proves all-group registry migration,
      offset/correlation preservation, one-poller cutover/rollback, bidirectional
      exact Reply/instruction isolation and restart across the real boundary; these
      installed checks do not replace source-package acceptance.

## Provenance

Captain HITL implementation order (2026-10-11, answer
h1a12b713f57-2eea27) under 8xa.t.h8x/8xahhp; host-observed activation
blockers (one lifecycle socket / single-repo AttemptCoordinator, poller
offset skip, global gateway-disable guard, lab-control group exposure);
design evidence `.ace-local/evidence/gad8-hitl/shared-transport-topology-contract.md`
(provenance only; corrected per one-Hermes). Tool-minted after owner reconciliation: no
existing ACE task owns ace-hitl transport topology (xz9 = protected scope;
vs3 = publication/HITL behavior; gad.8/gad.b = lab-config deployment side).
