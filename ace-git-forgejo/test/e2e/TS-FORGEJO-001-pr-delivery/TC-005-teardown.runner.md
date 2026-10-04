# TC-005 — Disposable server teardown

## Goal

1. Record the server version one last time:
   `curl -s $FORGEJO_URL/api/v1/version` → `server-version.json`
   (expected: a Forgejo release at or above 8.0, the documented
   capability floor).
2. Stop and remove the disposable server:
   `docker rm -f ace-e2e-forgejo` → save exit to `teardown.exit`.
3. Confirm it is gone: `docker ps -a | grep ace-e2e-forgejo` → save to
   `teardown-ps.stdout` (expected: no matching line; empty output).
