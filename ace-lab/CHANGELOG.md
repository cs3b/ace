# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `ace-lab verify` (L8.5, task 8xg.t.sbz.7.4): read-only end-of-install
  readiness verification UNDER THE TARGET ACCOUNTS. For every account,
  directory, key pair, role, project and grant declared in the trusted
  install manifest it recomputes the facts from the same artifacts
  install/resume derive truth from — no journal, no second state
  owner, nothing written. Checks: account existence/login class
  (non-login shells block readiness), declared directory mode/owner,
  key pair usability (0600/0644/`.ssh` 0700 modes, account ownership,
  and the public fingerprint matching the key derived from the private
  half — the exact probe `prepare` applies, now exposed as a public
  read-only `KeyProvisioner#pair_fingerprint`), role instruction
  readability by the role's account (the `prepare` role verifier),
  repository structure with origin matching the manifest remote
  (local origins probed with `git ls-remote`; network origins reported
  `unknown`, not dialed by the read-only verifier), principal grants
  resolved through the real read-side mechanics (`CallerAuthorizer`)
  against the trusted document, per-project registry visibility, and
  the private `.ace-tasks/_overseer/` folder being present and
  Git-ignored (`git check-ignore`). Every check reports pass/fail/
  unknown with a concrete reason; a failure never hides healthy data
  (the full report renders first) and blocks the `ready` verdict; the
  command exits non-zero naming every failed check. Output: table or
  stable JSON (`ready`/`checks`/`counts`) for the overseer or the next
  tool. A fresh install and a resumed one verify identically.

- Resuming the installer's own interrupted installation (L8.4, task
  8xg.t.sbz.7.3): re-running `ace-lab install` after a mid-run crash
  recognizes the partial state — derived from the real artifacts the
  steps read and write, with no journal or marker file — and finishes
  it. Steps that already completed report `exists`/`verified` without
  destructive rework (converged directories and key pairs keep their
  inode; a converged trusted document stays byte-identical), missing
  steps complete (a half-written key pair regenerates only the public
  half; partially granted own principals converge while foreign
  sections of the document are kept), and grants are still configured
  only over a converged install. Foreign content is refused at every
  step: a project directory with foreign content, a repository with a
  foreign origin, a foreign declared directory (e.g. a symlink) and a
  trusted document granting undeclared projects each fail their step
  with a classified, concrete message before any takeover or cleanup,
  wet and in `--dry-run` alike (prediction parity on partial states).

- `ace-lab install` (L8.3, task 8xg.t.sbz.7.2): the full new-lab
  installation from the trusted install manifest, composing the
  existing molecules in a fixed order — `Prepare` (L8.1: accounts,
  directories, keys, roles), `ProjectAdd` (L8.2) per manifest-declared
  project, and the new `GrantProvisioner` that writes the trusted-tier
  principal grants into `/etc/lab/ace-lab/authorization.yml` so the
  installed projects are visible to `ace-lab projects` and
  `ace-overseer projects` with no read-side change. The manifest schema
  (still v1) gains optional `projects` (id/path/remote/label; unique
  ids and paths) and `grants` (principal → declared project ids)
  sections. A foreign lab is refused before any mutation: an existing
  trusted document granting projects the manifest does not declare
  aborts with a classified error and zero writes, and a manifest that
  would remove an existing grant is refused (grants only grow);
  undeclared principals and every other document section are preserved.
  A converged wet re-run writes nothing at all — the trusted document
  (admin-authored comments included) stays byte-identical; a manifest
  with no `grants` over an absent document is a no-op (`skipped`,
  nothing created). The existing document's principals are validated
  exactly like the read side before any write (shared validation with
  `GrantResolver`; malformed policies are refused with a classified
  error instead of silently rewritten, whitespace-padded principal
  names are normalized, and duplicate-after-strip principals are
  rejected by the manifest schema).
  Idempotent re-runs converge (`exists` statuses); `--dry-run`
  faithfully predicts every phase (`would_*`) with exit 0, wet failures
  render the report then exit non-zero naming each failed step.

- `ace-lab project add` (L8.2, task 8xg.t.sbz.7.1): registers a project
  and makes it ready for team work. A `ProjectAdd` organism runs three
  idempotent steps in a fixed order — `RepositoryProvisioner` (clone the
  declared origin into the target path, or verify/converge an existing
  repository's origin; refuse a different origin or a foreign
  non-repository location), `OverseerProvisioner` (prepare the private
  gitignored `.ace-tasks/_overseer/` folder plus its `.gitignore` entry,
  never touching existing content), and `ProjectRegistry` (register the
  project's id/label/path/remote in the project-tier
  `.ace/lab/config.yml` cascade document, refusing contradictory
  registrations, path conflicts, unparseable or foreign documents before
  any write). Consumers need no change: `ace-lab status` classifies the
  project as configured through the ordinary cascade and
  `ace-lab projects` / `ace-overseer projects` list it through the
  existing topology surface. `--dry-run` predicts with zero mutations;
  wet failures print the report and exit non-zero naming each step.

- Adapter and tool declarations in the install manifest (tasks
  8xg.t.sbz.7.2/.7.4, LAB-3): the schema (v1) now accepts an
  `adapters` list (`id`, `kind` `communication`/`hitl`, optional local
  `command`, optional `config` mapping) and a `tools` list of required
  executable names. `ace-lab install` validates and normalizes the
  declarations (the trusted manifest stays their single state owner —
  no second configuration file), echoes them in its report under
  `adapters`/`tools`, and finishes with a NEW final `verify` stage over
  the converged lab whose readiness gates the install's `ok` (dry runs
  skip the stage — nothing has converged to verify). `ace-lab verify`
  gained matching checks: every required tool must resolve to an
  executable on PATH (presence only — no execution, no network), and
  every declared adapter must have a valid configuration with its
  command, when declared, resolvable; a missing tool or broken adapter
  is a classified check failure that blocks readiness, never a crash.
  Network reachability of communication adapters stays out of scope
  (L9). The install CLI renders the verify verdict and names every
  failed check in its non-zero-exit summary.

- Target-executor ownership propagation for installed projects (task
  8xg.t.sbz.7.4, LAB-2): `ProjectAdd` accepts an `owner` account and,
  when the installer runs as root, chowns a converged project tree to
  the declared executor (derived by install from the owning declared
  directory above the project) so root installs yield
  executor-writable repositories; non-root installers report the step
  skipped and `verify` judges the executor's actual access on the real
  permission bits. The report carries the new `owner` step.

### Changed

- `ace-lab status` refined to the reviewed `l7-statuses` implementation
  (task 8xg.t.sbz.6.0; extracted from the superseded PR #382): tri-state
  classification moved into a `ConfigStateClassifier` molecule with the
  corrected config cascade precedence and missing-state classification,
  ADR-034 state-owner scanning isolated into a `LabStateScanner`
  (per-location error isolation), and a `StatusReport` model behind a
  `StatusService` organism — table/json/`-q` output preserved.

### Fixed

- Critical review fix: `ProjectAdd`'s privileged ownership propagation
  called `FileUtils.chown_R` with the wrong argument order (path
  passed as the user, the gid Integer as the file list), so every
  root install with a declared owner failed the `owner` step with a
  misleading error. The chown is now invoked as
  `chown_R(uid, gid, path)`, rescued for TypeError as well, and is an
  injectable seam so the root branch is testable without uid 0.
- Review fix: an unset or empty `PATH` no longer produces false FAILs
  for the tools/adapters checks — the probe is tri-state and yields
  `unknown` ("PATH is unset; cannot probe …") instead of blocking
  readiness in minimal-PATH environments.
- Review fix (trust posture): a privileged (root) installer never
  executes the repository-controlled `bin/ace-nav` binstub during
  final verification — under root only the PATH-installed resolver is
  used, consistent with the LAB-1 symlink refusals.
- Review fix: an unexpected exception from the final verify stage is
  a classified `verify: failed` install stage, never a raw crash.
- Review fix: a symlinked `.gitignore` is refused up front even when
  the ignore rule would already match — no privileged read-through
  (`git check-ignore` follows the link) either.

- Privileged provisioning writes no longer follow repository-controlled
  symlinks (LAB-1, audit PR #393): `OverseerProvisioner` refuses a
  symlinked `.gitignore` (checked via lstat before any read/append) or
  `.ace-tasks` component before creating anything, and
  `ProjectRegistry` refuses a symlinked `.ace`/`.ace/lab` ancestor and
  creates its atomic-write temp file EXCLUSIVELY (`O_CREAT|O_EXCL`)
  under an unguessable random name instead of the predictable
  `.config.yml.tmp.<PID>` that a pre-planted symlink could capture
  (F3) — a committed symlink can no longer redirect installer writes
  outside the project.

- `ace-lab verify` now judges project readiness for the declared
  TARGET EXECUTOR, not the invoking installer (LAB-2): every account a
  role binds must be able to reach the project through its ancestors
  (search permission) and read/write the project directory — a
  repository behind an installer-owned 0700 ancestor with a different
  target UID is NOT ready even though the installer's git access
  succeeded. The check shares the role verifier's governing-class
  permission logic so the two can never drift apart.

- Final verification resolves protocol role instructions
  (`wfi://`, `prompt://`, `tmpl://`) through the actual resolver for
  the execution context (LAB-4): prepare's syntax-only protocol check
  is no longer reused as proof of readiness, so a syntactically valid
  but nonexistent role (`wfi://does-not-exist/not-a-role`) fails the
  check and blocks readiness. Resolution runs `bin/ace-nav resolve`
  (project binstub, else PATH) from every declared project root; an
  environment without the resolver reports `unknown` and does not
  block, mirroring the offline posture for network remotes.

- `_overseer` ignore provisioning decides through REAL Git evaluation
  (LAB-5): `OverseerProvisioner` uses `git check-ignore` (the same
  probe verify applies) instead of matching `.gitignore` lines, so a
  later negation (`!.ace-tasks/_overseer/`) no longer masquerades as
  an effective ignore rule — the effective rule is appended and the
  decision re-evaluated to confirm.

- A malformed per-project registry (e.g. `topology: invalid`) is now a
  classified per-project check failure instead of a `TypeError` from
  `dig` that killed the entire readiness report (LAB-6): the document
  is validated through `TopologySchema.normalize!`, and healthy checks
  beside the failure keep running and stay visible.

- `RepositoryProvisioner` compares project identity against the RAW
  stored remote URL (`git config --get remote.origin.url`) instead of
  the `insteadOf`-expanded `git remote get-url` value (LAB-7):
  idempotent re-add/resume under a common SSH rewrite configuration
  (`url.<base>.insteadOf`) no longer false-fails an identical project —
  connection rewriting is Git transport policy, not a changed identity.

- `KeyProvisioner`'s internal pair-usability probe could return
  `false` instead of `nil` for an unusable pair (the new public
  `pair_fingerprint` probe normalizes to `nil`); existing internal
  callers treated both as falsy and were unaffected.

- `GrantProvisioner` failure reports now carry `kept: []` like every
  other grants status, so machine consumers of the install report see
  one stable schema for the grants section regardless of outcome.

- `project add` review fixes (round 1, task 8xg.t.sbz.7.1):
  `RepositoryProvisioner#repository?` now requires the target path to
  be the Git repository toplevel (`rev-parse --show-toplevel` compared
  against the expanded path), so a non-empty directory nested inside a
  parent repository's work tree is refused as a foreign location
  instead of converging and mutating the parent's origin (8xikzhvh);
  `ProjectRegistry` pre-validates the loaded document with
  `TopologySchema.normalize!` (a malformed `topology.projects` entry is
  a classified "not this lab's registry" failure, not a `TypeError`
  crash — 8xikzhvi), validates the updated document before the dry-run
  branch so `--dry-run` predicts invalid id/label failures exactly like
  the wet run (8xikzhvj), writes the registry atomically via a temp
  file plus `File.rename` (8xikzhvk), updates the label on re-add with
  a changed `--label` and reports the new `updated`/`would_update`
  statuses (8xikzhvl), refuses an empty-but-existing registry file with
  a clear message (8xikzhvq), and `OverseerProvisioner` no longer
  counts a `!` negation line as an existing ignore entry (8xikzhvp).
  `docs/usage.md` documents the trusted-tier grant and project-root
  prerequisites for listing the new project (8xikzhvm) and that
  `path`/`remote` registry fields are installer-owned data outside the
  public projection (8xikzhvs).
- Security (8xi1p4z5): when an ancestor of the key path denies search
  permission (`EACCES` on realpath, e.g. an account locking out the
  unprivileged installer), `KeyProvisioner`'s git-worktree guard now
  fails closed — the path is judged as inside a worktree and refused —
  instead of falling back to the lexical spelling, which a symlink
  behind the denied ancestor could fool (the pre-F2 behavior). The
  `:repair_public` classification branch is documented as a deliberate
  TOCTOU safety net (8xi1p4z7), and the dry-run contract comment now
  states that prediction uses read-only filesystem probes plus
  read-only `ssh-keygen` invocations (8xi1p4z4).
- `RoleVerifier` (8xi16mz1): the reachability walk now resolves the
  instruction file's OWN symlink too (`File.realpath(path)`), not just
  the ancestors of the link's path. Previously a symlinked instruction
  pointing at a file behind an unsearchable directory (e.g. 0700
  other-owned) verified as reachable because only the symlink's own
  ancestors were checked; the target's directory chain is what open(2)
  traverses, so it is what the walk judges now.
- `KeyProvisioner` (8xi16mz2/8xi16mz5/8xi16mz6): the dry-run
  prediction and the wet existing path now share one
  `classify_existing_pair` step (read-only `pair_fingerprint`,
  including a 0600 tmpdir copy when the private key's mode has drifted
  and ssh-keygen would refuse to load it), run BEFORE the mode-drift
  branch. A garbage pair with mode drift now predicts `failed` (not
  usable) instead of `would_fix_mode` — the wet run converges the
  modes and then fails verification, and the prediction says exactly
  that; `would_fix_mode` is only ever predicted for a verified pair.
  The duplicated not-usable message became the shared
  `NOT_USABLE_TEMPLATE` constant.
- Security (PR #392 F2): `KeyProvisioner`'s git-worktree guard now
  resolves the PHYSICAL ancestors of the key path (realpath of the
  deepest existing ancestor plus the lexical tail) before any
  generate/mutation step. Previously the guard walked lexical
  directories only, so `/outside/alias/.ssh/id_ed25519` with `alias`
  a symlink into a repository passed and the real key landed inside
  the worktree — including when `.ssh` did not exist yet behind the
  alias. Symlinked ancestors resolving outside any worktree remain
  legitimate.
- `KeyProvisioner` (PR #392 F4): a pair that cannot be verified as
  usable is now a `failed` item, never `exists`/`created` with
  `fingerprint: nil`. Verification requires the `.pub` fingerprint to
  match the public key derived from the private key via
  `ssh-keygen -y` (comparing `-lf` on the private file is not sound —
  ssh-keygen resolves the adjacent `.pub`), so garbage files and a
  `.pub` belonging to a different private key both fail the prepare
  aggregate (`ok: false`, non-zero exit). An unknown pair is still
  never overwritten (takeover-refusal policy).
- `RoleVerifier` (PR #392 F5): instruction files are verified for
  reachability, not just read bits — every ancestor directory of the
  resolved path (realpath follows ancestor symlinks) must grant the
  account search permission through its governing POSIX class (owner,
  primary/supplementary group via the `group_source` seam, or other;
  shared with the file-read check so the two cannot drift). A 0644
  file behind a 0700 directory owned by another account is now
  `failed`, not `verified`. ACLs remain out of scope.
- `AccountProvisioner` (PR #392, macOS UID allocation):
  `next_darwin_uid` parses only the trailing `UniqueID` column of
  each `dscl -list` line instead of scanning the whole output, so
  digits inside account names such as `deploy-2026` can no longer be
  mistaken for UIDs.

## [0.12.0] - 2026-10-18

### Added

- `ace-lab prepare [--dry-run] [--format table|json] [-q]`: the lab
  preparation phase (L8.1 / 8xg.t.sbz.7.0). Reads a trusted install
  manifest from the fixed root-owned deployment path
  `/etc/lab/ace-lab/install.yml` (verified through the same fail-closed
  `GrantResolver.read_verified` seam as the authorization document;
  deliberately no `--manifest` flag — a caller-selected manifest could
  manufacture privileges) and idempotently prepares accounts →
  directories → keys → roles in that fixed order, each through its own
  molecule: `AccountProvisioner` (darwin `dscl`/`createhomedir`, linux
  `useradd`; argv arrays only), `DirectoryProvisioner` (mode/ownership
  with symlink and foreign-takeover refusal; only mode drift on an
  owner-matching directory is repaired), `KeyProvisioner` (ed25519 pairs,
  `.ssh` 0700 / private 0600 / public 0644 with account ownership,
  missing-`.pub` regeneration, git-worktree guard) and `RoleVerifier`
  (account binding plus protocol-or-readable-file instruction sources).
  `Atoms::InstallSchema` validates the v1 manifest
  (machine/accounts/directories/keys/roles) with value-free messages;
  `Organisms::Prepare` aggregates a deterministic JSON report where `ok`
  means zero failed items, and key/role items whose account failed are
  reported as dependency failures. Missing permissions are classified
  with actionable messages; secret hygiene is enforced by tests: reports
  carry the public fingerprint and never private key material. A wet run
  with failed items prints the report and exits non-zero naming each
  `<section>/<item>`; `--dry-run` predicts (`would_*` statuses, zero
  mutations) and exits 0 on conflicts. The manifest is a deployment
  document, not task state (ADR-034): nothing outside the manifest is
  touched and no journal is written.

### Fixed (review round 1)

- `KeyProvisioner` refused symlinks on the private key path but followed
  them on the other account-controlled paths: a planted `~/.ssh`
  symlink was accepted by `mkdir_p` and then chmodded/chowned through
  (directory-ownership takeover of an arbitrary path in a privileged
  run), and a dangling `<key>.pub` symlink turned public-key
  regeneration into an arbitrary privileged write. Both paths are now
  `lstat`-guarded before any mutation, the `.pub` write uses
  `O_NOFOLLOW`, and adversarial symlink tests assert refusal with zero
  mutation of the target.
- `--dry-run` now predicts the fresh-machine flow it exists to predict:
  keys and roles of an account the account phase would create render as
  `would_create`/`verified` instead of `failed` dependency errors
  (prediction no longer re-consults live passwd for the account), an
  existing private key with a missing `.pub` predicts
  `would_repair_public` (matching the wet run's regeneration), and mode
  or ownership drift on an existing pair predicts `would_fix_mode`. An
  existing directory whose declared owner would be created reports a
  prediction limit with a rerun hint instead of a bare dependency
  failure.
- `Atoms::InstallSchema` duplicate-declaration messages are value-free,
  as the class contract already promised (the offending username/path/
  id is no longer interpolated).
- darwin account creation sets the complete dscl shape, including
  `GeneratedUUID` (fresh UUID) and `Password "*"`; `AccountProvisioner`
  classifies a missing `useradd`/`dscl` binary as `enoent`
  ("not found in PATH") like `KeyProvisioner` instead of
  `exit failed`.
- `DirectoryProvisioner` failed entries always carry the full
  `{path, owner, mode, status, message}` shape (rescue paths included),
  and the prepare CLI shares one section-namer map between the table
  renderer and the failure summary; `usage.md` documents the
  intermediate-path-component residual policy (leaf-only symlink
  refusal).

### Fixed (review round 2)

- `KeyProvisioner`'s wet *existing-key* path lacked the `.ssh` symlink
  guard entirely: with a regular key file already present (found via
  `lstat`), the run went straight to chmod/chown of the key pair —
  following a planted intermediate `~/.ssh` symlink and enabling
  cross-account private-key takeover with default manifests (uniform
  `<home>/.ssh/id_ed25519` filenames). The guard now runs at the top of
  the existing path (and in `generate`), and the regenerated `.pub` is
  chmodded/chowned fd-based on the already-`O_NOFOLLOW`-opened handle,
  closing the post-open race a path-based chmod/chown would reopen.
- Create-path TOCTOU window closed as far as stdlib allows: leaf
  directories (`.ssh` and declared directories) are created with
  component-wise `Dir.mkdir` (whose `EEXIST` on a planted symlink
  refuses instead of following it), re-`lstat`ed immediately after
  creation — refusing chmod/chown unless the leaf is a real directory
  the installer just created — and the directory mode-fix path re-lstats
  before chmod so a leaf swapped after the owner check is refused. The
  microscopic window between that final re-lstat and the path-based
  directory chmod/chown is documented as accepted in `usage.md` (no
  fd-based directory chmod in Ruby stdlib). Mid-flight-plant tests stub
  the mkdir step to plant a symlink and assert refusal with zero
  chmod/chown.
- Filesystem `Errno::ENOENT` is no longer blanket-mapped to "ssh-keygen
  not in PATH" (a missing binary is already classified via the runner's
  `enoent` status); it now prescribes the correct remedy: "key path …
  disappeared while preparing; rerun ace-lab prepare".
- linux account creation reports a message when the post-`useradd` uid
  lookup fails ("created but its uid could not be resolved yet"), so
  JSON consumers can distinguish it from a normal creation.
- The prepare table renders a truncated public fingerprint
  (`SHA256:` + 20 characters) for created/exists key rows, matching the
  README's "reports fingerprints" claim outside `--format json`.
- The install-manifest loader no longer embeds GrantResolver's
  "authorization file" wording inside install-manifest errors; the
  wrapper message is value-free and names the manifest path only.
- Refreshed stale cross-references now that L8.1 ships:
  `docs/lab-flow.md`'s L8 row (partially shipped), `docs/architecture.md`'s
  ace-lab bullet, and the gemspec summary/description (no longer
  "read-only"); the foreign-owner takeover refusal now also names the
  sudo rerun remedy. `usage.md` documents the dry-run role-file
  readability prediction limit (would-create accounts) and the symlink
  hardening/residual-race policy.
- `Organisms::Prepare#call` no longer mutates `@effective_dry_run` —
  the effective value is a local threaded explicitly into the
  per-call provisioner factories (stateless organism across calls); the
  fingerprint regex dropped a stray duplicate `+` in its character
  class.

### Fixed (review round 3)

- The private-key chmod/chown was still path-based (`FileUtils` by
  path): once `.ssh` was chowned to the account, the account could
  race-swap the key file for a symlink inside its own `.ssh` and have
  a privileged rerun chown an arbitrary file to itself. Both key files
  are now mutated only through `O_NOFOLLOW`-opened handles (the
  `regenerate_public` pattern): chmod/chown are fd-based, a mid-flight
  symlink swap surfaces as `ELOOP` and is refused, and a post-keygen
  re-`lstat` refuses a keygen that wrote through a swapped-in symlink
  before any ownership transfer. Adversarial tests assert refusal with
  zero mutation of the swap target.
- Dry-run fidelity: a planted `.ssh` symlink is now refused by the
  *existing-key* prediction too (the refusal check runs before the
  stat branch, matching the wet run), and a missing directory whose
  declared owner account failed the account phase is predicted as the
  wet run's `owner_unavailable` failure instead of `would_create`
  (the organism threads its computed available-account set into the
  directory stage, mirroring keys/roles).
- Ownership-drift policy is now symmetric: a pre-existing key pair
  owned by neither the declared account nor the installer is refused
  (`refusing takeover`), like directories, instead of being silently
  chowned — relevant for reused home directories with default key
  paths.
- `Psych::DisallowedClass` is reported as "YAML types outside the
  permitted set" instead of "could not be parsed as YAML" (different
  remedy; strictness unchanged).
- An existing account whose passwd home differs from the manifest home
  now reports the drift in its message; the manifest home stays
  authoritative for key paths (behavior unchanged).
- Keys of an account that was created but whose uid is not yet
  resolvable (linux passwd lag) fail with "rerun ace-lab prepare"
  instead of the misleading "fix the account phase first".
- The copy-pasted `FakeEntry` passwd stub lives in `test_helper.rb`
  once instead of six test files.

### Fixed (review round 4)

- `KeyProvisioner` leaked raw `SystemCallError` past its rescues (CLI
  backtrace, remaining manifest items unreported): with the manifest
  home authoritative for key paths, a leftover regular file at the
  home made `mkdir_p` re-raise `Errno::EEXIST` out of the molecule.
  The parent-path `mkdir_p` is now rescued (`EEXIST`/`ENOTDIR`) as a
  classified failed item, and a method-level `rescue SystemCallError`
  classifier on the provision entry path (mirroring
  `DirectoryProvisioner`) names the errno class and prescribes a rerun
  for anything else (e.g. `ELOOP` on the path-based directory chmod in
  a race).
- The ".ssh is 0700" guarantee is converged, not just set at creation:
  the wet existing-key path now chmods/chowns `.ssh` like the create
  path (path-based, same documented residual), and dry-run predicts
  the drift as `would_fix_mode` alongside key-file drift.
- `RoleVerifier#readable_by_account?` now short-circuits per POSIX
  permission class: a file owned by the account with only the group
  bit set previously verified through the gid match even though the
  runtime cannot read it (the owner class does not fall through).
- A pre-existing `.ssh` owned by neither the declared account nor the
  installer is refused as a takeover on the generate path, the wet
  existing-key path and the dry-run prediction (previously chmod
  0700 + chown silently took over a third party's directory) — the
  documented "refusing takeover" policy now covers `.ssh` like key
  files and declared directories.
- Dry-run fidelity: `AccountProvisioner` classifies unsupported
  platforms *before* the `would_create` prediction, so `--dry-run` on
  an unsupported platform predicts the wet failure instead of a
  creation it cannot perform.
- An exec-level `SystemCallError` from a provisioning subprocess
  renders "command could not be executed (`useradd`, `Errno::…`)"
  instead of the contradictory "command failed (useradd, exit
  failed)" — in both `AccountProvisioner` and `KeyProvisioner`.

### Fixed (review round 5)

- Security (S1): the key *generate* path lacked a pre-keygen guard on
  `<key>.pub` — all guards before `ssh-keygen` covered `.ssh` and the
  private path only, so a pre-planted dangling `.pub` symlink in an
  owner-matching `.ssh` passed every check and keygen created the
  `.pub` *by path through the symlink* (root-owned file creation at an
  account-chosen location). The generate path now `lstat`s the `.pub`
  before invoking `ssh-keygen` and refuses non-regular entries
  (mirroring `regenerate_public`), and `predict`'s missing-private
  branch mirrors the refusal so dry-run predicts it instead of
  `would_create`. A pinned comment now states the invariant: every
  wet-path refusal must have a predict counterpart.
- Security (S2): the `.ssh` ownership transfer on the generate path is
  deferred until *after* the post-keygen verification — previously
  `.ssh` was chowned to the account before keygen ran, letting the
  account plant a symlink inside its own `.ssh` during the keygen
  window with the post-keygen lstat catching it only after the write.
  While keygen writes by path, a freshly created `.ssh` now stays
  installer-owned 0700 (unwritable by the account). `usage.md`
  documents the remaining residual explicitly: the account-owned-home
  rename race (and pre-existing account-owned `.ssh` directories),
  where a substitution is caught by the post-keygen re-`lstat` after
  the write — whatever lands is root-owned 0600, a file-creation
  primitive, not an escalation. A staged-keygen-in-temp-dir +
  `File.rename` variant was considered and rejected: it does not fit
  the guard chain more cleanly than the deferred transfer and adds a
  second write path to verify.
- The unresolved-uid remedy (linux post-`useradd` passwd lag) is now
  threaded into the directory and role stages, mirroring keys: items
  under an account that was created but whose uid is not yet
  resolvable fail with "was created but its uid is not yet resolvable;
  rerun ace-lab prepare" instead of the factually wrong "fix the
  account phase first" (that phase did not fail).
- A signal-killed provisioning subprocess no longer renders a
  malformed "command failed (`useradd`, exit )" — the exit status
  falls back to "signal `<termsig>`" in both provisioners' `run_argv`
  (exitstatus is `nil` when the child died by signal).
- `RoleVerifier#readable_by_account?` covers supplementary groups: the
  group permission class now matches any group the account holds
  (injectable group-membership seam over an `Etc.group` scan), not
  only the primary gid — a group-readable instructions file held
  through a supplementary group no longer false-fails verification.
- Dry-run fidelity: an existing key pair under an account the account
  phase *would create* is no longer predicted plain `exists` where the
  wet run can refuse takeover — a pair owned by neither the installer
  nor the to-be-created account is conservatively predicted as the
  takeover refusal (pessimistic only in the pathological uid-reuse
  case), and `usage.md` documents this third prediction limit
  alongside the other two.

### Fixed (review round 6)

- Reject unknown top-level and entry keys in the install manifest with value-free messages (a typo like `acounts:` no longer converges nothing while reporting `ok`).
- Document the fourth dry-run prediction limit (installer-owned existing pair under a would-create account predicts `exists`; the wet-run ownership transfer is not predicted).
- Add a JSON-format wet-failure CLI test.

## [0.11.0] - 2026-10-18

### Fixed (review PR #383, round 3)

- `ace-lab status` resolves state locations against the git worktree top
  (falling back to the cwd outside a repository), so running it from a
  project subdirectory no longer misreports an initialized lab as absent.

### Added

- `ace-lab status`: read-only lab status snapshot with three strictly
  separated sections. `configuration` distinguishes `configured` (explicit
  cascade sources plus aggregate topology counts), `not_configured` (no
  explicit `.ace/lab/config.yml` or `~/.ace/lab/config.yml` — never an
  empty-ready lab), and `error` (source/parse/schema failure, path-bearing
  content-free message). `state_files` reports presence and entry counts for
  the canonical lab-flow locations (`.ace-tasks`, `.ace-tasks/_overseer`,
  `.ace-local/assign`, `.ace-local/coworker`, `.ace-local/hitl`, `.ace-wt`)
  with informational notes for absent coworker/overseer state — presence never
  declares readiness. `worktree_view` points at the existing
  `ace-git-worktree list` (k9y) instead of duplicating it. Table default,
  `--format json`; exit 0 whenever a report renders (8xg.t.sbz.6.0 / L7.1).

## [0.10.0] - 2026-10-17

### Removed

- Remove the protected authority/admission/receiver/listener/worker/recovery/publication/cleanup stack and the generic service-request admission/journal (`service request|status` without `--mode`), including their CLI selectors and tests.
- Remove the retained installed ordinary fixed-merge producer/receiver (`service request|status|listen --mode ordinary-merge`), the `ace-lab assignment …` ordinary-owner commands, and the installed run/command kernel (`run`, `run-status`, `command execute`), including their organisms, molecules, CLI registrations, authorizers, probes and tests.
- Remove the obsolete protected/generic policy, executor, input and receipt models plus the ordinary merge/assignment owner configuration (ordinary journal/authority/admission wiring) and command admission/policy/runtime helpers.
- Drop the now-unused runtime gem dependencies `ace-assign`, `ace-runtime`, `ace-herdr` and `ace-hitl`; the package keeps `ace-support-cli`, `ace-support-core`, `ace-support-config` and `ace-git-forgejo`.

### Changed

- `ace-lab` ships read-only topology queries only. The old installed authority/journal/command path is removed in L1 and the local file-based flow ([docs/lab-flow.md](../docs/lab-flow.md)) does not use it.
- Retain the Forgejo merge adapter and its trusted configuration loader as provider building blocks; the local flow does not invoke them.
- Refocus README and usage documentation on environment/project preparation, with the installer marked as planned L8.

## [0.9.0] - 2026-10-16

### Added

- Wire ordinary artifact retention to fresh installed project visibility and the existing exact service or canonical proposal decision; retention does not select an executor or consume publication authorization.
- Expose ordinary candidate upload, assigned review export/acceptance and canonical merge evidence through retained assignment requests. Compose their proof owner with the existing merge receiver and command executor journal.
- Compile configured candidate test commands from canonical references into sealed retained source views with explicit installed runtime and external output; revalidate native origin, current policy, source and configuration for test evidence. Preserve existing views and remove only fresh failed pre-child materializations.

- Expose ordinary driver status, bootstrap, progress, result and exact recovery commands using the selected Assign owner; authenticate coordinator replacement with bounded process-generation observation.

### Changed

- Require an explicit `purpose: command` or `purpose: test` on every installed command-policy entry. Only test commands with exact candidate head/tree and canonical successful execution can authorize merge evidence; previous entries without purpose are refused.

## [0.8.0] - 2026-10-16

### Added

- Compose ordinary Assign, HITL and Forgejo merge under one installed owner and journal, with readiness barriers and fresh native/project admission.
- Optionally serve existing mTLS HITL beside the ordinary Unix listener under the same canonical owner, journal, proposal policy and one-use OTP vault. Validate the configured project and service identity before either listener starts.
- Add retained assignment prepare/request clients and bounded canonical worktree observations. Separate stable configuration identity from changing decisions, preserve no-effect settlement after slow provider calls, and clean delivery handler process groups.
- This source cut enables initial installation; it does not claim autonomous release or installed two-project acceptance.

## [0.7.0] - 2026-10-16

### Added

- Run the ordinary merge listener and receiver through `service listen`, with authenticated admission, canonical Assign acknowledgement/status/receipts, restart reconciliation and bounded fixed execution.
- Invoke and inspect real Forgejo merges under the installed scoped service identity; revalidate authorization per request and bind the provider mutation to the approved candidate head.

### Changed

- Require ace-assign 0.69 and ace-git-forgejo 0.7 for the receiver record-listing and scoped provider APIs.

- Move the Forgejo merge provider ownership out of ace-lab (xz9.5): `ForgejoMergeAdapter` is now a thin delegation to the `ace-git-forgejo` provider (`Ace::Git::Forgejo::PullRequestApi` over its `HttpClient`, under the host-installed scoped service identity) — HTTP transport, authentication, payload shape, and failure classification live in the provider package, while the adapter keeps the receiver's closed outcome translation (`:invoked`/`:refused`/`:ambiguous`/`Unavailable`), the exact-head binding guard, and the normalized readback/nil-absence contract unchanged.

## [0.6.0] - 2026-10-14

### Added

- Add the ordinary fixed merge producer mode (`ace-lab service request/status --mode ordinary-merge`) per xz9.4: durable-once admission that issues the opaque reference only through the committed journal record, canonical SHA-256 request digests over the full eight-field binding, identical-replay acknowledgment, authorization/binding conflict refusals, read-only status, and terminal receipts bound to the admitted record and its execution identity.

## [0.5.2] - 2026-10-11

### Changed

- Follow the `ace-hitl` 0.14 lifecycle boundary line with dedicated per-authority socket-group configuration.

## [0.5.1] - 2026-10-10

### Fixed

- Require the published producer and consumer patch versions containing the protected context and managed-attempt APIs; exclude incompatible prior dependency graphs.

## [0.5.0] - 2026-10-08

### Added

- Deliver scoped RubyGems publication through the fixed receiver and canonical HITL authorization, preserving original request, OTP challenge and publication-result evidence.

### Changed

- Compose actual service/result owners without a read-proof completion handler; retain authenticated service settlement and cleanup boundaries.

### Fixed

- Load protected policy/listener dependencies directly and keep cleanup inspection tied to the original receiver and immutable result evidence.

## [0.4.0] - 2026-10-05

### Added

- Protected service policy, receiver and authority composition; incomplete full-service startup remains refused.
- Resolve immutable second-commander proposals through confirmed-delivery sixteen-hour policy and canonical Assign authorization.

### Changed

- Declare the required direct dependencies and minimum producer versions for this coordinated release: `ace-assign ~> 0.64`, `ace-runtime ~> 0.2`.

## [0.3.1] - 2026-10-04

### Changed
- Track the runtime-neutral ace-assign 0.62 line (the published 0.3.0 still allows `~> 0.61`, which resolves 0.62 — this release ships the tightened constraint).

## [0.3.0] - 2026-10-04

### Added
- **HITL delivery authorization policy (spec 8wq.t.34i)**: `Molecules::HitlAuthorizer` derives the lab-side transport facts (trusted transport uids, trusted HITL service identity, per-project Captain visibility) from the SAME trusted deployment document the grant resolver reads — uid-exact, project-scoped, never from claimed names or the cascade.

## [0.2.0] - 2026-10-02

### Added

- `service request` and `service status` for exact authorized operations,
  idempotent assignment-journal claims, peer-verified execution receipts,
  dry-run previews, and conservative uncertain-state recovery.

### Fixed

- Recheck the configured operation, authorization, and lease at dispatch;
  bind terminal receipts to the assignment request before acceptance.

## [0.1.0] - 2026-09-28

### Added

- Topology/routing CLI (`ace-lab`) addressing projects, agents, and services by
  stable IDs: `projects`, `agents`, `services`, `resolve`, `route` commands with
  deterministic JSON output (`--format json`).
- ADR-022 configuration contract for Lab topology (`schema_version: 1`) with
  validated stable IDs, project references, capability normalization, binding
  attestation fields, and verified-local-principal authorization mapping.
- Classified query outcomes: `missing`, `ambiguous`, `stale`, `unauthorized`,
  `invalid_configuration`.
- Allowlist-based public projection; tokens, auth-file paths, endpoint
  credentials, URL userinfo, query parameters, fragments, and raw pane/session
  identifiers never appear in public output.
