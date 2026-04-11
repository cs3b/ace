---
doc-type: workflow
title: Process Lint Report Workflow
purpose: lint report processing workflow instruction
ace-docs:
  last-updated: 2026-03-06
  last-checked: 2026-03-21
---

# Process Lint Report Workflow

## Purpose

Parse a lint report file and create structured tasks for issues requiring manual intervention. Groups issues by severity and type, generates fix proposals, and drafts tasks via ace-task.

## Prerequisites

- Lint report file exists (from `wfi://lint/run --report`)
- **ace-task is installed and available** - required for task creation commands
- Understanding of project lint rules

## Variables

- `$report_path`: Path to lint report JSON file (from argument)

## Instructions

1. **Locate and read the lint report**:

   **If report path provided:**
   ```bash
   cat "$report_path"
   ```

   **If no path, find most recent:**
   ```bash
   ls -t .ace-lint/reports/*.json | head -1
   ```

2. **Parse and analyze errors**:
   - Group by severity (error > warning)
   - Group by file (for efficient fixing)
   - Group by rule type (similar fixes together)

3. **Generate fix proposals** for each issue:

   | Rule Type | Fix Approach |
   |-----------|--------------|
   | frontmatter-required | Add missing field with default value |
   | yaml-syntax | Suggest correct syntax structure |
   | markdown-structure | Recommend structural changes |
   | link-broken | Suggest path updates or removal |

4. **Prioritize issues**:
   - **P0 (blocking)**: Syntax errors preventing file parsing
   - **P1 (high)**: Missing required metadata
   - **P2 (medium)**: Style/formatting issues
   - **P3 (low)**: Suggestions and improvements

5. **Create tasks via ace-task**:

   **For grouped issues (multiple similar errors):**
   ```bash
   ace-idea create --llm-enhance "Fix [N] [rule-type] lint errors in [component]

   Affected files:
   - file1.md (line 10, 25)
   - file2.md (line 5)

   Fix approach: [common fix description]"
   ```

   **For complex single issues:**
   ```bash
   ace-idea create --llm-enhance "Fix [rule-type] in [file]

   Error: [error message]
   Location: [file:line]

   Suggested fix: [fix proposal]"
   ```

6. **Generate summary report**:

   ```markdown
   # Lint Report Processing Summary

   ## Report: [report_path]
   ## Processed: [timestamp]

   ### Issues by Priority

   | Priority | Count | Status |
   |----------|-------|--------|
   | P0 | N | Task created |
   | P1 | N | Task created |
   | P2 | N | Grouped into M tasks |
   | P3 | N | Logged for later |

   ### Tasks Created

   1. [Task ID]: [Title] - [N] issues
   2. [Task ID]: [Title] - [N] issues

   ### Issues Deferred (P3)

   - [issue description] - [file:line]
   ```

## Grouping Strategy

### Group by File (for small projects)
- All issues in one file → single task
- Efficient for focused fixes

### Group by Rule Type (for large projects)
- All `frontmatter-required` errors → one task
- Efficient for batch fixes with similar patterns

### Group by Component (for mono-repos)
- All issues in `ace-lint/` → one task
- Respects package boundaries

## Fix Proposal Templates

### Missing Frontmatter Field
```markdown
**Fix:** Add the following to YAML frontmatter:
\`\`\`yaml
doc-type: [suggested-type]
\`\`\`
```

### YAML Syntax Error
```markdown
**Fix:** Correct YAML syntax at line [N]:
- Issue: [description]
- Current: `[problematic line]`
- Suggested: `[corrected line]`
```

### Broken Link
```markdown
**Fix:** Update link reference:
- Current: `[broken-path]`
- Options:
  1. Update to: `[correct-path]` (if file moved)
  2. Remove link (if resource deleted)
  3. Mark as external (if external URL)
```

## Success Criteria

- Report successfully parsed
- Issues grouped logically
- Fix proposals generated for each issue
- Tasks created in ace-task
- Summary report generated
- No issues lost or duplicated

## Response Template

**Report Processed:** [report_path]
**Total Issues:** [N]
**Tasks Created:** [M]
**Issues Grouped:** [breakdown by priority]
**Next Steps:**
- Run `/as-task-work [task-id]` for each created task
- Re-run lint after fixes to verify

## Error Handling

- **Empty report**: Report success, no tasks needed
- **Invalid JSON**: Report parse error, suggest re-running lint
- **ace-task unavailable**: Output task drafts as markdown