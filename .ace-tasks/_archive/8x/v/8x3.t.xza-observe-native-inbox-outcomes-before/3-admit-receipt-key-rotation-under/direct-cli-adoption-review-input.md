# Direct Inbox CLI adoption — readiness gap

Source audit on main `4de271222`, independently checked by `/root/audit_runtime_delivery_status`. This is an amendment review input, not an approved new transport contract. Existing context owner/rotation implementation remains delivered as checkpoints; direct entry-point acceptance is still missing.

## Required observable behavior

A protected caller using the registered Herdr inbox CLI cannot bypass context admission, key generation or durable in-flight state. CLI selection must authenticate a root-installed endpoint and retained protected principal classification before reading payload/proof files or constructing a local Inbox. Corrupt, removed or inaccessible protected selection refuses; it never restores local mode. Genuine standalone callers retain ordinary local operation.

Protected enqueue and deliver execute through the fixed context owner and its existing source Inbox. An admission token wrapped around caller-local mutation does not satisfy this contract. Request/replay binds exact event, attempt, target and payload identity; changed input conflicts. Loss of a reply never permits a second native submission. Existing delivery records remain the only delivery ledger, while existing context operation metadata retains outstanding/uncertain ownership. Rotation stays blocked until the existing owner positively verifies completion; elapsed time, EOF, exception or caller assertion is insufficient.

Protected reconciliation uses the maintained canonical authority binding/import/completion path. A CLI proof file cannot manufacture an authority effect binding or clear in-flight state. If no supported authenticated consumer exists for an operation, refuse before local mutation; refusal is not completion of the requested adoption scope.

Signer integration remains a separate real consumer: hold observe-to-sign admission through exact accepted downstream completion. Herdr currently exposes no signing CLI; do not invent one to claim that domain integration is done.

## Existing owners and missing joins

- `cli/commands/inbox.rb` unconditionally constructs `Inbox.from_config`, then executes local enqueue/deliver/reconcile. Ambient Herdr configuration and caller files currently choose its store/key.
- `InboxContextClient` already authenticates fixed endpoint credentials and process incarnation.
- `InboxContextOwner` already owns admission, rotation, active/uncertain metadata and the fixed source Inbox.
- `InboxContextServer::FIELDS` has snapshot/reconciliation/rotation operations, but no transported enqueue/deliver effect methods.
- `reconcile_context` is authority-only and validates a canonical effect binding. `confirm_context_completion` independently checks canonical acceptance.
- `InboxContextKey` authenticates the four-field key document only; it is not a general CLI endpoint/principal selector.
- Assign already depends on Herdr. Herdr must not import Assign's deployment classifier and create a package dependency cycle.

## Technical decisions required by readiness review

1. Select the source-owned installed context/principal projection and its production publisher. Specify exact closed schema, fixed trust root, retained-principal removal behavior, and how it joins the existing immutable bootstrap/publication without another mutable permission authority. Ambient config, CLI endpoint paths and environment claims are not trust roots.
2. Define exact enqueue/deliver effect and completion interfaces on the existing context owner, including registration ordering, crash boundaries, replay and no-resubmission proof. Reuse existing event records and in-flight metadata; do not add a second outcome journal.
3. Name the maintained public reconciliation route and exact selectors. Retain original canonical binding and source-owned completion verification; neither workers nor CLI-local receipt metadata can impersonate authority.

These are technical review questions, not permissions to weaken the required behavior. xza.3 returns to draft/needs_review until they are resolved and independently reviewed. No native probe or installed acceptance is authorized or claimed by this document.

## Acceptance additions

Execute registered CLI → authenticated selected context → maintained owner → actual temporary delivery store. Inject excluded kernel/native boundaries only. Prove enqueue pins the admitted key, deliver submits once, rotation races refuse mixed generations, lost reply retains uncertainty, duplicate invocation cannot resend, and crash/restart retains admission. Wrong/removed/corrupt selection, unauthorized identity, changed input, stale key, local proof override and inaccessible state must refuse before local construction/effects. Reconciliation must prove the original canonical acceptance rather than a callback boolean. Record exact source and independent verdict; installed account/key/native drills remain in gad.2.
