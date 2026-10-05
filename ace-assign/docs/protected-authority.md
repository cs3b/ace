# Protected native launch

`ace-assign authority serve --authority AUTHORITY` runs the standalone launch
composition. `ace-lab authority serve` supplies the separately implemented service
composition using the same Assign server, router, lifecycle, journal and endpoint.
The installed `composition` must match the entrypoint. A project has exactly one
configured authority owner; duplicate project owners or endpoints fail before
listener creation.

An administrator provisions `/etc/ace/assignment-authorities.json`. There is no
caller-selected configuration path or local fallback. The outer object contains
`schema: "ace.assign.authorities/v1"`, `authorities`, `projects`, and
`launch_mappings`; unknown fields are refused. The fixed schema is implemented
by `Ace::Assign::Authority::Deployment`:

| Installed object | Required fields |
| --- | --- |
| `authorities.ID` | `uid`, `gid`, sorted unique `groups`, `socket_path`, `state_root`, `composition` (`launch` or `services`) |
| `projects.ID` | `journal_repository`, `evidence_git_ref` (`refs/ace/execution`), `evidence_checkout_root`, `assignment_root`, `candidate_root`, `launcher_uids`, `reviewer_uids`, `worker_uids`, `service_executor_uids`, `supervisor_uids`, `peer_credentials` |
| `projects.ID.peer_credentials.UID` | `gid`, sorted unique `groups`, `scratch_root`; every configured role UID has one fixed entry |
| `launch_mappings.ID` | `project_id`, `authority_id`, `launcher_uid`, `launcher_gid`, `launcher_groups`, `worker_uid`, `worker_gid`, `worker_groups`, `worker_actor`, `worker_cwd`, `worker_argv`, `worker_env`, `bootstrap`, `bootstrap_sha256`, `native` |
| `launch_mappings.ID.native` | `socket_path`, `socket_identity`, `executable`, `version` (`0.9.3`), `server_identity` |

All paths are canonical and absolute. The native socket identity is the observed
`[device, inode, worker_uid]`. The server identity is the exact observed object
`{pid, uid, gid, groups, parent_pid, started_at, host}`, where `started_at` is
`linux:BOOT_ID:START_TICKS`. These observations must be made after the root-owned
native service starts; they cannot be invented, copied from a previous boot, or
supplied by a worker. An endpoint/server restart requires installer repinning.
The root-installed native service, its executable, environment and configuration
are trusted. Merely running arbitrary worker-supplied server code under the worker
account does not meet this deployment contract.

The authority, launcher and worker are distinct non-root accounts. Authority
journal/cache/import/candidate/assignment/state roots are authority-owned 0700
with protected ancestry. Peer scratch roots are private to their mapped account.
The authority socket's directory prevents worker/launcher replacement; its group
and narrow installer ACL must permit the configured peers to connect. Native
socket ACL permits the trusted launcher to use the pinned Herdr API. The
bootstrap, payload executable, native executable, mapping and their ancestors are
root-owned and non-writable by the worker. Payload argv/cwd/environment are fixed
installed data; loader and interpreter injection environment fields are refused.

Linux Yama `ptrace_scope=2`, empty Inh/Prm/Eff/Bnd/Amb capabilities,
`NoNewPrivs=1`, fixed real/effective/saved/filesystem UID/GID and supplementary
groups are mandatory for every participant, including the pinned native server.
The shipped [native build/install instructions](../../ace-runtime/native/README.md)
describe architecture, distro dependencies, immutable artifact digest and service
unit requirements. ACE verifies and refuses missing policy; it does not modify
sysctls, create accounts, change another user's Herdr, or install service policy.

After installation, the trusted launcher preflights without any mutation or
native creation:

```sh
ace-assign authority launch --mapping MAPPING --dry-run
```

Launch one managed definition using a stable invocation ID:

```sh
ace-assign authority launch --mapping MAPPING --assignment ASSIGNMENT \
  --definition /absolute/managed-definition.json --step 010 \
  --base-head EXACT_40_CHARACTER_COMMIT --mutation INVOCATION_ID
```

The definition is a normal managed assignment JSON document (maximum 32 KiB),
with matching `session_id`, `task_id` and installed `project_id`. The authority
stores its exact immutable bytes in the canonical journal and materializes the
owner-private assignment cache from that accepted blob. An active attempt blocks
changed definitions. Reservation creates an intent only. An unequivocally fresh
CAS response alone permits one fresh native layout creation; replay and lost
responses never permit another spawn.

The original authenticated native layout response fixes workspace/tab/pane and
exact child lineage. Record captures that original child; bind creates the running
attempt without payload permission. The immutable native bootstrap connects once,
sets non-dumpable before admission, and waits for the separate release. Release
commits issuance before one framed permission. Replay returns canonical issuance
without sending another frame. Reply loss after issuance is potentially executed.
A worker-controlled native input/close path can deny or interrupt launch, but cannot
replace the authenticated origin or forge authority release.

Inspect or request exact native termination through the same installed mapping.
Once the original launcher process has exited, run these commands as a mapped
recovery supervisor with the installed native close ACL; a new process under the
launcher UID does not inherit the original launcher incarnation:

```sh
ace-assign authority status --mapping MAPPING --assignment ASSIGNMENT --attempt ATTEMPT
ace-assign authority terminate --mapping MAPPING --assignment ASSIGNMENT --attempt ATTEMPT
```

Positive pre-release abort requires the authority's exact acquired child pidfd to
prove exit of the immutable gate and canonical absence of issued permission. Native
`pane.close`, disappearance, response loss, launcher death, PID reuse, or an already
issued child's exit alone cannot prove no surviving writer. Uncertain attempts keep
scope ownership for explicit protected recovery. Authority restart cannot recreate
lost creation permission or readmit a reconnecting gate.

Control replies are at most 16 KiB. Source-selected service transfer operations use
a 16 KiB authenticated header followed by bounded raw bytes, a shared 30-second
deadline, exact hashes, upload write-EOF and at most two active transfers. Exact
origin/role admission happens before private spool allocation and is revalidated
before canonical mutation. The standalone launch composition exposes no transfer
operations.

Source tests and Linux primitive fixtures are separate from installed deployment
acceptance. A Docker kernel with Yama=0 is expected to refuse the product gate;
it does not establish the required positive protected launch proof.
