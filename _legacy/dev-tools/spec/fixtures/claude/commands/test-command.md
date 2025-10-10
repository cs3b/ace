# Test Command

Execute the test workflow for Claude integration testing.

## Usage
```bash
handbook test-workflow
```

## Description
This command runs the test workflow to validate Claude integration functionality.

## Options
- `--dry-run`: Show what would be done without making changes
- `--verbose`: Display detailed output
- `--force`: Override existing files

## Generated from
workflow-instructions/test-workflow.wf.md

## Examples
```bash
# Run in dry-run mode
handbook test-workflow --dry-run

# Run with verbose output
handbook test-workflow --verbose

# Force regeneration
handbook test-workflow --force
```