# TC-004: Lease expiry and singleton issuer crash

Commission an isolated worker to validate its granted Forgejo access using public
`ace-lab auth request/status/exec/revoke`. Observe a successful scoped operation
and normal confirmed revocation.

Test a one-minute lease expiry and an issuer crash with separate leases. Before
each fault, capture the lease ID, issuer invocation ID, worker unit and invocation
ID, and the populated execution cgroup for the active authorized command. For
the crash, also check that a different live isolated session cannot use the
issued lease or access its credential projection while the owner can use it.
Denial for an expired or already revoked lease alone cannot prove isolation.

Inject the crash through the operator channel with
`systemctl kill --kill-whom=main --signal=SIGKILL ace-lab-auth.service`.
Target only the main process so that systemd can run the installed
`ExecStopPost` cleanup. Capture the journal, execution cgroup and lease state
before restarting the issuer. Restore through the installed service and
verify that recovery settles old records before new requests. The launcher
binds session lifetimes to the issuer. If dependent units stop, capture their
state and resume the Overseers through public start before testing a fresh
session's access and denial. Keep any credential used to check Forgejo HTTP
status in the operator process only, outside argv, transcripts and artifacts.

Capture `results/tc/04/commands.stdout`, `commands.stderr`, `commands.exit`,
`state.json` and `sessions.json` as declared by the runner contract.
