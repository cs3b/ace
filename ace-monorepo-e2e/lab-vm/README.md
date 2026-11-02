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
`bin/lab-vm-runtime
provision` starts a fresh work clone, verifies its SSH host key via the QEMU
guest agent, copies these inputs and invokes the guest-side runtime installer
and unprivileged native Herdr build. This provisioning path is still being
validated. It does not configure Pi credentials, create a Forgejo fixture or
run an E2E scenario. Downloaded inputs or successful provisioning alone are not
proof that ACE is operational.

For an actual run, `bin/lab-vm-forgejo create` installs the pinned ARM64
Forgejo and `fj` client in the working VM, starts Forgejo on guest loopback,
and seeds a private repository and four issues from the committed ACE revision.
It records the source and initial commits, VM identity, hashes and issue URLs
under a private run directory. Forgejo's signing key and detached release
signature are verified; the client archive is pinned by the SHA-256 of the
official release download. No real GitHub repository or credential is used.
This new fixture path still requires live validation, including the delivery
of distinct, short-lived worker and reviewer credentials.
`bin/lab-vm-fixture prepare RUN_ID` is the working-VM input setup: it seeds
`/lab` and `/lab/ace`, configures local observation input, and copies only the
host's `zai` Pi credential into the working VM. It checks that the installed
runtime and native Herdr are already present and does not start the overseer.
This setup path has not yet passed a complete VM run.

The seeded ACE revision has no project Overseer start configuration and also
contains an old tracked HITL route for another lab, including Hermes paths.
Those are deliberate input defects for the bootstrap commission. No Hermes
service runs in this fixture; project readiness requires the worker to leave a
working local route rather than relying on the old machine or its paths.

`bin/lab-vm-lab-start RUN_ID` is the initial launch path under development. It
starts a real headless Herdr server, creates the lab workspace and local HITL
route, launches `ace-overseer start`, and delivers a single high-level project
goal. It records the returned identities and refuses to repeat a start after
an uncertain outcome. It does not create the overseer's tasks or launch its
workers. The returned prompt receipt does not establish successful delegation.

The intended acceptance is a full autonomous cycle: a lab Overseer delegates
the project bootstrap, then the project Overseer independently orders and
delegates multiple issues in the VM's isolated Forgejo repository, obtains review,
merges their tested PRs in dependency order, and leaves the release queued. A
second run after reset and the restart, idempotency, idle and failure checks
are required before calling the environment accepted.
