---
id: 8xa.t.nh0
status: skipped
priority: high
created_at: "2026-10-12 00:30:00"
estimate: 
dependencies: [8x3.t.xz9]
external_dependencies: [lab-config:8wl.t.gad.8, lab-config:8wl.t.gad.b]
tags: [ace-hitl, ace-hitl-hermes, gad8, transport]
needs_review: true
---

## Current ordinary delivery owner (2026-10-16)

The approved program `8xf.t.ei9` now owns .9 installed shared Hermes/HITL transport. Reuse this task’s
implementation and history; remaining ordinary outcome work is tracked in
`.ace-tasks/8xf.t.ei9-wave-3/delivery-map.md`. The ordinary program does not
wait for unrelated protected-runtime work. Requirements below remain historical
and implementation context where superseded by that current contract. This
ownership transfer does not mark unfinished work done or reopen archived work.


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

Configuration contains credential references, never secret bytes. Both credential
objects reject unknown fields and nulls. `tls_client_credential` resolves exactly:

```json
{"certificate_file":"/absolute/path","private_key_file":"/absolute/path","ca_file":"/absolute/path","expected_server_uri_san":"urn:ace:hitl:<project-id>:lifecycle-server","expected_server_certificate_sha256":"<64-lowercase-hex>"}
```

`tls_server_credential` resolves exactly:

```json
{"certificate_file":"/absolute/path","private_key_file":"/absolute/path","ca_file":"/absolute/path","server_uri_san":"urn:ace:hitl:<project-id>:lifecycle-server","allowed_client_uri_san":"urn:ace:hitl:<project-id>:hermes-client","allowed_client_certificate_sha256":"<64-lowercase-hex>"}
```

Every string is non-empty; all three paths are absolute canonical paths; fingerprint
fields match `^[0-9a-f]{64}$`. The new client-side
`expected_server_certificate_sha256` is mandatory and is the sole configured server
pin. The server credential admits exactly one client SAN/fingerprint pair. Lists,
wildcards, CA-only admission and omitted pins are invalid.

Provisioning and startup enforce one exact ownership/mode layout on both host and
container; there are no mode alternatives:

- every credential-tree ancestor above the project leaf is `root:root` mode `0755`;
- the project credential directory is `root:<exact-service-group>` mode `0750`;
- the referenced private key is `<exact-service-user>:<exact-service-group>` mode
  `0400`;
- the referenced certificate and CA bundle are `root:root` mode `0444`;
- the root-owned runtime file containing endpoint/credential references is
  `root:<exact-service-group>` mode `0640`;
- each path component and file is a regular owned object as applicable: no symlink,
  ACL, group/world-writable component, hard-linked key, mount redirect or ownership
  substitution is accepted. The service user may traverse only through its exact
  service group and cannot create, replace or chmod any credential/config file.

Any missing, unreadable, redirected, over-broad, incorrectly owned/mode-set or
mismatched object refuses startup before a socket is opened.

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

### Reviewed cross-repository real-boundary prerequisite

nh0-A has two explicit external prerequisites in `lab-config`: `8wl.t.gad.8` owns
the disposable Incus instance, project credential trees, tailnet listeners,
firewall and TCP proxy devices; `8wl.t.gad.b` owns the two project lifecycle fixture
services, their start/stop order and effect-free negative-case observation. Their
reviewed deliverable is the host-owned executable
`bin/lab-hitl-boundary-fixture`; source agents do not invoke Incus/root commands
directly. Both prerequisite revisions and the fixture contract require independent
review before their evidence can clear nh0-A.

The host lab-config owner invokes exactly:

```text
bin/lab-hitl-boundary-fixture run \
  --invocation INVOCATION_ID \
  --ace-container lab \
  --ace-worktree /lab/projects/ace/.ace-wt/WORKTREE \
  --ace-head ACE_FULL_SHA \
  --scenario nh0-a-v1 \
  --format json
```

`run` rejects a dirty ACE worktree, a non-matching head, paths outside the declared
ACE workspace, reused invocation IDs and unreviewed lab-config/fixture revisions.
For that one invocation it builds the exact-head ACE packages, creates a disposable
Incus instance, provisions project A/B service accounts and the exact credential
layout above, starts two loopback TLS lifecycle services, installs distinct host
tailnet TCP proxy devices/firewall rules, and supplies the host-side test identity
with only its project-scoped client files. It then executes the nh0-A source scenario
against the real proxies, including every positive, isolation, credential, restart
and uncertainty case in this spec. In an ensure/finally phase it stops fixture
services, removes proxy/firewall devices, destroys the disposable instance and
removes ephemeral credential files. A failed test still performs teardown and
returns a failed receipt; incomplete teardown is itself a failure.

The single stdout JSON receipt is closed and contains exactly:

```json
{"type":"nh0_real_incus_acceptance","version":1,"invocation_id":"<id>","scenario":"nh0-a-v1","ace_head":"<40-hex>","lab_config_head":"<40-hex>","provision":{"instance_id":"<id>","project_ids":["A","B"],"proxy_configuration_sha256":"<64-hex>","credential_layout_sha256":"<64-hex>","server_certificate_sha256s":["<64-hex>","<64-hex>"],"client_certificate_sha256s":["<64-hex>","<64-hex>"],"completed_at":"<date-time>"},"test":{"command":"<exact-command>","receipt_ids":["<id>"],"passed":true,"positive_cases":1,"negative_cases":9,"completed_at":"<date-time>"},"teardown":{"services_stopped":true,"proxy_devices_removed":true,"firewall_removed":true,"instance_destroyed":true,"credential_files_removed":true,"completed_at":"<date-time>"},"evidence_sha256":"<64-hex>"}
```

All objects reject unknown fields and nulls. `project_ids` and both certificate
fingerprint arrays contain exactly two distinct strings; `receipt_ids` contains one
or more distinct non-empty strings. Timestamps assert RFC 3339 `date-time`; counts
are integers with the shown exact minimums (`positive_cases >= 1`,
`negative_cases >= 9`). `evidence_sha256` is the
digest of the separately retained canonical fixture report identified by the
invocation, not a self-hash of stdout. The report contains command exits and bounded
sanitized observations but no keys, tokens or message bodies.

The nh0 source task accepts this handoff only when invocation ID, scenario, both
reviewed repository heads, provision/test/teardown booleans, receipt IDs and evidence
digest all verify against the retained report and its own test record. Prose, a
different invocation, a loopback-only run, a mock proxy or gad.2's later installed
fleet run cannot substitute for this prerequisite receipt.

### Boundary acceptance and rollback

Source acceptance for this task consumes the reviewed invocation-bound
`nh0_real_incus_acceptance` receipt above from an actual disposable Incus instance
and proxy device, not a loopback-only or mocked locality test. A host Hermes client certificate
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
| nh0-A: shared routing + real crossing | 8xa.t.nh0 (`ace-hitl` server and `ace-hitl-hermes` client), after reviewed `lab-config:8wl.t.gad.8` + `8wl.t.gad.b` fixture prerequisite | Invocation-bound actual disposable Incus proxy receipt + mTLS project isolation, bidirectional flows, restart/uncertainty and unchanged Unix peer-auth tests above |
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

## Superseded (2026-10-17, Captain's architecture decision)

The shared-Hermes cross-VM transport model (multi-project groups, mTLS,
shared poller) assumed per-lab daemons — superseded by the no-daemon,
file-based decision. ace-hitl-hermes was never deployed and has no
dependents outside the HITL family (verified against all gemspecs); its
removal is a follow-up decision. Per-lab HITL configuration continues in
8xg.t.qn6.5 (ace-lab install).
