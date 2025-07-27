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

## Key Commands

### File Navigation (Important!)

**Always use `nav-path file <filename>` instead of `find` or `ls` commands** for locating files:

```bash
# ✅ Preferred - Fast, intelligent, respects project structure
nav-path file blueprint      # Finds docs/blueprint.md
nav-path file tools          # Finds appropriate tools.md
nav-path file config         # Finds .coding-agent/path.yml
nav-path file README         # Finds README files

# ❌ Avoid - Slow, verbose, may find wrong files
find . -name "*blueprint*" -type f
ls -la docs/ | grep blueprint
```

### Development Tools

The project includes 25+ CLI tools for development automation. Key tools include:

* **Task Management**: `task-manager next`, `task-manager recent`
* **Release Management**: `release-manager current`
* **Navigation**: `nav-tree`, `nav-path`, `nav-ls`
* **Git Operations**: `git-status`, `git-commit`, `git-push`, `git-pull` (operate on all 4 repositories)
* **LLM Integration**: `llm-query`, `llm-models`

For complete tool documentation, see [Tools Reference](docs/tools.md).

### Template Synchronization

```bash
# Synchronize embedded templates in workflow instructions
handbook sync-templates

# Preview changes without applying them
handbook sync-templates --dry-run

# Detailed output with verbose logging
handbook sync-templates --verbose

# Synchronize and automatically commit changes
handbook sync-templates --verbose --commit
```

### LLM Integration

Multiple LLM providers are supported through unified commands. See [Tools Reference](docs/tools.md) for complete usage documentation.

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

* Each submodule is a separate Git repository with its own development lifecycle
* Use `git submodule update --init --recursive` to initialize all submodules
* Submodule commits must be made from within the submodule directory

### Key Directories

* **bin/**: Project automation scripts and Git shortcuts
* **docs/**: High-level architecture and blueprint documentation
* **dev-handbook/**: Development guides and AI workflow instructions (submodule)
* **dev-taskflow/**: Task management with backlog/, current/, done/ structure (submodule)
* **dev-tools/**: Ruby gem with CLI tools for LLM integration (submodule)

## Development Workflow

### Task Management

Tasks are organized in the dev-taskflow/ submodule:

* `dev-taskflow/backlog/`: Future tasks by release
* `dev-taskflow/current/`: Active release tasks
* `dev-taskflow/done/`: Completed releases

Use `bin/tn` to find the next actionable task and `bin/tr` for recent task activity.

### Documentation Standards

* All Markdown files are linted with markdownlint
* Custom Ruby scripts check for broken links and task metadata
* Configuration in .markdownlint.json

### Git Submodules

This project uses 3 Git submodules plus the root repository (4 total repositories):

* **Root repository**: Main meta-repository
* **dev-handbook/**: Development guides and workflows
* **dev-taskflow/**: Task management structure
* **dev-tools/**: Ruby gem utilities

**Multi-repo operations**: All git shortcuts (bin/gs, bin/gl, bin/gc, bin/gp, bin/gpull) operate across all 4 repositories automatically.

**Intention-based commits**: Use `bin/gc -i "your intention"` to commit changes across multiple repos with contextually appropriate messages for each repository
based on the same intention.

## Important Notes

* This is primarily a **documentation project** - the main build step is a placeholder
* **Primary work areas**: dev-handbook/ (guides/workflows) and dev-taskflow/ (task management)
* **dev-tools/ submodule**: Used for utilities but generally not modified
* AI workflow instructions are in **dev-handbook/workflow-instructions/**
* Always run `bin/lint` before committing to ensure documentation quality
* When working in dev-tools/, use the ATOM architecture pattern (Atoms/Molecules/Organisms/Ecosystems)