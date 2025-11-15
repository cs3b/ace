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

### 2. Extract Change Information

Analyze the PR diff to gather information:

```bash
# Get PR diff with file names
gh pr diff $pr_number --name-only

# Focus on these files for metadata:
# - CHANGELOG.md or */CHANGELOG.md
# - .ace-taskflow/*/tasks/**/*.md (task files)
# - .ace-taskflow/*/tasks/done/**/*.md (completed tasks)
```

### 3. Read Changelog Entries

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

### 4. Read Task Files

If task files in diff:

Use Read tool to examine task files found in diff.

Extract from task frontmatter:
- `task-id`: Task identifier
- `title`: Task title
- `type`: Task type (feature, bugfix, chore, etc.)
- `status`: Task status
- Acceptance criteria

### 5. Analyze Commits

Get all commits in the PR:

```bash
gh pr view $pr_number --json commits -q '.commits[].messageHeadline'
```

Identify patterns:
- Conventional commit types (feat, fix, chore, etc.)
- Common themes across commits
- Scope of changes (which packages/modules)

### 6. Generate PR Title

Create title following conventional commits format:

**Pattern:** `<type>(<scope>): <description>`

**Guidelines:**
- Use most prominent change type (feat > fix > refactor > chore)
- Include scope if changes focused on specific package
- Keep description concise (< 72 chars)
- Focus on user-facing impact

**Examples:**
- `feat(ace-taskflow): enforce folder structure for ideas with validation`
- `fix(ace-git): resolve merge conflict in rebase workflow`
- `chore(ace-test): migrate test suite to new framework`

### 7. Generate PR Description

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

### 8. Update PR

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

### 9. Confirm Update

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
