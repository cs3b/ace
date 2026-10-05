# Read-only launch boundary evidence — 2026-10-05

Inspected source, not executed multi-UID acceptance:

- lab-config/herdr-lab-overseer@.service runs User=lab-overseer-%i, owns XDG_RUNTIME_DIR=/run/lab-overseer-%i and sets NoNewPrivileges=true. Panes execute directly as that account.
- lab-config/lab.py project_herdr_argv (line 437 at inspection) permits root via runuser or exact scoped user; refuses other UIDs and says another user cannot reach the scoped socket. This wrapper is not the desired unprivileged launcher transport.
- ACE Herdr RuntimeAdapter composes CLI control and exact process/native observations. HerdrExecutor currently selects a binary, without a protected cross-user endpoint/authentication map.
- Legacy labd uses setuid/runuser and is being removed; it cannot provide this prerequisite.

Root supplied upstream Herdr v0.9.3 research. [Native server](https://raw.githubusercontent.com/herdrdev/herdr/v0.9.3/src/api/server.rs)
creates a socket restricted to 0600 and dispatches accepted streams without a
peer-UID role allowlist. [IPC](https://raw.githubusercontent.com/herdrdev/herdr/v0.9.3/src/ipc.rs)
uses UnixStream. Client supports explicit HERDR_SOCKET_PATH; layout.apply accepts
fixed command argv, and pane.process_info reports process IDs. Root cached exact
source in primary .ace-local/lab-readiness/herdr-source/. This is capability
research only; no installed cross-UID authenticated gated-child proof exists.

Candidate A is deployment-reapplied narrow Herdr socket-connect/traverse ACL plus
root-installed fixed map, kernel peer UID/inode/native-birth verification and
fixed gated argv. Candidate B is supported saved-machine SSH or standard OS
authentication. Neither is selected until bounded actual capability evidence and
independent review. ACL alone is not native authentication or gate proof; socket
restart resets 0600, so installer reapplication is part of the contract.

Worker controls its account processes but cannot mutate separate authority qjl
or use launcher-role reserve/register APIs. Role UID collapse is prohibited.
Drafting host is UID 504; sudo -n true needs a password. Same-UID fixtures or
mocked identity cannot satisfy positive launch proof. Root owns Lab access and
installation; this worker ran no Lab SSH/deployment action.

## Executed isolated Linux native capability

Selected transport: per-worker Herdr v0.9.3 Unix socket with deployment-scoped
connect/traverse ACL. Evidence/herdr-cross-uid-observation.json retains kernel
peer PID3407/UID13001, launcher UID13002, PermissionError before ACL and after
revocation, fixed /bin/sleep argv native pane w1:p2, and launcher's own /proc
child PID3436/UID13001/parent3407/birth379484204. Binary provenance and SHA256
are retained in evidence/binary-proof.json. Root executed an isolated disposable
Docker fixture; fixture root only established deployment/test principals. The
launcher used no UID-switch helper or new daemon.

This supersedes the earlier absence of a retained cross-UID probe above. It
selects the native ACL transport; saved-machine SSH is unchosen. It proves no
actual gate/release, authority qjl transaction, restart ACL reapplication, lost
reply safety, macOS support, or installed Lab deployment. The existing inherited
parent-control-pipe wording needs an explicit remote-native bootstrap channel
decision in independent review; native socket access alone cannot supply it.
