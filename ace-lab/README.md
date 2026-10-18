# ace-lab

Environment and project preparation for the local, file-based ACE Lab. Part of
ACE (Agentic Coding Environment).

> **State owner:** none for task work. `ace-lab` prepares lab environments and
> projects; task/assignment state belongs to `.ace-tasks/` (ace-task) and the
> local stores under `.ace-local/`. The canonical flow is
> [docs/lab-flow.md](../docs/lab-flow.md).

> **Planned (L8):** project onboarding and readiness verification are not
> available yet; the installer's preparation phase is delivered as
> `ace-lab prepare` (L8.1).

## What exists today

`ace-lab` is the Lab environment package. Its installer and project-onboarding
capabilities are the L8 target; today the package ships read-only topology
queries, the lab status snapshot, and the `prepare` phase. It does not run a
queue, daemon, journal, authorization service, or command kernel.

### Topology queries

Topology configuration uses the ACE configuration cascade
(`~/.ace/lab/config.yml` or `.ace/lab/config.yml`). Queries never invoke a
service and never hand credentials to the caller.

```bash
ace-lab projects --format json
ace-lab agents --project atlas --format json
ace-lab services --project atlas --format json
ace-lab resolve --id atlas-planner --format json
ace-lab route --project atlas --capability search --format json
```

Every query prints one deterministic JSON document. Failures are classified
(`missing`, `ambiguous`, `stale`, `unauthorized`, `invalid_configuration`).
Stable IDs are canonical; labels are display values and never resolve.

### Lab status

```bash
ace-lab status                 # configuration + local file state (read-only)
ace-lab status --format json
```

`ace-lab status` distinguishes a valid empty set, missing configuration, and a
source error — never presenting an incomplete lab as empty-and-ready. The
enriched worktree view stays `ace-git-worktree list`; live terminal layout is
`ace-herdr status`.

### Lab preparation (`prepare`, L8.1)

```bash
ace-lab prepare --dry-run
```

Idempotently prepares accounts, directories (mode/ownership), ed25519 key
pairs and the role catalog from the trusted root-owned install manifest at
`/etc/lab/ace-lab/install.yml` (verified fail-closed like the authorization
document; no `--manifest` flag by design). Reports fingerprints, never key
material; refuses foreign-takeover of existing directories and key paths
inside git worktrees. See [docs/usage.md](docs/usage.md) for the manifest
schema, status table and L8.2–L8.5 boundaries.

## Not owners of the flow

`ace-lab` does not own task state, assignment plans, HITL events, worktrees, or
a queue. There is no journal, no authority/admission service, no listener that
blocks ordinary work, and no second state store.

The installed authority/admission/journal/command path is removed in L1: the
`service request|status|listen`, `ace-lab assignment …`, `run`, `run-status`,
and `command execute` commands no longer exist, and the local file-based flow
does not use them. The Forgejo merge adapter and its trusted configuration
loader remain as provider building blocks; the local flow does not invoke them.

## Install

```bash
gem install ace-lab
```

## Development

```bash
bin/ace-test ace-lab all
```
