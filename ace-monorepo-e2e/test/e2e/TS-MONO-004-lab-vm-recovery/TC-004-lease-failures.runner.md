# TC-004: Scoped credentials, expiry and interrupted execution

Use a separate disposable Forgejo token limited to `e2e-integrator/ace`,
with profile `e2e-probe` and the worker role. Run these commands as
`lab-operator` through the existing operator SSH channel, using installed
`/opt/ace/runtime/bin/ace-lab` and `ACE_TOOLCHAIN=installed`. The operator
profile is deliberately unavailable to agent role sessions. Exercise the installed public `ace-lab auth`
request/status/exec/revoke/reconcile commands using the configured local
credential source. The source is supplied by fixture setup, not by an agent
requesting root privileges. No issuer daemon or systemd session is involved.

Capture the lease ID, actual command PID and its birth identity, repository,
role, deadline and public status, without token values. Verify access to the
intended repository and denial for `e2e-integrator/unrelated` (the second private fixture repository) before any
fault. Scope is enforced by Forgejo, not by trusting the session environment.

Use distinct leases for: normal completion, expiry before exec, and interrupted
execution. After normal completion require token rejection and removed private
projection files. Expired access must refuse a new command. Interrupt only the
identified execution process; inspect its actual descendant exit and use public
reconcile for interrupted records. An unconfirmed revoke must remain blocked,
not be reported as cleared. Record what happens on actual process interruption;
do not claim guaranteed crash cleanup without evidence.

Static project tokens used to start agents are a separate fixture credential:
ending a session removes its private projection but must not revoke the shared
static token. Do not test same-UID malicious-agent isolation or expect another
trusted process to be unable to read every file owned by that same user.

Capture `results/tc/04/commands.stdout`, `commands.stderr`, `commands.exit`,
`state.json` and `sessions.json`. No token may occur in these artifacts, argv or
prompts. Restore all faults before continuing. Provider mocks and component
probes cannot substitute for the real Forgejo checks.
