---
title: Iterative Review with Next-Phase Dry Runs
filename_suggestion: feat-taskflow-iterative-review
enhanced_at: 2026-02-25 23:24:54.000000000 +00:00
llm_model: pi:glm
status: done
completed_at: 2026-02-26 15:32:31.000000000 +00:00
id: 8poz4f
tags: []
created_at: '2026-02-25 23:24:54'
---

# Iterative Review with Next-Phase Dry Runs

## What I Hope to Accomplish
Implement an iterative review process that simulates the next phase in the idea -> task -> plan pipeline to surface questions and improvements before committing. When capturing an idea, automatically or manually trigger a dry run of task drafting; when creating a task, dry run plan preparation. Insights from these dry runs feed back as refinements to the current step—improving the content or adding questions to answer—without advancing the workflow state.

## What "Complete" Looks Like
A review workflow in ace-taskflow that: (1) can trigger "next-phase dry runs" from idea, task, and plan states; (2) captures insights from the dry run as structured questions or refinements; (3) presents feedback to the user for acceptance before state transition; (4) supports both auto-triggered and manual review modes; (5) integrates with existing review agents and uses the wfi:// protocol for workflow orchestration.

## Success Criteria
- Idea capture workflow can optionally dry-run task drafting and surface missing context as questions
- Task creation workflow can dry-run plan preparation and identify gaps in task specifications
- Dry-run outputs are captured as questions or refinements without modifying downstream artifacts
- Review agents can invoke dry runs and process their outputs deterministically
- Users can enable/disable auto-review via configuration cascade (CLI > project > user > defaults)

---

## Original Idea

```
improve the review process on the idea -> task -> plan, as part of review we should do dry run of the next phase, and got back to previous step to ask question about things we learn when doing next phase dry run, e.g.; we want to capture idea and we capture the idea, but we can (auto or not) rreview this idea by trying to draft task and learn from this. of even draft task, prepare plan and then in backwards ask questions that we should answear. We don't make any modification except the improving the idea or adding questions that should be answerered in the future ...
```