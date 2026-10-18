# ace-lab

Environment and project preparation for the local, file-based ACE Lab. Part of
ACE (Agentic Coding Environment).

> **State owner:** none for task work. `ace-lab` prepares lab environments and
> projects; task/assignment state belongs to `.ace-tasks/` (ace-task) and the
> local stores under `.ace-local/`. The canonical flow is
> [docs/lab-flow.md](../docs/lab-flow.md).

> **Planned (L8):** lab installer, project onboarding, and readiness
> verification are not available yet.

## What exists today

`ace-lab` is the Lab environment package. Its installer and project-onboarding
capabilities are the L8 target; today the package ships read-only topology
queries only. It does not run a queue, daemon, journal, authorization service,
or command kernel.

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

> **L7.1 delivered:** `ace-lab status` reports lab configuration state
> (configured / not configured / error — never conflated) and file-based local
> state, and points at `ace-git-worktree list` for the worktree view.
> Aggregated overseer status and pi continuation remain planned.

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
