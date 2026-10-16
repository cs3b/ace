# Ordinary execution entry and driver

Source baseline: `31c386ecd`; source-only implementation, no installation or
program completion claim. The installed native-session mismatch is addressed by
that separately reviewed baseline.

## Existing public contracts

* Lab `assignment prepare/request` retains immutable PreparedWork and mutation
  input; installed OrdinaryLifecycle alone registers, starts, advances and accepts
  results through the canonical execution ref. It never starts a model process.
* Overseer WorktreeProvisioner and WindowOpener own existing worktree/window
  preparation. `work-on --project` remains explicitly protected. The local path
  and its cache cannot provide ordinary execution state.
* Assign OrdinaryQueue reuses QueueScanner/AssignmentExecutor over authenticated
  canonical snapshots. Start/progress/result require the actual original native
  worker. Supervisor finish reads the exact submitted result and reobserves that
  worker before terminal CAS.
* Herdr RuntimeAdapter and LLM InteractiveCommandBuilder already own native pane
  handoff and provider invocation. Dispatch acceptance is not process start.
* Native ace-wake `/watch --path` persists a selected existing file path and wakes
  its owning Pi session when a result hint changes. A wake is only a hint; reading
  the original project/assignment/attempt and successful finish CAS is adoption.

## Scope and ownership

1. Assign owns a generic ordinary driver over a supplied request transport. It
   retains immutable mutation requests and their exact upload bytes, downloads
   canonical snapshots, projects existing queue state and transfers attributable
   execution receipts. Retained input is not an execution ledger. No fallback to
   `.current`, a local assignment store, or protected authority is permitted.
2. Lab composes that driver with its installed OrdinaryOwnerConfig/client and
   exposes public start/status/step/result/adopt operations. Native worker start
   comes from the real model process ancestry, not the supervisor launcher.
3. Overseer exposes an explicit ordinary prepare/launch/status/resume path using
   WorktreeProvisioner, WindowOpener, PreparedWorkBuilder and the existing provider
   command builder. An immutable launch selection records project, task, scope,
   attempt, supervisor pane, worker pane, cwd and provider. Explicit preparation checkout is verified against the installed
   common directory; project configuration and provisioning run there, not in
   the unrelated native coordinator cwd. A persisted pre-send
   intent prevents duplicate launches after crash or lost transport reply.
   Resume observes the original selection and continues its original driver;
   it never creates a replacement worker on uncertainty.
4. The existing assign/drive workflow branches explicitly for ordinary context
   before any local queue command. Public Lab commands perform canonical work;
   the model executes task instructions and supplies actual check/report bytes.
5. Callback is the existing native watch over a nonauthoritative result hint, targeted
   to the selected supervisor session. Watch output and stale/foreign hints do
   not authorize mutation. The worker writes the hint only after canonical result
   submission is acknowledged; a lost signal/reply is recovered by the existing
   progress-audit600 and read-only resume. The owner always reads canonical status,
   never the hint contents. Persisted watch restoration and live consumption are
   installed acceptance gates, not inferred from a generated command.

## Inbox boundary

Current Inbox settlement verifies inbound records addressed to the worker. It
does not implement a result notification addressed to the supervisor. The
domain Pi queue client currently selects an ambient socket and cannot become
the UID966 authority transport by assumption. This slice uses native watches;
inbound Inbox remains unconfigured and nonempty references remain fail-closed.
No legacy transport record is imported, discarded or interpreted as this Inbox.

## Explicit coordinator replacement

The owner-service restart preserves its journal; replacing the actual Pi
coordinator additionally requires canonical `adopt_supervisor`. The new caller
must be a real coordinator in the installed project's native placement. Compare
the original supervisor binding digest and definition-chain generation, positively
observe the old process generation as ended (kernel ESRCH or a different exact
birth at that PID), and CAS old→new binding in the same canonical journal. An
inaccessible observation, EPERM, host mismatch or malformed identity stays
unknown; a still-live old generation refuses adoption. Recheck actual new caller
and old-generation evidence at acceptance. Do not alter worker attempts, pending
requests, accepted results or dispatch intents. Old-supervisor finish/replay
refuses after adoption; repeated adoption requests replay their original result.

The supervisor reads explicit current owner status before adoption and before
terminal finish. Native watch restoration is tied to the resumed Pi session;
its hint does not authorize owner replacement. Tests include a real old process
that exits/reaps, new coordinator adoption, live/unknown/wrong-project refusal,
stale generation and lost adoption reply with original IDs.

## Verification

Focused tests cover two independent retained selections, exact request replay,
lost start/progress/result/finish replies, canonical queue projection, wrong
project/attempt/pane/result refusal, stale generation, result-before-terminal
distinction, no second launch after uncertain send, and provider/cwd fidelity.
Exercise real OrdinaryLifecycle with actual canonical journal CAS in integration
tests; mock external model/pane effects only at their existing boundary.
Run affected packages with bin/ace-test, then required bin/ace-test-suite and
obtain independent verdict. Deployment and exact package cuts are separate.

Installed acceptance later: two fresh w1 native workers in selected ACE
worktrees; actual start receipts; queue/report/result submission; consumed wake
and supervisor adoption; restart/repeated wake with original IDs; two serial
reviewed merges. Keep each worker alive until finish reobserves its binding.
Historical unknown attempts and w6 legacy execution remain untouched.

## Review F1: reconcile refused generation before new result/finish input

Independent Pi review of c5e43d391 identified retained-request key poisoning: a real canonical generation advance before acceptance leaves constant result / supervisor-only finish keys tied to the refused generation. Record this correction before implementation. Result input keys must include attempted generation; finish keys must include supervisor and attempt generations. Original bytes and mutation IDs remain immutable. Before result retry, canonical status distinguishes an accepted result (replay exact original retained request, including after lost acknowledgment) from a still-running attempt with no result at a later generation (old CAS can no longer accept; permit separate input at the observed generation). Unknown status never authorizes another mutation. Test actual Unix/Git CAS races for result and finish, original-byte retention, accepted lost-ACK replay with newer observed generation, and no second result/start.
