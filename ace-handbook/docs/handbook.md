---
doc-type: user
title: Ace::Handbook Handbook Reference
purpose: Skills and workflows catalog for ace-handbook
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Ace::Handbook Reference

## Skills

| Skill | What it does |
| --- | --- |
| `as-handbook-init-project` | Initialize handbook structure in a project |
| `as-handbook-manage-guides` | Create and update handbook guides |
| `as-handbook-review-guides` | Review guides for quality and consistency |
| `as-handbook-manage-workflows` | Create and update workflow instruction files |
| `as-handbook-review-workflows` | Review workflow instructions for correctness |
| `as-handbook-manage-agents` | Create and maintain agent definition files |
| `as-handbook-update-docs` | Refresh package documentation |
| `as-handbook-parallel-research` | Coordinate parallel handbook research |
| `as-handbook-synthesize-research` | Synthesize parallel research outputs |
| `as-handbook-perform-delivery` | Drive delivery execution workflow |
| `as-release` | Orchestrate gem release workflow |
| `as-release-bump-version` | Increment gem version following semver |
| `as-release-rubygems-publish` | Publish gems to RubyGems.org |
| `as-release-update-changelog` | Update CHANGELOG with recent changes |

## Workflow Protocols

| Protocol | Purpose |
| --- | --- |
| `wfi://handbook/init-project` | Initialize project handbook structure |
| `wfi://handbook/manage-guides` | Create or update guide content |
| `wfi://handbook/review-guides` | Validate guide quality and standards |
| `wfi://handbook/manage-workflows` | Create or update workflow instructions |
| `wfi://handbook/review-workflows` | Validate workflow instruction quality |
| `wfi://handbook/manage-agents` | Create or update agent definitions |
| `wfi://handbook/update-docs` | Update package docs from implementation state |
| `wfi://handbook/parallel-research` | Run coordinated parallel research |
| `wfi://handbook/synthesize-research` | Consolidate research findings |
| `wfi://handbook/perform-delivery` | Execute delivery coordination workflow |
| `wfi://handbook/research` | Legacy research workflow path |

## Source Paths

- Canonical package workflows: `ace-handbook/handbook/workflow-instructions/handbook/`
- Canonical package skills: `ace-handbook/handbook/skills/`
- Canonical package guides: `ace-handbook/handbook/guides/`
- Canonical package templates: `ace-handbook/handbook/templates/`
- Project-level overlays (outside monorepo): `.ace-handbook/workflow-instructions/`, `.ace-handbook/guides/`,
  `.ace-handbook/templates/`, `.ace-handbook/skills/`
- Landing and docs: `ace-handbook/README.md`, `ace-handbook/docs/`
