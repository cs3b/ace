# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **Coding Agent Workflow Toolkit (Meta)** repository - a meta-repository that provides documentation and guidance for setting up AI-assisted
development workflow systems. It contains three Git submodules:

* **dev-handbook/**: Standardized development guides, workflow instructions, and templates *(integrated development)*
* **dev-taskflow/**: Unified task management structure for all components *(integrated development)*
* **dev-tools/**: CLI tools submodule for LLM integration and development automation *(integrated development)*

**Main work focus**: The development work is now integrated across all three submodules as part of a unified meta-project. The **dev-taskflow/** provides
centralized task management for coordinated development across **dev-handbook/** (guides and workflows) and **dev-tools/** (executable tools).

## Agent Recommendations

When working with specific tasks, use these specialized agents for focused, efficient execution. All agents follow single-purpose design and standardized response formats.

### Task Management
- **`task-finder`** - FIND tasks only - list, filter, discover next actionable tasks
- **`task-creator`** - CREATE tasks only - generate task files with content and metadata
- **`release-navigator`** - NAVIGATE releases - discover current/all releases, track recent activity

### Git Operations  
- **`git-all-commit`** - COMMIT ALL changes - fast execution without file selection
- **`git-files-commit`** - COMMIT SPECIFIC files - requires file list
- **`git-review-commit`** - REVIEW then COMMIT - analyze changes before committing

### Development Tools
- **`lint-files`** - LINT and FIX code quality - supports ruby, markdown, all types with autofix
- **`create-path`** - CREATE files/directories - supports templates (NOT for tasks)
- **`feature-research`** - RESEARCH gaps and missing features - outputs .fr.md reports
- **`search`** - SEARCH code patterns and files - intelligent filtering across codebase

### Agent Invocation
- **Direct**: `@agent-name` or use the Task tool with `subagent_type: agent-name`
- **With params**: Agents accept expected_params documented in their definitions
- **Composition**: Agents delegate to each other for complex workflows

### Agent Management
- **Location**: All agents in `dev-handbook/.integrations/claude/agents/*.ag.md`
- **Symlinks**: `.claude/agents/` contains symlinks to originals
- **Workflow**: Use `@manage-agents` workflow for creating/updating agents
