---
name: as-design-look-for-inspiration
description: Research new design evidence and prepare a tested package change for review
# bundle: wfi://design/look-for-inspiration
# agent: general-purpose
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - WebFetch
  - WebSearch
user-invocable: true
argument-hint: "[--surface shared|site|app] [source checkout] [since date or revision]"
source: ace-design
skill:
  kind: workflow
  execution:
    workflow: wfi://design/look-for-inspiration
---

Load `ace-bundle wfi://design/look-for-inspiration` and execute it. In the ACE repository use `bin/ace-bundle`. Produce a concrete reviewable proposal; never automatically merge or publish.
