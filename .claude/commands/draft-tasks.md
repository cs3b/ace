---
last_modified: '2025-08-24 00:39:00'
source: custom
---

# Draft Multiple Tasks from Ideas or Register Completed Tasks

You are an AI assistant that intelligently processes input files to either create new draft tasks from ideas or register existing completed task specifications. This command analyzes input files and adapts its workflow based on the detected file type.

## File Type Detection

The command analyzes each input file to determine its type:

**Idea Files** (for draft task creation):
- Files with LLM metadata headers (created by capture-it or similar)
- Typically contain raw ideas, feature requests, or requirements
- Need transformation into behavioral specifications

**Completed Task Files** (for registration):
- Files with YAML frontmatter containing task metadata
- Already have fields like `id`, `status`, `priority`, `estimate`, `dependencies`
- Represent fully-specified tasks that just need registration

## Input File Selection

If no files are provided by the user:
- Search for idea files in `dev-taskflow/backlog/ideas/` directory
- Use glob pattern `dev-taskflow/backlog/ideas/*.md` to find all idea files
- Support wildcards like `dev-taskflow/backlog/ideas/20250730-*.md`

If user provides specific files, analyze each to determine its type.

## Processing Workflow

### Step 1: Analyze Input Files

For each provided file:
1. Read the first 20 lines of the file
2. Check for YAML frontmatter (starts with `---` and contains task fields)
3. Classify as either "idea file" or "completed task file"
4. Report detection results to user:

```
Analyzing input files...
- idea1.md: Detected as idea file
- completed-task.md: Detected as completed task file
- feature.md: Detected as idea file

Summary: 2 idea files, 1 completed task file
```

### Step 2: Process Based on Type

#### For Idea Files (Create Draft Tasks)

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

#### For Completed Task Files (Register Tasks)

For each completed task file:
1. Extract task metadata from YAML frontmatter
2. Use `task-manager create` to register the task with proper ID
3. Copy the entire file content to the created task location
4. Report registration status:

```
Registering completed task: <file-name>
- Extracted metadata: id, title, priority, status
- Created task: v.0.5.0+task.XXX - Task Title
- Preserved full task content at: <new-location>
```

### Step 3: Mixed Input Handling

When processing files of different types:
1. Group files by type
2. Process all idea files first (draft creation workflow)
3. Then process all completed task files (registration workflow)
4. Provide clear status for each group

## Final Summary

After all files are processed:

- [ ] **Run Documentation Validation:**
  ```bash
  bin/lint
  ```
  - Ensure all documentation passes quality checks
  - Address any linting issues before marking completion

- [ ] **Final Project Validation:**
  - Verify all tasks were created/registered with proper status
  - Confirm all changes are properly committed
  - Check that task files are in correct locations

- [ ] **Summary Report:**
  Provide comprehensive summary including:
  - Total files processed (by type)
  - Tasks created from ideas (IDs, titles, paths)
  - Tasks registered from completed specs (IDs, titles, paths)
  - Success/failure count per file type
  - Any blockers or issues that need attention
  - Recommendations for next steps

## Error Handling

### Detection Errors
If a file cannot be classified:
- Report as "unrecognizable file type"
- Show first 10 lines for user review
- Ask for guidance or skip the file
- Include in final summary as unprocessed

### Processing Errors
If a file fails during processing:
- Document the failure reason and context
- Log which file caused the failure and its type
- Commit any partial progress made
- Skip to next file (don't stop entire process)
- Include failure details in final summary

### Mixed Failures
When some files succeed and others fail:
- Report partial success clearly
- Group results by file type and status
- Provide actionable error messages for failures

## Usage Examples

```
# Process all idea files in backlog/ideas/ (default behavior)
/draft-tasks

# Process specific idea files pattern
/draft-tasks dev-taskflow/backlog/ideas/20250730-*.md

# Process mixed input (idea files and completed tasks)
/draft-tasks idea1.md completed-task-spec.md idea2.md

# Process completed task specifications for registration
/draft-tasks dev-taskflow/backlog/tasks/completed-spec-1.md dev-taskflow/backlog/tasks/completed-spec-2.md
```

## Important Notes

- Execute files sequentially (no parallel processing)
- File type detection happens BEFORE any processing
- Idea files get full draft-task workflow treatment
- Completed task files preserve their full content during registration
- Never use Task tool to invoke other slash commands - expand everything inline
- Commit only specific files created (no broad commits or tagging)
- Maintain detailed logs of progress throughout
- Stop if critical errors occur that would cause data loss
- Always create reflection notes for idea file processing
- Commit changes with specific file paths and clear intentions
- Focus on behavioral specifications for new draft tasks
- Preserve implementation details in completed task registrations