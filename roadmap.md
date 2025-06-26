---
title: Project Roadmap
last_reviewed: 2025-06-26
status: draft
---

## 1. Project Vision

To empower developers and AI agents with Coding Agent Tools (CAT), a seamless Ruby gem that standardizes and automates routine DevOps tasks, enabling a greater focus on high-value design and coding.

## 2. Strategic Objectives

| # | Objective                                                                 | Success Metric                                                                         |
|---|---------------------------------------------------------------------------|----------------------------------------------------------------------------------------|
| 1 | Deliver a robust and easily installable Ruby gem (CAT).                     | Gem installable via `gem install coding_agent_tools` or Bundler.                       |
| 2 | Provide ergonomic CLI tools for both human developers and AI agents.      | CLI commands succeed ≥ 99% over 1,000 automated invocations.                           |
| 3 | Ensure high-quality code and architecture.                                | Adherence to ATOM architecture; 100% unit & integration test coverage (RSpec).        |
| 4 | Enable flexible and offline-capable workflows.                            | Support for offline workflows via LM Studio local models.                              |
| 5 | Improve developer and agent productivity in Git and task workflows.       | Reduce median time from code change to committed diff by 30% within pilot team.        |
| 6 | Achieve significant adoption of CAT commands in automated processes.      | ≥ 80% of automated CI runs invoke at least one CAT command.                            |
| 7 | Minimize support burden related to common DevOps tasks.                   | ≤ 2 support tickets/week related to Git setup or task selection after 1 month.         |

## 3. Key Themes & Epics

| Theme                          | Description                                                                                   | Linked Epics (Requirement IDs)                                           |
|--------------------------------|-----------------------------------------------------------------------------------------------|--------------------------------------------------------------------------|
| LLM Integration                | Core capabilities for interacting with various Large Language Models (Gemini, LM Studio).       | R-LLM-1, R-LLM-2, R-LLM-3, R-LLM-4                                       |
| Task Management & Orchestration| Utilities for managing development tasks, identifying next actions, and release context.    | R-TASK-1, R-TASK-2, R-TASK-3, R-TASK-4, R-TASK-5, R-TASK-6               |
| Developer Context Enhancement  | Tools to gather and present comprehensive contextual information for development tasks.         | R-CTX-1, R-CTX-2, R-CTX-3, R-CTX-4, R-CTX-5                               |
| Markdown Document Quality      | Utilities for maintaining the integrity and quality of Markdown documentation (linting).      | R-MD-1, R-MD-2, R-MD-3, R-MD-4                                           |
| AI-Assisted Task Definition    | Streamlining the creation of new tasks and ideas using LLM-based assistance.                  | R-TCI-1, R-TCI-2, R-TCI-3, R-TCI-4, R-TCI-5                               |

## 4. Planned Major Releases

| Version | Codename                  | Target Window | Goals                                                                                     | Key Epics (Conceptual/Requirement IDs)                                                               |
|---------|---------------------------|---------------|-------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| v0.3.0  | "Conductor"               | Q3 2025       | Task Management & Orchestration theme features. Beta release.                             | R-TASK-1, R-TASK-2, R-TASK-3, R-TASK-4, R-TASK-5, R-TASK-6                                         |
| v0.4.0  | "Pathfinder"              | Q4 2025       | Developer Context Enhancement theme features.                                             | R-CTX-1, R-CTX-2, R-CTX-3, R-CTX-4, R-CTX-5                                                        |
| v0.5.0  | "Scribe"                  | Q4 2025       | Markdown Document Quality theme features.                                                 | R-MD-1, R-MD-2, R-MD-3, R-MD-4                                                                       |
| v0.6.0  | "Spark"                   | Q4 2025       | AI-Assisted Task Definition theme features.                                               | R-TCI-1, R-TCI-2, R-TCI-3, R-TCI-4, R-TCI-5                                                        |
| v1.0.0  | "Keystone"                | Q1 2026       | Stable v1: All P1 features from all themes hardened, documented, published to RubyGems. | All P1 Req IDs (R-LLM\*, R-TASK\*, R-CTX\*, R-MD\*, R-TCI\*) integrated & stable.                 |

_Note: Release planning should align with project folder structure in `dev-taskflow/backlog/`, `dev-taskflow/current/`, and `dev-taskflow/done/` as per the Roadmap Definition Guide._

## 5. Cross-Release Dependencies

- **Advanced LLM Features (v1.0.0):** Several P1 features in v1.0.0 "Keystone", such as LLM-based context summarization (R-CTX-4) and LLM-assisted task expansion (R-TCI-2), depend on the foundational "LLM Integration" capabilities delivered in v0.2.0 "Synapse".
- **Task Utilities Data Source (v0.3.0):** The "Task Management & Orchestration" features (R-TASK-1, R-TASK-2, R-TASK-4) in v0.3.0 "Conductor" depend on the availability and stability of `dev-tools/exe-old/*` scripts, which serve as their primary data source.
- **External Service Dependencies:**
    - "LLM Integration" (R-LLM-1, R-LLM-3) requires access to Google Gemini API and a local LM Studio installation.

## 6. Update History

| Date       | Summary                                                                         | Author         |
|------------|---------------------------------------------------------------------------------|----------------|
| 2025-06-26 | Removed Git Workflow Automation theme and v0.3.0 Forge release (tools moved to separate repository). | AI Assistant   |
| 2025-01-15 | Added v.0.2.0-synapse release to backlog with concrete task breakdown.         | AI Assistant   |
| 2025-06-06 | Removed completed v0.1.0 Foundation from planned releases.                     | AI Assistant   |
| 2025-06-02 | Added v0.1.0 Foundation release with concrete task breakdown to backlog.        | AI Assistant   |
| 2025-06-02 | Restructured Planned Major Releases based on feedback (granular initial, theme-based). | AI Assistant   |
| 2025-06-02 | Populated Cross-Release Dependencies section.                                   | AI Assistant   |
| 2025-06-02 | Populated Key Themes, Epics, and Planned Major Releases from PRD.               | AI Assistant   |
| 2025-06-02 | Initial roadmap draft created from PRD.                                         | AI Assistant   |
