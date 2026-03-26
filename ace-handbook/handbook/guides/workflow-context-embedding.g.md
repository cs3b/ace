---
doc-type: guide
title: Workflow Context Embedding Guide
purpose: Documentation for ace-handbook/handbook/guides/workflow-context-embedding.g.md
ace-docs:
  last-updated: 2026-03-12
  last-checked: 2026-03-21
---

# Workflow Context Embedding Guide

This guide explains how to use `ace-bundle`'s `embed_document_source: true` feature to embed dynamic context directly into workflow instructions, reducing redundant command execution and improving agent efficiency.

## Goal

Define clear patterns for:

- When to use `embed_document_source: true` in workflow frontmatter
- How to write instructions that leverage embedded context
- Section naming conventions for embedded context
- Best practices for context embedding vs. manual gathering

## Background

**PR #120** introduced `ace-bundle wfi://protocol` which loads workflow instructions AND any embedded context in one operation. When an agent invokes `/ace:command`, they get:

1. The workflow instructions
2. Any embedded context (from commands, files, or protocols)
3. All in a single context load

This transforms workflows from "instructions that tell agents to gather context" into "instructions that come with context already included."

## Core Principles

1. **Context Already Available**: When context is embedded, agents don't need to run commands to gather it
2. **Explicit References**: Instructions should explicitly reference embedded sections
3. **No Redundancy**: Don't tell agents to run commands when context is already embedded
4. **Semantic Naming**: Use descriptive section names that indicate content type

## When to Use `embed_document_source: true`

### Good Use Cases

1. **Dynamic command output needed for workflow execution**
   - Current git state (status, diff)
   - Task or issue lists
   - Configuration validation

2. **Reference data for validation/selection**
   - Available presets, tasks, workflows
   - Configuration options
   - Environment status

3. **Workflow composition via protocols**
   - Including other workflows
   - Cross-referencing related instructions

### When NOT to Use

- Self-contained workflow instructions
- User-provided context (not discoverable)
- Static content that doesn't change
- Performance-sensitive paths (commands add overhead)

## Frontmatter Configuration

### Structure

```yaml
---
bundle:
  embed_document_source: true
  sections:
    section_name:
      commands:
        - command arg1
        - command arg2
      files:
        - path/to/file
      protocols:
        - wfi://workflow-name
---
```

### Example

```yaml
---
bundle:
  embed_document_source: true
  sections:
    current_repository_status:
      commands:
        - git status -sb
        - git diff --stat
    available_presets:
      commands:
        - ace-bundle --list
---
```

## Instruction Writing Patterns

### Pattern A: "Context Already Available"

**Before (manual gathering):**

```markdown
1. Get the current repository status:
   ```bash

   git status -sb
   git diff --stat

   ```

2. Review the changes
```

**After (embedded context):**

```markdown
1. **Repository status is embedded above** in `<current_repository_status>`.

   The current git state (status + diff summary) is already loaded in this workflow.
   Review it to understand what will be committed:
   - Which files are modified? (from status output)
   - How significant are the changes? (from diff --stat)

   No need to run git commands - the context is already provided.
```

### Pattern B: "Interactive Selection"

**Before:**

```markdown
1. List available presets:
   ```bash

   ace-bundle --list

   ```

2. Ask user which one to load
```

**After:**

```markdown
1. **Available presets are listed above** in `<available_presets>`.

   Based on the user's `$input` variable:
   - **Preset names** (simple names like "project", "base"):
     - Verify preset exists in `<available_presets>` embedded above
     - Run: `ace-bundle $input`
   - **File paths**: Run directly with `ace-bundle $input`
   - **Protocols**: Run directly with `ace-bundle $input`
```

### Pattern C: "Validation"

**Before:**

```markdown
1. Check if task exists:
   ```bash

   ace-task $task_ref

   ```

2. If error, report to user
```

**After:**

```markdown
1. **Verify task reference** against user input:
   - If `$task_ref` provided: use it directly
   - If not specified: check `<available_tasks>` embedded above
   - Present task options from embedded list if needed
```

## Section Naming Conventions

Use descriptive, semantic section names:

| Section Type | Example Names | When to Use |
|--------------|---------------|-------------|
| Current State | `current_repository_status`, `current_branch_state` | Git/status info, live state |
| Available Options | `available_presets`, `available_tasks`, `available_workflows` | Lists for selection |
| Reference Data | `recent_commits`, `project_structure` | Historical/structural info |
| Configuration | `tool_config`, `workflow_config` | Settings/state |

## Embedded Context Reference Pattern

When instructions reference embedded XML, use explicit markers:

```markdown
## Context Available

This workflow includes pre-loaded context:

- `<current_repository_status>`: Git status and diff summary
- `<available_presets>`: List of available context presets

Use these embedded sections instead of running commands to gather this information.
```

## Examples from Production

### commit.wf.md (ace-git-commit)

**Frontmatter:**

```yaml
bundle:
  embed_document_source: true
  sections:
    current_repository_status:
      commands:
        - git status -sb
        - git diff --stat
```

**Instructions:**

```markdown
1. **Repository status is embedded above** in `<current_repository_status>`.

   The current git state (status + diff summary) is already loaded in this workflow.
   Review it to understand what will be committed:
   - Which files are modified? (from status output)
   - How significant are the changes? (from diff --stat)
   - Is this the right scope for a single commit?

   No need to run git commands - the context is already provided.
```

### load-context.wf.md (ace-bundle)

**Frontmatter:**

```yaml
bundle:
  embed_document_source: true
  sections:
    available_presets:
      commands:
        - ace-bundle --list
```

**Instructions:**

```markdown
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
```

## Migration Checklist

When updating a workflow to use embedded context:

- [ ] Add `context: embed_document_source: true` to frontmatter
- [ ] Define `sections:` with appropriate commands/files/protocols
- [ ] Update instructions to reference embedded sections explicitly
- [ ] Remove redundant "run this command" steps
- [ ] Test workflow invocation with `/ace:command`
- [ ] Verify embedded context appears in output
- [ ] Confirm agent uses embedded context (no redundant commands)

## Future Considerations

- **Additional patterns**: As more workflows adopt this, new patterns may emerge
- **Tooling**: Potential for automated detection of missing embedded context references
- **Performance optimizations**: Cache warming for frequently accessed embedded context, lazy loading for large sections

## Related Documents

- **PR #120**: Historical migration that replaced `ace-nav wfi://` execution examples with `ace-bundle wfi://`
- **Task 152**: ace-bundle auto-format output by line count
- **documents-embedding.g.md**: Template and guide embedding standards
- **CLAUDE.md**: Agent guidance for workflow usage

---

*Last updated: 2026-01-03*
