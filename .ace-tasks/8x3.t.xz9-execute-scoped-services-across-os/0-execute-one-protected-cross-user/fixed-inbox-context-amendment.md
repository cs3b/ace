# Fixed protected Inbox construction — readiness candidate

This closes the concrete construction/schema gap in remaining-consumer-contract.md,
not a delivered source or installed claim. Framing-only source0b53a8d0a is separate.
No caller can select paths, native server, key, executable, environment or module.

## Closed installed schema

A services project may contain `inbox_contexts`, a map from existing bounded
JournalMutation IDs to exact entries:
`{deliveries_dir, receipt_public_key, native_mapping_id, pi_queue_client,
pi_queue_client_sha256, supervisor_uids}`. Paths are canonical absolute paths;
the digest is lowercase SHA256 and supervisor_uids is sorted distinct positive
UIDs, a subset of that project's existing supervisor_uids. native_mapping_id
must select a launch mapping of the same project and authority, never a foreign
endpoint. Context native identity is that mapping's installed native identity,
verified by existing protected native client. No context-level PID or current
endpoint repinning is permitted. Existing exact launcher incarnation also has
coordinator access; context UID allowlist does not replace kernel peer checks.

Fixed pi_queue_client is an installer-selected root-owned executable with digest
and protected ancestors, not a caller executable. This explicitly clarifies
prior 'no executable' wording: no peer-selectable executable/module exists, but
the existing Pi identity client must have a fixed installed path; an ENV/default
pi-overseer-queue-client is forbidden. The operation can invoke only its existing
`--identity` method through the existing bounded NativeQueueExecutor, with fixed
empty sanitized environment and no caller argv. No submit/deliver/wake operation
is exposed or called during protected reconciliation. Codex queue invocation is
not part of this construction. Unsupported target identity refuses.

The authority-owned deliveries directory is private and traversable only by the
installed authority/trusted coordinator profile, with immutable protected
ancestors; it must not overlap worker scratch, project checkout, receiver staging,
other context roots or service credential roots. Trusted public key and Pi client
are root-installed immutable regular non-symlink files; public key must parse as
public-only RSA using existing Inbox rules. Validate effective ancestry, endpoint
identity, key fingerprint, executable digest and authority access at startup and
every operation. No creation/chmod/ownership repair on query, no ~/.ace config or
cwd fallback. An absent/unsafe/unreadable context refuses before journal mutation.

## One Herdr-owned construction

Add a source-owned protected Inbox factory in ace-herdr, taking the resolved
installed context and existing ProtectedNativeControl instance. It directly uses
Inbox.new(executor:, native:, deliveries_dir:, receipt_public_key:). It does not
call Inbox.from_config defaults. The executor implements only Inbox's existing
`pane_get_bounded` observation through ProtectedNativeControl.request('pane.get',
{'pane_id': exact requested pane}); adapt its result to existing ExecutionResult
parsed_json shape `{result: {pane: ...}}`. Connected-peer/object pre/post checks
remain ProtectedNativeControl's own implementation; no second native transport.
The native identity collaborator exposes only existing `pi_identity` delegated
to NativeQueueExecutor with explicit fixed pi_client and a source-owned bounded
runner that supplies the fixed sanitized environment. It never executes defaults
or reimplements provider identity/signature semantics. Request timeout bounds
remain existing bounded native control/Pi identity defaults.

Deployment owns schema/project/ancestry selection; Herdr owns construction and
event lock/key/signature/native reconciliation. Assign Endcap receives only the
resolved Inbox plus validated fixed context; caller never supplies an Inbox object.
Any required HerdrExecutor/BoundedProcess environment seam is source-owned Herdr
implementation in this slice, not another executable/transport or arbitrary runner
from deployment JSON. Fixed constructor collaborators may be test-injected only
in source tests, never runtime configuration.

## Existing registration and canonical reconciliation

An already canonical inbox_binding must retain this exact inbox_context_id and
registration. An older local-only binding lacking context is not adopted or
backfilled. It refuses evidence_unavailable. bind_inbox remains later seal-aware
xz9.0 work; independent reconciliation tests create a genuine journal registration
with this exact existing event contract, not a scope completion claim.
Use unchanged reconcile_inbox exact selectors/two-part transport and live recorded
launcher or context-allowed mapped supervisor. Key signature proof is independent
of that transport role. Reverify current registration under Herdr event lock,
then import both exact raw parts and descriptor context atomically with qjl
reconciliation/reply; no receipt path fallback. Herdr accepted-before-qjl crash
uses exact signed replay, never rollback or native resubmit.

## Required verification

Schema: unknown keys, cross-project mapping, excessive role allowlist, root
overlap, symlink, mutable ancestor, private-key input, wrong client digest and
missing file each refuse. Real temporary filesystem tests verify ancestry and
file access rather than all-mocked path checks.
Factory: actual Inbox with controlled existing native boundary verifies it uses
only the fixed pane endpoint/explicit Pi identity client and sanitized environment;
poison global config/PATH/ACE_HERDR_PI_QUEUE_CLIENT without changing routing.
No queue submit/wake or caller-controlled argv is possible.
Reconciliation: signed original event, wrong registration/key/context/claim,
replacement-target identity, Herdr-before-qjl crash, canonical descriptor/blob
corruption, replay after worker exit/seal and per-reader provenance coverage.
Actual installed native/multi-user criteria remain open. Review independently
before source steps02/03 or promotion; no such source exists in this candidate.
