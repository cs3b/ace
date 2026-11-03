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
`--rebuild-base` also exports the prior base. `destroy` removes only identities
in the private state file after checking UTM inventory, package path and UUID;
it retains verified exports. Lifecycle operations hold a single-writer lock.
Provisioning requires at least 25 GiB of free host disk.

`bin/lab-vm-artifacts` downloads the release manifest's public gem, Ruby, Node,
Zig and Rust bootstrap archives and rejects any checksum mismatch. The Pi npm
lockfile pins its dependency graph and integrity hashes. Locally built test
gems are rebuilt from the manifest's exact commits by `bin/lab-vm-build-gem`
and must match their pinned hashes; they are never published. The operational
gem repository is populated only from manifest entries, not every cached gem.
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
and session identity reports. The current extension projection is writable by
`mo` and its parent can be replaced by `mo`; it does not yet satisfy the
root-owned operational-runtime requirement. This setup path has not yet passed
a complete VM run.

The seeded ACE revision has no project Overseer start configuration and also
contains an old tracked HITL route for another lab, including Hermes paths.
Those are deliberate input defects for the bootstrap commission. No Hermes
service runs in this fixture; project readiness requires the worker to leave a
working local route rather than relying on the old machine or its paths.

`bin/lab-vm-lab-start RUN_ID` is the initial launch path under development. It
starts a real headless Herdr server, creates the lab workspace and local HITL
route, launches `ace-overseer start`, and delivers a single high-level project
goal. A separate `captain` terminal displays local HITL questions without
interpreting them as shell commands; the operator can inspect its pane from
the receipt and answer the exact case through `ace-hitl reply`. It records the
returned identities and refuses to repeat any attempted start. For a new run,
reset the working VM and prepare a new fixture. It does not create the overseer's tasks or launch its
workers. The returned prompt receipt does not establish successful delegation.

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
diagnosis. The Git commands enter the namespace with `nsenter`. A separate
dynamic-UID child is attached to the unit's cgroup and must be killed when the
unit stops. This does not prove an ACE launcher or that the Git commands ran
inside that cgroup.

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
