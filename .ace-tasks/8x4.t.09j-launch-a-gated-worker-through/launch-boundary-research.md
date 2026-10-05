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
parent-control-pipe wording was unresolved at that probe; the subsequent Selected
native gate contract supersedes it with an authority-connected socket gate.

## Native gate primitives executed in isolated Docker

`evidence/native-gate-primitives.json` retains three actual Herdr v0.9.3 cases:
EOF before release exits with empty payload counter; exact release increments
once, followed by pane.close and pidfd exit; pane.close while gated exits without
another counter increment. The root-owned compiled C fixture set non-dumpable,
connected from UID13001 to authority-owned socket UID13003 and compared kernel
peer PID with launcher UID13002 native process_info. Authority operations were
fixture root process orchestration (listener process UID0, socket owner UID13003),
not an actual UID13003 receiver or product qjl integration. No host credentials/socket
mount or user's Herdr/TUI was used. Disposable fixture root installed principals;
launcher calls never switched UID. Scratch fixture sources remain in the owned
worktree .ace-local/gate-probe and are not product implementation.

The Docker kernel reports Yama=0. We did not modify host sysctls. Thus this probe
cannot attest hostile-worker isolation. Selected protected deployment requires
Yama=2 and capability bounds plus installer-pinned server birth; same UID alone
cannot establish trusted server or bootstrap readiness. Exact stream credentials
prove process identity, not executable trust. Kernel documentation supports the
selected deployment policy; an actual enforced-policy adversarial fixture is
required before protected acceptance.

Sources: [Yama kernel documentation](https://www.kernel.org/doc/html/latest/admin-guide/LSM/Yama.html),
[Unix peer credentials](https://man7.org/linux/man-pages/man7/unix.7.html),
[non-dumpable process protection](https://www.man7.org/linux/man-pages/man2/PR_SET_DUMPABLE.2const.html),
[pidfd exact exit observation](https://man7.org/linux/man-pages/man2/pidfd_open.2.html).
