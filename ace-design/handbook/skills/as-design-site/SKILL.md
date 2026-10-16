---
name: as-design-site
description: Generate preset-driven design variants with shared mock data for a web site
# bundle: wfi://design/explore
# agent: general-purpose
allowed-tools:
  - Bash(ace-design:*)
  - Bash(ace-bundle:*)
  - Bash(bin/ace-design:*)
  - Bash(bin/ace-bundle:*)
  - Read
user-invocable: true
argument-hint: "[brief or session or URL] [project path]"
source: ace-design
skill:
  kind: workflow
  execution:
    workflow: wfi://design/explore
---

Bind `surface=site`. Load `ace-bundle wfi://design/explore` in the current project and execute the workflow with that surface binding. In the ACE repository use `bin/ace-bundle`. Choose `--kind view|component` and the appropriate `--profile`; use the matching adjust skill for project-wide preference changes. Use the CLI runner and supply per-variant extra prompts when useful. Preserve this binding throughout. This skill concerns web interfaces; native platforms use a separate future family.
