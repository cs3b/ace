# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **Coding Agent Workflow Toolkit (Meta)** repository - a meta-repository that provides documentation and guidance for setting up AI-assisted
development workflow systems. It contains three Git submodules:

* **dev-handbook/**: Standardized development guides, workflow instructions, and templates *(integrated development)*
* **dev-taskflow/**: Unified task management structure for all components *(integrated development)*
* **dev-tools/**: Ruby gem with CLI tools for LLM integration and development automation *(integrated development)*

**Main work focus**: The development work is now integrated across all three submodules as part of a unified meta-project. The **dev-taskflow/** provides
centralized task management for coordinated development across **dev-handbook/** (guides and workflows) and **dev-tools/** (executable tools).

## Agent Recommendations

When working with specific commands, consider using these specialized agents for more efficient execution:

### Task Management
- **`task-finder`** - Use when running `task-manager list`, `task-manager next` to find tasks
- **`task-creator`** - Use when running `task-manager create` to create new tasks
- **`release-navigator`** - Use when running `release-manager current`, `release-manager all`, or `task-manager recent`

### Git Operations
- **`git-all-commit`** - Use for `git-commit` when committing ALL changes
- **`git-files-commit`** - Use for `git-commit` when committing specific files
- **`git-review-commit`** - Use for `git-commit` when you want to review changes before committing

### Development Tools
- **`code-lint-agent`** - Use when running linting or code quality checks
- **`create-path-agent`** - Use when creating new files or directories with `create-path`
- **`feature-research`** - Use when researching new features or analyzing gaps
- **`search`** - Use when searching for code patterns or files across the codebase

To invoke an agent, use: `@agent-name` or the Task tool with `subagent_type: agent-name`
