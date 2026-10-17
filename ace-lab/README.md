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
queries and one explicit project-command kernel. Neither capability runs a
queue, daemon, journal, or authorization service.

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

> **Planned (L7):** topology values and status integration for the new flow are
> not available yet. Existing queries are read-only building blocks.

### Explicit project commands

```bash
ace-lab run --project atlas -- /usr/local/bin/publish-release 1.2.3
ace-lab run-status --project atlas --reference REFERENCE --format json
```

`run` executes exactly the argv it is given under the configured project. It
does not interpret a shell string and does not retry an uncertain execution.

## Not owners of the flow

`ace-lab` does not own task state, assignment plans, HITL events, worktrees, or
a queue. There is no journal, no authority/admission service, no listener that
blocks ordinary work, and no second state store. The old protected
service-request/executor stack was removed in L1.

The ordinary fixed-merge producer/receiver (`ace-lab service listen|request|
status --mode ordinary-merge`) and the `ace-lab assignment …` ordinary-owner
commands are retained as internal transports for the planned L3/L6 work. They
are not part of the local flow documented here and are not required by it.

## Install

```bash
gem install ace-lab
```

## Development

```bash
bin/ace-test ace-lab all
```
