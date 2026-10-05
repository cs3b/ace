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
