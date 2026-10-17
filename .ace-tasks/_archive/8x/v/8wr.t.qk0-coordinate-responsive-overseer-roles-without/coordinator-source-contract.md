# Responsive coordinator source contract — readiness candidate

This is qk0 specification review against ACE `87eebc987`, not implemented overseer behavior or task promotion. Delivered Assign prompt/status/stop/lifetime owners are the consumer boundary; installed provisioning and exercise remain gad.2/gad.8/gad.b/gad.9. Review this contract, `protected-inventory-contract.md`, admission draft and usage together.

## Agent identity, visibility and admission

For protected execution, the stable agent ID is exactly the existing protected `Deployment.launch_mappings` key. There is no agent-to-mapping configuration table, role alias or logical-agent-to-many-slots resolver. Domain topology publishes those same IDs. A project with multiple builder slots publishes distinct IDs such as `builder-1` and `builder-2`; `--agent builder` selects only a literal installed mapping named `builder`.

Use the existing held-byte protected `Deployment.load` owner to select the current fixed descriptor. Resolve mappings by exact ID and `project_id`; retain its whole-file provenance during discovery. Public ace-lab project grants/topology provide caller visibility and labels, not execution permission or capacity. Candidate agents are the intersection of visible topology IDs and that project's installed mapping IDs. A conflicting project association, missing mapping, unavailable protected descriptor or malformed topology is explicit unavailable/refusal; do not resolve by display name, role, array position, pane or PID. Never expose descriptor credentials, private filesystem paths or native origin through public topology/status.

The installed mapping pool is the complete configured protected capacity. Report its count separately from visible candidates and currently usable candidates. Visibility is `complete` only when every installed project mapping is present in authorized topology; otherwise `partial`. A partial list cannot be reported as full capacity or as global exhaustion. Current kernel UID/GID/groups and installed mapping permissions determine whether this process can issue a launch; configuration cannot create those credentials. Assign checks the actual peer and current fixed mapping again at every operation. Descriptor advance or permission revocation invalidates selection; reconcile a possibly accepted reservation before any new selection.

Automatic selection considers visible provisioned mapping IDs in bytewise order. An explicit selection is never substituted. Try the next mapping only after an attributable pre-registration refusal proves zero registration/reservation/native effect; accepted registration fixes the exact mapping even if reserve subsequently conflicts; timeout, missing reply or uncertainty retains the original assignment/attempt/mutation identity for canonical reconciliation. A supervisor-only coordinator can inspect/steer/stop within its installed grants but cannot launch as another UID. It delegates to an already provisioned launcher-role instance through the role/assignment workflow; no `sudo`, `su`, detached broker, raw socket grant or cross-UID process spawn is introduced.

## Canonical inventory and restarted observers

Consume delivered qk0.0 `assignment_inventory` exactly as specified in `protected-inventory-contract.md` through the existing Assign authority, Server/Router/Client and retained journal reader. The canonical producer and actual protected Status consumer are delivered; qk0.1 fresh launch/recovery consumption and its reservation attribution extension remain implementation work. It enumerates accepted registrations/reservations at one authenticated canonical revision with bounded continuation, null mutation ID and current mapped permissions. The delivered definition reader honors `commit:`; never read current bytes while labelling them historical.

Enumerate each selected mapping independently. Keep each page set's revision and completeness; never combine incomplete revisions or report unreachable/forbidden/malformed inventory as empty. Duplicate assignment references across mappings retain their original mapping/attempt association. A full project summary requires successful complete discovery of the full visible authorized pool and explicitly reports partial project visibility otherwise. Inventory is discovery, not liveness or an admission grant.

The inventory additionally projects exact attempt authority generation, original binding digest and authenticated canonical state/terminal/release selectors at its selected snapshot. The parent verifies its ready child's binding/generation through that projection at the retained ready commit even after live advance. Detailed `attempt_status` observations retain their own revision. The current original-launcher read requires its captured kernel birth. Server resolves mapping launcher/worker credentials before project supervisor grants; an overlapping launcher/supervisor UID remains launcher. A restarted launcher-role process may discover old canonical occupancy/release through stable credentials, but cannot impersonate the old launcher for detailed status or its private channel. Without a distinct currently admitted supervisor actor, old-attempt live details remain unknown. A supervisor observation does not recreate an original driver. `prompt_status` uses the delivered stable-principal retry contract for a known public mutation; it does not imply blanket access to other principals' prompts or expose prompt bytes.

## Foreground child and terminal layout

Only a process running with the mapping's provisioned launcher credentials starts the maintained `ace-assign authority launch` foreground child. qk0 retains that exact child/wait handle; the child owns its authenticated driver/native connection. Read one UTF-8 strict, duplicate-key-free JSON `launch_ready` line, at most 16,384 bytes, within a 30-second monotonic deadline. Require the delivered closed eight-field schema, integer version/generation, exact 40-or-64-character journal commit, selected mapping/assignment/attempt and original binding digest. Verify against the accepted canonical original binding through the delivered owner before claiming ready. Stdout is one readiness line, not an event stream; bounded stderr remains diagnostic, never prompt/status evidence.

Dry-run, refusal and replayed reservation produce no new original-ready transition. Missing/late/oversized/malformed/mismatched readiness is an unresolved launch until canonical reconciliation; do not launch a replacement or erase accepted work. A lost child is uncertain, not release. Transient channel loss reconnects inside the same original child and never resends an issued prompt. Local cancellation alone is not stopped proof. qk0 uses public `stop_attempt`, maintains the child until actual terminal plus original reservation release, and consumes its exit; EOF/error/foreign binding/unreleased terminal never authorize cleanup. Delivered Driver lifetime queries retain their unchanged 30-second limit.

Protected execution uses the delivered Herdr owner. `tmux` remains valid for ordinary local mode; protected tmux refuses before allocation until it has the same protected capability. `auto` selects only a backend with the requested capability; it cannot silently downgrade protected work to local execution. The maintained protected owner creates one fresh single-pane tab for each actual reservation CAS winner: ProtectedNativeControl#create sends layout.apply with one pane root and validates no children/first/second. This satisfies at-most-four without a count-then-create race. qk0.1 does not pack/split/reuse existing tabs, create native panes itself or acquire the worker endpoint. No empty future tab is created. Changed/non-single-pane layout refuses and retains any possible creation as uncertain; it never allocates a replacement. Ordinary local layout remains separate. A layout refusal preserves any already accepted Assign reservation for explicit recovery; it cannot be converted into another launch. Closing a pane is a display effect after accepted terminal/release, never the evidence for them.

## Roles, charters and proposals

Deliver canonical workflow assets at `ace-overseer/handbook/workflow-instructions/roles/project-overseer.wf.md`, `roles/lab-coordinator.wf.md` and `roles/second-commander.wf.md`, loaded through the existing workflow bundle. Role selection changes instructions only; it does not change OS credentials, project grants, reviewer identity or authority permissions. A launcher-role instance is the project-overseer charter under explicit provisioned launcher credentials, not a fourth role or a native grant obtainable from config. Domain consumers adopt these assets; remove duplicated generic domain charters. The Captain remains the human decision owner.

The project overseer owns reviewed project tasks, attributable assignments, independent reviews, integration decisions and worktree/records cleanup. The Lab coordinator owns project routing, priorities, capacity, pause/resume and cross-project capability/dependency resolution, not each project PR queue or cleanup. The second commander presents unresolved cross-project scope/priority/policy choices to the Captain. Every wake reconciles the existing task/assignment queue plus scoped HITL proposals/callbacks. Escalations are existing task/assignment/proposal references with source scope, blocker and evidence, not another execution registry or review acceptance owner. An unreachable coordinator is unavailable; a policy refusal is a distinct visible decision. Failed delivery/callback retains its existing attributable record; no silent success or repeated effect.

Use the existing ace-hitl proposal policy and Hermes delivery owner unchanged: acknowledged delivery starts the sixteen-hour window; silent approval requires the owner's healthy/drained delivery checkpoint. Approve/veto/clarify, revised/superseded proposals and safe stop requests retain their existing meanings. A coordinator tick or elapsed clock is not approval. A new Captain instruction becomes a reviewed task/scope or a revised proposal referencing the old assignment/attempt and accepted candidate/input binding. Stop conflicting work through its actual owner and keep uncertainty visible; never rewrite the old attempt's accepted definition or start replacement work into an occupied slot. Technical work/review is delegated while the conversation accepts further instructions.

## Project worktrees and active supervision

Draft amendment requiring fresh review (provenance: h8x PR37–42). Earlier review applies only to its original scope.

### Ownership and worktree discipline
The project overseer owns its worker/reviewer/records worktrees, task attempts,
integration queue and accepted cleanup. Implementation and independently executed
review use isolated attributable worktrees; task records and supervision changes
are prepared in a records worktree and reviewed through the existing delivery
policy. The canonical main checkout stays clean and synchronized to the accepted
remote after integration. A clean tracking label or unchanged local HEAD is not
proof that a fresh remote observation matches the accepted merged commit.

Before synchronization, inspect actual local/remote ancestry and dirty/untracked
work. Preserve divergent local commits and WIP with attributable ownership and
recovery evidence, then reconcile through the existing review/integration policy.
Never reset/discard work or place unreviewed commits on canonical main. Dirty or
diverged main initiates owned recovery with a concrete next action; it cannot
become a perpetual generic WAIT or erase evidence of a completed remote merge.

The Lab overseer routes projects, cross-project dependencies, priorities, capacity,
pause/resume and missing capabilities. It does not take over each project's PR
queue, record updates, worktree cleanup or per-PR integration decisions. A missing
project capability is routed to its actual owner with exact scope and evidence.

### All authored changes and content-specific review

Every authored repository change, including task creation, specification/status
updates, supervision records, documentation and configuration, uses an isolated
attributable worktree. Canonical main is reserved for clean accepted state. This
is the desired workflow contract; this draft amendment does not itself migrate
current WIP or claim current sessions already meet it.
Group authored versioned changes in the existing attributable records/spec
worktree; a heartbeat does not create a new worktree, task or PR. Operational
runtime transitions remain with their existing authoritative owner, not a reviewed
documentation queue or second journal. This rule governs authored repository
changes, not replacement of native runtime authority.

An independent reviewer (author != reviewer) reviews the exact candidate head.
Select review prompts/templates explicitly by content using the project's existing
ace-assign/handbook configuration mechanisms:

- Task/specification: intent clarity, consistency, scope and dependencies,
  measurable acceptance, implementability and absence of invented capabilities.
- Documentation/records: truth against actual sources, exact SHAs and operation
  receipts; no unexecuted effect or stale evidence represented as current fact.
- Code: the existing executed-test and independent code-review gates.

Mixed changes receive every applicable review type. Relabeling code as docs cannot
avoid code checks. Later edits invalidate affected verdicts; re-review the changed
candidate before integration. A task-only review approves the authored specification
or records, not implementation completion. Drafting stays draft; readiness promotion
occurs only through the explicit existing task-review workflow. Use existing project
review selection and evidence owners; add no parallel review engine or journal.

### Heartbeat decisions and integration
On each heartbeat or scoped watch/callback, the project overseer reconciles actual
canonical Assign/task/attempt state, current candidate and target ancestry,
independent exact-head test/review evidence and service execution receipts. These
are inputs to the same owning overseer, not a second coordinator or queue engine.
Work remains responsive; no blocked sleep-poll loop or repetitive narrative wake.

Select the ready integration order by dependencies and accepted scope, not worker
completion FIFO. Record the eligible ordered set, selected/deferred candidates and
reasons using existing evidence. Delegate rebase and fresh checks/review when the
candidate changes; re-evaluate target movement before integration. Submit only
within actual authority, capacity and pause state; accepted service receipts,
not a callback or CLI exit alone, establish effects. Worker PR-ready remains the
implementation boundary; delivery may still be open after its parent closes.

A closed/merged PR with accepted receipt advances the delivery state. If canonical
main lags, open owned synchronization recovery; do not reopen a merge WAIT merely
because local main is unchanged. Ready work advances without waiting for a new
human nudge. A genuine blocker is escalated once per unchanged blocker/owner,
retaining a durable reference and next observation; changed evidence may warrant
an update. WAIT requires a real pending operation and reconciliation path.

Restart adopts the same original attempt and unresolved effect references.
Unknown merge/publication outcomes are reconciled read-only; no duplicate launch,
resubmission or effect retry is inferred from a missing callback. Pause prevents
new dispatch/effects while observation and safe reconciliation continue; capacity
accounts for unresolved live/uncertain attempts.

## Bounded responsiveness and ownership checks

Replace the existing unbounded `ProposalTick` wait with the maintained bounded-process owner: five-second wall-clock deadline, at most 65,536 bytes per output stream, owned-child cleanup and no retry in a tick. Status returns current observations even when resolution is deferred. Coalesce wakes while one tick is outstanding; no new timer service or ledger. Authority calls use their delivered bounded deadlines; no lock, conversation handler or proposal resolver waits for implementation/test/review completion. Each asynchronous operation reports its retained task/assignment/mutation reference and current unknown/deferred state.

The consumer's source checks include exact protected-ID selection, descriptor/permission advance, partial visibility, real concurrent reservation conflicts, lost readiness/reply without second launch, restart discovery and old-birth refusal, four-pane boundary, stalled/noisy resolver, wake coalescing, original CLI child/reconnect/terminal-release exit, independent reviewer identity, changed candidate/scope and existing sixteen-hour decisions. Controlled boundaries establish source composition; installed privileges, native startup and Captain interaction remain the single gad.2 acceptance row.

## Cleanup boundary requiring final owner composition

Existing `PruneOrchestrator` takes the local lifecycle exclusion and rereads a local journal/cache. It is not yet a protected authority consumer. `attempt_status` itself takes shared task/assignment exclusions, so calling it while holding the exclusive prune lock would deadlock. A prior status read alone is not permission to remove a worktree while a new attempt can register. Physical cleanup is the distinct reviewed pending qk0.2 family (source not yet implemented), with its fixed Installer capability and preserved evidence contract; qk0.1 cannot infer physical cleanup from display/child exit. Parent promotion must wait for that family, while independent qk0.1 readiness is reviewed separately; no private journal fallback, new unreviewed cleanup capability or snapshot-as-lock shortcut is accepted. This is a concrete remaining design boundary within qk0, not a new dependency or a delivered cleanup API.
