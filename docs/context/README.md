# Project Context System

This directory contains documentation for the context loading system.

## Current Implementation

The context loading system is now integrated into the dev-tools `context` command with native preset support.

## Usage

### Using Presets (Recommended)

```bash
# Load project context using preset
context --preset project

# Load specific submodule context
context --preset dev-tools
context --preset dev-handbook

# List available presets
context --list-presets

# Override output location
context --preset project --output /tmp/my-context.md
```

### Configuration

Presets are configured in `.coding-agent/context.yml` in the dev-tools directory:

```yaml
presets:
  project:
    description: "Main project context"
    source: docs/context/project.yml
    output: docs/context/cached/project.md
    max_lines: 150000
    
  dev-tools:
    description: "Dev-tools submodule context"
    source: docs/context/dev-tools.yml
    output: docs/context/cached/dev-tools.md
    max_lines: 150000
```

## Features

### Automatic Chunking

Large contexts (>150K lines by default) are automatically split into chunks:
- Main file contains an index of chunks
- Each chunk is numbered sequentially
- Chunks are created in the same directory as the output file

### Security

The context tool includes security features:
- Path validation to prevent directory traversal
- Forbidden paths (e.g., .git, node_modules) are blocked
- Allowed paths can be configured per preset

### Usage with YAML Templates

YAML templates are automatically detected:
```bash
# Output to stdout (default)
context template.yml

# Output to file
context template.yml --output output.md
```

## Migration from Old System

The previous `bin/load-context` wrapper script has been replaced with native preset support in the context tool. All functionality is now available through the `context` command with enhanced features:

- ✅ Native preset support
- ✅ Automatic caching
- ✅ Smart chunking for large files
- ✅ Security validation
- ✅ Better error messages
- ✅ Configuration management

## Enhanced Context Tool Examples

The context tool now supports enhanced features with `<context-tool-config>` tagged format:

### Example Files

- **`project.md`** - Main project context with document embedding enabled
- **`dev-tools.md`** - Ruby gem focused context configuration
- **`dev-handbook.md`** - Handbook and workflows context with YAML output
- **`minimal-example.md`** - Simplest possible configuration example

### Usage Patterns

```bash
# Auto-detection with positional arguments
context docs/context/project.md
context .claude/agents/task-finder.ag.md
context template.yml
context 'files: [docs/*.md]'  # Inline YAML

# Preset-based usage
context --preset project
```

### Key Features

- **Auto-format detection** - Automatically detects YAML files (.yml/.yaml), agent files (.ag.md), and markdown files (.md)
- **Tagged YAML blocks** - Use `<context-tool-config>` tags for unambiguous configuration
- **Document embedding** - Set `embed_document_source: true` to embed results back into source document
- **Backward compatibility** - All existing flags and usage patterns continue to work

## See Also

- Context tool implementation: `dev-tools/lib/coding_agent_tools/cli/commands/context.rb`
- Configuration example: `dev-tools/.coding-agent/context.yml`
- Workflow instructions: `dev-handbook/workflow-instructions/load-project-context.wf.md`