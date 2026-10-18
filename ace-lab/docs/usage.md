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

### `ace-lab status [--format table|json] [-q]`

```bash
ace-lab status                 # readable table (default)
ace-lab status --format json   # full report as JSON
```

`status` is read-only local observability (task 8xg.t.sbz.6.0): it reads the
ADR-022 lab configuration cascade and the file-based state-owner locations
(ADR-034) — nothing is started, written, or installed, and there is no
authorization gate. Live terminal layout belongs to `ace-herdr status`; the
enriched worktree view with task associations is `ace-git-worktree list`
(delivered by k9y) — `status` shows only presence/count for worktrees and does
not duplicate that surface.

Lab configuration is reported in three distinct states — they are never
conflated:

- `configured` — at least one overlay (`.ace/lab/config.yml` or
  `~/.ace/lab/config.yml`) present and valid, with topology counts
  (0/0/0 is a *valid empty set*).
- `missing` — defaults only: no overlay exists. Informational; exit code 0.
  Never rendered as a ready-but-empty lab.
- `invalid` — an unparsable/non-mapping document or a schema violation;
  carries the path-bearing message.

Runtime *configuration* is echoed (project/user `runtime/config.yml`, then the
`ACE_RUNTIME` environment variable) with its value and origin. No runtime
detection and no `ace-runtime` dependency: runtime availability is
`ace-herdr status`'s dimension.

Local state covers `.ace-tasks/`, `.ace-tasks/_overseer/` (presence only —
private, never enumerated), `.ace-local/assign/`, `.ace-local/hitl/`,
`.ace-wt/`, and `.ace-local/coworker/` (presence only — reserved L3). Absence
of overseer or coworker state is information, not a failure.

Exit codes: 0 for `configured` and `missing` (empty or not); a source error —
invalid configuration or an unreadable location — prints the **full report
first**, then fails non-zero with the error, so available results stay visible
next to the failure.

## Planned waves

> **L7 remainder:** `ace-lab status` is delivered; the remaining L7 scope
> (configurable `ace-overseer status` aggregation, pi continuation) lives in
> its own packages and is not available yet.
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
