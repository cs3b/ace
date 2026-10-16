---
name: as-design-site-audit
description: Audit design with browser and optional source evidence for a web site
# bundle: wfi://design/audit
# agent: general-purpose
allowed-tools:
  - Bash(ace-design:*)
  - Bash(ace-bundle:*)
  - Bash(bin/ace-design:*)
  - Bash(bin/ace-bundle:*)
  - Read
  - Edit
  - Write
user-invocable: true
argument-hint: "[brief or session or URL] [project path]"
source: ace-design
skill:
  kind: workflow
  execution:
    workflow: wfi://design/audit
---

Bind `surface=site`. Load `ace-bundle wfi://design/audit` in the current project and execute the workflow with that surface binding. In the ACE repository use `bin/ace-bundle`. Preserve this binding when delegating. This skill concerns web interfaces; native platforms use a separate future family.
