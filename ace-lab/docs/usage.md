# ace-lab usage

`ace-lab` currently exposes read-only topology queries only. The lab installer
and project onboarding are **planned (L8: not available yet)**.

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

## Status

```bash
ace-lab status              # table: configuration + local state + worktree pointer
ace-lab status --format json
```

Read-only snapshot in three sections; starts nothing, writes nothing, and
exits 0 whenever a report renders (only usage errors exit non-zero).

- `Lab configuration:` one of `configured` (explicit cascade sources and
  aggregate projects/agents/services counts — no ids or endpoints),
  `not configured (no .ace/lab/config.yml or ~/.ace/lab/config.yml)`, or
  `error - <reason>` (malformed or schema-invalid source; messages carry the
  path, never content). A not-configured lab is never presented as an empty,
  ready one.
- `Local state:` presence and entry counts for the canonical lab-flow
  locations (`.ace-tasks`, `.ace-tasks/_overseer`, `.ace-local/assign`,
  `.ace-local/coworker`, `.ace-local/hitl`, `.ace-wt`). Absent coworker or
  private-overseer state is an informational note, never a readiness claim.
- `Worktree view:` points at the existing `ace-git-worktree list` (task
  associations, activity, PR state); this command does not duplicate it.

Unlike the query commands, `status` emits a plain top-level JSON object
(status never fails; each section carries its own state) rather than the
`{status, data}` query envelope.

## Planned waves

> **Planned (L7):** configurable aggregated overseer status and pi
> continuation build on `ace-lab status`; they are not available yet.
>
> **Planned (L8):** installer (accounts, directories, keys), project onboarding,
> resuming an interrupted install, and readiness verification are not available
> yet.

## Boundaries

`ace-lab` owns no task, assignment, HITL, or worktree state. There is no
journal, authority/admission service, daemon, queue engine, command kernel, or
extra state cache in this package.

The installed authority/admission/journal/command path is removed in L1: the
`service request|status|listen`, `ace-lab assignment …`, `run`, `run-status`,
and `command execute` commands no longer exist. The local file-based flow does
not use them. The Forgejo merge adapter and its trusted configuration loader
remain as provider building blocks; the local flow does not invoke them.
