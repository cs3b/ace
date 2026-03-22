---
doc-type: user
title: Ace::Handbook Usage Reference
purpose: Practical command reference for ace-handbook workflows
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-handbook Usage Reference

`ace-handbook` is a workflow package. Use `ace-nav` for discovery/resolution and `ace-bundle` to load executable workflow instructions.

## Discover workflows with `ace-nav`

```bash
ace-nav list 'wfi://handbook/*'
ace-nav resolve wfi://handbook/manage-guides
ace-nav resolve wfi://handbook/review-workflows

```

Use discovery when you need available paths or exact protocol references.

## Load workflows with `ace-bundle`

```bash
ace-bundle wfi://handbook/init-project
ace-bundle wfi://handbook/manage-guides
ace-bundle wfi://handbook/review-guides
ace-bundle wfi://handbook/manage-workflows
ace-bundle wfi://handbook/review-workflows
ace-bundle wfi://handbook/manage-agents
ace-bundle wfi://handbook/update-docs

```

Use bundle output as source-of-truth instructions.

## Workflow command matrix

| Protocol | Typical use |
| --- | --- |
| `wfi://handbook/init-project` | Initialize handbook project structure |
| `wfi://handbook/manage-guides` | Author/update guide files |
| `wfi://handbook/review-guides` | Validate guide quality and standards |
| `wfi://handbook/manage-workflows` | Author/update workflow instructions |
| `wfi://handbook/review-workflows` | Validate workflow quality |
| `wfi://handbook/manage-agents` | Manage `.ag.md` agent definitions |
| `wfi://handbook/update-docs` | Refresh package docs from implementation state |
| `wfi://handbook/parallel-research` | Coordinate parallel research flows |
| `wfi://handbook/synthesize-research` | Merge parallel findings |
| `wfi://handbook/perform-delivery` | Drive delivery orchestration |

## Demo workflow assets

Create and record terminal demo assets:

```bash
ace-demo create ace-handbook-getting-started --desc "Show handbook workflow discovery" -- "ace-nav resolve wfi://handbook/manage-guides"
ace-demo record ace-handbook/docs/demo/ace-handbook-getting-started.tape --output ace-handbook/docs/demo/ace-handbook-getting-started.gif

```

## Notes

- Keep command invocations direct (`ace-*`) without shell post-processing.
- Treat loaded workflow bundles as canonical instructions.
- Keep README concise and move detailed reference content into `ace-handbook/docs/`.
