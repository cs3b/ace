---
doc-type: guide
title: ACE Project Delivery Guide
purpose: Canonical project policy for agent-assisted ACE development and delivery
version: 1
ace-docs:
  last-updated: 2026-08-31
  last-checked: 2026-08-31
---

# ACE Project Delivery Guide

This is the project-owned contract used by developers, Lab Overseer, builders,
reviewers, integrators, and release administrators. It describes how ACE work
is discovered, implemented, verified, integrated, released, synchronized, and
closed. Machine-specific Lab code may enforce it, but may not silently replace
it.

## Sources and planning

- The canonical implementation task is a reviewed `ace-task` specification in
  this repository. GitHub issues, Forgejo PRs, and a Lab high-level plan may
  point to it, but do not replace its acceptance contract.
- Inspect tasks with `ace-task show REF --tree`. The canonical implementation
  procedure is [`wfi://task/work`](wfi://task/work), loaded with
  `ace-bundle wfi://task/work`; harness-specific skills are projections of that
  workflow, not a separate project contract. Draft or still-reviewable work
  returns to planning before implementation.
- A project-level goal may become several ordered or independent Works. The
  Overseer records dependencies, integration points, accepted Deliveries, and
  whether a later Release is required. Each Work retains its own detailed ACE
  task flow.
- Read-only discovery uses Git, `fj` for Forgejo, and `gh` for GitHub. Missing
  authority is a blocker; it is never a reason to substitute a stronger role.

## Repository and environment

- ACE is a Ruby monorepo. Packages live in top-level `ace-*` directories and
  the registered suite inventory is `.ace/test/suite.yml`.
- Trust the exact repository `mise.toml`, activate it with `mise`, and use the
  locked root bundle. Do not install a private bundle per package.
- Run ACE commands directly. Use `ace-test PACKAGE all` for a package and
  `ace-test-suite --no-color --target all` for the complete deterministic
  suite. Do not use raw package Rake or Ruby test commands.
- Validate the inventory with `.ace-bin/ci_package_inventory.rb`, exercise the
  monorepo E2E discovery with `ace-test-e2e ace-monorepo-e2e --dry-run`, and run
  the explicit handbook projection gate with `ace-test ace-handbook all` when
  handbook sources or generated guidance can change.
- A builder always works in its assigned branch and worktree. Provider homes,
  credentials, prompts, and logs are not shared even when compatible compiled
  gems are reused by one Unix trust role.

## Work and agent development

Work execution follows [`wfi://task/work`](wfi://task/work). Coordinated
single-delivery execution may use
[`wfi://handbook/perform-delivery`](wfi://handbook/perform-delivery), while the
project-level release decision in this guide remains authoritative.

- Every Work is bound to a reviewed task snapshot and exact base SHA. Agent,
  toolchain, provider, guide, and remote capability preflight happens before a
  credential is minted.
- An Attempt is immutable execution evidence. A retry creates another Attempt;
  it does not rewrite an accepted Work result.
- Builders remain within the assigned scope, branch, worktree, and credential
  boundary. Focused development checks do not replace the task's acceptance
  contract.
- Commits, branch publication, and PR creation are builder outcomes. Merge,
  repository policy, publication, deployment, GitHub synchronization, and
  upstream closure belong to their named roles and decisions.

## Review, verification, and integration

- Review uses a clean, exact PR-head checkout and an independent reviewer.
  Findings, commands, artifact digests, trust boundary, and verdict are stored
  as exact-SHA evidence. The feedback lifecycle belongs to
  [`wfi://review/run`](wfi://review/run). The current
  [`wfi://review/pr`](wfi://review/pr) adapter is GitHub-only and uses `gh`;
  Forgejo review therefore uses `wfi://review/run` against the clean local
  exact-head diff until ACE gains a Forgejo PR adapter.
- Forgejo CI must validate the complete registered package inventory and keep
  the protected summary context `Test Suite / Test Summary (pull_request)`.
  Package-level results remain visible even when one shared suite environment
  executes them.
- Manual verification is explicit and bound to the same SHA. CLI behavior uses
  the Lab test shell; UI behavior requires an operator-accessible preview.
- Evidence may be reused only when SHA, lockfiles, runtime/toolchain,
  acceptance criteria, artifact digest, and required trust remain compatible.
  A changed SHA or missing artifact makes the affected claim pending again.
- The integrator receives a single Work/repository-scoped lease only after the
  delivery evidence gate passes. It merges the approved exact PR head into
  Forgejo `main`. Merge is a Delivery outcome; it does not imply Release,
  deploy, GitHub synchronization, or task closure.

## Release grouping and publication

- Accepted PRs may wait and be grouped into one reviewed Release. Not every
  merge warrants a version bump or publication.
- A Release plan names the included exact merged SHAs, version policy,
  changelog scope, package set, acceptance checks, rollback, and required human
  decision. Run `ace-bundle wfi://release/local` for coordinated release
  preparation.
- RubyGems publication is a separate `release.rubygems` admin transaction.
  Publish through
  [`wfi://release/rubygems-publish`](wfi://release/rubygems-publish), using only
  artifacts built from the synchronized release SHA. OTP is supplied through
  the approved out-of-band path and is never sent through Telegram, stored in
  task history, or delegated to a builder.
- A coordinated multi-package publication is not onboarding-safe until
  `ace-test-e2e ace-monorepo-e2e TS-MONO-001` records its post-publish proof and
  classification (`SAFE`, `LAG_DETECTED`, or `METADATA_BROKEN`) according to
  [`ace-handbook/docs/release-rubygems-proof.md`](../../ace-handbook/docs/release-rubygems-proof.md).
- Deployment, when a future ACE service requires it, is another named admin
  capability and another decision. The current gem-only ACE release has no
  implicit deployment step.

## Upstream synchronization and closure

- Forgejo `main` is the working integration target. GitHub `main` is updated
  only by the `github.sync` admin capability after the selected Forgejo main
  SHA and release decision are proven.
- Close or update GitHub issues and canonical `ace-task` state only after their
  promised outcome is delivered. A merged PR may remain open at the project
  level while other Works wait for the same Release.
- Overseer records the final Work, Delivery, optional Release, synchronization,
  and closure outcomes independently.

## Capability ownership

| Operation | Capability | Role |
| --- | --- | --- |
| Discover project state and plan | `project.read`, `work.plan` | Overseer |
| Implement, test, push branch, open PR | `code.build` | Builder |
| Independent exact-SHA review | `code.review` | Reviewer / lab-admin |
| Merge an accepted exact PR head | `delivery.merge` | Integrator |
| Configure Forgejo repository or Actions | `forgejo.repository.configure`, `forgejo.actions.configure` | lab-admin |
| Publish RubyGems | `release.rubygems` | lab-admin + human OTP |
| Synchronize GitHub main | `github.sync` | lab-admin |
| Close upstream issue/task | `issue.close` | lab-admin / Overseer decision |
| Ask for a safe human decision | `hitl.coordinate` | Overseer / requesting Attempt |

Full-permission/yolo mode belongs inside the selected role's Unix, credential,
network, and repository boundary. It never upgrades this table.

## Failure and rollback

- A failed Attempt leaves Work actionable unless an explicit rollup decision
  marks it failed, rejected, superseded, or abandoned. It cannot erase an
  accepted Delivery.
- A failed or interrupted privileged transaction must revoke its remote lease,
  clear guest tmpfs material, remove host metadata, and record any unverified
  cleanup as `recovery_required`.
- A bad open PR is updated or superseded; a bad unmerged branch is never force
  pushed over another Work. A merged regression is repaired by a new Work and
  PR. Published gems are not deleted as a rollback mechanism; fix forward with
  a reviewed version according to RubyGems policy.
- Reconciliation is dry-run first, evidence-bound, atomic, and idempotent. It
  never performs release, deploy, sync, or closure as a side effect.
