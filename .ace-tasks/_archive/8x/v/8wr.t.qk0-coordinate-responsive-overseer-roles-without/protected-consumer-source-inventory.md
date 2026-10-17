# Protected overseer consumer inventory

Source inspected at ACE `b50b5e3a35ff769cd4421a90f3aa0be6c8c62f43`. This is readiness input, not an approved implementation plan or a delivered capability. qk0 remains draft/needs_review. Existing SC1–SC3 own the changes; this report does not add hidden work outside that task.

## Maintained consumer paths

- `ace-overseer/lib/ace/overseer/cli/commands/work_on.rb`: the CLI still restricts runtime to tmux or legacy lab and forwards Work IDs to LabClient. The underlying runtime adapter work does not remove this distinct engine branch. Replace the branch with task/assignment plus stable project/agent selection and the reviewed original foreground-launch consumer.
- `cli/commands/{projects,agents}.rb`: use LabClient today; select the existing ace-lab topology service instead. Its public projection must remain the owner of visibility and stable IDs.
- `cli/commands/{prompt,stop,review,prepare}.rb`, `status.rb`, and `prune.rb`: legacy calls/Work-ID forms remain. Remove obsolete prepare/Work-ID interfaces and LabClient paths as specified; route prompt/stop through xz9.2 and review/prune through existing canonical owners. Neither local pane lookup nor terminal EOF proves protected completion.
- `molecules/lab_prune_safety_checker.rb` is solely the legacy adapter; deleting the Lab engine path must not delete or weaken `assignment_prune_safety_checker.rb` and the protected owner preservation/no-writers requirements.
- `molecules/worktree_context_collector.rb` discovers local assignment directories and uses local AttemptCoordinator recovery; `organisms/status_collector.rb` scans worktrees and subprocesses. These are not a protected cross-user inventory. Local behavior remains a separate supported mode, not a fallback when protected authority fails.
- `handbook/workflow-instructions/overseer.wf.md` and the matching command tests still document/exercise runtime=lab. Update the canonical workflow and fixtures together with code; do not preserve a forwarding shim.

## Concrete owner contract needed for status and restart

The current protected LaunchLifecycle exposes `inspect_launch` and `attempt_status` with mapping_id, assignment_id and attempt_id. No assignment inventory/discovery operation was found in maintained Client, Server, Router, LaunchLifecycle or Endcap. The consumer cannot recover a project-wide list merely by calling a known-attempt status route.

Before promoting qk0, specify and review an authorized, bounded read-only enumeration projection from the existing Assign authority and its canonical journal. It must identify original mapping/assignment/attempt references and the selected journal revision without requiring private journal access, a persistent second ledger, or a remembered launcher PID. Producer authorization must use the current mapped peer and selected project/authority, with explicit pagination/size bounds and unavailable/unknown behavior. Detailed attempt state remains owned by the existing status API. The review must settle how task and active-step references join the accepted assignment definition, and how a concurrent journal change is represented rather than silently mixing revisions.

This is part of qk0's existing status/restart integration requirements, not a reason to broaden or delay xz9.2's prompt/stop delivery. Its final implementation belongs in the Assign owner plus the Overseer consumer, with controlled genuine canonical-journal fixtures. No task status or acceptance checkbox is changed by this inventory.

## Verification boundary

Research only: source searches and direct reads. No test or installed acceptance is claimed. Required future source cases include restart with no local assignment cache, authorized inventory, cross-project/role refusal, bounded enumeration, changed revision, unknown authority and no private-directory fallback. Installed native/OS-user acceptance remains solely in lab-config:gad.2.

Independent source check (`wave_n0n`, Sol 6.1): agrees with the inventory gap. Maintained Endcap operations, Router, Client and LaunchLifecycle contain no enumeration route; registration_status also needs an already known assignment. This report correctly leaves the missing consumer/owner contract in qk0 and adds no gate to xz9.2.
