---
name: release-publish
description: Compatibility entrypoint for release preparation (non-publishing default)
allowed-tools: Bash, Read, Edit
argument-hint: "[target...] [patch|minor|major]"
doc-type: workflow
purpose: compatibility alias for local release prep until a publication contract exists
update:
  frequency: on-change
  last-updated: "2026-08-12"
---

# Release Publish (Compatibility) Workflow

## Goal

Provide a stable `wfi://release/publish` entrypoint for skills and assign catalog steps.
**Default behavior is non-publishing:** follow local release preparation until the project
supplies an explicit publication contract.

## Prep vs publication

| State | Behavior |
|-------|----------|
| **Default (this baseline)** | Equivalent to local preparation — version/changelog/verify/commit only |
| **Project publication contract present** | Project overlay replaces this file and may perform registry/deploy steps |

Never invent registry credentials, deploy targets, or publish commands from this baseline.

## Prerequisites

Same as local release preparation: identifiable release targets, version/changelog surfaces,
and verification tooling when available.

## Project Context Loading

- Load `wfi://release/local` via `ace-bundle wfi://release/local` and treat that workflow as
  the executable contract for this compatibility entrypoint.
- Also load project context (`ace-bundle project`) when the local workflow requires it.

## Process Steps

### 1. Prefer local preparation

1. Run `ace-bundle wfi://release/local`.
2. Read and execute that workflow end-to-end with the same arguments passed to this skill/step.
3. Stop after local preparation succeeds.

### 2. Publication gate (do not cross by default)

Only continue into external publication when **all** of the following are true:

- A project-local (or higher-priority) overlay for `wfi://release/publish` defines publish steps, **or**
  the operator explicitly loaded a dedicated publication workflow (for example a customized
  `wfi://release/rubygems-publish`).
- Credentials/targets required by that contract are present.
- The operator intent is clearly to publish (not merely prepare).

If those are not met, report that publication is blocked pending a project publication contract.

## Override

To make `wfi://release/publish` actually publish:

1. Add `.ace-handbook/workflow-instructions/release/publish.wf.md` (or another higher-priority
   WFI source) with explicit registry/deploy steps, credentials checks, and verification gates.
2. Keep the URI stable so assign catalog steps (`release`, `release-minor`) keep resolving.
3. Optionally specialize sibling URIs (`rubygems-publish`, deploy workflows) instead of
   overloading this compatibility entrypoint.

## Success Criteria

- [ ] Local release preparation completed via the local workflow contract
- [ ] No external publish/deploy performed unless a project publication contract authorized it
- [ ] If publication was requested without a contract, failure is explicit and actionable

## Common Issues

- Assign steps reference `wfi://release/publish` expecting prep — that is intentional for the
  default baseline.
- Silent publish is forbidden; missing contracts must fail clearly rather than no-op publish.
