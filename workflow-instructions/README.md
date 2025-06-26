# Workflow Instructions

[← Back to docs-dev root](../README.md) ▸ Workflow Instructions

This directory contains detailed, step-by-step instructions designed to be followed by an AI agent (often guided by a
user) to perform common development and project management tasks.

## Core Workflow

- [Load Environment](./load-env.wf.md): Load project context, guides, and task information.
- [Review Task](./review-task.wf.md): Review and analyze a task before implementation.
- [Work on Task](./work-on-task.wf.md): Select and understand a task before implementation (includes TDD cycle).
- [Commit](./commit.wf.md): Create well-structured Git commits.

## Project Initialization & Setup

- [Initialize Project Structure](./initialize-project-structure.wf.md): Initialize `docs-dev` and `dev-taskflow` structures.
- [Update Blueprint](./update-blueprint.wf.md): Update the `docs/blueprint.md` project overview.

## Draft Releases

- [Draft Release](./draft-release.wf.md): Prepare content, documentation, and perform pre-flight checks for a
  release.

### Creating Tasks

- [Breakdown Notes into Tasks](./breakdown-notes-into-tasks.wf.md): Orchestrates processing of various inputs into
  structured notes for task creation.
  - [From Concepts in Backlog](./breakdown-notes-into-tasks/from-concepts-in-backlog.md)
  - [From Diff](./breakdown-notes-into-tasks/from-diff.md)
  - [From FRD](./breakdown-notes-into-tasks/from-frd.md)
  - [From PR Comments (API)](./breakdown-notes-into-tasks/from-pr-comments-api.md)
  - [From PR Comments (MCP)](./breakdown-notes-into-tasks/from-pr-comments-mcp.md)
  - [From PRD](./breakdown-notes-into-tasks/from-prd.md)
  - [From Release Backlog](./breakdown-notes-into-tasks/from-release-backlog.md)

## Documentation Generation

- [Create ADR](./create-adr.wf.md)
- [Create API Docs](./create-api-docs.wf.md)
- [Create Release Overview](./create-release-overview.wf.md)
- [Create Retrospective Document](./create-retrospective-document.wf.md)
- [Create Review Checklist](./create-review-checklist.wf.md)
- [Create Test Cases](./create-test-cases.wf.md)
- [Create User Docs](./create-user-docs.wf.md)

## Testing

- [Fix Tests](./fix-tests.wf.md): Debug and fix failing tests.

## Project Management & Reflection

- [Update Roadmap](./update-roadmap.wf.md): Update project roadmap and task priorities.
- [Review Tasks Board Status](./review-tasks-board-status.wf.md): Review current task statuses, dependencies, and
  priorities on the board.
- [Log Compact Session](./log-compact-session.wf.md): Log a compact summary of the current session for context
  saving/reloading.
- [Create Reflection Note](./create-reflection-note.wf.md): Capture individual observations and learnings using the
  standard reflection template.

## Publish Release

- [Publish Release](./publish-release.wf.md): Execute the release process (versioning, tagging, building, publishing).
