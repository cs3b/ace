---
doc-type: guide
title: ACE Project Delivery Guide
purpose: Canonical project policy for agent-assisted ACE development and delivery
version: 2
ace-docs:
  last-updated: 2026-10-17
  last-checked: 2026-10-17
---

# ACE Project Delivery Guide

This is the project-owned policy used by developers, the Lab Overseer, workers,
reviewers, integrators, and release administrators. It describes how ACE work is
discovered, implemented, verified, integrated, released, and closed. The
file-based ownership model is canonical in
[`docs/lab-flow.md`](../../docs/lab-flow.md); this guide states the delivery
policy on top of it.

## Sources and planning

- The canonical implementation task is a reviewed `ace-task` specification in

  `.ace-tasks/`. GitHub issues, Forgejo PRs, and an overseer plan may point to
  it, but do not replace its acceptance contract.

- Inspect tasks with `ace-task show REF --tree`. The canonical implementation

  procedure is [`wfi://task/work`](wfi://task/work), loaded with
  `ace-bundle wfi://task/work`; harness-specific skills are projections of that
  workflow, not a separate project contract. Draft or still-reviewable work
  returns to planning before implementation.

- A project-level goal may become several ordered or independent tasks. The

  Overseer records dependencies, integration points, accepted deliveries, and
  whether a later release is required. Each task keeps its own `ace-task` flow.

- Read-only discovery uses Git, `fj` for Forgejo, and `gh` for GitHub. Missing

  access to a repository or forge is a blocker; it is never a reason to
  substitute a stronger role or credential.

- State owners are fixed:

  `.ace-tasks/` (project tasks, ace-task; `_overseer/` is a lab-prepared,
  gitignored folder in the same tree, reached with `ace-task --in _overseer`),
  `.ace-local/assign/` (assignment plan and steps, ace-assign),
  `.ace-local/coworker/` (reserved L3 role configuration),
  `.ace-local/hitl/` (HITL event files, ace-hitl), and
  `.ace-wt/` (one worktree per project task).

- Explicit non-owners of the flow: no journal, no authority/admission service,

  no listener/daemon, no topology registry as a queue, no queue engine, and no
  extra state cache or broker. tmux, Herdr, and Hermes are transports only.
  Repeating a message delivery never repeats the task execution.

## Repository and environment

- ACE is a Ruby monorepo. Packages live in top-level `ace-*` directories and the

  registered suite inventory is `.ace/test/suite.yml`.

- Trust the exact repository `mise.toml`, activate it with `mise`, and use the

  locked root bundle. Do not install a private bundle per package.

- Run ACE commands directly. Use `bin/ace-test PACKAGE all` for a package and

  `bin/ace-test-suite --no-color --target all` for the complete deterministic
  suite. Do not use raw package Rake or Ruby test commands.

- Validate the inventory with `.ace-bin/ci_package_inventory.rb`, exercise the

  monorepo E2E discovery with `bin/ace-test-e2e ace-monorepo-e2e --dry-run`, and
  run the package handbook projection gate with `bin/ace-test ace-handbook all`
  when package-owned handbook sources or generated guidance can change. Project
  overlays under `.ace-handbook/` require the conceptual and cross-reference
  review in [`wfi://handbook/review-guides`](wfi://handbook/review-guides); the
  package test alone does not validate them.

- A worker always works in its task's branch and worktree under `.ace-wt/`.

  Provider homes, credentials, prompts, and logs are not shared.

## Work and agent development

Work execution follows [`wfi://task/work`](wfi://task/work).

- Every task work is bound to the reviewed task specification and the exact

  branch/worktree the overseer prepared.

- The assignment plan in `.ace-local/assign/` is the only execution plan. The

  overseer's private list and the coworker configuration reference it; they
  never copy its steps or form a second queue.

- Only one active executor works in a task worktree at a time. The reviewer

  takes the worktree over after the worker finishes; reviewer fixes stay within
  the reviewer assignment. Different tasks may run in parallel worktrees.

- Progress that must survive between turns is written in the task folder. A

  restart reads the existing task, assignment, and worktree truth instead of
  replaying a queue.

- Builders remain within the assigned scope, branch, and worktree. Focused

  development checks do not replace the task's acceptance contract.

- Commits and branch publication are worker outcomes. Merge, repository

  policy, publication, deployment, forge synchronization, and closure belong to
  their named roles and decisions.

> **Planned (L3):** `ace-coworker` starts from `.ace-local/coworker/`, drives an
> assignment, records results, and reports through HITL -- not available yet.

## Review, verification, and integration

- Review uses a clean, exact candidate-head checkout and an independent

  reviewer. The reviewer fixes detected defects itself, checks the fix diff, and
  runs further full rounds.

- Default convergence policy: at least 3 full rounds, the last 2 consecutive

  rounds with no confirmed High/Critical findings and no unresolved earlier
  High/Critical; maximum 10 full rounds. If round 10 satisfies the conditions it
  ends successfully; otherwise it escalates to the Overseer. A diff review does
  not increment the counter. An interrupted or incomplete review is not a clean
  round. Resumption keeps prior findings, counters, and results.

- Executed tests and an independent reviewer verdict are the merge gate. CI

  status is advisory: a red CI signal is repaired and never replaces executed
  checks or blocks an otherwise accepted merge.

- Evidence may be reused only when the head, lockfiles, runtime/toolchain,

  acceptance criteria, artifact digests, and required trust remain compatible.
  A moved head requires a recorded assessment of what changed. Historical
  evidence never certifies the current head by itself.

- The integrator receives the delivery once the evidence gate passes, merges

  the approved exact head, and applies the project merge policy. Merge is a
  delivery outcome; it does not imply release, deploy, synchronization, or task
  closure. The integrator assignment is tracked in the Overseer's private
  process, not in a new integration service.

- Review sessions and feedback items live under `.ace-local/review/` and are

  owned by `ace-review`. The old durable-campaign/coordinator-receipt requirement
  is not part of the file-based flow.

> **Planned (L5.5):** role rules (worker/reviewer/integrator), review rounds, and
> the forge-neutral review/delivery workflow -- not available yet. Until then the
> ordinary `ace-review` and `ace-git pr` commands are the supported path.

## Release grouping and publication

- Accepted PRs may wait and be grouped into one reviewed release. Not every

  merge warrants a version bump or publication.

- A release plan names the included exact merged SHAs, version policy,

  changelog scope, package set, acceptance checks, rollback, and required human
  decision. Run `ace-bundle wfi://release/local` for coordinated release
  preparation.

- RubyGems publication is a separate release-admin transaction. Publish through

  [`wfi://release/rubygems-publish`](wfi://release/rubygems-publish), using only
  artifacts built from the synchronized release SHA. A six-digit OTP may pass
  through the approved secure HITL adapter only when it is consumed without
  persistence and injected once into the resumed publisher; otherwise use the
  readiness-only, out-of-band environment path. No OTP is stored in task
  history or delegated to a worker, and no long-lived secret enters chat or
  HITL.

- A coordinated multi-package publication is not onboarding-safe until the

  monorepo release-install verification records its post-publish proof and
  classification (`SAFE`, `LAG_DETECTED`, or `METADATA_BROKEN`) according to
  [`ace-monorepo-e2e/docs/release-install-verification.md`](../../ace-monorepo-e2e/docs/release-install-verification.md).

- Installation is a named delivery outcome. The release manifest binds exact

  package versions and artifact digests; installation verifies every intended
  consumer. Publication alone does not complete delivery. Preserve
  intentionally pinned legacy runtimes.

> **Planned (L9):** the full pre-release pass and scenarios -- not available yet.
>
> **Planned (L10):** gem release from RubyGems and final acceptance -- not
> available yet.

## Upstream synchronization and closure

- Forgejo `main` is the working integration target. GitHub `main` is updated

  only by the `github.sync` admin capability after the selected Forgejo main
  SHA and release decision are proven.

- Close or update GitHub issues and canonical `ace-task` state only after their

  promised outcome is delivered. A merged PR may remain open at the project
  level while other tasks wait for the same release.

- The Overseer records the final work, delivery, optional release,

  synchronization, and closure outcomes independently.

## Communication and human attention

- `ace-hitl` owns HITL event files in `.ace-local/hitl/`. It distinguishes a

  report that needs no answer from a question/escalation that requires one.

- A report reaches the Overseer, which interprets the message and updates its

  own managing task. A reply goes to the correct case. Repeating message
  delivery never repeats task execution.

- Adapters are configurable individually or as a set; `ace-hitl-hermes` remains

  an adapter. tmux and Herdr transport handling requires no different sender
  interface.

> **Planned (L2):** the unified report/question/reply interface and configurable
> adapter set -- not available yet.
>
> **Planned (L6):** the private Overseer queue and worktree handoff between roles
> -- not available yet.
>
> **Planned (L7):** aggregated status, blocked/failure display, and pi
> continuation of already delegated work -- not available yet.

## Role and owner table

| Operation | Owner | Role |
| --- | --- | --- |
| Discover project state and plan | `.ace-tasks/` + private `_overseer` | Overseer |
| Implement, test, and commit in the worktree | `.ace-wt/` + `.ace-local/assign/` | Worker |
| Independent exact-head review and fixes | `.ace-local/review/` + reviewer assignment | Reviewer |
| Merge an accepted exact head | integrator assignment in Overseer process | Integrator |
| Prepare worktree and assignment sequence | `.ace-wt/` + `.ace-local/assign/` | Planner (L4 planned) |
| Ask for a human decision | `.ace-local/hitl/` | Overseer / requesting worker |
| Publish RubyGems | release transaction (L10 planned) | Release admin + human OTP |
| Synchronize GitHub main / close upstream | admin sync and forge issue operations | Lab admin / Overseer decision |

Full-permission/yolo mode belongs inside the selected role's Unix, credential,
network, and repository boundary. It never upgrades this table.

## Failure and rollback

- A failed assignment step leaves the work actionable unless an explicit

  decision marks it failed, rejected, superseded, or abandoned. It cannot erase
  an accepted delivery.

- A failed or interrupted privileged transaction must revoke its remote lease,

  clear temporary privileged material, remove host metadata, and record any
  unverified cleanup as `recovery_required`.

- A bad open PR is updated or superseded; a bad unmerged branch is never force

  pushed over another task. A merged regression is repaired by a new task and
  PR. Published gems are not deleted as a rollback mechanism; fix forward with a
  reviewed version according to RubyGems policy.

- Reconciliation is dry-run first, evidence-bound, atomic, and idempotent. It

  never performs release, deploy, sync, or closure as a side effect.
