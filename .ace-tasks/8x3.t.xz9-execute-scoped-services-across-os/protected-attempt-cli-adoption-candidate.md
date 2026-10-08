# Protected attempt CLI adoption amendment candidate

Status: pending independent readiness review; no implementation or task promotion.
The bounded handler checkpoint is public Authority::Client/Server evidence only.
Existing attempt/base.rb unconditionally constructs the local coordinator; finish
accepts local receipt files and reconcile invokes local cache recovery. Existing
inbox-reconcile also uses the local coordinator. These are actual missing source
consumers, not test gaps.

## Selection and ownership

Reuse ProtectedAssignmentContext.load and its delivered client(options:) helper.
Extend this same classifier with an authority-operation selection method using
exhaustive current and retained installed principal inventories: all five declared
project role UID arrays (launcher/reviewer/worker/service_executor/supervisor),
authorities[].uid, each Inbox context owner_credentials.uid, installed receiver
executor_uid and mapping launcher/worker UIDs. These exact declared source fields
are the inventory; do not guess UID fields recursively or omit non-command roles.
Any such participant, or explicit --mapping / ACE_ASSIGN_LAUNCH_MAPPING, selects
protected operation. Unsupported installed participants (including authority,
service and Inbox context-owner accounts) must refuse before local coordinator
construction; classification never upgrades them to launcher/supervisor/worker.
The principal classification is a refusal boundary, never permission: actual
Client/Server kernel role admission remains authoritative. Any protected hint,
removed retained mapping, corrupt installed descriptor/history, or protected
principal lacking an exact mapping refuses; never construct local coordinator on
that path. Ordinary unmapped users with no protected selector retain local mode.
All supplied assignment/attempt hints must exactly agree with explicit options;
environment hints select addresses only and grant no authority. No scope inference,
first active attempt lookup, generation refresh, or local receipt fallback.

## Closed public invocations

`ace-assign attempt finish --mapping MAP --assignment ASSIGNMENT --attempt ATTEMPT
--result RESULT --head SHA --candidate-generation N --mutation ID
--expected-generation N` calls existing protected finish. The result selector must
name an already canonically submitted result; --receipt is forbidden in protected
mode. The current authority mutation generation is distinct from the original
candidate generation. Caller must supply both exactly; retry preserves the entire
original tuple and mutation. Output is the existing bounded authority reply.

`ace-assign attempt reconcile --mapping MAP --assignment ASSIGNMENT --attempt
ATTEMPT --mutation ID --expected-generation N` calls protected recover. It forbids
--receipt, never invokes assignment-wide resume, and emits the existing decision,
reason, state and original accepted commit. Repeated accepted mutation keeps its
first reply; terminal pure reads authenticate the current internally pinned
terminal/release evidence without changing it. No implicit stop or restart.

`ace-assign inbox-bind --mapping MAP --assignment ASSIGNMENT --attempt ATTEMPT
--event EVENT --inbox-context CONTEXT --mutation ID --expected-generation N`
calls existing bind_inbox through the same fixed client. Actual worker identity,
registration/key selection and fresh scope seal exclusion remain the source owner.
The command never reads private Inbox storage or creates a registration itself.

All IDs use existing TOKEN bounds and generation flags are strict integer values.
Unknown/extra incompatible local options refuse before local construction or wire
mutation. Public reply projection is JSON only; raw proof bytes and local private
journals are not displayed. Visibility or adoption metadata is never a grant.

## Role and workflow consumption

Original worker uses inbox-bind immediately after the existing Herdr enqueue/
delivery owner returns its event selector, before scope seal. It may not substitute
current pane/discovered key data. Original launcher or installed supervisor uses
attempt finish only after canonical result submission and accepted independent
review for succeeded results; the command does not submit local receipt bytes,
close the scope or manufacture proof. Supervisor uses attempt reconcile with an
explicit stable mutation to classify one original attempt after interruption.
Role/usage instructions must name these actual public commands and preserve the
existing kernel admission limits; changing a charter cannot grant privileges.
Existing result producer and Inbox reconciliation workflow adoption remain separate
required family source joins; this amendment does not claim they are delivered.

## Required controlled evidence

Actual default CLI → ProtectedAssignmentContext → actual Client/Server → maintained
Endcap/Git composition for all three commands, including genuine independent review
for succeeded finish, original Inbox registration, terminal+released pure recovery.
Constructor trap proves protected success and refusal never load local coordinator.
Unknown mapping, wrong assignment/attempt hint, local receipt option, foreign role,
wrong generation, accepted exact replay and changed bytes under same ID are negative
cases. Ordinary local command behavior remains verified through its existing owner.
Injected OS/kernel facts only; no root/native/systemd/installed probes. Independent
review of this exact amendment precedes source edits; no family status closure.
