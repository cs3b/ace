# Replace ace-nav wfi:// with ace-context wfi:// Usage

## Overview

This task standardizes how Claude Code commands and workflows load context by replacing `ace-nav wfi://` with `ace-context wfi://` across the codebase.

## Current vs New Pattern

### Current Pattern (ace-nav)

```markdown
# In .claude/commands/*.md
read and run `ace-nav wfi://workflow-name`

# In workflow instructions
Read and follow: `ace-nav wfi://load-project-context`
```

**Behavior**: Returns file path, agent must then read the file.

### New Pattern (ace-context)

```markdown
# In .claude/commands/*.md
read and run `ace-context wfi://workflow-name`

# In workflow instructions
Read and follow: `ace-context wfi://load-project-context`
```

**Behavior**:
- Small workflows (< 500 lines): Returns content directly
- Large workflows (>= 500 lines): Returns file path (with auto-format from task 152)

## Usage Scenarios

### Scenario 1: Claude Command Loading Workflow

**Before:**
```markdown
# .claude/commands/ace/commit.md
---
description: Commit Changes
---
read and run `ace-nav wfi://commit`
```

**After:**
```markdown
# .claude/commands/ace/commit.md
---
description: Commit Changes
---
read and run `ace-context wfi://commit`
```

### Scenario 2: Workflow Cross-Reference

**Before:**
```markdown
# work-on-task.wf.md
## Project Context Loading
- Read and follow: `ace-nav wfi://load-project-context`

## When task is orchestrator
Read and execute: ace-nav wfi://work-on-subtasks
```

**After:**
```markdown
# work-on-task.wf.md
## Project Context Loading
- Read and follow: `ace-context wfi://load-project-context`

## When task is orchestrator
Read and execute: ace-context wfi://work-on-subtasks
```

### Scenario 3: Documentation Examples

**Before:**
```markdown
# CLAUDE.md
- `ace-nav wfi://workflow-name` - Navigate to workflow
```

**After:**
```markdown
# CLAUDE.md
- `ace-context wfi://workflow-name` - Load workflow content
```

## Command Reference

| Command | Returns | Use Case |
|---------|---------|----------|
| `ace-nav wfi://name` | File path | When you need the path |
| `ace-context wfi://name` | Content or path | When you need the content |

## Files Affected

### Claude Commands (~36 files)
- `.claude/commands/ace/*.md`
- `.claude/commands/ace-*.md`

### Workflow Instructions (~30 files)
- `ace-taskflow/handbook/workflow-instructions/*.wf.md`
- `ace-docs/handbook/workflow-instructions/*.wf.md`
- `.ace/handbook/workflow-instructions/*.wf.md`

### Documentation (~8 files)
- `CLAUDE.md`
- `README.md`
- `docs/tools.md`
- `docs/architecture.md`
- `docs/command-reference.md`
- Template files

## Transition Notes

### Prerequisites

This task depends on ace-context supporting plain markdown file loading (files with frontmatter but no `context:` configuration). Currently, ace-context expects:
- `context:` key in frontmatter, OR
- Template config keys (`files`, `commands`, etc.) in frontmatter

Workflow files typically have only metadata frontmatter (`name`, `description`, etc.) and instruction content.

**Potential Solution**: Enhance ace-context's `load_template` method to fall back to returning raw file content when no context configuration is found.

### Backwards Compatibility

- `ace-nav wfi://` continues to work (returns path)
- Agents using `ace-context wfi://` get direct content (improved UX)
- No breaking changes to existing automated workflows

## Tips

1. **Search and Replace**: Use `ace-search "ace-nav wfi://" --content` to find all occurrences
2. **Test incrementally**: Update one command, test, then proceed
3. **Preserve file paths**: Some workflows may intentionally need the path - review context before replacing

## Error Handling

| Error | Resolution |
|-------|------------|
| "No valid configuration found" | Workflow file needs ace-context enhancement to support plain markdown |
| Protocol resolution failed | Check workflow file exists via `ace-nav wfi://name` |
