---
name: as-design-app-implement
description: Implement a selected direction with production verification for a web
  application
allowed-tools:
- Bash
- Read
- Edit
- Write
- Glob
- Grep
user-invocable: true
argument-hint: "[brief or session or URL] [project path]"
source: ace-design
skill:
  kind: workflow
  execution:
    workflow: wfi://design/implement
---

Bind `surface=app`. Load `ace-bundle wfi://design/implement` in the current project and execute the workflow with that surface binding. In the ACE repository use `bin/ace-bundle`. Preserve this binding when delegating. This skill concerns web interfaces; native platforms use a separate future family.
