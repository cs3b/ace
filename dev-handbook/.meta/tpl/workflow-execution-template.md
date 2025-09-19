# Workflow Execution Template

This template provides a standardized high-level execution plan structure for AI workflow instructions.
All workflow files should include this execution pattern to ensure consistent, systematic task completion.

## Standardized 7-Step Execution Pattern

Copy and adapt this template structure into your workflow file's "Process Steps" section:

```markdown
## Process Steps

1. **Select Task/Target:**
   * Identify the target for this workflow
   * Validate prerequisites and dependencies
   * Confirm scope and boundaries
   * Example commands:
     ```bash
     # List available targets
     ls -1 target-directory/
     
     # Validate target structure
     bin/test --check-target-format
     ```

2. **Load Context & Validate Structure:**
   * Load the content of the selected target
   * **Verify Structure Requirements:**
     ```markdown
     # Expected structure format
     [Document your expected structure here]
     ```
   * If structure is invalid, STOP and report the issue
   * Review the objective to ensure understanding

3. **Update Status/Initialize:**
   * Update target status appropriately (e.g., pending → in-progress)
   * Create necessary tracking or temporary files
   * Initialize working environment
   * Save updated state

4. **Execute Plan Step-by-Step:**
   * Process each step in the defined order
   * For Planning Steps (research/analysis):
     * Execute research, analysis, or design work
     * Document findings inline or in separate files
     * Check for embedded tests and run them
   * For Execution Steps (implementation):
     * Implement the concrete action
     * Follow coding standards
     * Check for embedded tests and run them
   * **Test Execution:**
     * Run any embedded test commands
     * If tests fail: STOP, report failure, await instructions
     * Only mark step complete after tests pass

5. **Follow Standards & Quality Checks:**
   * Apply relevant coding/documentation standards
   * Run quality checks (linting, formatting, validation)
   * Ensure consistency with project patterns
   * Document any deviations or special considerations

6. **Handle Failures & Recovery:**
   * If errors occur during execution:
     **Immediate Actions:**
     1. Stop processing the current step
     2. Capture the error output
     3. Report to user with context
     
     **Resolution Options:**
     * Fix the implementation
     * Update requirements if changed
     * Mark as blocked if external help needed

7. **Final Review & Completion:**
   * Review all completed steps
   * Verify against acceptance criteria
   * Run final validation commands:
     ```bash
     # Project-specific validation
     bin/test
     bin/lint
     bin/build  # if applicable
     ```
   * Update final status
   * Commit all changes with descriptive message
```

## Template Customization Guidelines

### For Different Workflow Types

**Task Execution Workflows:**

- Step 1: Focus on task selection and dependency validation
- Step 2: Emphasize task structure and implementation plan validation
- Step 3: Status update from `pending` to `in-progress`

**File Processing Workflows:**

- Step 1: Focus on file/directory selection and access validation
- Step 2: Emphasize file format and content structure validation
- Step 3: Create backup or tracking files as needed

**System Setup Workflows:**

- Step 1: Focus on environment and prerequisite validation
- Step 2: Emphasize configuration and dependency validation
- Step 3: Initialize configuration files or environment state

### Embedded Test Pattern

When including tests in your workflow steps, use this format:

```markdown
* [ ] Planning/Research step
  > TEST: Descriptive Test Name
  > Type: Pre-condition Check | Action Validation | Post-condition Check
  > Assert: What needs to be verified or expected outcome
  > Command: bin/test --specific-validation-command

- [ ] Implementation/Execution step
  > TEST: Descriptive Test Name
  > Type: Pre-condition Check | Action Validation | Post-condition Check
  > Assert: What needs to be verified or expected outcome
  > Command: bin/test --specific-validation-command
```

### Common Command Patterns

**File Operations:**

```bash
# Check if file/directory exists
ls -la path/to/target

# Validate file format
bin/test --check-format filename

# Create backup
cp original backup-$(date +%Y%m%d-%H%M%S)
```

**Git Operations:**

```bash
# Check repository status
git status

# Validate changes
git diff --check

# Commit with message
git commit -m "descriptive message"
```

**Project-Specific Validation:**

```bash
# Run all tests
bin/test

# Run linting
bin/lint

# Build project
bin/build
```

## Usage Instructions

1. **Copy the 7-step structure** into your workflow's "Process Steps" section
2. **Customize Step 1** based on your workflow's target (task, file, system, etc.)
3. **Adapt Step 2** to match your expected structure or format requirements
4. **Modify Step 3** to reflect appropriate status changes or initialization
5. **Detail Steps 4-7** with workflow-specific actions while maintaining the core pattern
6. **Add embedded tests** using the standardized format where validation is needed
7. **Include project-specific commands** in the template placeholders

## Quality Assurance

Before using this template:

- [ ] Verify all command examples are valid for your project
- [ ] Ensure test commands match your project's testing infrastructure
- [ ] Confirm status update patterns align with your workflow management
- [ ] Test the template with a sample workflow to verify completeness

## References

- Based on the pattern demonstrated in `work-on-task.wf.md`
- Incorporates the 7-step execution pattern from project requirements
- Follows project coding standards and quality guidelines
