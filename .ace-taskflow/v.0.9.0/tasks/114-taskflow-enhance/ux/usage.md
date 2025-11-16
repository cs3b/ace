# ace-review Task Integration Usage Guide

## Overview

The ace-review tool now supports saving review reports directly to ace-taskflow task directories using the `--task` flag. This feature ensures review feedback becomes part of the task's permanent artifacts, improving traceability and providing historical context for development decisions.

## Key Benefits

- **Persistent Storage**: Review reports are automatically saved to task directories
- **Historical Context**: All reviews for a task are stored in one location
- **Improved Traceability**: Clear audit trail of review feedback per task
- **AI Agent Access**: Saved reports are discoverable by AI assistants for context

## Command Structure

### Basic Syntax
```bash
ace-review --preset <preset-name> --task <task-reference>
```

### Task Reference Formats
The `--task` flag accepts multiple reference formats:
- **Task Number**: `047` - Simple numeric reference
- **Task Prefix**: `task.047` - Explicit task prefix
- **Full ID**: `v.0.9.0+047` - Complete task identifier

### Available Options
- `--task <ref>`: Specify task to save report to
- `--preset <name>`: Review preset to use (pr, security, comprehensive, etc.)
- `--auto-execute`: Run review without interactive prompts
- `--model <name>`: Override default LLM model
- All existing ace-review options remain available

## Usage Scenarios

### Scenario 1: PR Review for Current Task
**Goal**: Review pull request changes and save to the task you're working on

```bash
# Working on task 114, review PR changes
ace-review --preset pr --task 114

# Output:
# ... normal review output ...
# Review report saved to: .ace-taskflow/v.0.9.0/tasks/114-taskflow-enhance/reviews/20251116-143025-claude-pr-review.md
```

### Scenario 2: Security Review with Auto-Execute
**Goal**: Run automated security review and save to task directory

```bash
# Run security review without prompts
ace-review --preset security --task task.089 --auto-execute

# Output:
# Loading preset: security
# Executing review with gpt4...
# ... security findings ...
# Review report saved to: .ace-taskflow/v.0.9.0/tasks/089-auth-feature/reviews/20251116-144512-gpt4-security-review.md
```

### Scenario 3: Comprehensive Review for Completed Task
**Goal**: Final comprehensive review before marking task complete

```bash
# Full review using explicit task ID
ace-review --preset comprehensive --task v.0.9.0+095

# Output:
# ... comprehensive review results ...
# Review report saved to: .ace-taskflow/v.0.9.0/tasks/095-api-refactor/reviews/20251116-150230-claude-comprehensive-review.md
```

### Scenario 4: Quick Code Review with Custom Model
**Goal**: Use different LLM model for specific review

```bash
# Use Gemini for code review
ace-review --preset code --task 102 --model gemini

# Output:
# ... code review feedback ...
# Review report saved to: .ace-taskflow/v.0.9.0/tasks/102-optimize-search/reviews/20251116-151845-gemini-code-review.md
```

### Scenario 5: Multiple Reviews Same Task
**Goal**: Run different review types for the same task

```bash
# First: Security review
ace-review --preset security --task 110 --auto-execute

# Then: Performance review
ace-review --preset performance --task 110

# Result: Both saved with unique timestamps
# .../110-feature/reviews/20251116-160000-claude-security-review.md
# .../110-feature/reviews/20251116-160145-claude-performance-review.md
```

### Scenario 6: Review Without Task Association
**Goal**: Traditional review without saving to task

```bash
# Works as before - no task association
ace-review --preset pr

# Output:
# ... review output ...
# (No report saved to task directory)
```

## Command Reference

### ace-review with --task
```bash
ace-review --preset <preset> --task <reference> [options]
```

**Parameters:**
- `--task <reference>`: Task to save report to
  - Accepts: number (047), prefix (task.047), or full ID (v.0.9.0+047)
  - Resolves via ace-taskflow to find task directory
  - Creates `reviews/` subdirectory if needed

**Internal Implementation:**
- Uses `ace-taskflow task <reference>` to resolve task path
- Generates filename: `YYYYMMDD-HHMMSS-<provider>-<preset>-review.md`
- Writes report content to `<task-dir>/reviews/` directory
- Provides user feedback about save location

### Error Handling

**Task Not Found:**
```bash
ace-review --preset pr --task 999
# Error: Task 999 not found. Review completed but report not saved to task.
```

**ace-taskflow Not Available:**
```bash
# If ace-taskflow gem not installed
ace-review --preset pr --task 047
# Warning: ace-taskflow not available. Review completed but report not saved to task.
```

## Tips and Best Practices

### Recommended Workflow
1. Start working on a task
2. Make changes and commits
3. Run review with `--task` flag before finalizing
4. Reports automatically saved for future reference

### Naming Conventions
- Reports use consistent naming: `YYYYMMDD-HHMMSS-provider-preset-review.md`
- Timestamp ensures uniqueness even for rapid reviews
- Provider and preset in name for easy identification

### Finding Saved Reports
```bash
# List all reviews for a task
ls -la .ace-taskflow/v.0.9.0/tasks/114-*/reviews/

# View latest review
cat .ace-taskflow/v.0.9.0/tasks/114-*/reviews/*.md | tail -1
```

### Integration with Git Workflow
```bash
# Before committing changes
ace-review --preset pr --task 114

# Before merging to main
ace-review --preset comprehensive --task 114

# Security check before deployment
ace-review --preset security --task 114 --auto-execute
```

## Troubleshooting

### Issue: Report not saved despite --task flag
- **Check**: Verify task exists with `ace-taskflow task <ref>`
- **Check**: Ensure write permissions to task directory
- **Check**: Confirm ace-taskflow gem is installed

### Issue: Duplicate timestamp (same second)
- **Resolution**: System automatically adds microseconds to filename
- **Example**: `20251116-160000-001234-claude-pr-review.md`

### Issue: Can't find saved reports
- **Location**: Reports saved in `<task-dir>/reviews/` subdirectory
- **Use**: `ace-taskflow task <ref>` to get task path
- **Then**: Navigate to `reviews/` subdirectory

## Migration Notes

### From Manual Report Management
**Before**: Copy review output manually to task notes
**Now**: Use `--task` flag for automatic saving

### From Release-Level Reviews
**Before**: Reviews saved only at release level
**Now**: Task-specific reviews for granular tracking

### Backward Compatibility
- All existing ace-review functionality unchanged
- `--task` flag is optional addition
- Reviews work normally without task association