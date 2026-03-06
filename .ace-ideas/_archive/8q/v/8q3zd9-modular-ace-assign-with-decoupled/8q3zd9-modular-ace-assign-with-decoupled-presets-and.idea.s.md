---
id: 8q3zd9
status: done
title: Modular ace-assign with Decoupled Presets and Sources
tags: []
created_at: "2026-03-04 23:34:44"
---

# Modular ace-assign with Decoupled Presets and Sources

## What I Hope to Accomplish
Transition `ace-assign` from a monolithic package with hardcoded logic for tasks and reviews into a flexible, decoupled orchestration engine. By adopting a "source registration" pattern similar to `ace-nav`, we can empower the `assign:` frontmatter configuration to use modular building blocks, allowing for greater extensibility and cleaner separation of concerns across the ACE suite.

## What "Complete" Looks Like
A system where `ace-assign` acts as a thin coordinator that knows nothing about the specifics of `ace-task` or `ace-review`. Other packages register themselves as sources or provide specific building blocks that `ace-assign` then composes into presets. The frontmatter `assign:` block becomes a powerful, declarative way to configure these modular interactions without internal coupling.

## Success Criteria
- Logic specific to `ace-task` and `ace-review` is removed from the `ace-assign` core repository.
- A registration API exists for internal packages to add new assignment sources and behaviors.
- Presets are redefined as compositions of registered building blocks rather than hardcoded procedures.
- The `assign:` frontmatter block can successfully trigger modular workflows from registered sources.
- Existing assignment functionality remains operational but runs through the new decoupled architecture.
