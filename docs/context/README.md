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

### Using Presets (Recommended)

The context tool now supports preset-based loading through `.coding-agent/context.yml`:

```bash
# List available presets
context --list-presets

# Load a preset (outputs to stdout by default)
context --preset project

# Load preset and save to file
context --preset project --output docs/context/cached/project.md

# Load preset with custom output format
context --preset dev-tools --format xml
```

### Legacy: Loading Context with Templates

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

### Direct Template Loading

For one-off template loading without presets:

```bash
# Load from YAML template
context --yaml docs/context/project.md

# Load from agent context
context --from-agent .claude/agents/task-manager.md

# Load from inline YAML
context --yaml-string "files: [README.md]"
```

### Reading Cached Context

After loading, read the cached context file:

```bash
# The tool will output the path, typically:
cat docs/context/cached/project.md
```

## Configuration

### Preset Configuration (`.coding-agent/context.yml`)

Define reusable presets in your project's `.coding-agent/context.yml` file:

```yaml
presets:
  project:
    description: "Complete project context"
    template: "docs/context/project.md"
    output: "docs/context/cached/project.md"
    chunk_limit: 150000
  
  dev-tools:
    description: "Development tools context"
    template: "docs/context/dev-tools.md"
    output: "docs/context/cached/dev-tools.md"
    chunk_limit: 100000

settings:
  default_chunk_limit: 150000
  cache_directory: "docs/context/cached"
  auto_create_directories: true

security:
  allowed_template_paths:
    - "docs/**"
    - "dev-handbook/**"
  allowed_output_paths:
    - "docs/**"
    - ".coding-agent/**"
  forbidden_patterns:
    - "**/.git/**"
    - "**/.env*"
    - "**/*.key"
```

### Preset Benefits

- **Reusable**: Define once, use everywhere
- **Secure**: Built-in path validation and security constraints
- **Chunking**: Automatic splitting for large contexts
- **Caching**: Smart file writing with directory creation

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

### Preset System

- **Configuration-driven**: Define presets in `.coding-agent/context.yml`
- **Security validation**: Path restrictions prevent access to sensitive files
- **Flexible output**: Save to file or output to stdout
- **Multiple formats**: XML, YAML, or Markdown-XML output

### Automatic Chunking

Large contexts are automatically split into manageable chunks:

- **Configurable limits**: Set chunk_limit per preset (default: 150K lines)
- **Index generation**: Main file contains references to all chunks
- **Sequential naming**: Chunks numbered for easy navigation
- **Metadata inclusion**: Optional chunk headers with line counts

### Smart Caching

- **Atomic writes**: Temporary files prevent corruption
- **Directory creation**: Auto-create output directories
- **Progress reporting**: Real-time feedback during long operations
- **Error handling**: Graceful failure with detailed messages

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
- **Preset Manager**: Handles configuration loading and path resolution
- **Chunking System**: Line-based splitting with configurable limits
- **File Writer**: Atomic operations with progress reporting
- **Security Layer**: Path validation against allowed/forbidden patterns
- **Legacy Support**: `bin/load-context` wrapper script for backward compatibility

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