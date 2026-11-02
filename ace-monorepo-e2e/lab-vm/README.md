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
lockfile pins its dependency graph and integrity hashes. `bin/lab-vm-runtime
provision` starts a fresh work clone, verifies its SSH host key via the QEMU
guest agent, copies these inputs and invokes the guest-side runtime installer
and unprivileged native Herdr build. This provisioning path is still being
validated. It does not configure Pi credentials, create a GitHub fixture or
run an E2E scenario. Downloaded inputs or successful provisioning alone are not
proof that ACE is operational.

For an actual run, `bin/lab-vm-github-fixture create` creates a new private
repository on the account authenticated by the host's `gh`, seeds it from the
current committed ACE revision and opens the four fixture issues. It records
the source and initial commits, issue URLs and any partial progress under a
private run directory. It never reuses or deletes an existing repository; a
failed partial run is retained for inspection. This uses the host credential
only and does not provide the guest with GitHub authorization. A separate,
short-lived credential limited to the new test repository is still required.
`bin/lab-vm-fixture prepare RUN_ID` is the working-VM input setup: it seeds
`/lab` and `/lab/ace`, configures local observation input, and copies only the
host's `zai` Pi credential into the working VM. It checks that the installed
runtime and native Herdr are already present and does not start the overseer.
This setup path has not yet passed a complete VM run.

`bin/lab-vm-lab-start RUN_ID` is the initial launch path under development. It
starts a real headless Herdr server, creates the lab workspace and local HITL
route, launches `ace-overseer start`, and delivers a single high-level project
goal. It records the returned identities and refuses to repeat a start after
an uncertain outcome. It does not create the overseer's tasks or launch its
workers. The returned prompt receipt does not establish successful delegation.

The intended acceptance is a full autonomous cycle: a lab Overseer delegates
the project bootstrap, then the project Overseer independently orders and
delegates multiple issues in an isolated GitHub repository, obtains review,
merges their tested PRs in dependency order, and leaves the release queued. A
second run after reset and the restart, idempotency, idle and failure checks
are required before calling the environment accepted.
