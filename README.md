# Coding Agent Workflow Toolkit

A framework for structuring effective AI-driven software development workflows. This toolkit provides a consistent methodology for collaborating with AI coding agents through a documentation-first approach.

## Overview

The Coding Agent Workflow Toolkit addresses the unique challenges of AI-assisted development:
- Maintaining context between sessions
- Converting high-level requirements to actionable tasks
- Processing feedback from multiple sources
- Ensuring consistent quality through structured workflows
- Preserving knowledge and decisions

## Key Components

### 1. Command Structure
Standardized commands in `workflow instructions/` define common workflow patterns:
- **Environment Setup**: `load-env`, `init-project`
- **Task Management**: `lets-start`, `self-reflect`, `review-kanban-board`
- **Implementation**: `lets-tests`, `lets-fix-tests`, `lets-commit`
- **Specification Generation**: `lets-spec-from-pr-comments`, `lets-spec-from-frd`, `lets-spec-from-prd`, `lets-spec-from-diff`
- **Documentation**: Generate commands for ADRs, API docs, release notes, etc.
- **Release Management**: `lets-release`

### 2. Unified Task Management System
A simple file-based system for tracking tasks across their lifecycle:
- `docs-project/backlog/` - Future planned work
- `docs-project/current/` - Active development
- `docs-project/done/` - Completed work

### 3. Guides Collection
Comprehensive guides in `guides/` to standardize development practices:
- Project management workflows
- Coding standards and best practices
- Testing methodology
- Documentation requirements
- Security guidelines
- Performance optimization
- Error handling
- Release management

### 4. Tools Directory
Utility scripts in `tools/` to assist with common tasks:
- GitHub PR data extraction
- Other automation utilities for workflow integration

### 5. Documentation Framework
Templates and structures for:
- Project architecture
- Coding standards
- Testing guidelines
- Release management
- Decision records

## Getting Started

1. Add this repository as a submodule to your project:
   ```bash
   # Add the toolkit as a submodule
   git submodule add git@github.com:cs3b/coding-agent-workflow-toolkit.git docs-dev

   # Create a project-specific documentation submodule (or a new directory)
   git submodule add git@github.com:username/your-project-docs.git docs-project
   # Or: mkdir docs-project
   ```

2. Initialize the project structure:
   - Run your coding agent (Claude, Zed Assistant, Windsurf Cascade, etc.)
   - Enter the instruction: `READ commands/initialize-project-structure.md and follow the instructions inside`

TODO: record screencast and write examples

The toolkit uses itself to manage its own development process through submodules:
- `docs-dev` - Core toolkit files (commands, guides, templates)
- `docs-project` - Project-specific documentation and task management

## Key Philosophy

The toolkit is built around "Slow Vibe Coding" - an approach that emphasizes:
1. Thorough planning before implementation
2. Documentation-driven development
3. Structured feedback loops
4. Clear traceability from requirements to implementation
## How Commands Work with AI Coding Agents

The commands in this toolkit are not executable scripts but rather markdown documents containing structured instructions. They work by:

1. **Providing Context**: You ask your AI coding agent (Claude, Zed Assistant, Windsurf Cascade, etc.) to read the command file
2. **Following Instructions**: The AI interprets the structured guidance and executes the workflow
3. **Maintaining Consistency**: Each command follows a standard format ensuring predictable outcomes

For example, to start a new task:

```
@claude Please read and execute the command in docs-dev/commands/lets-start.md with the task "Implement user login feature"
```

This approach leverages the AI's ability to understand complex instructions while providing a consistent framework that helps maintain context between sessions and standardize workflows across team members.

The command files themselves contain detailed instructions, examples, and guardrails to ensure the AI agent takes appropriate actions at each step of the development process.
