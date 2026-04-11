---
doc-type: workflow
title: Load Bundle Workflow Instruction
purpose: Documentation for ace-bundle/handbook/workflow-instructions/bundle.wf.md
ace-docs:
  last-updated: 2026-03-12
  last-checked: 2026-03-21
---

# Load Bundle Workflow Instruction

## Purpose

Load project context from flexible input sources: preset names, file paths, or protocol URLs.

## Prerequisites

- The `ace-bundle` tool is available (from ace-bundle gem)

## Variables

$input: project

## Instructions

### 1. Prepare Context

Run `ace-bundle` with the provided input. The tool automatically detects the input type:

```bash
ace-bundle $input
```

**Input type detection:**

- **Presets**: Simple names without path separators (e.g., `project`, `base`)
- **Files**: Paths with `/`, `./`, `../`, or file extensions (e.g., `./context.md`, `/absolute/path.yml`)
- **Protocols**: URLs with `://` pattern (e.g., `wfi://workflow-name`, `guide://testing`)

### 2. Select and Load Context

**Available presets are listed above** in `<available_presets>`.

Based on the user's `$input` variable:

1. **Preset names** (simple names like "project", "base"):
   - Verify preset exists in `<available_presets>` embedded above
   - Run: `ace-bundle $input`

2. **File paths** (contains `/`, `./`, extensions):
   - Run directly: `ace-bundle $input`

3. **Protocols** (contains `://`):
   - Run directly: `ace-bundle $input`
   - Note: Workflows with `embed_document_source: true` include their context

**After loading**, read the complete cached context file.

### 3. Prepare Summary

Analyze the loaded context and prepare a concise summary covering:

- Project purpose and objectives
- Technical architecture and design patterns
- Development conventions and standards
- Project structure and organization
- Available tools and workflows

## Usage

**Presets** - Standard project context, team-shared configurations:
> `ace-bundle project`
> "Load default project context"

> `ace-bundle base`
> "Load base preset"

**Files** - Task-specific context, custom one-off requirements:
> `ace-bundle .ace-task/v.0.9.0/context/task-084.md`
> "Load task-specific context file"

> `ace-bundle /path/to/your/project/context.yml`
> "Load context from absolute path"

**Protocols** - Workflow-embedded context, dynamic discovery:
> `ace-bundle wfi://workflow-name`
> "Load context via protocol"

## Error Handling

| Error | Check | Fix |
|-------|-------|-----|
| File not found | Verify path: `ls -la <file-path>` | Check path is correct |
| Preset not found | List presets: `ace-bundle --list` | Verify preset name spelling |
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