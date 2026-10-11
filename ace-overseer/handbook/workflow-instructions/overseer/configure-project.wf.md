---
name: overseer-configure-project
description: Adapt delivery supervision to a project's existing presets, workflows, and decision policy
allowed-tools: Bash, Read, Write, Edit, Glob
doc-type: workflow
title: Configure Project Delivery Supervision
purpose: Resolve and safely adapt project delivery supervision without replacing project policy or duplicating canonical work.
ace-docs:
  last-updated: '2026-10-11'
  last-checked: '2026-10-11'
---

# Configure Project Delivery Supervision

## Goal

Make the four ACE delivery-supervision presets usable under the target project's
own workflow and decision policy while preserving existing customization and
producing an idempotent, attributable change report.

## Prerequisites

- Run from the target project root and identify that root explicitly before any write.
- Use the installed `ace-nav`, `ace-bundle`, and `ace-assign` package set that the
  project will actually run; source-checkout resolution is not installed-runtime proof.
- Have reviewed project policy for dependency ordering, integration groups, release
  cuts, demo/production delivery, evidence freshness, and authority ownership.
- Treat missing policy, authority, transport, or a durable result path as a blocker.
  This workflow does not grant permissions and does not publish, merge, deploy, or
  perform host-owned root operations.

## Project Context Loading

Read existing project-owned sources before proposing a change:

- `.ace/assign/presets/` for project-local preset overrides.
- `.ace/overseer/config.yml` and other existing `.ace/overseer/` configuration.
- `.ace-handbook/workflow-instructions/` for project workflows.
- `.ace-handbook/guides/` and registered project guide sources for decision guides.
- Current task, Assign, review, release, and delivery records that already own work.
- Repository guidance such as `AGENTS.md`, architecture decisions, and delivery docs.

Resolve rather than infer protocol ownership. Run `ace-nav explain <URI>` followed by
`ace-nav resolve <URI>` for every applicable `wfi://` workflow and for
`guide://delivery-supervision`. Load resolved workflow content with `ace-bundle <URI>`.
If the expected project decision guide uses another registered URI, record that URI
and use it consistently instead of creating an alias or duplicate guide.

## High-Level Execution Plan

1. Inventory the effective package defaults and all project-owned overrides.
2. Review the resolved assets against the supervision invariants below.
3. Plan the smallest path-keyed set of project-local changes.
4. Apply only justified additions or surgical updates while preserving local policy.
5. Resolve everything again, repeat the inventory, and report exact outcomes.

## Process Steps

### 1. Establish the effective source inventory

For each baseline preset, resolve the same project-first ownership used by ACE:

- `supervise-delivery`
- `integrate-batch`
- `deliver-release`
- `close-delivery`

An existing `.ace/assign/presets/<name>.yml` is the effective project-local preset.
Otherwise use the installed `ace-assign` gem's
`.ace-defaults/assign/presets/<name>.yml`. Use `gem contents ace-assign` when an
installed package path is needed. Do not create a project copy merely to select the
unchanged package default.

Inventory applicable project workflows by exact `wfi://` URI and decision guides by
exact `guide://` URI. For every resolved item record its URI or preset name, resolved
path, owning source, and content digest. Record unresolved items as blockers rather
than silently substituting a remembered or similarly named file.

Before making task-related recommendations, reconcile existing implementation and
delivery tasks. Do not create or duplicate tasks. Delivery records reference producer
tasks; they never reparent, reopen, or clone producer work.

### 2. Review the effective supervision contract

Review project-local preset overrides, resolved workflows, and decision guides as one
contract. Preserve stronger project requirements. Require these minimum invariants:

- Worker and implementation-parent terminal behavior remains PR-ready; delivery stays
  a separate explicit decision scope.
- One canonical Assign tree and attempt/evidence ledger owns state. No second queue,
  journal, daemon, timer, or fabricated runtime context is introduced.
- Integration decisions record the ordered eligible set, selected entry, every
  deferred entry with reason, actor, timestamp, evidence references, and policy/plan
  revision. Completion order is never integration order.
- Dependency, candidate head, target head, evidence, authority, or transport movement
  triggers a fresh decision. A moved candidate receives fresh relevant tests and an
  independent review bound to its new exact head.
- `WAIT(reference, next-check)` requires an existing durable operation reference and
  exact reconciliation path. Missing provision is `BLOCKED(provision, owner)`.
  Uncertain effects are reconciled through the original operation and never replayed
  blindly.
- Release preparation binds the exact accepted source set, package versions, and
  artifact digests. Later merges cannot enter an accepted cut silently. Publication
  remains a separate-authority placeholder.
- Closure preserves evidence and work, positively proves no surviving writers, keeps
  producer references and delivery tags discoverable, and closes only accepted scope.
  Host-owned root effects remain referenced external operations.

If a project decision is absent, do not invent it. Report the precise missing policy,
the owner needed to decide it, and the assets that remain usable without that choice.

### 3. Build an idempotent change plan

Key every proposed mutation by one target path per logical override. Classify each
inventory item before editing:

- `KEPT`: the effective default or customization already satisfies the contract.
- `CREATED`: no project asset exists and authoritative project policy requires a new
  project-local override.
- `UPDATED`: an existing project asset needs a minimal, reviewed change.
- `BLOCKED`: policy, provenance, ownership, authority, or safe merge information is
  missing.

Never overwrite an existing project customization with a packaged baseline. Preserve
unknown keys, comments, project-only steps, stronger gates, and established URIs.
Patch only the necessary fields. If two files claim the same logical override, stop
and report the collision instead of choosing one or creating a third.

Before every write, retain the path and before digest. If the desired bytes are
byte-identical, make the operation a no-op. Never append duplicate steps, mappings,
source registrations, task references, or configuration entries. A second execution
with unchanged inputs must plan zero writes.

### 4. Apply safe project-local adaptation

Create a project-local preset, workflow, or decision guide only when the project's
reviewed policy differs from the packaged contract or supplies policy that cannot be
generic. Use the project's existing registered locations and naming conventions.
Never edit an installed gem in place.

When updating YAML or Markdown, preserve unrelated content and ordering wherever
possible. Re-read the complete file immediately after the write. Record the after
digest and a concise semantic delta. If safe preservation is not possible, leave the
file unchanged and classify it `BLOCKED` with the collision or ownership reason.

The adaptation may select and specialize supervision behavior, but it does not grant
permissions, does not publish, and does not exercise merge, deployment, installation,
or root authority.

### 5. Verify resolution and repeatability

Repeat the complete source inventory after edits:

1. Run `ace-nav explain` and `ace-nav resolve` for every selected `wfi://` and
   `guide://` URI.
2. Load every selected workflow with `ace-bundle` and verify it came from the intended
   owner.
3. Re-read all four effective presets and confirm the invariant review still passes.
4. Re-run the change-plan calculation from current bytes. It must report zero planned
   writes and no duplicate paths, steps, mappings, registrations, or task references.
5. Keep genuine unresolved policy or provisioning as `BLOCKED`; idempotence never
   turns a blocker into assumed success.

## Required Report

Return one report with these fields for every inspected or changed asset:

```text
STATUS: CREATED | UPDATED | KEPT | BLOCKED
KIND: preset | workflow | decision-guide | configuration
IDENTITY: exact preset name, protocol URI, or configuration key
OWNER: package default or project-owned source
PATH: resolved or intended path
BEFORE: before digest, MISSING, or UNRESOLVED
AFTER: after digest, UNCHANGED, or NOT-WRITTEN
CHANGE: concrete semantic change or reason it was kept
EVIDENCE: resolution and review references
BLOCKER: missing policy/provision and responsible owner, or NONE
```

Finish with counts for `CREATED`, `UPDATED`, `KEPT`, and `BLOCKED`, followed by the
repeat-run planned-write count. List any remaining authority, transport, publication,
installation, deployment, or root-operation gates separately from source adaptation.

## Success Criteria

- All four delivery presets resolve from either an intentional project override or the
  installed package default and pass the supervision-invariant review.
- Applicable workflows and the project delivery decision guide resolve through their
  registered protocol sources with intended ownership.
- Existing project customization and unknown fields remain intact; no file is
  destructively replaced by a generic baseline.
- The repeated run produces no duplicate task, step, mapping, source registration,
  configuration entry, or file, and plans zero writes for unchanged inputs.
- The report names every concrete change and every unresolved blocker with its owner
  and evidence; it claims no permission, publication, deployment, installation, or
  host-owned root effect.

## Error Handling

- **Missing package preset:** report `BLOCKED(package, ace-assign owner)` and do not
  fabricate a local substitute.
- **Unresolved workflow or guide:** preserve any existing file, report the failed URI,
  source registrations inspected, and responsible project/package owner.
- **Conflicting project overrides:** make no write; report every competing path and
  require the project owner to choose the canonical source.
- **Unsafe merge with customization:** keep the current file byte-for-byte and report
  the exact invariant gap and proposed minimal delta.
- **Uncertain external effect:** retain the original operation reference and reconcile
  it through its owner; never repeat the effect as part of configuration.

