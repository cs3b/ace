# ace-lab usage

`ace-lab` currently exposes read-only topology queries and one explicit
project-command kernel. The lab installer and project onboarding are
**planned (L8: not available yet)**.

The file-based ownership model is documented once in
[../../docs/lab-flow.md](../../docs/lab-flow.md).

## Topology

Topology configuration is read from `~/.ace/lab/config.yml` or
`.ace/lab/config.yml` through the normal ACE configuration cascade. All
topology commands accept `--format json` (the only supported format) and
`-q/--quiet`.

```yaml
# .ace/lab/config.yml -- topology only
schema_version: 1
topology:
  projects:
    - { id: atlas, label: Atlas platform }
  agents:
    - id: atlas-planner
      project: atlas
      role: planner
      capabilities: [planning]
  services:
    - id: atlas-search
      project: atlas
      capabilities: [search]
      default_for: [search]
      endpoint: { kind: http, url: "https://search.example.internal/query" }
```

### `ace-lab projects`

```bash
ace-lab projects --format json
# {"status":"ok","data":{"projects":[{"id":"atlas","label":"Atlas platform"}]}}
```

### `ace-lab agents --project PROJECT`

```bash
ace-lab agents --project atlas --format json
```

`binding.state` is `available` when the configured runtime binding is active;
otherwise `stale`.

### `ace-lab services --project PROJECT`

```bash
ace-lab services --project atlas --format json
```

The endpoint in public output is a sanitized identity: scheme, host and an
explicit port only. Query parameters, userinfo, fragments and credentials are
never printed.

### `ace-lab resolve --id ID`

```bash
ace-lab resolve --id atlas-planner --format json
```

Labels are display values and never resolve: resolving `"Atlas platform"` is a
`missing` error.

### `ace-lab route --project PROJECT --capability CAPABILITY`

```bash
ace-lab route --project atlas --capability search --format json
```

Routing selects a capable service in the requested project. It never invokes
the service and never grants credentials.

## Explicit project commands

### `ace-lab run`

Run one command with an explicit project selection. Pass the argv after `--`;
no shell interpretation happens.

```bash
ace-lab run --project atlas -- /usr/local/bin/publish-release 1.2.3
```

### `ace-lab run-status`

Inspect an original command execution without running it again.

```bash
ace-lab run-status --project atlas --reference REFERENCE --format json
```

## Planned waves

> **Planned (L7):** topology values and status integration for the file-based
> flow are not available yet.
>
> **Planned (L8):** installer (accounts, directories, keys), project onboarding,
> resuming an interrupted install, and readiness verification are not available
> yet.

## Boundaries

`ace-lab` owns no task, assignment, HITL, or worktree state. There is no
journal, authority/admission service, daemon, queue engine, or extra state
cache in this package. The old protected service-request/executor path is
removed (L1); a missing old listener does not block ordinary work.

The ordinary fixed-merge producer/receiver (`service listen|request|status
--mode ordinary-merge`) and the `ace-lab assignment …` ordinary-owner commands
are retained as internal transports for planned L3/L6 work. They are not
required by the local flow and are intentionally not documented here as a user
path.
