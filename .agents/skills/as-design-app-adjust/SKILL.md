---
name: as-design-app-adjust
description: Personalize and refresh project design assumptions for app views and
  components
allowed-tools:
- Bash(ace-design:*)
- Bash(ace-bundle:*)
- Bash(bin/ace-design:*)
- Bash(bin/ace-bundle:*)
- Read
- Edit
- Write
user-invocable: true
argument-hint: "[preferences or refresh] [view|component] [context]"
source: ace-design
skill:
  kind: workflow
  execution:
    workflow: wfi://design/adjust
---

Bind `surface=app`. Load `ace-bundle wfi://design/adjust` and execute it in the target project. In the ACE repository use `bin/ace-bundle` and `bin/ace-design`. Preserve the surface binding and the user's view/component scope. Use the runner to compose assumptions; do not independently overwrite generated context files, except to restore verified candidate/previous evidence during the workflow's explicit manual-edit recovery.
