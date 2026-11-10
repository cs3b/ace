# TC-004: Scoped credentials, expiry and interrupted execution

Require real Forgejo access to the configured repository and rejection for a
second repository, using the same scoped token. Require command exit and
confirmed revoke after normal temporary-token execution; expired access must
refuse new execution. For interruption, match the PID and birth identity to the
executed command and inspect the existing lease record after public reconcile.
Unknown remote cleanup must remain visibly blocked. Do not infer revocation
from a missing local file or a process exit.

Ending a session must remove its private credential projection without revoking
a shared static project token. No daemon, systemd invocation ID, cgroup or
same-UID adversarial-isolation proof is required. Verify credentials are absent
from captured argv, prompts and reports. A synthetic provider is not Forgejo
acceptance.

Use `results/tc/04/state.json`, `sessions.json`, the actual command stdout/stderr
and exit captures. Missing or contradictory evidence fails the case. Record
unimplemented or unexecuted subcases as failures, never skipped successes.
