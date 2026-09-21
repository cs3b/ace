---
id: 8wk.t.l1e
title: Forge-neutral Git core with GitHub and Forgejo providers
status: pending
priority: high
created_at: "2026-09-21 14:01:33"
estimate: large
dependencies: []
tags: [ace-git, forge-neutral, providers]
needs_review: false
---

# Forge-neutral Git core with GitHub and Forgejo providers

Implements overseer task `8vu.t.l2d` ("Make ACE forge-neutral across Git and delivery workflows") and subtasks `8vu.t.l2d.0` ("Define provider-neutral Git and server resolution"), `8vu.t.l2d.1` ("Provide GitHub behavior through ace-git-github"), and `8vu.t.l2d.2` ("Provide Forgejo behavior through ace-git-forgejo") on `cs3b/lab-overseer` `main` (exact tip `7da7dc3`, tree present since commit `c6e264d`, 2026-08-31; `kx8` baseline closed `662720f`, 2026-09-16). This is the product-task spec for the builder Work; it is not the implementation.

## Problem (evidence, executed 2026-09-21)

Repository `cs3b/ace` `main` at tip `fc14c43d3` (clean, aligned with origin; W671 / PR #25 delivery).

1. **Current GitHub coupling inventory inside `ace-git` core:**
   Direct `gh` execution and GitHub-specific semantics currently reside inside the core `ace-git` gem:
   - `ace-git/lib/ace/git/molecules/gh_cli_executor.rb`: Safely executes `gh` CLI commands directly via `["gh", subcommand] + args`, handling CLI timeouts and subprocess execution.
   - `ace-git/lib/ace/git/molecules/pr_metadata_fetcher.rb`: Directly executes `gh` commands (`gh --version`, `gh auth status`, `gh pr diff`, `gh pr view`, `gh pr list`) and raises `Ace::Git::GhNotInstalledError`.
   - `ace-git/lib/ace/git/molecules/github_issue_sync.rb`: Tightly couples issue synchronization to GitHub APIs and conventions.
   - `ace-git/lib/ace/git/cli/commands/pr.rb`: Implements CLI pull request commands assuming GitHub CLI semantics.
   - `ace-git/lib/ace/git/atoms/pr_identifier_parser.rb`: Formats pull request identifiers specifically for `gh_format`.
   The gem layout follows `atoms/molecules/organisms/cli/models`.

2. **Zero Forgejo / `fj` presence anywhere in `ace-git/lib`:**
   Executed grep (`grep -rniE "forgejo|\bfj\b" ace-git/lib`) returned zero matches (exit code 1). Despite cs3b/ace delivery occurring on Forgejo, `ace-git` has zero Forgejo support.

3. **Absence of dedicated provider gems:**
   Directory inspection in `/lab/projects/ace` confirms no `ace-git-github` or `ace-git-forgejo` gem directories exist in the monorepo. The only existing `ace-git-*` gems are `ace-git-commit`, `ace-git-secrets`, and `ace-git-worktree`.

4. **Hardcoded GitHub assumptions in metadata while delivery runs on Forgejo:**
   `ace-git/ace-git.gemspec` hardcodes `github.com` metadata URIs:
   - `homepage = "https://github.com/cs3b/ace/tree/main/ace-git"`
   - `source_code_uri = "https://github.com/cs3b/ace/tree/main/ace-git/"`
   - `changelog_uri = "https://github.com/cs3b/ace/blob/main/ace-git/CHANGELOG.md"`
   Meanwhile, cs3b/ace delivery actively runs through Forgejo (PR #23, PR #24, PR #25 merged on Forgejo). This exemplifies the silent-GitHub coupling defect across the codebase.

5. **Silent-fallback defect class:**
   When forge operations are attempted without explicit configuration or when Forgejo operations fail, systems must never silently fall back to GitHub or hide `fj` failure behind ad-hoc curl. All forge interactions must require explicit or deterministic resolution and fail with actionable, classified errors.

6. **Pre-1.0 replacement posture:**
   ACE is pre-1.0 software: rejected architecture is replaced directly. No compatibility shims, legacy aliases, dual paths, forwarding wrappers, or transitional provider models may survive this foundation refactor.

## Behavioral specification

Foundation chunk F0 establishes a clean three-way architectural boundary mirroring overseer subtasks `8vu.t.l2d.0`, `.1`, and `.2`:

### 1. Provider-neutral Git core (`ace-git`)

- **Local Git isolation:** Local Git operations (such as log, diff, commit, branch, status, rev-parse) must execute without requiring any forge CLI (`gh` or `fj`), forge credentials, or network connectivity.
- **Server configuration:** Configuration supports multiple uniquely named forge servers (e.g. `github-public`, `forgejo-lab`, `forgejo-corp`) and exactly one explicit default server.
- **Deterministic resolution:**
  - Callers may request an explicit named server.
  - Callers may request default resolution, which succeeds if and only if exactly one explicit default server is configured.
  - Callers may resolve server identity from repository remotes, matching configured remote URLs without assuming `github.com`.
- **Core provider contract:** `ace-git` defines the provider interface contract and normalized data structures. The core exposes provider capabilities to higher-level consumers, but never invokes `gh` or `fj` subprocesses or parses raw forge output.

### 2. GitHub provider package (`ace-git-github`)

- **Ownership:** `ace-git-github` owns all GitHub-specific terminology, `gh` CLI invocation, output parsing, authentication verification (`gh auth status`), and error handling.
- **Normalized evidence:** Translates GitHub PR, issue, check, and repository responses into the common normalized evidence contract (exact server, repository, object, head, checks).
- **Classified failures:** Exposes distinguished failures for missing `gh` binary, unauthenticated state, unreachable server, malformed output, and object not found.

### 3. Forgejo provider package (`ace-git-forgejo`)

- **Ownership:** `ace-git-forgejo` owns all Forgejo-specific terminology, `fj` CLI invocation, output parsing, authentication verification, and error handling.
- **Normalized evidence:** Translates Forgejo PR, issue, Actions/check, and repository responses into the same common normalized evidence contract.
- **Strict prohibitions:** Ad-hoc curl fallbacks are strictly forbidden. Failure to execute `fj` or parse its response must yield classified failures that distinguish ACE integration errors from upstream `fj` defects.

### 4. Classified failure taxonomy

Every non-success path must produce a distinct, classified failure with actionable context:
- `NoDefaultServerConfiguredError`: Default requested but no default configured.
- `MultipleDefaultServersError`: More than one server marked as default.
- `DuplicateServerNameError`: Multiple servers configured with the same identifier.
- `UnknownProviderError`: Server references an unregistered provider type.
- `UnknownServerNameError`: Requested server name is not found in configuration.
- `AmbiguousRemoteError`: Remote URL matches multiple configured servers or none deterministically.
- `ProviderCliMissingError`: Provider CLI (`gh` or `fj`) is not installed in `PATH`.
- `ProviderAuthenticationError`: Provider CLI is unauthenticated or token lease expired.
- `ProviderUnreachableError`: Remote forge endpoint is offline or unreachable.
- `ProviderMalformedOutputError`: Provider CLI returned invalid JSON or unexpected schema.
- `ProviderObjectNotFoundError`: Requested PR, issue, branch, or commit does not exist.

Under no circumstances may any failure trigger fallback to an alternate provider or curl invocation.

## Interface contract

```ruby
# Server resolution via Ace::Git
resolved = Ace::Git::ServerRegistry.resolve("forgejo-lab")
# => #<Ace::Git::ResolvedServer name="forgejo-lab" provider=:forgejo url="https://forgejo.tail6c0887.ts.net/cs3b/ace">

default_server = Ace::Git::ServerRegistry.resolve_default
# => #<Ace::Git::ResolvedServer name="forgejo-lab" ...> (or raises NoDefaultServerConfiguredError / MultipleDefaultServersError)

remote_server = Ace::Git::ServerRegistry.resolve_remote("origin")
# => matches remote URL deterministically against configured servers

# Provider interaction through common contract (implemented by ace-git-github / ace-git-forgejo)
provider = Ace::Git::Providers.for(resolved)
pr = provider.pull_request(number: 25)
# => #<Ace::Git::ProviderPullRequest number=25 title="..." head_sha="fc14c43d3..." base_ref="main" state=:merged>
```

- Callers supply a named server, request the configured default, or resolve from a remote, and receive an exact `ResolvedServer` identity or an actionable classified failure.
- Core exposes provider capabilities but performs no `gh` or `fj` execution.

## Atomicity

- **Single Delivery Chunk F0:** Foundation chunk F0 must ship as one atomic unit — `ace-git` core refactor, `ace-git-github`, and `ace-git-forgejo` delivered together in a single pull request.
- **No Partial Merges:** The core must never merge without both providers; neither provider may merge without the core contract.
- **Consumer Migration Out of Scope:** Existing consumers (`ace-git-worktree`, `ace-review`, `ace-task`, `ace-assign`, and canonical delivery workflows) remain out of scope for F0 and will be migrated in subsequent chunks F1 (`8vu.t.l2d.3`–`.5`), F2 (`.6`–`.7`), and proved in F3 (`.8`).

## Acceptance criteria

- [ ] Local-only Git commands succeed with zero forge configuration, no provider CLI (`gh` or `fj`) installed, and no network access.
- [ ] `ace-git` core contains zero direct invocations of `gh` or `fj`, zero parsing of provider CLI output, and no hardcoded GitHub assumptions.
- [ ] `ace-git-github` exists as a monorepo package implementing the common provider contract for GitHub using `gh`.
- [ ] `ace-git-forgejo` exists as a monorepo package implementing the common provider contract for Forgejo using `fj`; no ad-hoc curl fallback exists.
- [ ] Configuration supports multiple uniquely named servers with at most one explicit default server; multiple named servers remain distinct even when sharing a provider type.
- [ ] Deterministic remote resolution resolves configured servers from git remote URLs without hostname or GitHub assumptions.
- [ ] Failure paths (no default, multiple defaults, duplicate server names, unknown provider, unknown server, ambiguous remotes, missing CLI, auth failure, offline, malformed output) each return distinct classified failures with no silent fallback.
- [ ] No compatibility shim, legacy alias, dual path, forwarding wrapper, or transitional provider model survives.
- [ ] Atomic delivery: core refactor and both provider packages are prepared and delivered together in a single PR.
- [ ] Monorepo test suite green (`ace-test-suite --target all`) and `bundle exec ace-task doctor` clean on the task tree.

## Verification plan

### Unit / component

- Core contract boundary tests: mock system environment without `gh` and `fj` in `PATH`; assert local Git operations succeed cleanly.
- Assert core boundary rejects provider command execution.
- Server configuration tests: validate single default, zero defaults, multiple defaults, duplicate names, explicit selection, and remote URL matching.
- Provider contract parity tests: run identical contract test suites against `ace-git-github` and `ace-git-forgejo` test doubles/fakes; assert identical normalized output shapes.
- Classified failure tests: exercise all error conditions (missing binary, auth failure, offline, malformed output) and verify exact exception types and messages.

### Integration / E2E

- Exercise local Git operations with network disabled and provider CLIs uninstalled.
- Execute repository, PR, and check status queries against GitHub and Forgejo endpoints through the common contract.
- Full monorepo fast test loop: `ace-test-suite --target all`.

### Packaging & hygiene

- Verify `ace-git/ace-git.gemspec` removes hardcoded GitHub URLs and reflects forge neutrality.
- Verify `ace-git-github.gemspec` and `ace-git-forgejo.gemspec` declare correct dependencies and metadata.
- Verify `bundle exec ace-task doctor` is completely clean on `.ace-tasks/8wk.t.l1e-forge-neutral-git-core-with/`.

## Out of scope

- Migrating existing consumers: `ace-git-worktree` (`8vu.t.l2d.3`), `ace-review` (`8vu.t.l2d.4`), `ace-task` (`8vu.t.l2d.5`), `ace-assign` (`8vu.t.l2d.6`), canonical delivery workflows (`8vu.t.l2d.7`).
- Cross-provider delivery matrix proof (`8vu.t.l2d.8`).
- RubyGems publication or release train execution.
- Host/Lab control-plane changes (`lab`, `labd`, `lab-admin`).
- Overseer repository changes (`cs3b/lab-overseer`).

## Provenance

- Overseer task `8vu.t.l2d` ("Make ACE forge-neutral across Git and delivery workflows") and subtasks `8vu.t.l2d.0`, `8vu.t.l2d.1`, `8vu.t.l2d.2` on `cs3b/lab-overseer` `main` (exact tip `7da7dc3`, present since commit `c6e264d`, 2026-08-31).
- Prerequisite baseline `8vu.t.kx8.0`–`.2` closed complete on 2026-09-16 (commit `662720f`).
- Verified coupling evidence items 1–4 executed in `cs3b/ace` at tip `fc14c43d3` on 2026-09-21.

### Review note (2026-09-21, fresh-eyes review)

Reviewed fresh-eyes before promotion:

- **Evidence currency**: All coupling and environment evidence re-executed 2026-09-21 on `cs3b/ace` `main` at clean tip `fc14c43d3` (clean `git status`; `origin/main` tip verified; `gh` references in `ace-git/lib/{molecules,cli,atoms}` inventoried; zero `fj`/Forgejo in `ace-git/lib` confirmed via grep; non-existence of `ace-git-github`/`ace-git-forgejo` verified; hardcoded GitHub metadata in `ace-git.gemspec` verified against active Forgejo delivery on PRs #23–#25).
- **Bounded scope**: Scope is strictly bounded to foundation chunk F0 (core provider-neutral Git in `ace-git`, GitHub provider in `ace-git-github`, and Forgejo provider in `ace-git-forgejo`). Migration of existing consumers (`ace-git-worktree`, `ace-review`, `ace-task`, `ace-assign`, canonical delivery workflows) is explicitly out of scope and assigned to subsequent chunks F1 (`8vu.t.l2d.3`–`.5`), F2 (`.6`–`.7`), and closure F3 (`.8`). No gem publication, host changes, or overseer changes authorized.
- **Testable acceptance criteria**: Every criterion is an executable check (local Git with zero network/forge CLI; core command execution rejection; contract parity between GitHub and Forgejo providers; deterministic server/remote resolution; monorepo suite green; `ace-task doctor` clean).
- **Explicit failure taxonomy**: Classified failure modes are explicitly enumerated (`NoDefaultServerConfiguredError`, `MultipleDefaultServersError`, `DuplicateServerNameError`, `UnknownProviderError`, `UnknownServerNameError`, `AmbiguousRemoteError`, `ProviderCliMissingError`, `ProviderAuthenticationError`, `ProviderUnreachableError`, `ProviderMalformedOutputError`, `ProviderObjectNotFoundError`). Silent fallbacks to GitHub or ad-hoc curl are strictly forbidden.
- **Atomicity language**: Delivery chunk F0 is explicitly required to ship as ONE atomic unit in a single PR — core plus both providers together; partial merges or standalone core delivery are explicitly forbidden.
- **No-shim clause**: Pre-1.0 direct replacement policy is explicit — no compatibility shims, legacy aliases, dual paths, forwarding wrappers, or transitional provider models may survive.

No blocking findings.

### Promotion note (2026-09-21, promotion)

Promoted from `status: draft`, `needs_review: true` to `status: pending`, `needs_review: false`.
The task specification is fully reviewed, aligned with overseer authority `8vu.t.l2d` and subtasks `.0`–`.2`, validated with live executed preflight evidence, and clean under `ace-task doctor`. Ready for builder Work scheduling.


