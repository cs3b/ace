# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.13.1] - 2026-10-26

### Added

- Gem-set installation into the target lab runtime (gad.2 acceptance
  gap #1, owner spec 8xg.t.sbz.7, L8 install group): the trusted
  install manifest (still schema v1) gains an optional `gemset` section
  — a sibling of `tools` — declaring the target runtime (`gem_home`,
  an absolute path converged as GEM_HOME and GEM_PATH) and the required
  gem set (`name` + exact `version`; unique names, versions validated
  as real Gem versions, so ranges and "latest" are rejected at load).
  A manifest without the section behaves exactly as before.
  `ace-lab prepare` (and therefore `ace-lab install`) converges the gem
  set into the declared runtime idempotently through a new
  `GemsetProvisioner` molecule: exact version present = no-op
  (`exists`), missing = installed, different version present = updated
  (the declared version installed; RubyGems keeps versions side by
  side and verify judges the declared set). The gem subprocesses run
  with `GEM_HOME`/`GEM_PATH` pinned to the runtime through the same
  argv runner seam as every other prepare step — with the invoking
  process's bundler context stripped (`RUBYOPT`, `RUBYLIB`,
  `BUNDLE_*`/`BUNDLER_*`), so `bundle exec ace-lab prepare` converges
  the LAB runtime instead of its own bundle. The runtime directory is
  created only with administrator privileges (the AccountProvisioner
  seam); a symlink or non-directory runtime is refused (the
  DirectoryProvisioner takeover posture); runtime failures fail every
  gem item as a dependency and gate the install's projects and grants
  like any other machine-level failure. `--dry-run` predicts
  `would_install`/`would_update`/`exists` read-only and predicts the
  wet privilege failure. The install report echoes the declared gemset
  under `gemset`. `ace-lab verify` gained a matching read-only `gems`
  check — every declared gem must be installed at its exact version in
  the declared runtime, judged through the SAME probe the provisioner
  converges from (a missing `gem` executable reports `unknown`, the
  offline posture). `project add` stays project-scoped: gem
  installation is machine-level provisioning and is deliberately not
  added there. (PR #77)


## [0.13.0] - 2026-10-20

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

- Review 8xirj8: a failed payload write inside `HitlRoutes`' exclusive
  temp-file helper no longer leaks the temp file (close + delete +
  re-raise); the shallow per-key merge semantics are documented.

- Review 8xir47 (findings 1, 3, 4): a decidable HITL route failure is
  no longer masked as UNKNOWN when PATH is unset (route failures take
  precedence over the PATH-unset probe message and always FAIL
  readiness); the ownership-skip message names the actually failing
  step instead of always blaming the repository step; the
  prepare-dependency project report carries the `hitl` key like every
  other ProjectAdd report variant.

- Review 8xir47 (findings 5-6) in `HitlRoutes`: the runtime route
  configuration (`.ace/hitl/config.yml`) is now written ATOMICALLY
  (exclusive temp file + rename, the ProjectRegistry discipline) — a
  crash mid-write can no longer truncate the operator-facing config.
  Convergence is now by route NAME everywhere: on re-install the
  manifest-declared keys are merged into the existing same-name route
  (manifest keys win, operator extra keys such as `pane: p5` survive
  instead of being silently replaced), operator-added routes are kept,
  and `verify` accepts a same-name route carrying every
  manifest-declared key/value even when the operator extended it with
  extra keys — an extended route no longer fails verification until
  re-install. An unchanged route list is never rewritten (comments
  survive idempotent no-op installs); a converging write is a YAML
  round-trip and drops comments, as documented in the class docstring.

- PR #393 final audit (FINAL-LAB1): `ProjectAdd` now resolves declared
  project owners through the REAL system passwd lookup by default (the
  same `Etc.getpwnam` seam `RoleVerifier`/`Verify` use). The previous
  `account_lookup: nil` default made every declared owner
  "nonexistent" in production installs — only tests injected a lookup,
  masking the bug. A root installer also no longer skips ownership
  propagation when the project root already carries the target uid: a
  root uid match proves nothing about generated children (`.ace/lab/
  config.yml`, `.ace/hitl/config.yml` may still be root-owned), so the
  whole tree is always converged. A declared directory matching a
  project path exactly (not only as a prefix) now selects that
  project's owner too.

- PR #393 final audit (FINAL-LAB2): `kind: hitl` adapter declarations
  are now projected into the runtime HITL configuration contract —
  `hitl.adapters.routes` in every declared project's
  `.ace/hitl/config.yml`, the exact cascade location the ace-hitl
  route loader reads (an empty adapter configuration used to yield
  `ok:true`/`ready:true` while the runtime failed with NoRoutesError).
  The new `HitlRoutes` molecule installs the routes idempotently
  (operator-owned routes and settings are preserved; unparseable
  documents are refused, not overwritten), and `ace-lab verify`
  re-derives the expected route per adapter and validates the
  resulting configuration against the runtime loader's rules
  (non-empty mapping list, required `adapter`, single-segment route
  names, no duplicates) in every declared project — a missing or
  invalid route configuration blocks readiness. The committed suite
  cross-checks the written document against the real
  `Ace::Hitl::Molecules::HitlRouteLoader` so the mirrored validation
  cannot drift.

- PR #393 final audit (FINAL-LAB3): required tools and adapter
  commands are now probed FOR THE TARGET EXECUTORS, not the installing
  account — an installer-owned mode-0700 executable fails readiness
  when the declared executor (different uid) cannot run it. The new
  `RoleVerifier#executable_access_reason` applies the same
  governing-class permission logic (owner/group/other short-circuit,
  supplementary groups, ancestor search) as the repository access
  checks, and the project-directory access mask now requires
  read+write+search (a directory without x on itself is unusable to
  the executor however rw it is). Tool/adapter availability that is
  undecidable (unset PATH) still reports `unknown`; as with every
  other unknown it does not block readiness by itself and never counts
  as a verified pass.

- Review fix: `check_adapters` status precedence — a malformed adapter
  configuration (not a mapping) stays a decidable FAIL even when PATH
  is unset (only the command probe may degrade to unknown); the dead
  `tool_reason` helper introduced with the tri-state probe is removed;
  and two review-round acceptance scenarios (gitignore-symlink
  read-through refusal, verify-stage crash classification) were
  accidentally defined outside their minitest classes and never
  executed — they now run (and pass) in the package suite.

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

