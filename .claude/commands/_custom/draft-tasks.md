---
last_modified: '2025-08-05 01:02:11'
---

# Draft Multiple Tasks from Ideas

You are an AI assistant that automatically creates multiple draft tasks from idea files in sequence. This command processes a list of idea files and performs the complete draft task workflow for each one by expanding all workflow instructions inline.

## Idea File Selection

If no idea file list is provided by the user:
- Search for idea files in `dev-taskflow/backlog/ideas/` directory
- Use glob pattern `dev-taskflow/backlog/ideas/*.md` to find all idea files
- If user wants specific patterns, support wildcards like `dev-taskflow/backlog/ideas/20250730-*.md`

If user provides a specific idea file list or command, use that instead.

## For Each Idea File in Sequence

For each idea file, use the Task tool to create a sub-agent that executes the complete workflow:

**Use Task tool with this prompt:**

```
Execute the complete draft-task workflow for: <idea-file-path>

- [ ] **Draft Task Creation:**
  - Read the entire file: dev-handbook/workflow-instructions/draft-task.wf.md
  - Follow all steps in the workflow exactly as written
  - Input file: <idea-file-path>

- [ ] **Create Reflection Note:**
  - Read the entire file: dev-handbook/workflow-instructions/create-reflection-note.wf.md
  - Follow all steps in the workflow exactly as written
  - Context: Reflect on the draft task creation just completed

- [ ] **Processing Summary:**
  - Idea file processed
  - Draft tasks created (IDs and titles)
  - Files modified
  - Any issues encountered
  - Status (completed/partial/blocked)
```

**Subagent type:** general-purpose

## Between Idea Files

After completing one idea file, briefly report progress and move to the next idea file in the list.

## Final Summary

After all idea files are processed:

- [ ] **Run Documentation Validation:**
  ```bash
  bin/lint
  ```
  - Ensure all documentation passes quality checks
  - Address any linting issues before marking completion

- [ ] **Final Project Validation:**
  - Verify all draft tasks were created with proper status
  - Confirm all changes are properly committed
  - Check that task files are in correct locations

- [ ] **Summary Report:**
  Provide comprehensive summary including:
  - Total idea files processed
  - Total draft tasks created
  - Success/failure count per idea file
  - Overview of all draft tasks created (IDs, titles, paths)
  - Any blockers or issues that need attention
  - Recommendations for next steps (e.g., implementation planning)

## Error Handling

If an idea file fails during processing:
- Document the failure reason and context
- Log which idea file caused the failure
- Commit any partial progress made
- Skip to next idea file (don't stop entire process)
- Include failure details in final summary
- Consider creating follow-up tasks for failures

## Usage Examples

```
# Process all idea files in backlog/ideas/
/draft-tasks

# Process specific idea files pattern
/draft-tasks dev-taskflow/backlog/ideas/20250730-*.md

# Process specific idea files (as provided in arguments)
/draft-tasks dev-taskflow/backlog/ideas/20250730-2324-context-optimization.md dev-taskflow/backlog/ideas/20250731-0748-capture-it-rename.md
```

## Important Notes

- Execute idea files sequentially (no parallel processing)
- Each idea file gets full draft-task workflow treatment with expanded instructions
- Never use Task tool to invoke other slash commands - expand everything inline
- Commit only specific files created (no broad commits or tagging)
- Maintain detailed logs of progress throughout
- Stop if critical errors occur that would cause data loss
- Always create reflection notes for learning and improvement
- Commit changes with specific file paths and clear intentions for better tracking
- Focus on behavioral specifications, not implementation details
- All created tasks should have `status: draft` indicating need for implementation planning
