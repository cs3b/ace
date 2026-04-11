---
doc-type: user
purpose: Handbook index for ace-retro skills, workflows, and templates.
ace-docs:
  last-updated: '2026-03-22'
---

# ace-retro Handbook Reference

Complete catalog of skills, workflows, and templates shipped with `ace-retro`.

The `handbook/` directory contains canonical skill definitions and workflow instructions used by provider integrations and assignment-driven execution.

## Skills

| Skill | Purpose |
|-------|---------|
| `as-retro-analyze-worktree` | Analyze one or many completed worktrees for scope drift, post-completion residual work, and `.ace-local` review/test telemetry, then generate ranked spec-improvement recommendations |
| `as-retro-create` | Capture a retrospective and move the idea file into the retro workspace |
| `as-retro-synthesize` | Synthesize multiple retrospectives into recurring patterns and recommendations |
| `as-handbook-selfimprove` | Analyze agent mistakes, update process guidance, and fix the immediate issue |

## Workflow Instructions

Load any workflow with `ace-bundle wfi://<namespace>/<action>`.

| Protocol Path | Description | Invoked by |
|--------------|-------------|------------|
| `wfi://retro/analyze-worktree` | Analyze one or many completed worktrees (fleet mode enabled) for scope drift, residual work, and `.ace-local` quality telemetry; emits a ranked spec-improvement retro | `as-retro-analyze-worktree` |
| `wfi://retro/create` | Create a retrospective artifact from a task or idea context | `as-retro-create` |
| `wfi://retro/synthesize` | Aggregate retros into structured learnings | `as-retro-synthesize` |
| `wfi://retro/selfimprove` | Guided self-improvement flow for agent quality issues | `as-handbook-selfimprove` |

## Templates

| Template Path | Protocol | Purpose |
|---------------|----------|---------|
| `handbook/templates/retro/retro.template.md` | `tmpl://retro/retro` | Base markdown structure for a retrospective entry |

## Source Layout

```text
handbook/
  skills/
    as-retro-analyze-worktree/SKILL.md
    as-retro-create/SKILL.md
    as-retro-synthesize/SKILL.md
    as-handbook-selfimprove/SKILL.md
  workflow-instructions/retro/
    create.wf.md
    synthesize.wf.md
    selfimprove.wf.md
    analyze-worktree.wf.md
  templates/retro/
    retro.template.md
```

## Runtime Discovery

```bash
ace-bundle wfi://retro/create
ace-bundle wfi://retro/analyze-worktree
ace-bundle wfi://retro/synthesize
ace-bundle wfi://retro/selfimprove
```
