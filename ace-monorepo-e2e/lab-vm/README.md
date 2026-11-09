# Disposable UTM lab fixture

This directory contains the versioned inputs for an ARM64 Linux test machine.
It is not a production lab. The UTM disk packages, SSH key and evidence are
kept under the worktree's gitignored `.ace-local/lab-vm`; exports may contain
credentials from a run and must remain private.

On an Apple Silicon host with UTM installed, from the repository worktree:

```sh
ace-monorepo-e2e/bin/lab-vm prepare
ace-monorepo-e2e/bin/lab-vm status
ace-monorepo-e2e/bin/lab-vm reset
ace-monorepo-e2e/bin/lab-vm prepare --rebuild-base
ace-monorepo-e2e/bin/lab-vm destroy
```

The first `prepare` downloads the pinned Debian image and creates and cleans a
base VM; `reset` creates a working clone. The base contains an SSH operator and
QEMU guest agent but no ACE or provider credentials. `reset` exports and
verifies the existing working VM before deleting its registered identity and
cloning the frozen base; the export is retained locally for diagnostics.
`--rebuild-base` also exports the prior base. `destroy` removes only registered
VMs whose UUID and name match the private state file. Before removal, UTM
exports the stopped VM to a fresh directory under the worktree's private
evidence path. The helper verifies the exported identity and self-contained
disks, records the full package fingerprint, then rechecks the stopped
registration. It retains verified exports. Lifecycle operations hold a
single-writer lock.

UTM owns the original package path. The helper uses UTM's registered identity
and verifies the location and contents of the export in the worktree. It
does not read UTM's protected App Data directory. The first AppleScript
invocation may still need macOS Automation consent for UTM.
Provisioning requires at least 25 GiB of free host disk.

`bin/lab-vm-artifacts` downloads the release manifest's public gem, Ruby, Node,
Zig and Rust bootstrap archives and rejects any checksum mismatch. The Pi npm
lockfile pins its dependency graph and integrity hashes. Locally built test
gems are rebuilt from the manifest's exact commits by `bin/lab-vm-build-gem`
and must match their pinned hashes; they are never published. The operational
gem repository is populated only from manifest entries, not every cached gem.
Bootstrap installs only the installer/index-tool closure from exact archives,
including transitive prereleases, without network resolution. RubyGems supplies
a dependency-first plan for every manifest pin; cycles and invalid pins fail
before installation. `ace-lab install` installs the remaining packages and
`ace-lab verify` checks the operational set. A fresh process checks every pinned activation.
System dependencies use the manifest's Debian snapshot and retain APT signature
and package checksum checks. Index refresh and archive download each get at most
three fresh APT processes on acquisition failure, with internal APT retries
disabled to avoid the Debian 3.0.3 delayed-retry warning accumulation. Installation
runs once, with network downloads disabled, only after acquisition succeeds.
Exhaustion fails setup and preserves the VM; it never blesses partial indexes.
These retries do not change snapshot pins or bypass verification.

`bin/lab-vm-runtime provision` starts a fresh work clone, verifies its SSH host key via the QEMU
guest agent, copies these inputs and invokes the guest-side runtime installer
and unprivileged native Herdr build. The pinned ARM64 Herdr binary and its
provenance can be reused from a private local artifact cache; both hashes and
`ace-herdr native-source verify` are checked before use. If the cache is
absent, the same source build is performed and must match the pinned hashes
before being cached. A corrupted, stale or partially present cache blocks provisioning.
The cache is `.ace-local/lab-vm/artifacts/herdr-native`; after changing the pinned
Herdr build, move the old cache aside so the next build can establish the new
artifact, and retain it if it is needed as evidence.
This provisioning path is still being validated. It does not configure Pi credentials, create a Forgejo fixture or
run an E2E scenario. Downloaded inputs or successful provisioning alone are not
proof that ACE is operational.

For an actual run, `bin/lab-vm-forgejo create` installs the pinned ARM64
Forgejo and `fj` client in the working VM, starts Forgejo on guest loopback,
and seeds a private repository and four issues from the committed ACE revision.
The fixture omits the source repository's historical `.ace-tasks` backlog so
that the project Overseer receives only the disposable test commissions.
It records the excluded path, source and initial commits, VM identity, hashes
and issue URLs under a private run directory. Forgejo's signing key and detached release
signature are verified; the client archive is pinned by the SHA-256 of the
official release download. No GitHub issue, pull request, or credential is
used; the separately pinned public Herdr source is fetched for its native build.
This new fixture path still requires live validation, including the delivery
of distinct, short-lived worker and reviewer credentials.
`bin/lab-vm-fixture prepare RUN_ID` is the working-VM input setup: it seeds
`/lab` and `/lab/ace`, configures local observation input, and copies only the
host's `zai` Pi credential into the working VM. It checks that the installed
runtime and native Herdr are already present and does not start the overseer.
Before starting agents, the fixture installs the pinned Herdr binary's own Pi
integration and checks its status as `mo`; this supplies Herdr with Pi lifecycle
and session identity reports. Operational gems and extensions remain root-owned;
provider credentials live only in `/etc/lab/ace-lab/pi-auth.json` (0600).
The protected deployment selects roles, runtime and per-session grants. Public
`ace-lab install` converges the singleton issuer; `ace-lab verify` checks it.
No credentials are placed in mo's Pi home or a base image.

The seeded ACE revision has no project Overseer start/eyes configuration. That
is the repair goal. Both scopes already have valid local HITL routes; the
project contains no route to Hermes or another lab. Project tasks, assignments,
reports and worktrees remain inside `/lab/ace`; lab coordination is private to
`/lab/.ace-tasks/_overseer`.

`bin/lab-vm-lab-start RUN_ID` starts the headless Herdr server and calls public
`ace-overseer start --scope lab --format json`. Product code owns workspace
selection and isolated session admission. The helper sends one high-level
bootstrap goal to the returned terminal and records the acknowledgement.
It never creates the overseer's tasks, dispatches workers or marks readiness.
Local operator replies use `ace-hitl reply CASE --stdin` in the case owner's
scope. An attempted start is never blindly repeated; inspect the retained
receipt and VM, or reset for a new run. A prompt acknowledgement is not
successful delegation, first-turn readiness or acceptance.

The intended acceptance is a full autonomous cycle: a lab Overseer delegates
the project bootstrap, then the project Overseer independently orders and
delegates multiple issues in the VM's isolated Forgejo repository, obtains review,
merges their tested PRs in dependency order, and leaves the release queued. A
second run after reset and the restart, idempotency, idle and failure checks
are required before calling the environment accepted.

`probe-issuer-cleanup.py` is a narrower diagnostic for an already installed
candidate in a disposable Linux working VM. Run it as root in the guest,
passing its Ruby executable, candidate gem home, shared dependency gem path,
and exact candidate version. It creates its own temporary systemd unit and
synthetic provider, kills the unit's main process, and checks the installed
cleanup entry point, lease record and handoff removal. For example:

```sh
python3 probe-issuer-cleanup.py --ruby /opt/ace/toolchains/ruby-VERSION/bin/ruby \
  --gem-home /opt/ace/probe-lab-VERSION --shared-gems /opt/ace/runtime/gems \
  --version GEM_VERSION
```

The probe removes its temporary unit and, on success, its files. On failure it
prints the retained guest paths for diagnosis. It does not contact Forgejo or
prove the real issuer's installation, host reboot recovery or the autonomous
Overseer acceptance scenario. Add `--startup-recovery` to kill the temporary
issuer without `ExecStopPost` and then exercise the installed startup recovery
entry point against its remaining lease; this simulates an interrupted process
and does not reboot the VM.

`probe-forgejo-revoke.py` takes the same arguments and runs as root inside a
provisioned working VM with `ace-e2e-forgejo.service` active. It creates a
temporary Forgejo administrator, issues a token limited to the local fixture
repository, verifies access before and denial after issuer recovery, and
checks handoff removal. The generated password stays in a root-only guest
file. On success the probe removes its temporary administrator and files; on
failure it prints the retained guest paths and account name so an operator can
recover any uncertain token before removing them. This is a provider probe,
not a full autonomous cycle or a power-loss test.

`probe-forgejo-delayed-issue.py` takes the same arguments. Its local proxy
holds one real Forgejo token request past the client's deadline, lets the
retry observe a 404, then releases the original request. It verifies that the
lease remains pending, no second token is requested, and service recovery
revokes the late token and marks its lease revoked. The token belongs to the
probe's own temporary account. An injected test runner exercises the service
as root; this does not enable or prove guarded session issuance. The probe removes
the temporary administrator only after confirmed cleanup and retains protected
guest diagnostics on failure.

`probe-issuer-socket.py` takes the same arguments and creates temporary socket,
issuer and isolated session units. It checks that the installed request entry
point is activated by a real Unix socket, authenticates the session, and
refuses a nonexistent profile. It cleans up only its uniquely named units and
restores the previous Yama setting. Its successful refusal does not mean that
session token issuance has been enabled.

`probe-project-idmap.sh` runs as root in a disposable Linux working VM. It
creates a temporary `mo`-owned Git repository, maps it to a separate numeric
UID inside a private mount namespace, then creates a worktree and commit
through that view. It checks that `mo` still owns the resulting file and can
read the branch. Run the copied script with `/bin/sh probe-project-idmap.sh`.
The probe removes its temporary repository and mounts; it tests a filesystem
primitive only, not session isolation, credential issuance or acceptance.

`probe-systemd-idmap.sh` runs as root on the disposable working VM and tests
the same Git operation inside the private mount namespace of a temporary
systemd `DynamicUser` unit. It checks that the dynamic UID cannot write the
unmapped project, performs a commit through the mapped view, stops the unit,
and checks the worktree as `mo`. It removes its unique unit and repository
on success; on failure it stops its unit and retains the repository for
diagnosis. Systemd starts the dynamic-UID process in its own cgroup. A root
helper uses `nsenter` to prepare the process's private mount namespace, then
releases that process to run Git. A pidfd confirms the same process exits when
the unit stops. This tests operating-system primitives, not an ACE launcher,
token issuance or a real agent session.

`probe-session-runner.py` takes the same installed-candidate arguments as
`probe-issuer-cleanup.py` and runs as root in the disposable VM. It creates a
temporary dynamic-UID unit and mapped project, then calls the installed
`SessionRunner`. Its test-only attachment creates a command cgroup under the
unit, and the privilege-dropped child attaches itself; the
probe checks the child's UID, empty supplementary groups, capabilities,
`NoNewPrivileges`, mount namespace and cgroup, as well as `mo` ownership of
the resulting file. It also requires rejection of a mount namespace owned by
a separate user namespace. It removes the unit and temporary project on success and
preserves the project for diagnosis on failure. The test seam does not prove
`SessionPeer`, issuer supervision, token issuance or an ACE agent launch.
With `--test-kill-fallback`, it also forces pidfd signaling to fail after a
command starts and checks that its command cgroup terminates while the
session stays active; select `EPERM` or `ESRCH` with `--signal-error`.
`--check-detached-descendant` checks that a detached child has exited before
the runner returns. `--test-writable-cgroup` requires refusal of an unsafe
session cgroup. These checks use a test attachment and do not by themselves
establish issuer or autonomous-cycle acceptance.

`probe-cgroup-containment.py` runs as root in a disposable working VM. It
starts its own non-delegated DynamicUser unit and puts a privilege-dropped
test command in a root-controlled child cgroup. It checks that the command
cannot move itself to the parent, starts a detached descendant, kills the
child cgroup and confirms that the descendant exits while the unit's main
process remains alive. It removes its temporary cgroup and unit. This checks
OS primitives only; it does not prove ACE's session runner uses them.

`probe-execution-crash.py` takes the installed-candidate arguments and runs
as root on the disposable VM. It uses a synthetic provider, kills an issuer
with `SIGKILL` after its lease records a running command, and checks that a
fresh service refuses reuse and reports unresolved execution. It removes its
private synthetic files on success and preserves them on failure. This does
not exercise a real agent, provider or systemd issuer supervision.

`probe-command-recovery.py` takes the same arguments and runs as root in the
disposable VM. It requires refusal of an unrelated systemd invocation, then
checks that installed issuer recovery stops the exact recorded command and
revokes a synthetic lease while preserving the session main process.

`probe-authenticated-runner.py` takes the same arguments. It creates a local
socket and a temporary dynamic-UID systemd session, then invokes the installed
`SessionPeer`, `SessionAttachment` and `SessionRunner` together to touch a
file in an id-mapped temporary project. It checks the resulting `mo` ownership
and restores the Yama setting. Its dummy command does not request a credential;
the production issuer and ACE worker launcher remain separate acceptance work.
With `--prepopulate-runtime`, the probe inserts an unexpected file in the
session runtime directory and requires two consecutive requests to fail
without executing the command.
With `--issuer-crash`, it creates a synthetic lease, kills the real
socket-activated issuer while its session command runs, and checks that a
temporary `ExecStopPost` invokes issuer recovery, terminates the recorded
command and revokes the lease without stopping the session main process.
The default provider and lease are synthetic. Add `--real-forgejo` to create
a temporary local Forgejo administrator and a scoped token, confirm access
before the crash and denial after recovery, and remove the administrator only
after confirmed success. On failure it preserves protected diagnostics and
the temporary account for recovery. The lease is prepared by the probe; the
production issuer graph and real agent remain outside this check.
With `--lease-expiry --real-forgejo`, it prepares a short-lived lease, verifies
that cleanup refuses to race its running command, then checks that expiration
stops the command, revokes the local Forgejo token and preserves the session.
The lease is prepared by the probe, not requested through the public CLI.

`probe-protected-projection.rb VERSION` runs as root in the provisioned
working VM with `ACE_TOOLCHAIN=installed` and `GEM_HOME`/`GEM_PATH` selecting
the candidate. It verifies root-owned extension projection and verification,
and rejects a user-controlled ancestor and an agent-owned projected file.
`probe-protected-pi.py` runs as root in the same VM and invokes the installed
Pi CLI as `mo`. It verifies that a user-controlled extension is discoverable
in the control run, then is excluded by `--no-extensions` while explicit
protected `/eyes` and `/watch` extensions load. Both are component probes;
neither launches a Herdr agent or verifies session-scoped authorization.

`probe-installed-eyes.rb` checks the installed observer and reader together
as the session account on Linux. Set `GEM_HOME` to the candidate and
`GEM_PATH` to the candidate plus installed dependencies, then run:

```sh
ruby probe-installed-eyes.rb /absolute/path/to/node HERDR_VERSION COWORKER_VERSION LAB_VERSION WAKE_VERSION OVERSEER_VERSION
```

It creates a temporary synthetic Pi transcript and synthetic Herdr binding,
but uses the live Node process's real UID and Linux birth identity. It checks
acceptance while that process runs and refusal after exit. It does not control
Herdr or replace a live-session acceptance test.

### Restoring a compressed diagnostic export

Some older diagnostic exports may be kept as `UUID.utm.zip` with a private
`UUID.utm.zip.json` sidecar to save disk space. They are local evidence, not
UTM-registered machines. Compare the archive's SHA-256 with `archive_sha256`
in its sidecar before restoring it, then extract it into the evidence directory:

```sh
shasum -a 256 .ace-local/lab-vm/evidence/UUID.utm.zip
ditto -x -k .ace-local/lab-vm/evidence/UUID.utm.zip .ace-local/lab-vm/evidence
ruby -e 'load "ace-monorepo-e2e/bin/lab-vm"; puts LabVm.package_fingerprint(ARGV.fetch(0))' .ace-local/lab-vm/evidence/UUID.utm
```

Before removing an uncompressed exported package, the archived copy was
extracted and its complete file fingerprint was compared with the original;
compare the printed fingerprint with `package_fingerprint` in the sidecar.
Archives may contain test credentials and must remain private.

### Acceptance instrumentation

`bin/lab-vm-guest mo RUN_ID COMMAND ARG...` runs the public installed command
as the fixture owner in `/lab`, with the installed runtime selected. Use an
explicit working directory for project commands. `operator` instead of `mo`
is host-only fault instrumentation through QEMU: stop a selected session or
issuer, inspect systemd cleanup, or temporarily remove a required runtime
file. It checks the run receipt against the currently owned VM before every
call. This helper is never installed in the guest or offered to an agent.
Restore each injected fault before advancing to the next case; record its
start/end and exact affected session/file. Never repair the commissioned
project or create tasks/reviews/merges using operator instrumentation.

For a live disposable Forgejo worker lease, run the expiry or issuer crash
probe through the same operator channel:

```bash
ace-monorepo-e2e/bin/lab-vm-guest operator "$run_id" /usr/bin/python3 -c \
  "$(cat ace-monorepo-e2e/lab-vm/lease-fault-evidence.py)" expiry "$lease_id"
```

Use `crash` in place of `expiry` to kill the issuer's main process after
the live check. Run the crash probe only after the distinct live session's
access denial has been captured. The probe keeps the test credential in
guest operator process memory. It reports HTTP status and owner state and
requires confirmed cleanup. It leaves issuer restart to the runner.

Scenarios share one working VM per acceptance set: run TS-MONO-003 first, then
TS-MONO-004 against its fixture receipt. Reset before repeating the pair with
identical release-manifest bytes. A failure preserves the VM and evidence;
continuation after a product change is diagnostic until a new clean pair runs.
