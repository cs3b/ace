# Workflow Instructions

This directory contains detailed, step-by-step instructions designed to be followed by an AI agent (often guided by a user) to perform common development and project management tasks.

Refer to the [Writing Effective Workflow Instructions Guide](../guides/writing-workflow-instructions.md) for details on structure and best practices.

## Core Workflow

-   [Load Environment](./load-env.md): Load project context, guides, and task information.
-   [Work on Task](./work-on-task.md): Select and understand a task before implementation (includes TDD cycle).
-   [Commit](./commit.md): Create well-structured Git commits.
-   [Fix Tests](./fix-tests.md): Debug and fix failing tests.
-   [Prepare Release](./prepare-release.md): Prepare content, documentation, and perform pre-flight checks for a release.
-   [Ship Release](./ship-release.md): Execute the release process (versioning, tagging, building, publishing).

## Project Initialization & Setup

-   [Initialize Project Structure](./initialize-project-structure.md): Initialize `docs-dev` and `docs-project` structures.
-   [Update Blueprint](./update-blueprint.md): Update the `docs-project/blueprint.md` project overview.

## Task Preparation

-   [Prepare Tasks](./prepare-tasks.md): Overview of task preparation.
    -   [From Concepts in Backlog](./lets-prepare-tasks/from-concepts-in-backlog.md)
    -   [From Diff](./lets-prepare-tasks/from-diff.md)
    -   [From FRD](./lets-prepare-tasks/from-frd.md)
    -   [From PR Comments (API)](./lets-prepare-tasks/from-pr-comments-api.md)
    -   [From PR Comments (MCP)](./lets-prepare-tasks/from-pr-comments-mcp.md)
    -   [From PRD](./lets-prepare-tasks/from-prd.md)
    -   [From Release Backlog](./lets-prepare-tasks/from-release-backlog.md)

## Documentation Generation

-   Docs Generation (`docs/`):
    -   [Generate ADR](./docs/generate-adr.md)
    -   [Generate API Docs](./docs/generate-api-docs.md)
    -   [Generate Release Overview](./docs/generate-release-overview.md)
    -   [Generate Retro](./docs/generate-retro.md)
    -   [Generate Review Checklist](./docs/generate-review-checklist.md)
    -   [Generate Test Cases](./docs/generate-test-cases.md)
    -   [Generate User Docs](./docs/generate-user-docs.md)

## Project Management & Reflection

-   [Review Kanban Board](./review-kanban-board.md): Review task status in the project.
-   [Log Session](./log-session.md): Log the current session details.
-   [Self Reflect](./self-reflect.md): Perform self-reflection on a completed task or session.
