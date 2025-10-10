# context - Project Context Loading Tool

## Overview

The `context` tool loads and assembles project documentation, files, and command outputs into a unified context document. It's designed to help AI assistants and developers quickly understand project structure and state.

## Basic Usage

```bash
# Load project context using preset
context --preset project

# Load from a YAML template
context template.yml

# Load from a markdown file with embedded config
context docs/context/project.md

# Output to file instead of stdout
context --preset project --output /tmp/context.md

# List available presets
context --list-presets
```

## Configuration Methods

### 1. Presets (Recommended)

Presets are configured in `.coding-agent/context.yml`:

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

### 2. YAML Templates

Create a `.yml` or `.yaml` file:

```yaml
files:
  - path: README.md
  - path: docs/architecture.md
    max_lines: 100
  - pattern: "lib/**/*.rb"
    max_files: 5

commands:
  - cmd: "git status --short"
  - cmd: "bundle exec rspec --version"

format: markdown-xml  # or 'markdown' or 'yaml'
max_total_lines: 50000
```

### 3. Markdown with Embedded Config

Use `<context-tool-config>` tags in markdown files:

```markdown
# Project Context

This document loads the project context.

<context-tool-config>
files:
  - README.md
  - docs/what-do-we-build.md
  - docs/architecture.md
  - docs/blueprint.md

commands:
  - cmd: "git-status --short"
  - cmd: "task-manager recent --limit 5"

format: markdown-xml
embed_document_source: true
</context-tool-config>
```

## Features

### Auto-Detection

The tool automatically detects input format:
- `.yml`/`.yaml` files → YAML template
- `.ag.md` files → Agent file with config
- `.md` files → Markdown with potential embedded config
- Inline YAML strings → Direct YAML parsing

### Automatic Chunking

Large contexts are automatically split:
- Default limit: 150,000 lines per file
- Creates numbered chunks: `output_chunk1.md`, `output_chunk2.md`
- Main file contains an index of all chunks

### Security Features

- **Path Validation**: Prevents directory traversal attacks
- **Forbidden Paths**: Blocks `.git`, `node_modules`, etc.
- **Allowed Paths**: Can be restricted per preset
- **Safe Command Execution**: Commands run with restricted permissions

### Output Formats

- **markdown-xml** (default): XML-wrapped content blocks
- **markdown**: Plain markdown with headers
- **yaml**: YAML structure with metadata

## Examples

### Minimal Example

```yaml
# minimal.yml
files:
  - README.md
format: markdown-xml
```

```bash
context minimal.yml
```

### Project Context Example

```markdown
# project-context.md

<context-tool-config>
files:
  - path: README.md
  - path: docs/what-do-we-build.md
  - path: docs/architecture.md
  - path: docs/decisions.md
  - path: docs/blueprint.md
  - pattern: "lib/**/*.rb"
    max_files: 10
    max_lines: 500

commands:
  - cmd: "git-status --short"
  - cmd: "task-manager recent --limit 5"
  - cmd: "release-manager current"

format: markdown-xml
embed_document_source: true
max_total_lines: 150000
</context-tool-config>
```

### Multiple Presets

```bash
# Load and combine multiple contexts
context --preset project --preset dev-tools --output combined.md

# Load preset with additional files
context --preset project --input extra-file.md
```

## Advanced Options

### Command Line Flags

```bash
--preset NAME           # Use a configured preset
--output PATH          # Output to file (default: stdout)
--format FORMAT        # Override format (markdown-xml, markdown, yaml)
--max-lines N          # Maximum lines per file
--list-presets         # Show available presets
--input FILE           # Additional input files
--embed-source         # Embed result in source document
```

### Configuration Options

```yaml
# Complete configuration example
files:
  - path: "exact/file.md"
  - pattern: "**/*.rb"
    max_files: 20
    max_lines: 1000
    
commands:
  - cmd: "command to run"
    label: "Optional label"
    
format: markdown-xml
max_total_lines: 200000
embed_document_source: false
allowed_paths:
  - /path/to/allow
forbidden_paths:
  - /path/to/forbid
```

## Integration

### With Claude Code

The context tool integrates with Claude Code through the `/load-context` command:

1. User types `/load-context`
2. Command maps to workflow instruction  
3. Workflow executes `context --preset project --output stdout`
4. Claude receives pre-structured context

### In Workflows

```bash
# In a workflow script
context --preset project > /tmp/project-context.md

# Check if context is up to date
if [ docs/context/cached/project.md -ot README.md ]; then
  context --preset project
fi
```

## Troubleshooting

### Common Issues

1. **File too large**: Adjust `max_lines` or `max_total_lines`
2. **Permission denied**: Check file permissions and allowed_paths
3. **Command not found**: Ensure commands are in PATH
4. **YAML parse error**: Validate YAML syntax

### Debug Mode

```bash
# Enable verbose output
DEBUG=1 context --preset project

# Check configuration
context --preset project --dry-run
```

## See Also

- Configuration file: `.coding-agent/context.yml`
- Source code: `lib/coding_agent_tools/cli/commands/context.rb`
- Workflow: `dev-handbook/workflow-instructions/load-project-context.wf.md`