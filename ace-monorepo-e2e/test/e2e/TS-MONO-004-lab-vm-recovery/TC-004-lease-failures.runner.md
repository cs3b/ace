# TC-004: Lease expiry and singleton issuer crash

Commission an isolated worker to validate its granted Forgejo access using public
`ace-lab auth request/status/exec/revoke`. Observe a successful scoped operation
and normal confirmed revocation.

Test a one-minute lease expiry and an issuer crash with separate leases. For the
crash, use a second live isolated session to check that the issued lease's
credential projection is unreadable and that `ace-lab auth exec` refuses the
different principal. Capture this refusal while the lease is live and unused.
Confirm that it remains issued, then start the authorized command as the owner.
Before each fault, capture the lease ID, issuer invocation ID, worker unit and
invocation ID, and the populated execution cgroup for the active command.

Run the host-only lease evidence probe once for each active lease, with
`expiry` or `crash` and its exact lease ID. The helper checks live Forgejo
access and the populated execution cgroup, then waits for expiry or sends
SIGKILL only to the issuer's main process. It proves that the same
credential is rejected afterwards. Start the crash probe with more than
95 seconds remaining on the active lease so natural expiry cannot explain
the cleanup. Use the invocation in the lab VM README
and capture both JSON records and the probe exit status. In crash mode this
is the fault injection itself. Capture the installed `ExecStopPost` journal,
execution cgroup and lease state before restarting the issuer.
Restore through the installed service and
verify that recovery settles old records before new requests. The launcher
binds session lifetimes to the issuer. If dependent units stop, capture their
state and resume the Overseers through public start before testing a fresh
session's access and denial. Never read the credential in the runner.

Capture `results/tc/04/commands.stdout`, `commands.stderr`, `commands.exit`,
`state.json` and `sessions.json` as declared by the runner contract.
