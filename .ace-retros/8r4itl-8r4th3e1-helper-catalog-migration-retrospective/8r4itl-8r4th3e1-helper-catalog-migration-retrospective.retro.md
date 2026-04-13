---
id: 8r4itl
title: 8r4.t.h3e.1 helper catalog migration retrospective
type: standard
tags: [ace-assign, skills, workflow, migration]
created_at: "2026-04-05 12:32:53"
status: active
---

# 8r4.t.h3e.1 helper catalog migration retrospective

## What Went Well
- Migrated helper ownership for `task-load`, `mark-task-done`, `reflect-and-refactor`, and `create-retro` to internal canonical skills/workflows without breaking assignment execution tests.
- Added an explicit discovery boundary (`user-invocable: true`) in `SkillAssignSourceResolver`, with regression tests proving internal helpers stay out of public assign catalogs.
- Preserved runtime behavior by keeping compatibility shims in step catalog YAML while adding explicit migration metadata for deferred helpers.

## What Could Be Improved
- Release workflow execution in a scoped assignment subtree can force version/changelog updates even for task-level migration work; assignment presets should distinguish package-release-required vs task-only subtrees.
- Explicit `workflow:` fields in migrated helper shims caused resolver failures in constrained test fixtures; migration playbooks should include this fixture-compatibility check up front.

## Action Items
- Add a follow-up migration task to move `pre-commit-review` and `verify-test` nested template behavior into internal orchestration skills/workflows.
- Add a guardrail test documenting when helper step shims should avoid explicit `workflow:` in favor of skill-only compatibility.
