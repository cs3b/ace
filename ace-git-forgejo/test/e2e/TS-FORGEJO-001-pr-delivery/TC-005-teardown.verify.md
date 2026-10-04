# TC-005 Verify — Teardown goal

### Goal 1 - Disposable server is recorded and removed

- **Verdict**: PASS only if `server-version.json` contains a Forgejo
  version at or above 8.0 (e.g. `8.0.3+gitea-1.22.0`), `teardown.exit` is
  0, and `teardown-ps.stdout` shows no `ace-e2e-forgejo` container.
