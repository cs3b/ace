# Project Context System

This directory contains the standardized context loading system for the Coding Agent Workflow Toolkit.

## Purpose

The context system provides a unified way to load and cache project documentation and runtime information for AI agents and developers. It ensures consistent access to essential project information while managing file size constraints for tools like Claude Code.

## Structure

```
docs/context/
├── README.md           # This file
├── project.md          # Main project context definition
├── dev-tools.md        # Dev-tools submodule context definition
├── dev-handbook.md     # Dev-handbook submodule context definition
└── cached/             # Generated context cache (gitignored)
    ├── project.md      # Cached project context
    ├── dev-tools.md    # Cached dev-tools context
    └── dev-handbook.md # Cached dev-handbook context
```

## Usage

### Loading Context

Use the `load-context` script to process context definitions:

```bash
# Load the main project context
bin/load-context project

# Load specific submodule contexts
bin/load-context dev-tools
bin/load-context dev-handbook

# Get help
bin/load-context --help
```

### Reading Cached Context

After loading, read the cached context file:

```bash
# The tool will output the path, typically:
cat docs/context/cached/project.md
```

## Context Definition Format

Context definitions are YAML files with markdown headers that specify:

- **files**: List of files to include (supports glob patterns)
- **commands**: Shell commands to run for dynamic information
- **format**: Output format (xml, yaml, or markdown-xml)

Example structure:

```yaml
---
files:
  - docs/what-do-we-build.md
  - docs/architecture.md
  - README.md

commands:
  - cmd: git-status
    label: "Current Git Status"
  - cmd: nav-tree --depth 2
    label: "Project Structure"

format: markdown-xml
```

## Features

### Automatic Chunking

Large contexts (>150K lines) are automatically split into chunks for tools with file size limitations:

- Main file contains chunk references
- Each chunk is under 150K lines
- Chunks are numbered sequentially

### Caching

- Contexts are cached in `docs/context/cached/`
- Cache directory is gitignored
- Caches are overwritten on each run (no incremental updates)

### Multi-Repository Support

For monorepo projects, create separate context definitions for each component:

- `project.md` - Overall project context
- `dev-tools.md` - Tools submodule specific
- `dev-handbook.md` - Handbook submodule specific
- Add more as needed for other components

## Integration with Workflows

The context system is integrated with AI workflow instructions:

1. **Load Project Context Workflow** (`dev-handbook/workflow-instructions/load-project-context.wf.md`)
   - Uses this system as the standard way to load project context
   - Supports both single project and monorepo scenarios

2. **AI Agents**
   - Can run `bin/load-context` to get fresh context
   - Read cached files for efficient access

3. **Claude Code**
   - Optimized for Claude Code's ~200K token context window
   - Automatic chunking prevents file size issues

## Adding New Contexts

To add a new context definition:

1. Create a new `.md` file in `docs/context/`
2. Add YAML front matter with files and commands
3. Test with `bin/load-context [name]`
4. Document in this README

## Implementation Details

- **Context Tool**: Uses the `context` executable from dev-tools
- **Wrapper Script**: `bin/load-context` provides caching and chunking
- **File Limits**: Chunks at 150K lines for safety with Claude Code
- **Format**: Default is markdown-xml for best AI agent compatibility

## Troubleshooting

### Context Not Loading

- Check YAML syntax in definition file
- Ensure all referenced files exist
- Verify commands are available in PATH

### Cache Not Updating

- Caches are overwritten on each run
- Check write permissions on `docs/context/cached/`
- Verify .gitignore includes the cache directory

### File Too Large

- Automatic chunking handles large contexts
- Check for chunk files: `cached/{name}_chunk*.md`
- Main file will list all chunks