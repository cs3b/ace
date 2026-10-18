# ace-lab usage

`ace-lab` exposes read-only topology queries, the lab status snapshot, and
the `prepare` phase of the lab installer. Full installation and project
onboarding are **planned (L8: not available yet)**.

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

## Prepare (L8.1)

```bash
ace-lab prepare              # table: one line per manifest item
ace-lab prepare --dry-run    # predict (would_*) without mutating anything
ace-lab prepare --format json
```

`prepare` reads the trusted install manifest from the fixed deployment
path `/etc/lab/ace-lab/install.yml` and makes the machine match it,
idempotently, in a fixed section order: accounts → directories → keys →
roles. There is deliberately no `--manifest` flag: a caller-selected
manifest could manufacture privileges (accounts, directories, keys), so
the manifest is a root-owned deployment document verified through the
same fail-closed traversal as the authorization file (every element on
the path root-owned and not group/world-writable, `O_NOFOLLOW` on the
final component). It is never edited through the `.ace/` cascade and is
not task state (ADR-034): nothing outside the manifest is touched, and
no progress journal is written — re-running `prepare` simply converges.

```yaml
# /etc/lab/ace-lab/install.yml — root-owned deployment document
schema_version: 1            # required, must be 1
machine: lab01               # required identity (role/HITL addressing)
accounts:                    # optional
  - username: ace-worker     # ^[a-z_][a-z0-9_-]{0,31}$, unique
    role: worker             # informational binding
    create: false            # default; true requires administrator privileges
    home: /home/ace-worker   # default: /Users/<u> (darwin), /home/<u> (linux)
directories:                 # optional
  - path: /home/ace-overseer/labs   # absolute
    owner: ace-overseer      # optional; omitted = installer ownership
    mode: "0750"             # optional octal string, default "0755"
keys:                        # optional, ed25519 only (v1)
  - account: ace-worker      # must reference a declared account
    path: /home/ace-worker/.ssh/id_ed25519  # optional, default <home>/.ssh/id_ed25519
roles:                       # optional
  - id: worker               # ^[a-z][a-z0-9_-]{0,31}$, unique
    account: ace-worker
    instructions: wfi://assign/work  # wfi://|prompt://|tmpl:// or an absolute readable file
```

Statuses: accounts `created|exists|would_create|failed`; directories
`created|exists|mode_fixed|would_create|would_fix_mode|failed`; keys
`created|exists|would_create|would_repair_public|would_fix_mode|failed`
(with the public `fingerprint`); roles `verified|failed`. `ok` in the
JSON report means zero failed items. Key/role items whose account
failed are reported as dependency failures instead of being attempted.

`--dry-run` is a faithful prediction of the wet run (`would_*`
statuses, zero mutations): keys and roles of an account the account
phase *would create* are predicted (`would_create` keys, `verified`
roles) even though the account does not exist in passwd yet; an
existing private key with a missing `.pub` predicts
`would_repair_public` (the wet run regenerates it); mode or ownership
drift on an existing pair predicts `would_fix_mode`. One prediction
limit: an *existing* directory whose declared owner account does not
exist yet cannot have its ownership checked, and is reported as a
failed item with a rerun hint.

Behavior and guarantees:

- **Idempotent convergence.** Existing resources are verified, not
  recreated; only mode drift on an owner-matching directory is repaired.
  A pre-existing directory owned by a different account is refused
  (`refusing takeover`), never silently chowned. Symlinks and
  non-directories at declared paths are refused. Residual policy:
  symlink refusal applies to the *declared leaf* path only —
  intermediate path components are followed (and created with default
  mode/ownership, since only the leaf carries declared values); the
  manifest is root-owned, so this trusts the deployment document, not
  the account.
- **Account creation** uses the platform's own tooling (darwin
  `dscl . -create` + `createhomedir`, linux `useradd -m`), always with
  argv arrays. Unsupported platforms are reported with a manual remedy
  (`create: false`). Missing administrator privileges are classified
  with an actionable message, as is a missing account without
  `create: true`.
- **Secret hygiene.** Key pairs are generated with `ssh-keygen -t
  ed25519`; `.ssh` is 0700, the private key 0600, the public key 0644,
  ownership assigned to the account. Reports carry the public
  fingerprint only — private key material never appears in any status,
  message, report, or diagnostic argument. Key paths inside a git
  worktree are refused outright. Planted symlinks on the
  account-controlled paths — `.ssh` (checked with `lstat` before any
  `mkdir`/chmod/chown) and `<key>.pub` (checked with `lstat`, written
  with `O_NOFOLLOW`) — are refused, so a privileged run cannot be
  turned into an arbitrary chmod/chown/write by the account.
- **Exit codes.** A wet run with failed items prints the report, then
  exits non-zero enumerating each `<section>/<item>: <message>`;
  `--dry-run` exits 0 whenever a report renders (conflicts appear as
  predicted failures). A missing, untrusted or invalid manifest is a
  classified error naming the path, never its content.

Boundaries (what `prepare` is not):

- No project onboarding (`ace-lab project add`, L8.2) — the manifest's
  role catalog declares where each role lives and under which account;
  the project-add step consumes it.
- No full `ace-lab install` orchestration (L8.3): no HITL adapter
  configuration, no foreign-lab refusal, no cross-check of `machine`
  against the `hitl` cascade.
- No interrupted-install resume bookkeeping (L8.4): re-running `prepare`
  is the resume mechanism; install-level resumption composes it.
- No end-to-end verification under the target accounts (L8.5): real
  multi-account proof belongs to the readiness verification step.

## Planned waves

> **L7 remainder:** `ace-lab status` is delivered; the remaining L7 scope
> (configurable `ace-overseer status` aggregation, pi continuation) lives in
> its own packages and is not available yet.
>
> **Planned (L8):** project onboarding, resuming an interrupted install,
> and readiness verification are not available yet. The preparation
> phase is delivered as `ace-lab prepare` (L8.1); `ace-lab install`
> (L8.3) will compose it with configuration, HITL adapters and
> verification.

## Boundaries

`ace-lab` owns no task, assignment, HITL, or worktree state. There is no
journal, authority/admission service, daemon, queue engine, command kernel, or
extra state cache in this package.

The installed authority/admission/journal/command path is removed in L1: the
`service request|status|listen`, `ace-lab assignment …`, `run`, `run-status`,
and `command execute` commands no longer exist. The local file-based flow does
not use them. The Forgejo merge adapter and its trusted configuration loader
remain as provider building blocks; the local flow does not invoke them.
