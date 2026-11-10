# Building the selected native Herdr

`ace-herdr native-source selection` reports the source commit, tree and patch
digest packaged with this gem. The patch retains ordinary prompt/terminal
identity fixes and adds explicit process environments. It does not install an
issuer, systemd session launcher or separate operating-system identity.

Build with the public owner command:

```sh
ace-herdr native-source build --source /absolute/clean/herdr-checkout \
  --output /absolute/new/artifact-directory --target aarch64-unknown-linux-musl
ace-herdr native-source verify --artifact /absolute/new/artifact-directory
```

The build runs as a nonroot user on Linux or macOS. Install the selected Rust
toolchain, its target standard library, and the selected Zig version first.
Use actual tool executables in `PATH`, rather than shims which resolve another
version. The packaged linker invokes that same pinned Zig for the selected
Linux target; a VM and a separate cross compiler are unnecessary. Output
contains the ELF executable and its source/toolchain/byte provenance. A failed
build retains its output directory for diagnosis and never overwrites it.

The selected native CLI accepts `herdr agent start … --env-file /absolute/env.json`.
The file must be a regular, non-symlink file owned by the process user with mode
`0600`, containing a JSON object of environment variable names and string values.
The ordinary child process receives that environment, plus native terminal
identity (`HERDR_*` pane/workspace/socket fields and the ACE pane/session aliases).
Ambient credentials are cleared. File contents are never submitted to the
terminal or returned in the start response. The caller removes the file after
startup returns. With `ACE_SESSION_CREDENTIALS_DIRECTORY` equal to
`PI_CODING_AGENT_DIR`, a same-user `0700` directory named `ace-session-*`, the
ordinary helper waits for the child and removes only `auth.json` on exit or
failed startup. Session evidence remains. TERM/HUP are forwarded to the child;
terminal Ctrl-C reaches its existing foreground process group. An uncatchable
kill can leave credentials behind, so the assignment/coordinator owner must
reconcile them before replacing a dead session. This is cleanup between trusted
processes, not isolation between hostile processes sharing the same user.

Cold server restoration keeps such a pane visibly unavailable until its
coordinator supplies a fresh environment. It never resumes an agent through
an ambient shell. Live terminal handoff preserves the already-running process.

Host tests and a cross-built ELF do not establish live ARM64 lab acceptance.
