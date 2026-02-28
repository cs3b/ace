---
id: 8ppq7w
title: "Refactor ace-taskflow: Simplify Release Model and Archive Structure"
status: done
tags: []
created_at: '2026-02-26 17:28:46'
filename_suggestion: refactor-taskflow-simplify-archive
enhanced_at: 2026-02-26 17:28:46
location: active
llm_model: pi:glm
completed_at: 2026-02-26T20:34:02+00:00
---
# Refactor ace-taskflow: Simplify Release Model and Archive Structure

## What I Hope to Accomplish

Simplify ace-taskflow by removing complex release folder structures (v.0.9.0 pattern) in favor of a flat task-based model with unique IDs. Extract domain-specific directories (.ace-ideas, .ace-tasks, .ace-retros, .ace-reviews) to reduce interdependencies. Archive tasks by b36ts week format (YM/W/) to eliminate the need for moving tasks between active and completed states. Rename ace-review to ace-code-analysis for semantic clarity.

The goal is to make the system less tightly coupled - tasks can exist independently of ideas, releases become metadata (task as release) rather than structural hierarchies, and archival is location-based rather than requiring moves.

## What "Complete" Looks Like

1. Unique task ID system implemented (b36ts format, system-wide no duplication)
2. Flat task storage in `.ace-task/<taskid>/` with all task artifacts self-contained
3. Separate domain directories created: `.ace-ideas/`, `.ace-tasks/`, `.ace-retros/`, `.ace-reviews/`
4. Archive structure uses YM/W/ (e.g., 26/08/) week folders under archive/
5. ace-review renamed/rebranded as ace-code-analysis throughout
6. Release process simplified to "mark task as done" - no folder creation or moves required
7. Tasks decoupled from ideas (optional parent-child relationship, not structural dependency)
8. All existing ace-taskflow commands updated to work with new flat structure
9. Migration path provided for existing v.0.9.0 release folders

## Success Criteria

- All ace-taskflow commands operate correctly on flat task structure
- No task ID collisions occur in concurrent task creation across releases
- Archive organization by week eliminates need for task moves on completion
- ace-code-analysis commands work independently of task associations
- Migration from existing release folder structure to flat structure is lossless
- System complexity reduced: fewer directory traversal operations, simpler state transitions
- Documentation updated to reflect simplified release/workflow model

---

## Original Idea

```
rethink the releases (we might not need the folders as much - only archive/release, but tasks can be in .ace-task/<taskid> - maybe we should have unique taskids - similar to b36ts across whole system so the ids are not duplicating ) 
maybe we should extract ace-idea (.ace-ideas) ace-task (.ace-tasks) ace-retros (.ace-retro) ace-review should not be linked with task (.ace-reviews) and btw.: ace-review should be ace-code-analysis to be fair 

to add to this - the task itself is a release very often - we still time from time we will make a bigger release but if we will organize archive by b36ts week 3 characters folders ym/w/tasks-folders then in archive we will not ahve issue about moving those tasks anywhere anytime at all this simplify realease process - it can be just marking task as done 

addtionla ace-taskflow grow .. grow a lot and removing all the release part (as 2025 concept, of folder v.0.9.0 ) we will simplify the system - make it less interconnected ( task can be created form idea but doens't have to, and so on ) it will allow to simplify and make it more robust 

a lot of thougsh here but this the directions i see
```