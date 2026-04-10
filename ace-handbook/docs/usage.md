---
doc-type: user
title: Ace::Handbook Usage Reference
purpose: Practical command reference for ace-handbook workflows
ace-docs:
  last-updated: '2026-04-10'
  last-checked: '2026-04-10'
---

# ace-handbook Usage Reference

`ace-handbook` is a workflow package. Use `ace-nav` for discovery/resolution and `ace-bundle` to load executable workflow instructions.

## Discover workflows with `ace-nav`

```bash
ace-nav list 'wfi://handbook/*'
ace-nav resolve wfi://handbook/manage-guides
ace-nav resolve wfi://handbook/review-workflows
ace-nav list 'guide://*'
ace-nav list 'cookbook://*'
ace-nav resolve cookbook://setup-starting-an-astro-project-with-ace
ace-nav list 'tmpl://*'
ace-nav list 'skill://*'

```

Use discovery when you need available paths or exact protocol references.

## Project handbook extensions (`.ace-handbook/`)

For ordinary projects (outside the ACE monorepo), use `.ace-handbook/` as the canonical root for project-specific
handbook assets:

```text
.ace-handbook/
  workflow-instructions/
  cookbooks/
  guides/
  templates/
  skills/
```

Typical setup:

```bash
mkdir -p .ace-handbook/workflow-instructions/handbook
mkdir -p .ace-handbook/cookbooks
mkdir -p .ace-handbook/guides
mkdir -p .ace-handbook/templates
mkdir -p .ace-handbook/skills
```

Protocol resolution (`wfi://`, `guide://`, `tmpl://`, `skill://`) uses the merged project context, so these
project paths are discovered alongside installed package handbooks.

## Load workflows with `ace-bundle`

```bash
ace-bundle wfi://handbook/init-project
ace-bundle wfi://handbook/manage-guides
ace-bundle wfi://handbook/manage-cookbooks
ace-bundle wfi://handbook/review-guides
ace-bundle wfi://handbook/review-cookbooks
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
| `wfi://handbook/manage-cookbooks` | Author/update cookbook files |
| `wfi://handbook/review-guides` | Validate guide quality and standards |
| `wfi://handbook/review-cookbooks` | Validate cookbook quality and standards |
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

## Sync completeness and rerun guidance

`ace-handbook sync` prints provider projection counts and inventory source counts. If it reports only one source
(for example `ace-handbook`), you may have synced before installing the full ACE stack. After installing additional
packages, rerun:

```bash
ace-handbook sync
```

## Notes

- Keep command invocations direct (`ace-*`) without shell post-processing.
- Treat loaded workflow bundles as canonical instructions.
- Keep README concise and move detailed reference content into `ace-handbook/docs/`.
- For multi-package releases, use `wfi://release/rubygems-publish` to publish, then run `ace-test-e2e ace-monorepo-e2e TS-MONO-001` to record the propagation proof result (`SAFE`, `LAG_DETECTED`, or `METADATA_BROKEN`) with mitigation guidance when lag is detected.
- See `ace-handbook/docs/release-rubygems-proof.md` for the proof contract consumed by onboarding docs.
