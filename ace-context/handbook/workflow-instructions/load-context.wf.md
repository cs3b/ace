---
update:
  update_frequency: on-change
  last-updated: '2025-10-24'
---

# Load Context Workflow Instruction

## Purpose

Load project context from flexible input sources: preset names, file paths, or protocol URLs.

## Prerequisites

- The `ace-context` tool is available (from ace-context gem)

## Variables

$input: project

## Instructions

### 1. Prepare Context

Run `ace-context` with the provided input. The tool automatically detects the input type:

```bash
ace-context $input
```

**Input type detection:**

- **Presets**: Simple names without path separators (e.g., `project`, `base`)
- **Files**: Paths with `/`, `./`, `../`, or file extensions (e.g., `./context.md`, `/absolute/path.yml`)
- **Protocols**: URLs with `://` pattern (e.g., `wfi://workflow-name`, `guide://testing`)

### 2. Read the Generated Context

Read the complete cached context file returned by ace-context:

```bash
# The ace-context tool outputs the cache file path like:
# Context saved (N lines, X KB), output file: /path/to/cache/file.md
```

Read the ENTIRE file to understand the full project context.

### 3. Prepare Summary

Analyze the loaded context and prepare a concise summary covering:

- Project purpose and objectives
- Technical architecture and design patterns
- Development conventions and standards
- Project structure and organization
- Available tools and workflows

## Usage

**Presets** - Standard project context, team-shared configurations:
> `/ace:load-context`
> "Load default project context"

> `/ace:load-context base`
> "Load base preset"

**Files** - Task-specific context, custom one-off requirements:
> `/ace:load-context .ace-taskflow/v.0.9.0/context/task-084.md`
> "Load task-specific context file"

> `/ace:load-context /path/to/your/project/context.yml`
> "Load context from absolute path"

**Protocols** - Workflow-embedded context, dynamic discovery:
> `/ace:load-context wfi://workflow-name`
> "Load context via protocol"

## Error Handling

| Error | Check | Fix |
|-------|-------|-----|
| File not found | Verify path: `ls -la <file-path>` | Check path is correct |
| Preset not found | List presets: `ace-context --list` | Verify preset name spelling |
| Permission denied | Check perms: `ls -la <file-path>` | Fix permissions: `chmod +r <file-path>` |

## Response Template

**Presets Loaded:** [List of input source(s)]
**Preset Stats:** [The size of the context - N lines, X KB]

Read the whole file from: [$contextFilePath]

**Understanding Achieved:** [Summary of project purpose, structure, and conventions]

## Success Criteria

- Context is successfully loaded from the specified input
- Full cached context file has been read completely (not just sampled)
- Clear understanding of project purpose, architecture, and conventions
- Ready to work with project-specific context
