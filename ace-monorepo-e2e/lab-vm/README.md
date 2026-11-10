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
of distinct, project-scoped worker and reviewer credentials.
`bin/lab-vm-fixture prepare RUN_ID` is the working-VM input setup: it seeds
`/lab` and `/lab/ace`, configures local observation input, and copies only the
host's `zai` Pi credential into the working VM. It checks that the installed
runtime and native Herdr are already present and does not start the overseer.
Before starting agents, the fixture installs the pinned Herdr binary's own Pi
integration and checks its status as `mo`; this supplies Herdr with Pi lifecycle
and session identity reports. Operational gems and extensions remain root-owned;
provider model credentials are staged in the working VM only. The deployment
selects role environment files containing references to private Forgejo login
files. Tokens are restricted by Forgejo to the fixture repository and role.
Each agent runs in its own process/worktree as `mo`; this is not a security
boundary between malicious processes sharing that UID. `ace-lab install` and
`ace-lab verify` own runtime convergence; no auth daemon is required.
No credential is placed in the base image.

The seeded ACE revision has no project Overseer start/eyes configuration. That
is the repair goal. Both scopes already have valid local HITL routes; the
project contains no route to Hermes or another lab. Project tasks, assignments,
reports and worktrees remain inside `/lab/ace`; lab coordination is private to
`/lab/.ace-tasks/_overseer`.

`bin/lab-vm-lab-start RUN_ID` starts the headless Herdr server and calls public
`ace-overseer start --scope lab --format json`. Product code owns workspace
selection and ordinary process startup. The helper sends one high-level
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

The former systemd issuer, DynamicUser, namespace and UID-mapping probes were
removed with that execution model. Their historical results do not establish
acceptance of ordinary worktree/process/environment sessions. Provider-specific
late-response recovery remains covered by `probe-forgejo-delayed-issue.py`.

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
execution process, inspect credential cleanup, or temporarily remove a required runtime
file. It checks the run receipt against the currently owned VM before every
call. This helper is never installed in the guest or offered to an agent.
Restore each injected fault before advancing to the next case; record its
start/end and exact affected session/file. Never repair the commissioned
project or create tasks/reviews/merges using operator instrumentation.

For temporary credentials, use the public local `ace-lab auth` commands and
capture lease identifiers, actual process identities and remote access/rejection.
The operator-only `e2e-probe` profile keeps its source and lease files under
`/home/lab-operator/.ace-e2e-auth`; run it as `lab-operator`, not root or an agent.
The second private repository `e2e-integrator/unrelated` proves that Forgejo
rejects a token restricted to `ace`. Never print tokens. Static fixture credentials are not revoked on each session
exit; resetting the fixture destroys the disposable Forgejo database and grants.

Scenarios share one working VM per acceptance set: run TS-MONO-003 first, then
TS-MONO-004 against its fixture receipt. Reset before repeating the pair with
identical release-manifest bytes. A failure preserves the VM and evidence;
continuation after a product change is diagnostic until a new clean pair runs.

### Iteration versus cold acceptance

`lab-vm-scenario-setup repeat EVIDENCE_DIRECTORY` exports the existing scenario
state, stops the dedicated fixture user's processes, resets only scenario data,
and seeds a new run on the same installed VM. Temporary session directories,
model auth, role tokens, tasks and Forgejo state are exported privately before
removal; the installed runtime is retained. It requires the identical runtime
fingerprint; changed runtime artifacts require explicit provisioning, never a
silent reuse. `existing` continues the current run for TS-MONO-004.

`fresh` explicitly prepares/resets/provisions the OS and runtime before creating
the fixture. Use it for cold acceptance, with two identical-manifest 003→004
pairs. Repeating on an existing VM is diagnostic and is recorded as such. No VM
acceptance was executed or credited by the simplification's local tests.
