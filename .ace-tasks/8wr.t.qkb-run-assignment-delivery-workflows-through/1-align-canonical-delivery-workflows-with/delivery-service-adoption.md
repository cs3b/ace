# Required delivery producer and consumer adoption

qkb.0 source prepares neutral workflow entrypoints and assignment catalog consumers.
Do not publish them until qkb.1 removes obsolete names, regenerates normal projections
and proves fresh installed resolution across every listed consumer.

The authorized qjx merge executor is the producer. Its handler consumes the existing
exact scoped ServicePolicy claim and calls the neutral provider merge primitive
with the claimed candidate SHA and PR target. It emits the executor-owned terminal
receipt with native evidence, through the existing service request journal.
The handler must not call worker DeliveryCoordinator#perform(operation: "merge"):
that method consumes a completed receipt and cannot execute its own pending request.

The assignment worker is the consumer. ProtectedDeliveryCoordinator verifies the
completed canonical service receipt, imported executor artifact and exact original
assignment/attempt/project/head/PR/input association. The existing authority's
complete_service CAS atomically publishes completion/import and the uniquely bound
delivery event; worker consumption is read-only and never repeats provider merge.
No transport journal, new grant dialect or credential-derived authorization exists.

## Source completion and central installed acceptance

The Captain's centralized acceptance decision assigns actual Lab installation and
execution to `lab-config:8wl.t.gad.2`, row `qkb-delivery`, with domain installation
owned by `gad.b`. The following installed scenarios are that row's obligations,
not additional deployment prerequisites for closing qkb.1 source work.

qkb.1 must first deliver the actual maintained producer/consumer composition,
workflow/catalog/role adoption, controlled integration tests covering its success
and refusal paths, and independent source review. Fixtures cannot replace missing
production behavior. Local package installation/resolution checks remain source
packaging evidence; they do not establish cross-user Lab acceptance.

Required installed scenarios referenced by `gad.2:qkb-delivery`:

- Install the actual configured integrator/executor merge handler and exact operation
  grants; source fixtures or injected handlers cannot establish this acceptance.
- Prove worker dispatch -> authorized executor neutral merge -> owned native terminal
  evidence -> worker receipt consumption, with exact SHA and resource throughout.
- Reject absent/wrong grants, stale SHA, altered receipt evidence and uncertain merge;
  preserve uncertainty without blind retry. Red CI alone does not reject integration.
- Prove all new wfi/skill entrypoints resolve outside ACE and old names fail; ship all
  consumer/catalog/projection updates in the same release as their removal.
- Keep publication separately authorized. Retain the central installed checklist
  as open until these executed scenarios and independent exact-head review pass;
  close qkb.1 only after its implementation, source tests and review are accepted.

## Fixed merge producer — independently reviewed amendment

The configured protected merge operation invokes exactly `ace-git service merge` through its existing trusted fixed local operation entry. No caller chooses an executable, argv, shell, evidence path or handler mode. The receiver supplies one bounded UTF-8 JSON document on stdin after its actual claim, candidate materialization, begin-dispatch and fresh authorization checks; the handler consumes no authorization from environment or command-line flags. Ordinary low-level `ace-git pr merge` remains a separate standalone entry, never a protected worker fallback.

The envelope is the current receiver's closed `{version, request, input, execution}` format. Require integer version1. `request` contains the existing terminal binding fields plus authorization, service_id and caller_uid. `execution` contains exactly executor_uid, authority_id, claim_binding, candidate_generation, head and staging_id. Operation must be merge; request executor UID and candidate_head equal the execution UID/head, input digest and target equal the request's accepted values, and candidate generation is positive. The fixed handler runs only as that executor UID. These validations are consistency checks, not a second grant authority: the existing receiver and service policy own permission.

Source admission bounds the complete encoded envelope to 128KiB, its encoded structured input to the existing receiver's 64KiB limit, and its fixed evidence artifact to 64KiB. JSON is one strict document with depth16, no decoded duplicate keys, comments, additions or non-finite numbers. Executor and generation fields retain integer types. Publication rechecks the held private root's ownership, mode and path identity before writing; publication failure after merge remains uncertain.

Merge input is exactly `{target, delivery, method}`. Target is exactly `{resource, artifact_digest}` with the retained PR URL and nullable SHA256 artifact digest; it equals the canonical request target. Delivery is the existing complete normalized delivery parameter mapping: forge_server, forge_default and pr_provenance `{mode, head_repository_url, head_ref, base_repository_url, base_ref}`. Use the same maintained neutral validation for both assignment delivery and this merge producer rather than duplicate it; extract the forge-neutral input validator to its ace-git owner if required. Explicit named/default or remote resolution follows existing selection rules, never a fallback. Method is exactly squash, merge or rebase; no default. All input is non-secret and bound to the authorized input digest. The expected candidate SHA comes only from the receiver's retained execution/request join, never another input SHA.

Before one merge call, resolve the selected forge once and verify the normalized PR URL/number, head SHA, head/base repositories and refs against target, candidate and explicit provenance. Invoke the maintained neutral merge primitive once with that exact head and method. A succeeded receipt must describe merge for that same selected PR/candidate and verified merged remote outcome with a concrete merge commit. Emit no success when the effect is uncertain, reply is lost, or post-effect identity/outcome cannot be verified. Never retry merge to obtain evidence. A proven refusal before mutation or normalized failed result may emit failed; a failed outcome does not claim effect absence or release its authorization.

On a verified result, write one bounded immutable artifact under the receiver's existing private materialized candidate root using a fixed source-owned filename, exclusive regular no-follow creation, fsync and held digest. It contains the existing service attestation line followed by exact normalized forge/PR/provenance/method/candidate/result evidence. Return only the existing `{request_id,input_digest,outcome,evidence:[{ref,sha256}]}` response. No worker-supplied artifact path, new journal or new receipt format is introduced. The receiver reads/uploads the artifact and existing canonical import/ServiceEvidence owns terminal acceptance. This textual executor-owned attestation is the current source contract; it is not signed native or installed execution proof.

Controlled source verification uses actual neutral lifecycle/provider adapters with injected provider command responses, and the actual fixed merge CLI stdin/response and receiver handler composition with injected process/UID boundaries. Cover GitHub, default/named Forgejo, canonical/fork provenance, exact-head/resource/method mismatches, malformed/oversized input, ambiguous selection, lost/uncertain merge and evidence publication failure. Red CI alone never blocks. No provider network call, real merge, native/root/installed probe or publication is authorized by these tests.

Historical producer amendment scope: this amendment supplied the fixed merge producer only. The original protected worker delivery consumer, canonical receipt verification, workflow/role routing and full SC7 composition remain required source work. The current caller-local DeliveryCoordinator cannot substitute for that consumer. Its exact original capability/receipt API join must be reviewed before implementation; no invented RPC or local-journal fallback is authorized here.
