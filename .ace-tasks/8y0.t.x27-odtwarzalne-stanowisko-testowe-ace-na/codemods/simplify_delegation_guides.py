"""Replace superseded OS-session launch instructions at their owners."""
from pathlib import Path
p=Path('ace-overseer/handbook/workflow-instructions/overseer/start.wf.md');s=p.read_text()
a=s.index('### Launching an isolated coworker');b=s.index('For delivery from a forge issue',a)
s=s[:a]+'''### Launching a coworker

Use `ace-overseer work-on --task <project-task> --runtime herdr` for a new
ordinary delivery sequence. It prepares the worktree and role assignments,
validates the brief, starts the actual worker and records its native identity.
For an already prepared sequence (including bootstrap), use
`ace-overseer handoff --task <project-task> --runtime herdr`. Without
`--dry-run`, handoff starts the next eligible role; the returned execution
binding is evidence of a start, not merely an opened window.

The environment is prepared from the installed runtime and the selected
project/role credential source. A role has its own process and worktree;
OS users, systemd units and an authorization service are not prerequisites.
`ace-coworker start` still renders a brief; do not mistake its output for a
running agent or write a second launch script around it.

Record returned assignment, worktree, terminal and role on the matching
private coordination step, then END THE TURN. Eyes observes the result.
On replay, reconcile the recorded execution. An uncertain launch blocks a new
start; never invent another name to bypass it. A missing observer, runtime or
credential source is a concrete blocker to report, not a repair for you to do.

After accepting the worker report, `process-reports` retires that executor
and uses the same handoff operation for independent review, then integration.
Executed tests and independent review must bind to the current candidate HEAD.

'''+s[b:]
s=s.replace('expected worktree and isolated role', 'expected worktree and recorded role').replace('for all isolated recovery', 'for recovery')
a=s.index('## Session-scoped forge access')
s=s[:a]+'''## Project-scoped forge access

The session starts with the selected project's read or role credential in its
environment or private provider config. Use that configured forge normally.
Continuous observation needs a read credential valid for the observer's
lifetime. An unavailable login is a visible configuration blocker; do not
read host administrator credentials or invent another login method.

When the deployment explicitly configures a temporary credential provider,
use the existing `ace-lab auth request/status/exec/revoke` procedure. These
commands run locally; they do not depend on a service. Request only the named
repository and role. `auth exec` gives its child the credential and reports
execution and cleanup separately. An unconfirmed revoke remains unresolved.
Static shared project credentials are not revoked when one worker exits.

Pass repository, role, scope and acceptance criteria in the commission,
never tokens. Workers implement, reviewers independently review, and
integrators merge; the coordinator never borrows those roles to do their work.
'''
p.write_text(s)
p=Path('ace-overseer/handbook/workflow-instructions/overseer/bootstrap-delegation.wf.md');s=p.read_text()
s=s.replace('The isolated bootstrap uses', 'Bootstrap uses').replace("an address, not a writable directory in the executor's mount", 'a report address, not permission to edit the coordinator\'s private tasks')
a=s.index('`ace-coworker start --config <returned-path>`');b=s.index('## Receive, verify, start',a)
s=s[:a]+'''`ace-coworker start --config <returned-path>` validates and prints a brief.
Launch the first prepared leg with `ace-overseer handoff --task <executable-task>
--runtime herdr` from the target project. This operation starts the actual
process in the returned worktree with the role's explicit environment and
records its native identity on the existing commission. No prompt file,
service setup or shell workaround is needed from the coordinator.

Record the returned terminal and assignment on the matching private step.
End the turn with eyes armed. A repeated command reuses recorded work or
reports an explicit blocker; an uncertain start must not be bypassed by
another dispatch. Worker or observation failure is delegated/escalated,
never repaired by the Lab Overseer.

'''+s[b:]
a=s.index('From the target project root, use `ace-overseer handoff --dry-run');b=s.index('Only after accepted worker completion',a)
s=s[:a]+'''After accepting the worker's report, use `ace-overseer process-reports` to
retire its recorded executor and continue the prepared sequence. If accepting
manually, preserve the exact report and assignment identity before invoking
`ace-overseer handoff --task <task> --runtime herdr` for the verifier.
Do not launch a second executor while a predecessor is active or unknown.
Repeated reports reconcile the same commission; they do not repeat the work.

'''+s[b:]
s=s.replace("command's authenticated readiness result", "command's native-session readiness result").replace("matching isolated session's", "matching session's")
p.write_text(s)
p=Path('ace-overseer/handbook/workflow-instructions/overseer/lab-start.wf.md');s=p.read_text().replace('starts an isolated Pi session through native Herdr', 'starts an ordinary Pi process with an explicit environment through native Herdr');p.write_text(s)
p=Path('ace-coworker/handbook/workflow-instructions/coworker/integrator.wf.md');s=p.read_text().replace('Inside the ACE repository itself, invoke every tool as `bin/ace-*` (the\n  binstubs pin the checkout\'s bundle).', 'In ACE development mode, use `bin/ace-*`. With `ACE_TOOLCHAIN=installed`,\n  use installed commands and packaged instructions even inside an ACE checkout.');p.write_text(s)
p=Path('ace-coworker/handbook/workflow-instructions/coworker/worker.wf.md');s=p.read_text().replace('test for every changed package passes (or the task\'s monorepo gate passes),', 'test declared by the task passes. When the task does not specify checks,\nrun each changed package\'s required suite (or its monorepo gate),');p.write_text(s)
p=Path('ace-overseer/docs/usage.md');s=p.read_text();a=s.index('  In an isolated lab session');b=s.index('- A repeated delivery',a);s=s[:a]+'''  With the Herdr backend, work-on and handoff start the actual executor with
  an explicit environment and record its identity on the coworker commission.
  Accepted reports retire that executor before continuation. A completed role
  sequence does not close pending coordination steps. No authorization daemon
  or isolated operating-system session is required.
'''+s[b:];p.write_text(s)
