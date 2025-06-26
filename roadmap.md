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

## 4. Planned Major Releases

| Version | Codename                  | Target Window | Goals                                                                                     | Key Epics (Conceptual/Requirement IDs)                                                               |
|---------|---------------------------|---------------|-------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| v.0.3.0 | "Workflows"               | Q1 2026       | Improve workflow independence and integration capabilities for coding agents like Claude Code, Windsurf, Zed | Workflow Independence, Agent Integration, Documentation Enhancement |
| v1.0.0  | "Keystone"                | Q1 2026       | Stable v1: Core LLM integration features hardened, documented, published to RubyGems.   | All P1 Req IDs (R-LLM\*) integrated & stable.                                              |

_Note: Release planning should align with project folder structure in `dev-taskflow/backlog/`, `dev-taskflow/current/`, and `dev-taskflow/done/` as per the Roadmap Definition Guide._

## 5. Cross-Release Dependencies

- **External Service Dependencies:**
    - "LLM Integration" (R-LLM-1, R-LLM-3) requires access to Google Gemini API and a local LM Studio installation.

## 6. Update History

| Date       | Summary                                                                         | Author         |
|------------|---------------------------------------------------------------------------------|----------------|
| 2025-06-26 | Added release v.0.3.0-workflows to planned releases focusing on workflow independence and agent integration. | AI Assistant   |
| 2025-06-26 | Removed all tool-related themes and releases (moved to separate dev-tools repository). Roadmap now focuses solely on LLM integration. | AI Assistant   |
| 2025-01-15 | Added v.0.2.0-synapse release to backlog with concrete task breakdown.         | AI Assistant   |
| 2025-06-06 | Removed completed v0.1.0 Foundation from planned releases.                     | AI Assistant   |
| 2025-06-02 | Added v0.1.0 Foundation release with concrete task breakdown to backlog.        | AI Assistant   |
| 2025-06-02 | Restructured Planned Major Releases based on feedback (granular initial, theme-based). | AI Assistant   |
| 2025-06-02 | Populated Cross-Release Dependencies section.                                   | AI Assistant   |
| 2025-06-02 | Populated Key Themes, Epics, and Planned Major Releases from PRD.               | AI Assistant   |
| 2025-06-02 | Initial roadmap draft created from PRD.                                         | AI Assistant   |
