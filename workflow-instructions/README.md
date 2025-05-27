[← Back to docs-dev root](../README.md) ▸ Workflow Instructions

# Workflow Instructions

This directory contains detailed, step-by-step instructions designed to be followed by an AI agent (often guided by a user) to perform common development and project management tasks.

## Core Workflow

- [Load Environment](./load-env.md): Load project context, guides, and task information.
- [Work on Task](./work-on-task.md): Select and understand a task before implementation (includes TDD cycle).
- [Commit](./commit.md): Create well-structured Git commits.
- [Fix Tests](./fix-tests.md): Debug and fix failing tests.
- [Prepare Release](./prepare-release.md): Prepare content, documentation, and perform pre-flight checks for a release.
- [Ship Release](./ship-release.md): Execute the release process (versioning, tagging, building, publishing).

## Project Initialization & Setup

- [Initialize Project Structure](./initialize-project-structure.md): Initialize `docs-dev` and `docs-project` structures.
- [Update Blueprint](./update-blueprint.md): Update the `docs-project/blueprint.md` project overview.

## Task Preparation

- [Breakdown Notes into Tasks](./breakdown-notes-into-tasks.md): Orchestrates processing of various inputs into structured notes for task creation.
  - [From Concepts in Backlog](./breakdown-notes-into-tasks/from-concepts-in-backlog.md)
  - [From Diff](./breakdown-notes-into-tasks/from-diff.md)
  - [From FRD](./breakdown-notes-into-tasks/from-frd.md)
  - [From PR Comments (API)](./breakdown-notes-into-tasks/from-pr-comments-api.md)
  - [From PR Comments (MCP)](./breakdown-notes-into-tasks/from-pr-comments-mcp.md)
  - [From PRD](./breakdown-notes-into-tasks/from-prd.md)
  - [From Release Backlog](./breakdown-notes-into-tasks/from-release-backlog.md)

## Documentation Generation

- [Create ADR](./create-adr.md)
- [Create API Docs](./create-api-docs.md)
- [Create Release Overview](./create-release-overview.md)
- [Create Retrospective Document](./create-retrospective-document.md)
- [Create Review Checklist](./create-review-checklist.md)
- [Create Test Cases](./create-test-cases.md)
- [Create User Docs](./create-user-docs.md)

## Project Management & Reflection

- [Review Tasks Board Status](./review-tasks-board-status.md): Review current task statuses, dependencies, and priorities on the board.
- [Log Compact Session](./log-compact-session.md): Log a compact summary of the current session for context saving/reloading.
- [Create Reflection Note](./create-reflection-note.md): Capture individual observations and learnings using the standard reflection template.
