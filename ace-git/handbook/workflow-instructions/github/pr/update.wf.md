---
doc-type: workflow
title: Update PR Description Workflow
purpose: evidence-based PR documentation
ace-docs:
  last-updated: 2026-03-04
  last-checked: 2026-03-21
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
ace-git diff $(git merge-base HEAD origin/main)..HEAD --format grouped-stats
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
## 📋 Summary
## ✏️ Changes
## 📁 File Changes
## 🧪 Test Evidence
## 📦 Releases
## 🎮 Demo
```

Section sourcing rules:

| Section | Required Source | Avoid |
|---|---|---|
| Summary | Behavioral change in diff + commit intent | Task spec objective text |
| Changes | Concern-grouped diff changes, traced to commits | Raw commit list dump |
| File Changes | `ace-git diff $(git merge-base HEAD origin/main)..HEAD --format grouped-stats` output, pasted verbatim and in full | Manual hand-written file listing, trimming or abbreviating the grouped-stats output |
| Test Evidence | Test names mapped to behaviors + suite totals | Raw unstructured test output paste |
| Releases | CHANGELOG entries from diff | Repeating content already in Changes |
| Demo | Runnable commands from README/usage.md + observed output | Screenshots, prose-only descriptions without commands |

**Grouped-stats formatting rule:**
- The `## 📁 File Changes` section must wrap grouped-stats output inside a fenced code block (```)
- Paste the output exactly as produced — preserve all column alignment, tree indentation, and emoji markers
- Never convert grouped-stats output into bullet lists, tables, or prose

Bullet formatting rules:
- **Bold the first key term** in each bullet (feature name, class name, CLI flag, or config key) so it serves as a visual anchor before the explanation. Example: `- Add **\`GroupedStatsFormatter\`**: formats numstat output into...`
- In Test Evidence, bold the test class name: `- **GroupedStatsFormatterTest** (6 tests) — validates...`
- In Releases, bold the package+version: `- **ace-git v0.11.0–v0.11.6** — Add grouped-stats format...`

### 6. Summary Writing Rules

Write Summary in this sequence:
1. What is easier now for users/reviewers
2. What pain/manual step/error state existed before
3. What changed to remove that pain

Constraints:
- Do not copy wording from task specs
- Do not start with method/class names
- Prefer behavior language over implementation language

### 7. Demo Section Rules

Include `## 🎮 Demo` when the PR introduces a user-facing CLI command or runnable entry point that a reviewer can try.

Structure:

```markdown
## 🎮 Demo

### Run
\`\`\`bash
[exact command to copy-paste]
\`\`\`

### Expected Output
[what the reviewer should see]

### Artifacts
[where to find generated files]
```

Omit when: the PR has no user-facing CLI, no runnable entry point, or is purely internal refactoring.

**Recorded demo integration**: If a recorded demo GIF has been attached as a PR comment (via `ace-demo record --pr`), reference it in the Demo section: "See attached demo recording in PR comments below" alongside the runnable commands. The recorded demo supplements but does not replace the runnable commands.

### 8. Omission and Fallback Rules

- If no changelog evidence: omit `## 📦 Releases`
- If no test-file evidence: keep `## 🧪 Test Evidence` with suite totals only
- If `ace-git diff $(git merge-base HEAD origin/main)..HEAD --format grouped-stats` is unavailable: use flat file list fallback under `## 📁 File Changes`
- If no user-facing CLI or runnable entry point: omit `## 🎮 Demo`
- Omit sections with no supporting evidence instead of leaving placeholders

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

### 9. Update PR

```bash
gh pr edit $pr_number \
  --title "Generated title" \
  --body "$(cat <<'BODY'
## 📋 Summary
...
BODY
)"
```

### 10. Confirm Update

```bash
gh pr view $pr_number --json url,title -q '.url + "\n" + .title'
```

## Success Criteria

- Description uses: `📋 Summary -> ✏️ Changes -> 📁 File Changes -> 🧪 Test Evidence -> 📦 Releases -> 🎮 Demo`
- Summary leads with user impact and does not restate task specs
- File Changes contains the complete, untruncated grouped-stats output (never trimmed, summarised, or selectively omitted)
- Test Evidence maps tests to behavior and includes totals
- Releases derived from changelog evidence only
- Empty/no-evidence sections are omitted