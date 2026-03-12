# Claude Command Metadata Field Reference

This document describes the metadata fields available in Claude command YAML front-matter.

## Overview

Claude commands use YAML front-matter to provide metadata that helps Claude Code understand how to execute commands. All fields are optional, and the system will use sensible defaults when fields are omitted.

## Field Reference

### `description`
**Type:** String  
**Purpose:** Short help text shown in Claude Code's /help output  
**Example:** `description: Capture and document a new idea as a task`

This field provides a human-readable description of what the command does. It should be concise (typically 5-10 words) and clearly explain the command's purpose.

### `allowed-tools`
**Type:** String (comma-separated list)  
**Purpose:** Restricts which tools the command can use (security feature)  
**Format:** `Tool, Tool2, Tool3`  
**Example:** `allowed-tools: Bash, Read, Write`

This field limits which tools Claude can use when executing the command. It's a security feature that prevents commands from performing unintended operations. Common tools:
- `Bash` - Allow bash commands
- `Read, Write` - Allow file reading and writing
- `Edit` - Allow file editing
- `TodoWrite` - Allow task list management
- `Grep, Glob` - Allow file searching
- `WebSearch, WebFetch` - Allow web operations

### `argument-hint`
**Type:** String  
**Purpose:** Shown in autocomplete, helps users understand expected arguments  
**Format:** `"[argument-name]"` or `"[arg1] [arg2]"`  
**Example:** `argument-hint: "[task-id]"`

This field provides hints about what arguments the command expects. The square brackets indicate placeholder names that help users understand what to provide.

### `model`
**Type:** String (model identifier)  
**Purpose:** Forces specific model for this command  
**Default:** User's selected model  
**Example:** `model: claude-sonnet-4-20250514`

This field allows commands to request a specific Claude model.

### `skill`
**Type:** Mapping (ACE canonical extension)  
**Purpose:** Declares typed skill taxonomy and workflow binding  
**Example:**

```yaml
skill:
  kind: workflow
  execution:
    workflow: wfi://task/plan
```

Canonical rules:
- `skill.kind` is required for canonical `SKILL.md` and must be one of: `capability`, `workflow`, `orchestration`
- `skill.execution.workflow` is required and must be a `wfi://...` reference
- Unknown keys under `skill` or `skill.execution` should be rejected by schema-aware validators
- Canonical skills are authored in package `handbook/skills` paths and projected directly into provider trees (for example `.claude/skills` and `.codex/skills`)

### `assign`
**Type:** Mapping (ACE canonical extension, optional)  
**Purpose:** Assignment-aware metadata for workflow/orchestration skills  
**Example:**

```yaml
assign:
  source: wfi://task/work
```

Canonical rules:
- Optional field
- Valid only when `skill.kind` is `workflow` or `orchestration`
- `capability` skills must not define `assign`

**Available Models by Family:**

**Opus Models (Complex Analysis):**
- `claude-opus-4-1-20250805` - Claude Opus 4.1 (latest, most capable)
- `claude-opus-4-20250514` - Claude Opus 4

**Sonnet Models (Balanced Performance):**
- `claude-sonnet-4-20250514` - Claude Sonnet 4 (latest)
- `claude-3-7-sonnet-20250219` - Claude Sonnet 3.7
- `claude-3-5-sonnet-20241022` - Claude Sonnet 3.5 (New)
- `claude-3-5-sonnet-20240620` - Claude Sonnet 3.5 (Old)

**Haiku Models (Fast Operations):**
- `claude-3-5-haiku-20241022` - Claude Haiku 3.5 (latest)
- `claude-3-haiku-20240307` - Claude Haiku 3

**Recommended Usage:**
- Complex analysis/synthesis: `claude-opus-4-1-20250805`
- Quick iterations and fixes: `claude-sonnet-4-20250514`
- Simple, fast operations: `claude-3-5-haiku-20241022`

## Metadata Inference Rules

The Claude command generator automatically infers metadata based on workflow names:

### Descriptions
- Converts kebab-case to title case: `capture-idea` → `Capture Idea`
- Handles common abbreviations: `API`, `ADR`

### Allowed Tools by Workflow Type

| Workflow Pattern | Allowed Tools |
|------------------|---------------|
| `git-*`, `*commit*`, `*rebase*`, `*merge*` | `Bash, Read, Write` |
| `*-task` (draft, plan, work-on, review, complete) | `Read, Write, TodoWrite, Bash` |
| `create-adr`, `create-*-docs`, `create-reflection-note` | `Read, Write, Grep, Glob` |
| `create-test-cases` | `Read, Write, Bash, Grep` |
| `test-*`, `validate-*` | `Bash, Read, Grep` |
| `fix-tests`, `fix-linting-*` | `Read, Write, Edit, Bash, Grep` |
| `*research*`, `*analyze*` | `Read, Grep, Glob, WebSearch` |
| `synthesize-reflection-notes` | `Read, Write, Grep, TodoWrite` |
| `load-project-context` | `Read, LS` |
| `*release*` | `Read, Write, Bash, Grep` |
| `update-blueprint` | `Read, Write, Edit, Grep` |
| `capture-idea` | `Write, TodoWrite` |
| Default (unmatched) | `Read, Write, Edit, Grep` |

### Argument Hints by Workflow

| Workflow Pattern | Argument Hint |
|------------------|---------------|
| `*-task` (work-on, review, plan, complete) | `[task-id]` |
| `rebase-against`, `merge-from` | `[branch-name]` |
| `fix-linting-issue-from` | `[linter-output-file]` |
| `*release*` | `[version]` |
| `capture-idea` | `[idea-description]` |
| `create-adr` | `[decision-title]` |

### Model Selection

| Workflow Pattern | Preferred Model | Reason |
|------------------|-----------------|---------|
| `*analyze*`, `*synthesize*`, `*research*` | `opus` | Complex cognitive tasks |
| `fix-tests`, `fix-linting*` | `sonnet` | Fast iteration for fixes |

## Example Generated Command

```markdown
---
description: Capture and document a new idea
allowed-tools: Write, TodoWrite
argument-hint: "[idea-description]"
---

read whole file and follow @dev-handbook/workflow-instructions/capture-idea.wf.md

read and run @.claude/skills/commit.md
```

## Best Practices

1. **Minimal Permissions**: Only grant the tools necessary for the workflow
2. **Clear Descriptions**: Keep descriptions concise and action-oriented
3. **Helpful Hints**: Make argument hints descriptive enough to guide users
4. **Model Selection**: Only specify model when the default would be insufficient
5. **Security First**: When in doubt, be more restrictive with allowed-tools

## Validation

All generated YAML front-matter is validated to ensure:
- Valid YAML syntax
- No empty or malformed fields
- Proper escaping of special characters
- Consistent formatting

Commands with invalid YAML will generate a warning during creation but will still be created to avoid blocking workflows.
