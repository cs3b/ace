---
doc-type: guide
title: Strategic Planning Guide
purpose: Documentation for ace-handbook/handbook/guides/strategic-planning.g.md
ace-docs:
  last-updated: 2026-01-08
  last-checked: 2026-03-21
---

# Strategic Planning Guide

## Purpose

This guide explains **why** and **how** we maintain a living roadmap that aligns day-to-day development with long-term vision.

## 1. Conceptual Model

```text
Vision → Strategic Objectives → Roadmap (Themes/Epics → Releases) → Tasks
```

* Vision: enduring North Star.
* Strategic Objectives: 6–12 m outcomes aligned to vision.
* Roadmap: rolling plan mapping objectives to concrete Releases.
* Tasks: granular units executed via workflows.

## 2. Roadmap Document Anatomy

See `/dev-taskflow/roadmap.md`. Key sections:

1. Project Vision
2. Strategic Objectives (table)
3. Key Themes & Epics (table)
4. Planned Major Releases (table)
5. Cross-Release Dependencies
6. Update History

## 3. Roadmap Management Lifecycle

1. **Create / Propose Change**: Use `update-roadmap.wf.md` workflow.
2. **Review**: Stakeholder/lead approves via PR or discussion.
3. **Update**: Commit changes, increment `last_reviewed` and add entry to *Update History*.
4. **Quarterly Checkpoint**: At start/end of each release cycle, validate roadmap relevance.

## 4. Roles & Responsibilities

| Role | Responsibilities |
|------|------------------|
| Lead Maintainer | Owns roadmap integrity, final approvals |
| Contributors | Propose updates, align tasks with roadmap |
| AI Agent | Assist drafting and validating roadmap changes |

## 5. Workflow Integration Points

* **`prepare-tasks.md`**: Must consult roadmap when confirming target releases.
* **Release Templates**: Reference strategic objectives in release README.
* **`work-on-task.md`**: Tasks should link back to their roadmap Epic/Theme where applicable.

## 6. Tips & Common Pitfalls

* Avoid overly granular detail in roadmap--keep tactical work in tasks.
* Review metrics regularly; retire objectives once met.
* Keep roadmap lightweight--update tables, not essays.

---

## Last Updated

2025-05-07
