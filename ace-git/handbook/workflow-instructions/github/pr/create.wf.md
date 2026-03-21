---
doc-type: workflow
title: Pull Request Creation Workflow
purpose: pull request creation workflow
ace-docs:
  last-updated: 2026-03-04
  last-checked: 2026-03-21
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

**If push is rejected (non-fast-forward)**:
- For feature branches with worktree-based divergence, prefer `git push --force-with-lease`
- For shared branches or uncertain divergence, ask the user before force-pushing or rebasing
- Do NOT silently rebase — this is a potentially destructive operation requiring user consent

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
## 📋 Summary
## ✏️ Changes
## 📁 File Changes
## 🧪 Test Evidence
## 📦 Releases
## 🎮 Demo
```

Section sourcing rules:

| Section | Data Source | Avoid |
|---|---|---|
| Summary | Diff behavior and user pain removed | Restating task objective text |
| Changes | Concern-grouped code changes linked to commits | Raw commit dump |
| File Changes | `ace-git diff --format grouped-stats` | Manual unstructured file list |
| Test Evidence | Test names mapped to behaviors + totals | Raw command output paste |
| Releases | CHANGELOG diff entries | Duplicating Changes section |
| Demo | Runnable commands from README/usage.md + observed output | Screenshots, prose-only descriptions without commands |

**Grouped-stats formatting rule:**
- The `## 📁 File Changes` section must wrap grouped-stats output inside a fenced code block (```)
- Paste the output exactly as produced — preserve all column alignment, tree indentation, and emoji markers
- Never convert grouped-stats output into bullet lists, tables, or prose

Summary writing rules:
- Start with what is easier now
- Mention what users/reviewers had to do before
- Do not lead with method/class names
- Do not use task-spec text as prose source

Bullet formatting rules:
- **Bold the first key term** in each bullet (feature name, class name, CLI flag, or config key) so it serves as a visual anchor before the explanation. Example: `- Add **\`GroupedStatsFormatter\`**: formats numstat output into...`
- In Test Evidence, bold the test class name: `- **GroupedStatsFormatterTest** (6 tests) — validates...`
- In Releases, bold the package+version: `- **ace-git v0.11.0–v0.11.6** — Add grouped-stats format...`

Demo section rules:
- Include `## 🎮 Demo` when the PR introduces a user-facing CLI or runnable entry point
- Structure: `### Run` (exact command), `### Expected Output`, `### Artifacts` (where to find results)
- Omit when: no user-facing CLI, no runnable entry point, or purely internal refactoring

Omission/fallback rules:
- No changelog evidence -> omit `## 📦 Releases`
- No test-file evidence -> `## 🧪 Test Evidence` may include totals-only validation
- grouped-stats unavailable -> fallback to flat file list in `## 📁 File Changes`
- No user-facing CLI or runnable entry point -> omit `## 🎮 Demo`
- Omit any section lacking evidence; never leave empty placeholders

#### Grouped-stats example

Correct — output wrapped in a fenced code block preserving all formatting:

````
## 📁 File Changes

```
 +762,   -54   34 files   total

  +358,   -35   10 files      ace-overseer/
  +117,   -18    4 files   🧱 lib/
   +19,    -3                 ace/overseer/cli/commands/work_on.rb
```
````

Incorrect — reformatted into bullet list (loses tree structure and alignment):

```
## 📁 File Changes

- ace-overseer/lib/ace/overseer/cli/commands/work_on.rb (+19, -3)
- ace-overseer/lib/ace/overseer/molecules/assignment_launcher.rb (+42, -8)
```

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
## 📋 Summary

[What is easier now for users/reviewers]
[What pain/manual step/error existed before]

## ✏️ Changes

- Add **`[FeatureName]`**: [what it does]
- Add **`[ClassName]`** to [what it enables]

## 📁 File Changes

[Paste `ace-git diff --format grouped-stats` output verbatim inside a fenced code block — preserve all spacing and tree structure]
[Fallback: flat file list if grouped-stats unavailable]

## 🧪 Test Evidence

- **[TestClassName]** ([N] tests) — [behavior validated]
- Suite totals: [passed]/[total]

## 📦 Releases

- **[package vX.Y.Z]** — [CHANGELOG entry from diff]

## 🎮 Demo

[Runnable command(s) demonstrating the feature — omit section if no user-facing CLI]
[Expected output and artifact locations]
</template>

<template path="ace-git/handbook/templates/pr/bugfix.template.md">
## 📋 Summary

[What broke and what is now fixed]

## ✏️ Changes

- Fix **`[ErrorType]`** when [condition] ([commit-sha])
- Add **`[TestName]`** to guard against regression ([commit-sha])

## 📁 File Changes

[Paste `ace-git diff --format grouped-stats` output verbatim inside a fenced code block — preserve all spacing and tree structure]

## 🧪 Test Evidence

- **[TestClassName]** ([N] tests) — [regression behavior covered]
- Suite totals: [passed]/[total]

## 📦 Releases

- **[package vX.Y.Z]** — [CHANGELOG fix entry from diff]
</template>

<template path="ace-git/handbook/templates/pr/default.template.md">
## 📋 Summary

[What is easier now]
[What changed from user/reviewer perspective]

## ✏️ Changes

- Add **`[PrimaryChange]`**: [description] ([commit-sha])
- Update **`[SecondaryChange]`**: [description] ([commit-sha])

## 📁 File Changes

[Paste `ace-git diff --format grouped-stats` output verbatim inside a fenced code block — preserve all spacing and tree structure]

## 🧪 Test Evidence

- **[TestClassName]** ([N] tests) — [behavior validated]
- Suite totals: [passed]/[total]

## 📦 Releases

- **[package vX.Y.Z]** — [CHANGELOG entry from diff, if any]

## 🎮 Demo

[Runnable command(s) demonstrating the change — omit section if no user-facing CLI]
[Expected output and artifact locations]
</template>
</documents>