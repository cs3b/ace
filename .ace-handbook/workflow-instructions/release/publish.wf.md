---
name: release-publish
description: Compatibility shim for release-local workflow
allowed-tools: Bash, Read, Edit
argument-hint: package-name... bump-level
doc-type: workflow
purpose: compatibility alias
update:
  update_frequency: on-change
  frequency: on-change
  last-updated: '2026-04-22'
---

# ACE Publish (Compatibility) Workflow

## Goal

This workflow is deprecated. Use `wfi://release/local` for current coordinated release
preparation behavior.

## Notes

* `wfi://release/publish` is kept as a compatibility entrypoint for existing integrations.
* Run `ace-bundle wfi://release/local` and follow that workflow end-to-end.
* This shim does not add additional behavior.
