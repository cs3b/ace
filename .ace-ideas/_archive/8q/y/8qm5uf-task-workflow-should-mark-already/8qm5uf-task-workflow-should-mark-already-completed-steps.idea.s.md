---
id: 8qm5uf
status: done
title: "Task workflow should mark already-completed steps "
tags: [workflow, task, ux]
created_at: "2026-03-23 03:53:48"
---

# Task workflow should mark already-completed steps 

Task workflow should mark already-completed steps as done when documenting unplanned work. When creating tasks to document work that has already been done (e.g. via as-task-document-unplanned), the task spec steps that correspond to completed work should be marked as done automatically. This prevents agents from being asked to redo work that was already completed. Current example: README refresh task 8qm.t.5nx has 3 done subtasks for already-completed README rewrites, but the task workflow would still present all steps as pending.
