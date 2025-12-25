---
name: update-pr-description
allowed-tools: Bash, Read, Grep
description: Update PR title and description based on current work
argument-hint: "[pr-number]"
doc-type: workflow
purpose: automated PR documentation from commits and changes
update:
  frequency: on-change
  last-updated: '2025-11-15'
---

# Update PR Description Workflow

## Purpose

Automatically generate comprehensive PR titles and descriptions based on the actual work done, extracting information from commits, changelog entries, and task files.

## Context

Quality PR descriptions require:
- Accurate title reflecting all changes
- Summary of what was done and why
- Breakdown of changes by category
- Test results and validation
- Links to related tasks

This workflow automates PR documentation by:
- Analyzing git diff for changelog and task file changes
- Extracting task IDs, titles, and metadata
- Examining commit messages for change patterns
- Generating structured, comprehensive descriptions

## Variables

- `$pr_number`: PR number to update (optional - auto-detects from current branch)

## Instructions

### 1. Get PR Number

If not provided as argument, detect from current branch:

```bash
# Auto-detect PR number from branch
gh pr view --json number -q .number
```

If no PR exists for current branch, ask user for PR number.

### 2. Verify Target Branch

Check if PR target is correct based on task hierarchy:

```bash
# Get current PR info
gh pr view $pr_number --json baseRefName,headRefName,title

# Check task hierarchy
ace-taskflow status
```

**Validation Rules:**

| Task Context | Current Target | Correct Target | Action |
|--------------|----------------|----------------|--------|
| Has "Parent Task" | `main` | Parent branch | Fix target |
| Has "Parent Task" | Parent branch | ✓ Correct | No action |
| No parent | `main` | ✓ Correct | No action |

**Auto-fix target if subtask targeting main:**

If `ace-taskflow status` shows "Parent Task" section but PR targets `main`:

```bash
current_base=$(gh pr view $pr_number --json baseRefName -q .baseRefName)

# Check for parent task
parent_info=$(ace-taskflow status | grep -A1 "Parent Task")
if [[ -n "$parent_info" && "$current_base" == "main" ]]; then
  # Extract parent task ID from context
  parent_id=$(echo "$parent_info" | grep -oE 'task\.[0-9]+' | head -1 | sed 's/task\.//')
  correct_base=$(git branch -r | grep -E "origin/${parent_id}-" | head -1 | sed 's/origin\///' | xargs)

  if [[ -n "$correct_base" ]]; then
    echo "⚠️  Subtask targeting main instead of parent branch"
    echo "   Correcting: main → $correct_base"
    gh pr edit $pr_number --base "$correct_base"
  fi
fi
```

### 3. Extract Change Information

Analyze the PR diff to gather information:

```bash
# Get PR diff with file names
gh pr diff $pr_number --name-only

# Focus on these files for metadata:
# - CHANGELOG.md or */CHANGELOG.md
# - .ace-taskflow/*/tasks/**/*.md (task files)
# - .ace-taskflow/*/tasks/done/**/*.md (completed tasks)
```

### 4. Read Changelog Entries

If CHANGELOG files in diff:

```bash
# Get recent changelog additions
gh pr diff $pr_number | grep "^+"
```

Extract:
- Version numbers
- Change types (feat, fix, chore, refactor, etc.)
- Change descriptions
- Breaking changes markers

### 5. Read Task Files

If task files in diff:

Use Read tool to examine task files found in diff.

Extract from task frontmatter:
- `task-id`: Task identifier
- `title`: Task title
- `type`: Task type (feature, bugfix, chore, etc.)
- `status`: Task status
- Acceptance criteria

### 6. Analyze Commits

Get all commits in the PR:

```bash
gh pr view $pr_number --json commits -q '.commits[].messageHeadline'
```

Identify patterns:
- Conventional commit types (feat, fix, chore, etc.)
- Common themes across commits
- Scope of changes (which packages/modules)

### 7. Generate PR Title

**Title Format Rules:**

| Context | Format | Example |
|---------|--------|---------|
| Has task ID (from `ace-git context`) | `<task-id>: <description>` | `140.10: Add PR activity awareness` |
| No task ID | `<type>(<scope>): <description>` | `feat(auth): Add OAuth support` |

**Get task ID from context:**
```bash
# Check ace-git context for task pattern
ace-git context --no-pr | grep "Position (task:"
```

**Guidelines:**
- If task ID present, use `<task-id>: <description>` format
- Keep description concise (< 60 chars after task ID)
- Focus on user-facing impact

**Examples with task ID:**
- `140.10: Add PR activity awareness to context command`
- `140.02: Update ace-taskflow to use ace-git`
- `135.03: Fix validation error in form submission`

**Examples without task ID:**
- `feat(ace-taskflow): enforce folder structure for ideas`
- `fix(ace-git): resolve merge conflict in rebase workflow`

### 8. Generate PR Description

Create structured markdown description:

```markdown
## Summary

[1-2 sentences describing what was done and why]

## Changes

### 1. [Main Feature/Fix Name]
- Key point 1
- Key point 2
- Key point 3

### 2. [Secondary Changes]
- Change 1
- Change 2

[Continue for each major change category]

## Breaking Changes

[If any breaking changes, list them with ⚠️ marker]
[If none, omit this section]

## Test Results

```
[Include test output if available]
```

## Related Tasks

- Task #XXX: [Task title]
[List all related tasks from task files]

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 9. Update PR

Use GitHub CLI to update:

```bash
gh pr edit $pr_number \
  --title "Generated title here" \
  --body "Generated description here"
```

**Note:** Use heredoc for multi-line body:

```bash
gh pr edit $pr_number \
  --title "feat(scope): description" \
  --body "$(cat <<'EOF'
## Summary
...
EOF
)"
```

### 10. Confirm Update

Show updated PR URL:

```bash
gh pr view $pr_number --json url -q .url
```

## Best Practices

1. **Be Comprehensive**: Include all significant changes, not just the main feature
2. **Use Concrete Examples**: Show actual command outputs, test results
3. **Highlight Breaking Changes**: Always call out breaking changes with ⚠️
4. **Link Everything**: Reference related tasks, issues, commits
5. **Keep It Structured**: Use consistent markdown formatting
6. **Focus on Impact**: Explain what changed from user perspective

## Example Usage

```bash
# Auto-detect PR from current branch
/ace:update-pr-desc

# Specify PR number
/ace:update-pr-desc 35
```

## Output Example

```
✅ PR #35 updated successfully

Title: feat(ace-taskflow): enforce folder structure for ideas with validation

Description: Updated with:
- Summary of 3 main changes
- 6 detailed change sections
- Breaking changes warning
- Test results (26 tests passing)
- 2 related tasks

View: https://github.com/org/repo/pull/35
```
