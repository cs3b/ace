# ace-lab usage

`ace-lab` exposes read-only topology queries, the lab status snapshot, the
`prepare` phase of the lab installer (L8.1), `project add` project
onboarding (L8.2), the full installer `install` (L8.3, which also resumes
its own interrupted installation, L8.4), and the end-to-end readiness
verification `verify` (L8.5).

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
projects:                    # optional (consumed by ace-lab install)
  - id: atlas                # ^[a-z][a-z0-9_-]{0,31}$, unique
    path: /Users/ace/lab/atlas         # absolute, unique
    remote: git@forge:atlas/atlas.git  # optional clone source
    label: Atlas platform    # optional display label
grants:                      # optional: trusted-tier principal grants
  ace-overseer:              # principal → declared project ids
    - atlas
gemset:                      # optional (gad.2): target runtime + required gem set
  gem_home: /opt/lab/gems    # absolute; converged as GEM_HOME and GEM_PATH
  gems:                      # exact versions, unique names
    - name: ace-lab
      version: 0.13.0        # must be an exact gem version (no ranges)
  extensions:                # optional (8xs.t.pu0.0): harness extension projections
    - gem: ace-wake          # must be declared in gems above
      path: /Users/overseer/.pi/agent/extensions  # absolute target directory
      account: lab-overseer  # must be a declared account (the loading executor)
```

Statuses: accounts `created|exists|would_create|failed`; directories
`created|exists|mode_fixed|would_create|would_fix_mode|failed`; keys
`created|exists|would_create|would_repair_public|would_fix_mode|failed`
(with the public `fingerprint`); roles `verified|failed`; gems
`installed|updated|exists|would_install|would_update|failed` (one item
per declared gem). `ok` in the
JSON report means zero failed items. Key/role items whose account
failed are reported as dependency failures instead of being attempted;
gem items fail as dependencies when the declared runtime did not
prepare.

`--dry-run` is a faithful prediction of the wet run (`would_*`
statuses, zero mutations): keys and roles of an account the account
phase *would create* are predicted (`would_create` keys, `verified`
roles) even though the account does not exist in passwd yet; an
existing private key with a missing `.pub` predicts
`would_repair_public` (the wet run regenerates it); mode drift on an
owner-matching pair predicts `would_fix_mode`; a planted `.ssh`
symlink is refused in dry-run exactly as the wet run refuses it, and a
missing directory whose declared owner account *failed* the account
phase is predicted as the wet run's owner-unavailable failure (the
orchestrator threads its computed account set into the directory
stage). Four prediction limits: an *existing* directory whose declared
owner account does not exist yet cannot have its ownership checked,
and is reported as a failed item with a rerun hint; likewise, a role's
instruction *file* readability cannot be checked against an account
that does not exist yet (its uid is unknown), so such bindings are
predicted `verified` from the file's existence and type alone — the
wet run performs the full readability check; and an *existing key
pair* under an account the phase would create cannot have its
ownership checked either (the future uid is unknown) — a pair owned
by neither the installer nor the to-be-created account is
conservatively predicted as the wet run's takeover refusal, which is
pessimistic only in the pathological case where account creation
reuses exactly that uid. A fourth, smaller limit: when the account
phase *would create* the account, an existing installer-owned pair (or
installer-owned `.ssh`) is predicted as a plain `exists` even though the
wet run would chown it to the account while converging — the transfer
itself is not predicted.

Behavior and guarantees:

- **Idempotent convergence.** Existing resources are verified, not
  recreated; only mode drift on an owner-matching directory or
  owner-matching key pair is repaired. A pre-existing directory — or
  key pair — owned by a different account is refused (`refusing
  takeover`), never silently chowned, and that policy covers `.ssh`
  itself: a pre-existing `.ssh` owned by neither the account nor the
  installer is refused on both the create and the existing-key path
  (wet and dry-run). Symlinks and
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
  `create: true`. For an *existing* account whose passwd home differs
  from the manifest home, the drift is reported in the message; the
  manifest home stays authoritative (key default paths derive from
  it).
- **Secret hygiene.** Key pairs are generated with `ssh-keygen -t
  ed25519`; `.ssh` is 0700, the private key 0600, the public key 0644,
  ownership assigned to the account — and `.ssh` mode/ownership is
  *converged* on the existing-key path too (drift predicts
  `would_fix_mode` in dry-run and is repaired in the wet run; a
  foreign-owned `.ssh` is a takeover refusal, see above). A pair is
  ready only when the `.pub` fingerprint matches the public key
  derived from the private key (`ssh-keygen -y`); unreadable or
  mismatched pairs are `failed` items, never usable-looking
  `exists`/`created` with no fingerprint — the unknown pair itself is
  left untouched for manual resolution. Reports
  carry the public
  fingerprint only — private key material never appears in any status,
  message, report, or diagnostic argument (the derived public key
  exists only inside a private tmpdir for the duration of one
  read-only comparison). Key paths inside a git
  worktree are refused outright — judged by their PHYSICAL location
  (existing ancestors resolved with `realpath`), so a symlinked
  ancestor cannot smuggle a key into a repository. Planted symlinks on the
  account-controlled paths — `.ssh` (checked with `lstat` before any
  `mkdir`/chmod/chown, on the *existing-key* path and in dry-run too)
  and `<key>.pub` (checked with `lstat` — including *before*
  `ssh-keygen` on the create path, since keygen writes the `.pub` by
  path — and written with `O_NOFOLLOW`) —
  are refused, so a privileged run cannot be turned into an arbitrary
  chmod/chown/write by the account.
- **Symlink-race hardening.** Leaf directories (`.ssh` and declared
  directories) are created with component-wise `Dir.mkdir` — whose
  `EEXIST` on a planted symlink refuses instead of following it — and
  re-`lstat`ed immediately after creation: a leaf that is not a real
  directory the installer just created is refused before any
  chmod/chown, and a directory swapped between the owner check and a
  mode fix is re-checked before the chmod. Key *files* never carry a
  path-based mutation: after `ssh-keygen` the pair is re-`lstat`ed
  (a keygen writing through a swapped-in symlink is refused before any
  ownership transfer), and every chmod/chown on the private key and
  the `.pub` — regenerated or not — goes through an
  `O_NOFOLLOW`-opened file handle, so a mid-flight symlink swap
  surfaces as `ELOOP` and is refused. On the create path the `.ssh`
  ownership transfer is *deferred* until after the post-keygen
  verification: while `ssh-keygen` writes by path, a freshly created
  `.ssh` is still installer-owned 0700 and unwritable by the account,
  so nothing can be planted inside it during the keygen window.
  Accepted residuals: a microscopic
  window remains between that final re-`lstat` and the path-based
  `chmod`/`chown` on a *directory* leaf (Ruby stdlib offers no fd-based
  directory chmod); closing it would require exotic APIs for no
  practical gain over the guard chain above — and `ssh-keygen`
  necessarily writes by path, so the keygen step itself retains the
  *account-owned-home rename race*: an account that already owns the
  parent home directory can rename the installer-owned `.ssh`
  mid-flight and substitute its own (likewise, an `.ssh` that
  pre-exists account-owned stays writable by the account throughout).
  The post-keygen re-`lstat` then detects the substitution after the
  write and refuses before any ownership transfer; whatever was
  written lands root-owned 0600 — a file-creation primitive at an
  attacker-chosen location, not an escalation, and inside the same
  accepted-threat envelope as the directory residual above.
- **Role instruction reachability.** A file instruction source is
  `verified` only when the account can actually reach it: the file's
  read bits AND the search (`x`) bit of every ancestor directory of
  the resolved path (ancestor symlinks followed) must grant the
  account's governing POSIX class — owner, primary or supplementary
  group, or other. A readable file behind an unsearchable directory
  (e.g. 0644 inside a 0700 directory owned by someone else) is
  `failed`, not `verified`. ACLs remain out of scope.
- **Gem-set convergence (gad.2).** When the manifest declares a
  `gemset`, prepare converges the declared gem set into the declared
  target runtime (`gem_home`): a gem whose exact declared version is
  already present is a no-op (`exists`), a missing gem is installed
  (`installed`), a gem present at a different version is updated (the
  declared version is installed; RubyGems keeps versions side by side
  and verify judges the declared set). The `gem` subprocesses run with
  `GEM_HOME`/`GEM_PATH` pinned to the runtime (through the POSIX `env`
  command, argv arrays only) and with the invoking process's bundler
  context stripped (`RUBYOPT`, `RUBYLIB`, `BUNDLE_*`/`BUNDLER_*`), so
  a `bundle exec ace-lab prepare` converges the LAB runtime, never its
  own bundle. The runtime directory is created only with
  administrator privileges; a symlink or non-directory at `gem_home`
  is refused (takeover posture). Installs fetch from the `gem`
  command's configured sources (provisioning network access, like
  cloning a declared remote) with `--no-document`. `--dry-run` is a
  faithful prediction: the read-only probe runs, statuses are
  `would_install`/`would_update`/`exists`, nothing is created or
  installed, and a runtime that would need privileges predicts the wet
  failure.
- **Dependency closure and CLI activation (8xs.t.pu0.0).** Presence of
  the exact declared version is necessary but not sufficient. Prepare
  also walks each declared gem's runtime dependency closure in the
  target runtime and installs missing transitive dependencies at the
  parent's requirement — a gem whose version already figures in
  `gem list` but misses a transitive dependency (the manually repaired
  `json` class of gap) is repaired by `ace-lab install`, and an
  unsatisfiable dependency is a classified failure, never readiness.
  A NEWER version of a declared gem sitting beside the declared one
  would win RubyGems activation and silently take over the runtime's
  CLI; convergence removes it from the declared runtime (the manifest
  is the single owner of the declared set) and `verify` fails the gem
  while any newer sibling remains. `verify` re-derives both facts with
  the same probes convergence uses — readiness means the closure
  resolves AND the declared version wins activation.
- **Extension projections (8xs.t.pu0.0).** Each `gemset.extensions`
  entry projects the installed gem's `handbook/extensions` tree — at
  its EXACT declared version, never the checkout and never a newer
  sibling — into the declared target directory. The projection is
  receipt-based: only files recorded in the target's
  `.ace-lab-extension-projection.json` receipt are ever removed, so
  user-authored extensions in the same directory stay untouched. The
  report carries `loaded_version` (the version the running harness
  still holds) and `restart_required` — a changed projection means the
  executor's processes hold the old extension, and the installer
  REPORTS the restart need; it never restarts an executor on its own.
  `verify` re-derives the projection from the installed gem tree and
  the receipt: a missing receipt, a version mismatch, or a differing
  file fails readiness.
- **Exit codes.** A wet run with failed items prints the report, then
  exits non-zero enumerating each `<section>/<item>: <message>`;
  `--dry-run` exits 0 whenever a report renders (conflicts appear as
  predicted failures). A missing, untrusted or invalid manifest is a
  classified error naming the path, never its content.

Boundaries (what `prepare` is not):

- No project onboarding in `prepare` itself (`ace-lab project add`,
  L8.2, is the dedicated command) — the manifest's role catalog
  declares where each role lives and under which account; the
  project-add step consumes that converged environment.
- No full `ace-lab install` orchestration (L8.3, delivered as
  `ace-lab install`): no project onboarding, no trusted-tier grants
  configuration, no foreign-lab refusal — `prepare` converges the
  machine and leaves the composition to the installer.
- No interrupted-install resume bookkeeping (L8.4): re-running `prepare`
  is the resume mechanism; install-level resumption composes it.
- No end-to-end verification under the target accounts (L8.5): real
  multi-account proof belongs to the readiness verification step.

## Project add (L8.2)

```bash
ace-lab project add atlas --path /Users/ace/lab/atlas --remote git@forge:atlas/atlas.git
ace-lab project add atlas --path /Users/ace/lab/atlas --dry-run
ace-lab project add atlas --path /Users/ace/lab/atlas --format json
```

`project add` makes a project ready for team work (task 8xg.t.sbz.7.1),
assuming `ace-lab prepare` (L8.1) already converged the machine-level
accounts, directories, keys and roles. Three steps run in a fixed order:

1. **repository** — the target path becomes a Git repository with the
   declared origin remote. A missing or empty path is cloned from
   `--remote`; an existing repository without an origin gets one; an
   existing repository with a *different* origin is refused as a
   contradictory registration, and a non-empty non-repository path is
   refused as a foreign location — never taken over, never overwritten.
   The path itself must be the repository toplevel: a directory nested
   inside another repository's work tree is refused as foreign.
2. **overseer** — the private, untracked `.ace-tasks/_overseer/` folder
   is created (ADR-034) and its `.gitignore` entry ensured. Existing
   `.gitignore` content and folder content are never touched; the
   folder is never enumerated.
3. **registry** — the project is registered in `<path>/.ace/lab/config.yml`
   (the project tier of the ordinary ADR-022 lab-config cascade) with
   its `id`, `label`, absolute `path` and `remote`. Because every
   consumer already reads that cascade, `ace-lab status` shows the
   project (`configured`, topology counts) and `ace-lab projects` /
   `ace-overseer projects` list it — no second registry exists, and
   `ace-overseer` needed no read-side change. Two prerequisites for
   that listing: grants come exclusively from the trusted tier of the
   cascade, so listing the new project id requires a trusted-tier
   principal grant covering it — configuration the installer (L8.3)
   owns, not `project add` — and the project-tier document only enters
   the cascade when the command runs from the project root (cascade
   tiering). The `path` and `remote` registry fields are
   installer-owned deployment data and are not exposed in the public
   projection.

The planner chain consumes the result directly: `ace-coworker prepare`
provisions task worktrees from the registered repository, and the
overseer's private queue lives in the prepared `_overseer` folder —
no manual directory fixing is needed.

Statuses per step: `created|exists|updated|would_create|would_update|failed`.
`ok` means
zero failed steps; a wet run with failures prints the report first,
then exits non-zero naming each step. `--dry-run` predicts
(`would_*`) with zero mutations and exits 0.

Idempotence and refusals:

- Re-adding an already-registered project re-validates every step and
  reports `exists` without rewriting the registry, the `.gitignore`,
  or anything inside `_overseer`. A changed `--label` on re-add
  updates the recorded label (display data, not identity) and reports
  `updated`; an omitted `--label` keeps the recorded one.
- The same id registered with a different `path` or `remote`, or the
  same absolute `path` registered under a different id, is refused
  before any write.
- An unparseable registry document or a foreign `schema_version` is
  refused rather than overwritten.
- A failed repository step fails the overseer and registry steps as
  dependency failures instead of attempting them.

Boundaries: `project add` does not clone role accounts or keys (L8.1
owns those), does not configure HITL adapters or run the full install
(L8.3/`ace-lab install`), and adds no new state owner — the only
persisted artifact is the project's own lab-config cascade document.

## Install (L8.3)

```bash
ace-lab install              # full installation from the trusted manifest
ace-lab install --dry-run    # predict every phase without mutating
ace-lab install --format json
```

`install` performs the full new-lab installation (task 8xg.t.sbz.7.2)
from the same trusted install manifest as `prepare`, by composing the
existing molecules in a fixed order:

1. **Foreign-lab guard — before any mutation.** The trusted
   authorization document `/etc/lab/ace-lab/authorization.yml` (when
   present) must not grant projects the manifest does not declare: a
   ready or foreign lab is refused with a classified error and zero
   writes, identically in wet runs and `--dry-run` (prediction parity).
2. **prepare (L8.1)** — accounts → directories → keys → roles → gems,
   exactly as `ace-lab prepare` (same organism, same per-item report;
   the declared gem set converges into the declared target runtime).
3. **project add (L8.2) per declared project** — repository, private
   `_overseer`, project registry, exactly as `ace-lab project add`.
   Projects are isolated: one failing project does not block the
   others. When `prepare` did not converge, every project is reported
   as a dependency failure instead of being attempted.
4. **grants** — the trusted-tier principal grants from the manifest's
   `grants` section are converged into the `principals` mapping of the
   authorization document: this is the installer-owned configuration
   that makes the installed projects visible to `ace-lab projects` and
   `ace-overseer projects` (see the L8.2 boundary above). Grants only
   grow: a manifest that would remove an existing grant is refused.
   Principals the manifest does not mention and every other section of
   the document (e.g. HITL adapter policy) are preserved untouched —
   and a converged re-run writes nothing at all, so the document's
   admin-authored comments stay byte-identical. A manifest with no
   `grants` over an absent document is a no-op (`skipped`): no empty
   authorization file is ever created. Before any write the existing
   document's principals are validated exactly like the read side
   (shared validation with the grants resolver): a malformed policy is
   refused with a classified error instead of silently rewritten, and
   whitespace-padded principal names are normalized so they cannot
   coexist with a stripped twin.
   The write is atomic (temp file + rename, mode 0644). Grants are
   configured only when the earlier phases converged — never over a
   partially failed install (no pretend success).

Statuses: `prepare` contributes its own per-item statuses; each project
contributes `created|exists|updated|would_*|failed` per step; grants
report `created|updated|exists|skipped|would_*|failed` plus a
per-principal breakdown and the `kept` list (present and possibly
empty, so machine consumers see a stable schema). `ok` means every phase converged. A wet run with failures
prints the report first, then exits non-zero enumerating each
`<phase>/<item>: <message>`; `--dry-run` predicts with zero mutations
and exits 0.

Idempotence and resume design: every step is idempotent, so an
interrupted re-run converges where steps already completed (accounts
`exists`, repositories `exists`, grants `exists`) without duplicates or
lost configuration — the per-step record is the resume mechanism; no
journal exists or is needed for convergence. See
[Resuming an interrupted install](#resuming-an-interrupted-install-l84).

### Resuming an interrupted install (L8.4)

```bash
ace-lab install              # same command: recognizes and finishes its own partial state
ace-lab install --dry-run    # previews exactly which steps exist and which would run
```

An installation interrupted mid-run (crash after accounts, directories,
keys, a project, or part of the grants) is resumed by running the same
`ace-lab install` command again. Recognition is derived from the real
artifacts the steps read and write — there is no journal, marker file
or second state owner:

- already-done steps report `exists`/`verified` and are not reworked:
  the converged directory and key pair keep their inode and content, an
  already-cloned repository keeps its worktree (untracked files
  included) and a converged trusted document stays byte-identical;
- missing steps complete: a key pair whose public half is missing
  regenerates only that half from the surviving private key; a project
  whose repository exists finishes only `_overseer` and the registry;
  partially granted own principals converge while principals and
  sections the manifest does not mention are kept;
- grants are configured only when prepare and every project converged
  (no pretend success over a partial install).

Own-partial vs foreign is distinguished per step, not only for grants:
each already-present artifact is checked against what the manifest
declares before it is touched, and mismatching content is refused —
never taken over, never cleaned:

| Step | Foreign state | Result |
| --- | --- | --- |
| declared directory | symlink, non-directory, or foreign ownership | step fails with a resolve-manually message; projects and grants are gated as dependency failures |
| key pair | foreign-owned key files or `.ssh`, non-regular file | step fails with a resolve-manually message |
| gem set | symlinked or non-directory runtime, missing privileges, or a failed probe/install | every gem item fails with a classified message; projects and grants are gated as dependency failures |
| project repository | non-empty non-Git directory, or a Git repository with a different origin | step fails: "refusing to take over a foreign location" / "refusing to overwrite an existing registration"; the other projects still run (isolation) |
| grants | trusted document granting projects outside the manifest, or a document that fails verification/parsing | the whole install refuses before any mutation ("refusing to install over a foreign lab"), wet and in `--dry-run` alike |

When resume is not possible, the wet failure names every blocking step
concretely (`install failed (N step(s)): <phase>/<item>: <message>`);
`--dry-run` predicts the same per-step refusals with zero mutations
and exits 0.

Boundaries: `install` does not verify readiness under the target
accounts (that is `verify`, below); HITL adapter configuration beyond
preserving the existing trusted document sections is not orchestrated
by this slice.

## Verify (L8.5)

### `ace-lab verify [--format table|json] [-q]`

```bash
ace-lab verify                 # per-check table; exit 0 only when ready
ace-lab verify --format json   # stable machine report for the overseer / next tool
```

`verify` is the read-only end-of-install check that the lab is ready
UNDER THE TARGET ACCOUNTS — not merely for the installer's account. It
reads the same artifacts `install`/`prepare` derive truth from (the
trusted install manifest, the filesystem's permission bits and
ownership, the repositories, the per-project registry and the trusted
authorization document) and writes nothing anywhere: no journal, no
second state owner. (The key fingerprint probe may use an ephemeral
tmpdir scratch — 0600, removed afterwards — never a durable write.)
Because it judges converged artifacts only, a
fresh install and a resumed one verify identically — there is no
hidden gap after resume.

Per-check sections, each reported as `pass` / `fail` / `unknown` with
a concrete reason (never a bare boolean):

| Section | Checks, as the target account |
| --- | --- |
| accounts | account exists; home matches the manifest; login shell is usable (non-login shells block readiness) |
| directories | declared directory exists with the declared mode and owner |
| keys | the pair is usable: modes (0600/0644/`.ssh` 0700), account ownership, and the public fingerprint matches the key derived from the private half (the same probe `prepare` applies) |
| roles | instruction source readable by the role's account (the `prepare` role verifier) |
| repositories | the path is the repository toplevel, the origin matches the manifest remote; local origins are probed with `git ls-remote`, network origins are reported `unknown` (not dialed by the read-only verifier) |
| grants | the trusted document is present and verifiable, and every manifest principal's grants resolve through the real read-side mechanics (`CallerAuthorizer`) to the declared projects |
| registry | each project is registered in its `.ace/lab/config.yml` (visibility through the configuration cascade) |
| overseer | `.ace-tasks/_overseer/` exists and is ignored by Git (`git check-ignore`) |
| adapters | configuration is a mapping; a declared local command resolves (probed for the target executors); `kind: hitl` routes are installed in every project's `.ace/hitl/config.yml` and satisfy the runtime loader's rules |
| tools | each required tool resolves to an executable the target executors can run (presence + permission probe, no execution) |
| gems | each declared gem is installed at its EXACT declared version in the declared target runtime — judged through the same read-only probe prepare converges from; a missing runtime, a missing gem or a version mismatch blocks readiness (a missing `gem` executable reports `unknown`, the offline posture) |

The overall verdict is `ready` only when no check failed. A failure
never hides healthy data: the full report renders first (table or
JSON), then the command exits non-zero naming every failed check
concretely (`lab is not ready (N failed check(s)): <section>/<item>:
<reason>`). `unknown` (a network remote) is reported and counted but
does not block readiness — it is not a failure, and treating it as one
would make `verify` unusable offline. The JSON report shape is stable:
`ready`, `machine`, `manifest`, `authorization_path`, `checks`
(per-section lists), and `counts` (`pass`/`fail`/`unknown`).

Key material hygiene is inherited from the provisioner: only the
public fingerprint ever appears in a report; private key bytes stay
inside the `ssh-keygen` subprocess.

## Planned waves

> **L7 remainder:** `ace-lab status` is delivered; the remaining L7 scope
> (configurable `ace-overseer status` aggregation, pi continuation) lives in
> its own packages and is not available yet.
>
> **Planned (L8):** the preparation phase is delivered as `ace-lab
> prepare` (L8.1), project onboarding as `ace-lab project add` (L8.2),
> the full installer as `ace-lab install` (L8.3), resuming the
> installer's own interrupted installation as the same `ace-lab
> install` re-run (L8.4), and end-to-end readiness verification under
> the target accounts as `ace-lab verify` (L8.5).

## Boundaries

`ace-lab` owns no task, assignment, HITL, or worktree state. There is no
journal, authority/admission service, daemon, queue engine, command kernel, or
extra state cache in this package.

The installed authority/admission/journal/command path is removed in L1: the
`service request|status|listen`, `ace-lab assignment …`, `run`, `run-status`,
and `command execute` commands no longer exist. The local file-based flow does
not use them. The Forgejo merge adapter and its trusted configuration loader
remain as provider building blocks; the local flow does not invoke them.
