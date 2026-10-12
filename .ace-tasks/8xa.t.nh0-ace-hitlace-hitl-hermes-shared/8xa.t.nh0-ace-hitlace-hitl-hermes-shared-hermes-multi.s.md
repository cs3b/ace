---
id: 8xa.t.nh0
status: draft
priority: high
created_at: "2026-10-12 00:30:00"
estimate:
dependencies: [8x3.t.xz9]
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
   kernel peer credentials. The one selected host/Incus crossing is the existing
   bounded lifecycle framing protocol over TLS 1.3/TCP with mutual X.509
   authentication, forwarded byte-for-byte by an Incus TCP proxy device. The sole
   Hermes poller runs on the host. Each Lab project gets one host-tailnet listener
   `tls+tcp://HOST_TAILNET_DNS:PORT`; its Incus proxy connects only to that project's
   container-loopback `tcp://127.0.0.1:PORT`, where the project lifecycle service
   terminates TLS. There is no HTTP layer and the proxy is not an identity authority.
   The lifecycle service authorizes the verified project-scoped client certificate
   before decoding a lifecycle frame. Unix UID/GID, configured UID, payload fields,
   tailnet membership and a simulated boundary are not remote identity proof.
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

## Selected host/Incus transport contract — required

### Endpoint and protocol

- The remote endpoint form is exactly `tls+tcp://HOST_TAILNET_DNS:PORT`; literal
  wildcard, loopback, Unix and cleartext TCP endpoints are invalid in Hermes remote
  channel configuration. DNS name and port are deployment values, never request
  fields. The server certificate must match `HOST_TAILNET_DNS` and the configured
  project identity.
- The Incus device is a TCP proxy with
  `listen=tcp:<host-tailnet-address>:<project-port>` and
  `connect=tcp:127.0.0.1:<project-port>`. It performs no TLS termination, header
  insertion, identity translation or protocol conversion. The container lifecycle
  service accepts that loopback port only; it is not exposed on a container-wide
  wildcard address.
- After a mutually authenticated TLS 1.3 handshake, peers exchange the existing
  bounded `ace-hitl` lifecycle frames unchanged. Existing size/deadline/concurrency,
  request/answer/effect, OTP one-shot and unknown-result rules apply. TLS failure,
  EOF, malformed frame or identity mismatch occurs before any lifecycle read/write
  and never falls back to Unix, HTTP or unauthenticated TCP.

### Mutual project identity and credential references

Each project has a unique Hermes client identity and lifecycle server identity. The
certificate identity is a single URI SAN of the closed form
`urn:ace:hitl:<project-id>:hermes-client` or
`urn:ace:hitl:<project-id>:lifecycle-server`; `<project-id>` must exactly equal the
channel registry project. The server validates its configured client SAN and issuing
CA and required configured SHA-256 certificate fingerprint; Hermes validates the
server SAN, DNS name, issuing CA and required configured fingerprint. Certificate
validity and EKU (`clientAuth`/`serverAuth`) are checked on every new connection. A
certificate for one project cannot authorize another even when issued by the same
CA. Rotation provisions new files and atomically changes the exact configured
fingerprint; CA membership alone never grants a project.

Configuration contains credential references, never secret bytes:

- the Hermes channel names one `tls_client_credential` ID; the Hermes-owned runtime
  config resolves it to absolute `certificate_file`, `private_key_file` and
  `ca_file` paths plus the expected server URI SAN;
- the lifecycle endpoint config names one `tls_server_credential` ID resolving to
  its absolute certificate/private-key/CA paths and a closed list containing the
  one admitted Hermes client URI SAN and required certificate SHA-256 fingerprint;
- referenced regular files must have non-symlink, non-group/world-writable ancestry.
  Private keys are mode 0400 or 0600 and owned by the exact service account that
  reads them; public cert/CA files are root-owned and non-writable by that account.
  Missing, unreadable, redirected, over-broad or mismatched files refuse startup.

Host `lab-config` explicitly provisions the project CA material, distinct client
and server keypairs, parent directories, ownership/modes, Incus proxy device and
tailnet listener/firewall rule. It copies only the server key into the corresponding
Lab lifecycle account and only the client key into the host Hermes account. It does
not borrow the Telegram token, an SSH key, a maintainer credential, another
project's certificate or a local UID/group grant. ACE never generates or distributes
deployment credentials and no config entry itself grants access.

### Lifecycle and configuration ownership

- `ace-hitl` owns the TLS/TCP listener option, TLS validation, remote peer-to-project
  binding and reuse of the existing lifecycle frame/store semantics. Its authority
  config owns the loopback listen address, project ID and server credential ref.
- `ace-hitl-hermes` owns the TLS lifecycle client, channel-to-project/endpoint/client
  credential mapping, connection cache isolation and the single host-side Hermes
  polling process. Its registry/runtime config owns the remote endpoint and expected
  service identity; it never accepts these from Telegram content.
- `lab-config:gad.8/gad.b` owns host/container accounts, file provisioning, Incus
  devices, ports/firewall, service units and start order. `gad.2` owns final installed
  multi-project acceptance. No second Hermes actor, lifecycle store or ledger is
  introduced.

Start order is server credential/files -> Lab lifecycle service -> Incus proxy and
listener check -> complete Hermes channel registry validation -> sole Hermes poller.
Activation is atomic at the poller: no channel is enabled until every configured
authority passes authenticated health and project-binding checks.

### Boundary acceptance and rollback

Source acceptance for this task uses an actual disposable Incus instance and proxy
device, not a loopback-only or mocked locality test. A host Hermes client certificate
for project A must complete bidirectional ask/reply/pending/instruction flows through
the proxy to lifecycle A. Missing certificate, forged CA, expired certificate,
wrong SAN/fingerprint, project B certificate, wrong endpoint, cleartext client and
cross-channel correlation all refuse before store access. The same suite disconnects
during a request and restarts the client, lifecycle service and proxy independently;
canonical lifecycle receipts reconcile without replay. A separate Unix test retains
kernel peer-credential behavior for same-runtime authorities. gad.2 repeats this at
installed host/Lab boundaries with the real service accounts and all registered
projects.

Rollback first stops the sole new Hermes poller, preserving its durable Telegram
offset/correlation generation; it never overlaps polling owners. It drains or marks
uncertain in-flight lifecycle calls and leaves polling stopped until the corrected
single Hermes deployment is ready. It does not reactivate a retired Python poller.
Only afterward may lab-config stop TLS listeners and remove the project Incus proxy
devices/credential files. Canonical lifecycle stores, receipts and coverage-gap
records are retained. Rollback never switches to HTTP, copies credentials,
collapses projects onto one authority or treats lost calls as safe to replay.

### G-A (ace-hitl + ace-hitl-hermes, required)

Channel→lifecycle-endpoint mapping with per-project explicit service identity:

- config: each channel has exactly one local `hitl_socket` or remote
  `hitl_endpoint`; `hitl_endpoint` is the selected `tls+tcp://` form and requires a
  `tls_client_credential`. Global `hitl_socket` remains only the local same-authority
  default. Lifecycle clients are instantiated lazily and cached per exact endpoint
  plus credential identity;
- each channel's requests/replies/instructions resolve ONLY to the project
  authority bound to that channel's socket — no cross-project leakage in
  either direction (ask/reply/pending flows all carry the channel's project);
- locality: the host/Incus boundary MUST use the selected mutually authenticated
  TLS/TCP + Incus proxy contract above; within one runtime the existing Unix peer
  authentication stays.

### G-B (ace-hitl, required)

Serve CLI `--group` option passed through to `Service(group:)`
(service.rb:36 already parameterized) + dedicated-directory guidance in the
`verify_socket_directory!` error message. Narrow socket access; no
lab-control/legacy-labd exposure by default.

### G-D (ace-hitl-hermes, required)

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

- New tests: per-channel endpoint mapping (two channels → two authorities, no
  leakage); the actual disposable host/Incus mTLS proxy boundary defined above
  (no peer-uid reliance); `--group` passthrough; required G-D journal record and
  registration-time surfaced generation.
- Source acceptance must exercise the actual authenticated connection selected for
  the host/Incus boundary, not only configure a UID or label a simulated boundary.
  Valid project-scoped identity reaches only its bound authority; missing, forged,
  mismatched-project and cross-channel identity are refused before lifecycle reads
  or writes. Same-runtime peer authentication remains separately tested.
- Full suites: `bin/ace-test ace-hitl all` and `bin/ace-test
  ace-hitl-hermes all` green at final head.

### Acceptance criteria

- [ ] G-A/G-B/G-D implemented with tests; G-C absent.
- [ ] Both suites green at final head.
- [ ] Release prep (versions/changelogs) included.
- [ ] Independent exact-head review APPROVED; PR via AGit citing this task
      + the topology contract; STOP at approved PR.
- [ ] Host `gad.8/gad.b/gad.2` separately proves all-group registry migration,
      offset/correlation preservation, one-poller cutover/rollback, bidirectional
      exact Reply/instruction isolation and restart across the real boundary; these
      installed checks do not replace source-package acceptance.

### Independently implementable slices

| Slice | Owner | Source acceptance |
|---|---|---|
| nh0-A: shared routing + real crossing | 8xa.t.nh0 (`ace-hitl` server and `ace-hitl-hermes` client) | Actual disposable Incus proxy + mTLS project isolation, bidirectional flows, restart/uncertainty and unchanged Unix peer-auth tests above |
| nh0-B: narrow lifecycle group | 8xa.t.nh0 (`ace-hitl`) | `--group` reaches `Service(group:)`; dedicated directory/group checks reject broad or legacy-labd exposure |
| nh0-D: informed registration gap | 8xa.t.nh0 (`ace-hitl-hermes`) | Unknown chat metadata is durable before offset advance; later registration surfaces the gap and starts a new coverage generation |

## Provenance

Captain HITL implementation order (2026-10-11, answer
h1a12b713f57-2eea27) under 8xa.t.h8x/8xahhp; host-observed activation
blockers (one lifecycle socket / single-repo AttemptCoordinator, poller
offset skip, global gateway-disable guard, lab-control group exposure);
design evidence `.ace-local/evidence/gad8-hitl/shared-transport-topology-contract.md`
(provenance only; corrected per one-Hermes). Tool-minted after owner reconciliation: no
existing ACE task owns ace-hitl transport topology (xz9 = protected scope;
vs3 = publication/HITL behavior; gad.8/gad.b = lab-config deployment side).
