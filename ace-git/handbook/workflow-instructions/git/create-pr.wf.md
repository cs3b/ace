---
name: git-create-pr
allowed-tools: Bash, Read
description: Create pull requests with evidence-based descriptions
argument-hint: "[pr-type]"
doc-type: workflow
purpose: pull request creation workflow
update:
  frequency: on-change
  last-updated: '2026-02-25'
---

# Pull Request Creation Workflow

## Purpose

Create pull requests with descriptions sourced from code evidence (diff, commits, tests, changelogs), using consistent section structure.

## Variables

- `$pr_type`: `feature`, `bugfix`, or `default`
- `$target_branch`: target branch (default resolved from task/worktree context)
- `$draft`: create as draft (`false` by default)

## Instructions

### 1. Pre-PR Verification

```bash
git branch --show-current
git status
git log origin/${target_branch:-main}..HEAD --oneline
ace-test
```

Checklist:
- [ ] All changes committed
- [ ] Relevant tests pass
- [ ] CHANGELOG updated if release notes changed
- [ ] No sensitive data in diff

### 2. Resolve Target Branch

Prefer task/worktree metadata from `_current/*.s.md` (`worktree.target_branch`), fallback to `main`.

```bash
task_file=$(ls _current/*.s.md 2>/dev/null | head -1)
```

If subtask context exists and current target is `main`, switch target to parent task branch.

### 3. Push Branch

```bash
git push -u origin "$(git branch --show-current)"
```

### 4. Build Evidence Inputs

Before writing the body, collect evidence:

```bash
git log origin/${target_branch:-main}..HEAD --oneline
ace-git diff --format grouped-stats
```

And collect:
- Behavioral evidence from diff (old behavior vs new behavior)
- Test evidence (test names -> behavior proved, suite totals)
- Release evidence (CHANGELOG additions)

### 5. Draft PR Body with Required Sections

Use this order:

```markdown
## Summary
## Changes
## File Changes
## Test Evidence
## Releases
```

Section sourcing rules:

| Section | Data Source | Avoid |
|---|---|---|
| Summary | Diff behavior and user pain removed | Restating task objective text |
| Changes | Concern-grouped code changes linked to commits | Raw commit dump |
| File Changes | `ace-git diff --format grouped-stats` | Manual unstructured file list |
| Test Evidence | Test names mapped to behaviors + totals | Raw command output paste |
| Releases | CHANGELOG diff entries | Duplicating Changes section |

Summary writing rules:
- Start with what is easier now
- Mention what users/reviewers had to do before
- Do not lead with method/class names
- Do not use task-spec text as prose source

Omission/fallback rules:
- No changelog evidence -> omit `## Releases`
- No test-file evidence -> `## Test Evidence` may include totals-only validation
- grouped-stats unavailable -> fallback to flat file list in `## File Changes`
- Omit any section lacking evidence; never leave empty placeholders

### 6. Create PR

```bash
gh pr create \
  --title "<task-id-or-type>: <user-impact-description>" \
  --body-file pr-description.md \
  --base "${target_branch:-main}"
```

Optional draft mode:

```bash
gh pr create --draft --title "..." --body-file pr-description.md --base "${target_branch:-main}"
```

### 7. Add Metadata (Optional)

```bash
gh pr edit --add-reviewer @reviewer1,@reviewer2
gh pr edit --add-label "enhancement,needs-review"
```

### 8. Verify PR

```bash
gh pr view
gh pr checks
```

## Success Criteria

- PR created with evidence-based body
- Section order matches required structure
- Summary is user-impact-first and task-spec-independent
- File changes sourced from grouped-stats (or fallback)
- Test evidence maps tests to behavior
- Releases only included when changelog evidence exists

## Response Template

**PR Created:** [URL]
**PR Number:** #[number]
**Title:** [PR title]
**Type:** [feature/bugfix/default]
**Status:** [created|draft|failed]

<documents>
<template path="ace-git/handbook/templates/pr/feature.template.md">
## Summary

[What is easier now for users/reviewers]
[What pain/manual step/error existed before]

## Changes

- [Concern 1] ([commit-sha])
- [Concern 2] ([commit-sha])

## File Changes

- [Use `ace-git diff --format grouped-stats` output]
- [Fallback: flat file list if grouped-stats unavailable]

## Test Evidence

- [test_file_or_test_name] -> [behavior validated]
- Suite totals: [passed]/[total]

## Releases

- [CHANGELOG entry from diff]
</template>

<template path="ace-git/handbook/templates/pr/bugfix.template.md">
## Summary

[What broke and what is now fixed]

## Changes

- [Root cause and fix] ([commit-sha])
- [Guardrails/regression protection] ([commit-sha])

## File Changes

- [Use `ace-git diff --format grouped-stats` output]

## Test Evidence

- [test name] -> [regression behavior covered]
- Suite totals: [passed]/[total]

## Releases

- [CHANGELOG fix entry from diff]
</template>

<template path="ace-git/handbook/templates/pr/default.template.md">
## Summary

[What is easier now]
[What changed from user/reviewer perspective]

## Changes

- [Primary change] ([commit-sha])
- [Secondary change] ([commit-sha])

## File Changes

- [Use `ace-git diff --format grouped-stats` output]

## Test Evidence

- [test name] -> [behavior validated]
- Suite totals: [passed]/[total]

## Releases

- [CHANGELOG entry from diff, if any]
</template>
</documents>
