---
id: 8rjcdu
title: synthesis-e2e-public-surface-migration
type: standard
tags: [synthesis]
created_at: "2026-04-20"
status: active
---

# synthesis-e2e-public-surface-migration

Date: 2026-04-20
Context: Synthesis of 36 active retros added on the current branch for the PR 295 public-surface E2E migration, hardening, and release stabilization work.
Author: Codex
Type: Standard

## What Went Well

- Public-surface, goal-style E2E rewrites worked across the package batch. Most package retros reported successful migration from brittle implementation/artifact checks to documented CLI journeys and impact-first verification.
- Targeted rerun discipline kept the work tractable. Many retros cited direct scenario reruns, package-local `ace-test all --profile 6`, and focused failing-scenario loops as the mechanism that found real contract mismatches without excessive full-suite churn.
- Shared patterns emerged and were reused across packages: docs/help anchoring, explicit runner/verifier manifests, scenario-owned setup, and stronger public-output evidence.
- Several E2E failures produced real product or workflow improvements rather than test weakening, including fixes around CLI flag compatibility, config/default drift, release boundaries, sandbox behavior, and docs/help failure analysis.
- Coordinated release closeout generally worked once package scope was explicit: version bumps, package changelogs, root changelog entries, lockfile updates, and path-scoped commits were repeatedly completed in the same task flow.

## What Could Be Improved

- Missing `.ace-local/e2e-migration/*` review and plan artifacts were the most frequent planning problem, appearing across the majority of package retros. Agents repeatedly had to fall back to task specs plus live suite inspection, reducing traceability.
- `ace-task plan` reliability was a recurring blocker. Multiple retros reported path-mode stalls or warning-only runs that forced manual fallback planning.
- Pre-commit review frequently degraded to lint-only fallback because native review/session metadata was unavailable. The fallback produced useful but noisy markdown/style warnings after implementation instead of before commit.
- E2E runner and verifier contracts remained too brittle in several places: stale TC names, stale fixture paths, exact wording checks, arbitrary line-count thresholds, duplicate artifact requirements, and missing-artifact handling that conflicted with impact-first evidence.
- Sandbox/runtime assumptions still leaked into scenario failures, including `mise.toml` copy paths, PATH/env drift, tmux socket health, protocol-source visibility, external tool availability, and writable runtime/support paths.
- Release flow needed repeated recovery around package version reconciliation against `origin/main`, split commit residual files, non-gem `ace-*` directories, root changelog density, and already-bumped branch-local versions.

## Key Learnings

- E2E triage should classify failures before changing code: first sandbox/runtime health, then runner/verifier contract correctness, then product behavior. This pattern was explicitly validated in the stabilization retros and would have prevented some package-level rework.
- Public-surface tests are strongest when they prove user outcomes through docs/help-discoverable commands, stable final state, and direct artifacts. Exact copy, internal helper choreography, and aggregate-oracle thresholds are weak substitutes.
- Required artifacts are useful as evidence, but they should not override stronger real evidence from the same scenario. Passing reports should not continue to display accepted fallback artifacts as missing required artifacts.
- Fresh-sandbox E2Es test shipped defaults, not project overrides. The LLM stack failure showed that `.ace-defaults`, provider aliases, role order, and hardcoded model catalogs must move as one public surface.
- Release boundaries matter in this monorepo. Changed top-level directories are not necessarily releasable packages, and branch-local version/changelog state is not trustworthy until compared with `origin/main`.
- Docs/help drift is a first-class E2E concern. Failure analysis is incomplete if it does not check whether users can discover the intended job through docs, usage guides, or command help.

## Action Items

### Stop Doing

- Stop treating every red E2E scenario as an independent product bug before checking sandbox/runtime and verifier/spec failure buckets.
- Stop relying on task-bundled `.ace-local/e2e-migration/*` references without a preflight that confirms the files exist or explains fallback sources.
- Stop using arbitrary verifier quality thresholds, stale TC names, stale fixture paths, or duplicate artifact requirements as hard gates when they do not represent user-visible behavior.
- Stop declaring release surfaces complete after the first scoped commit set without checking version ordering, residual dirty files, and non-releasable directories.

### Continue Doing

- Continue anchoring E2E rewrites to public docs/help, documented CLI journeys, and impact-first evidence.
- Continue targeted reruns of failing scenarios and package-local tests before broad suite reruns.
- Continue using scenario-local fixtures and hermetic shims where ambient machine state would otherwise decide test outcomes.
- Continue making scenario fixes stronger rather than weaker when failures expose missing proof, unclear public contracts, or stale documentation.

### Start Doing

- Add a task-load/planning preflight that validates task-declared migration artifacts and fork/session metadata before assignment execution starts.
- Harden `ace-task plan` timeout, stall, and fallback behavior so failures produce deterministic diagnostics and usable recovery paths.
- Add a shared E2E environment preflight covering protocol-source visibility, sandbox PATH/env integrity, tmux socket health, `mise.toml` setup, external-tool availability, and writable runtime paths.
- Add runner-completion requirements for multi-goal scenarios: every goal must either produce required evidence or a blocker artifact explaining why it could not.
- Update E2E authoring guidance to prefer explicit fact-based verifier criteria, actual sandbox fixture paths, canonical artifact reuse, and stale TC renames when behavioral contracts change.
- Add release workflow checkpoints for `origin/main` version reconciliation, releasable-package pruning, residual diff sweeps after split commits, and root changelog cleanup during clustered releases.
- Keep `## Docs / Help Drift From E2E Failures` mandatory in E2E failure analysis and treat its absence as incomplete analysis.

## Technical Details

- Source set: 36 retros added under `.ace-retros/` on the current branch relative to `origin/main`.
- Dominant source theme: public-surface E2E migration across packages `ace-assign`, `ace-b36ts`, `ace-bundle`, `ace-compressor`, `ace-demo`, `ace-docs`, `ace-git`, `ace-git-commit`, `ace-git-secrets`, `ace-git-worktree`, `ace-handbook`, `ace-idea`, `ace-lint`, `ace-overseer`, `ace-review`, `ace-search`, `ace-support-nav`, `ace-test-runner`, and related support packages.
- High-frequency repeated issue: missing `.ace-local/e2e-migration/*` artifacts appeared in most package-level retros.
- High-impact stabilization topics: sandbox/runtime preflight, verifier artifact policy, docs/help drift checks, fresh-default LLM config drift, and coordinated release boundaries.

## Workflow Proposals

- Enhance assignment/task-load workflows with a context-artifact preflight before plan/work execution.
- Enhance E2E workflows with explicit failure-bucket classification, docs/help drift analysis, environment preflight, and runner-completion evidence checks.
- Enhance release workflows with version reconciliation against `origin/main`, package eligibility filtering, residual diff sweeps after split commits, and root changelog hygiene checkpoints.

## Additional Context

- Synthesized from the current branch diff requested by `git diff --stat origin/main -- .ace-retros/`.
- Consumed retros should be archived after this synthesis per `wfi://retro/synthesize`.
