---
last_modified: '2025-08-23'
source: custom
---

# Goal

Ensure all changes made in the current session or workflow are properly committed to git using the unified commit workflow.

# Implementation

Use the unified git-commit agent which intelligently selects the appropriate strategy:
- **Auto-detect**: Let the agent determine the best strategy based on context
- **Explicit strategy**: Specify all|files|review when you know what's needed

# Usage

## Automatic Strategy Selection (Recommended)

When called without parameters, the agent analyzes the repository state and selects the optimal strategy:

```
Use the git-commit agent to commit changes.
Intention: [Brief description of what was done]
```

## Explicit Strategy Control

When you know exactly what strategy to use:

```
Use the git-commit agent with strategy=[all|files|review].
Intention: [Purpose of changes]
Files: [Only if strategy=files]
```

## Examples

### Auto-detect strategy (most common):
```
Use the git-commit agent to commit changes.
Intention: Implement user authentication feature
```

### Commit all changes:
```
Use the git-commit agent with strategy=all.
Intention: Update documentation and fix typos
```

### Commit specific files:
```
Use the git-commit agent with strategy=files.
Files: src/auth.js, tests/auth.test.js, docs/auth.md
Intention: Complete authentication implementation
```

### Review before committing:
```
Use the git-commit agent with strategy=review.
Intention: Organize and commit refactoring changes
```

## Context from Workflows

When called from a workflow command:
- The agent automatically detects the workflow context
- Uses git-status to understand what changed
- Creates appropriate commit with workflow-specific message

When called directly:
- Reviews all changes made in current session
- Groups related changes appropriately
- Commits with clear conventional format

## Strategy Auto-Detection Rules

The agent follows these rules when no strategy is specified:
1. Few files in same directory → `all`
2. Documentation only changes → `all`
3. Mixed staged/unstaged → `review`
4. Large changeset (>10 files) → `review`
5. Cross-module changes → `review`
6. Test files only → `all`
7. Default fallback → `review` (conservative)

The unified agent replaces the three separate commit agents while maintaining all functionality through intelligent strategy selection.
