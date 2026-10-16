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
* Native ace-wake `/watch` persists a selected command and wakes its owning Pi
  session when the canonical observation changes. A wake is only a hint; reading
  the original project/assignment/attempt and successful finish CAS is adoption.

## Scope and ownership

1. Assign owns a generic ordinary driver over a supplied request transport. It
   retains immutable mutation requests and their exact upload bytes, downloads
   canonical snapshots, projects existing queue state and assembles attributable
   execution receipts. Retained input is not an execution ledger. No fallback to
   `.current`, a local assignment store, or protected authority is permitted.
2. Lab composes that driver with its installed OrdinaryOwnerConfig/client and
   exposes public start/status/step/result/adopt operations. Native worker start
   comes from the real model process ancestry, not the supervisor launcher.
3. Overseer exposes an explicit ordinary prepare/launch/status/resume path using
   WorktreeProvisioner, WindowOpener, PreparedWorkBuilder and the existing provider
   command builder. An immutable launch selection records project, task, scope,
   attempt, supervisor pane, worker pane, cwd and provider. A persisted pre-send
   intent prevents duplicate launches after crash or lost transport reply.
   Resume observes the original selection and continues its original driver;
   it never creates a replacement worker on uncertainty.
4. The existing assign/drive workflow branches explicitly for ordinary context
   before any local queue command. Public Lab commands perform canonical work;
   the model executes task instructions and supplies actual check/report bytes.
5. Callback is the existing native watch over canonical result status, targeted
   to the selected supervisor session. Watch output and stale/foreign hints do
   not authorize mutation. Persisted watch restoration and live consumption are
   installed acceptance gates, not inferred from a generated command.

## Inbox boundary

Current Inbox settlement verifies inbound records addressed to the worker. It
does not implement a result notification addressed to the supervisor. The
domain Pi queue client currently selects an ambient socket and cannot become
the UID966 authority transport by assumption. This slice uses native watches;
inbound Inbox remains unconfigured and nonempty references remain fail-closed.
No legacy transport record is imported, discarded or interpreted as this Inbox.

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
