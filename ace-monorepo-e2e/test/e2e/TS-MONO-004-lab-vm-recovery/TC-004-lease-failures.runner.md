# TC-004: Lease expiry and singleton issuer crash

Commission an isolated worker to validate its granted Forgejo access using public ace-lab auth request/status/exec/revoke. Observe a successful scoped operation and normal confirmed revocation. Separately test a one-minute lease expiry and kill the singleton issuer during an active authorized command; use host-only fault controls and preserve evidence before stopping sessions. Test that another isolated session cannot use that lease or read its secret. Restore the issuer through its installed recovery path before new requests.

Capture `results/tc/04/commands.stdout`, `commands.stderr`, `commands.exit`,
`state.json` and `sessions.json` as declared by the runner contract.
