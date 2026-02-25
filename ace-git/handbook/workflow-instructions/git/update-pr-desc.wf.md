---
name: git-update-pr-desc
allowed-tools: Bash, Read, Grep
description: Update PR title and description from code evidence
argument-hint: "[pr-number]"
doc-type: workflow
purpose: evidence-based PR documentation
update:
  frequency: on-change
  last-updated: '2026-02-25'
---

# Update PR Description Workflow

## Purpose

Generate PR titles and descriptions from code evidence in the PR (diff, commits, tests, and changelog entries), not from task specification text.

## Variables

- `$pr_number`: PR number to update (optional - auto-detect from current branch)

## Instructions

### 1. Resolve PR Number

```bash
gh pr view --json number -q .number
```

If no PR exists for current branch, ask the user for the target PR number.

### 2. Verify Target Branch

```bash
gh pr view $pr_number --json baseRefName,headRefName,title
ace-taskflow status
```

If taskflow context indicates a subtask and the PR targets `main`, retarget to the parent task branch before continuing.

### 3. Collect Evidence Inputs

Collect the evidence used to write the PR:

```bash
# Changed files
gh pr diff $pr_number --name-only

# Full diff for behavior and error-message changes
gh pr diff $pr_number

# Commit headlines
gh pr view $pr_number --json commits -q '.commits[].messageHeadline'

# File-change grouping (preferred)
ace-git diff --format grouped-stats
```

Also gather test evidence and release evidence:
- Test evidence: test files changed in diff + relevant test outputs/suite totals
- Release evidence: CHANGELOG entries present in diff

### 4. Generate Evidence-Based Title

Title format:
- If task ID available from `ace-git status --no-pr`: `<task-id>: <description>`
- Otherwise: `<type>(<scope>): <description>`

Title guidance:
- Focus on user-facing impact
- Keep concise (target < 60 chars after task-id)
- Do not lead with class/method names unless unavoidable

### 5. Generate PR Description

Use this section order exactly:

```markdown
## Summary
## Changes
## File Changes
## Test Evidence
## Releases
```

Section sourcing rules:

| Section | Required Source | Avoid |
|---|---|---|
| Summary | Behavioral change in diff + commit intent | Task spec objective text |
| Changes | Concern-grouped diff changes, traced to commits | Raw commit list dump |
| File Changes | `ace-git diff --format grouped-stats` | Manual hand-written file listing |
| Test Evidence | Test names mapped to behaviors + suite totals | Raw unstructured test output paste |
| Releases | CHANGELOG entries from diff | Repeating content already in Changes |

### 6. Summary Writing Rules

Write Summary in this sequence:
1. What is easier now for users/reviewers
2. What pain/manual step/error state existed before
3. What changed to remove that pain

Constraints:
- Do not copy wording from task specs
- Do not start with method/class names
- Prefer behavior language over implementation language

### 7. Omission and Fallback Rules

- If no changelog evidence: omit `## Releases`
- If no test-file evidence: keep `## Test Evidence` with suite totals only
- If `ace-git diff --format grouped-stats` is unavailable: use flat file list fallback under `## File Changes`
- Omit sections with no supporting evidence instead of leaving placeholders

### 8. Update PR

```bash
gh pr edit $pr_number \
  --title "Generated title" \
  --body "$(cat <<'BODY'
## Summary
...
BODY
)"
```

### 9. Confirm Update

```bash
gh pr view $pr_number --json url,title -q '.url + "\n" + .title'
```

## Success Criteria

- Description uses: `Summary -> Changes -> File Changes -> Test Evidence -> Releases`
- Summary leads with user impact and does not restate task specs
- File Changes sourced from grouped-stats (or explicit fallback)
- Test Evidence maps tests to behavior and includes totals
- Releases derived from changelog evidence only
- Empty/no-evidence sections are omitted
