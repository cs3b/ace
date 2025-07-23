# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **Coding Agent Workflow Toolkit (Meta)** repository - a meta-repository that provides documentation and guidance for setting up AI-assisted development workflow systems. It contains three Git submodules:

- **dev-handbook/**: Standardized development guides, workflow instructions, and templates *(primary focus)*
- **dev-taskflow/**: Project-specific documentation and task management structure *(primary focus)*
- **dev-tools/**: Ruby gem with CLI tools for LLM integration and development automation *(used as-is)*

**Main work focus**: The primary development work happens in the **dev-handbook/** submodule (creating guides and workflows) with task management organized in **dev-taskflow/**. The **dev-tools/** submodule provides utilities and is generally not modified.

## Key Commands

### Testing and Quality

```bash
# Run all tests (executes bin/lint for this project)
bin/test

# Run linting (markdownlint + custom Ruby scripts)
bin/lint

# Build project (placeholder - this is a documentation project)
bin/build
```

### Development Scripts

```bash
# Get next task to work on
dev-tools/exe/task-manager next

# List recent tasks
dev-tools/exe/task-manager recent

# Get current release context
dev-tools/exe/release-manager current

# View project tree structure
dev-tools/exe/nav-tree

# Git shortcuts (operate on all 4 repositories: root + 3 submodules)
dev-tools/exe/git-status     # git status across all repos
dev-tools/exe/git-log        # git log across all repos
dev-tools/exe/git-commit --intention "intention"  # git commit with intention-based messages for each repo
dev-tools/exe/git-push       # git push across all repos
dev-tools/exe/git-pull       # git pull across all repos
```

### Template Synchronization

```bash
# Synchronize embedded templates in workflow instructions
bin/markdown-sync-embedded-documents

# Preview changes without applying them
bin/markdown-sync-embedded-documents --dry-run

# Detailed output with verbose logging
bin/markdown-sync-embedded-documents --verbose

# Synchronize and automatically commit changes
bin/markdown-sync-embedded-documents --verbose --commit
```

### LLM Integration (via dev-tools submodule)

```bash
# Query LLM providers
dev-tools/exe/llm-query google:gemini-2.5-flash "prompt"
dev-tools/exe/llm-query anthropic:claude-4-0-sonnet-latest "prompt"

# List available models
dev-tools/exe/llm-models google

# Generate usage reports
dev-tools/exe/llm-usage-report
```

### Node.js Dependencies

```bash
# Install dependencies (for markdownlint)
npm install

# Run markdownlint directly
npx markdownlint-cli '**/*.md' --config .markdownlint.json
```

## Architecture

This is a **meta-repository** using Git submodules to organize different aspects of the workflow toolkit:

### Submodule Structure

- Each submodule is a separate Git repository with its own development lifecycle
- Use `git submodule update --init --recursive` to initialize all submodules
- Submodule commits must be made from within the submodule directory

### Key Directories

- **bin/**: Project automation scripts and Git shortcuts
- **docs/**: High-level architecture and blueprint documentation
- **dev-handbook/**: Development guides and AI workflow instructions (submodule)
- **dev-taskflow/**: Task management with backlog/, current/, done/ structure (submodule)
- **dev-tools/**: Ruby gem with CLI tools for LLM integration (submodule)

## Development Workflow

### Task Management

Tasks are organized in the dev-taskflow/ submodule:

- `dev-taskflow/backlog/`: Future tasks by release
- `dev-taskflow/current/`: Active release tasks
- `dev-taskflow/done/`: Completed releases

Use `bin/tn` to find the next actionable task and `bin/tr` for recent task activity.

### Documentation Standards

- All Markdown files are linted with markdownlint
- Custom Ruby scripts check for broken links and task metadata
- Configuration in .markdownlint.json

### Git Submodules

This project uses 3 Git submodules plus the root repository (4 total repositories):

- **Root repository**: Main meta-repository
- **dev-handbook/**: Development guides and workflows
- **dev-taskflow/**: Task management structure  
- **dev-tools/**: Ruby gem utilities

**Multi-repo operations**: All git shortcuts (bin/gs, bin/gl, bin/gc, bin/gp, bin/gpull) operate across all 4 repositories automatically.

**Intention-based commits**: Use `bin/gc -i "your intention"` to commit changes across multiple repos with contextually appropriate messages for each repository based on the same intention.

## Important Notes

- This is primarily a **documentation project** - the main build step is a placeholder
- **Primary work areas**: dev-handbook/ (guides/workflows) and dev-taskflow/ (task management)
- **dev-tools/ submodule**: Used for utilities but generally not modified
- AI workflow instructions are in **dev-handbook/workflow-instructions/**
- Always run `bin/lint` before committing to ensure documentation quality
- When working in dev-tools/ (rare), use the ATOM architecture pattern (Atoms/Molecules/Organisms/Ecosystems)
