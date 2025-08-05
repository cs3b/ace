# Handbook Claude Validate User Guide

## Overview

The `handbook claude validate` command provides comprehensive validation of Claude Code command coverage and integrity. It checks for missing commands, outdated references, duplicates, and ensures all workflow instructions have corresponding Claude commands properly registered and available.

### Key Features

- **Coverage Validation**: Ensure all workflows have corresponding commands
- **Integrity Checks**: Detect outdated references and broken links
- **Duplicate Detection**: Find conflicting command definitions
- **Workflow-Specific Validation**: Check individual workflows
- **Strict Mode**: Exit with error code for CI/CD integration
- **Multiple Output Formats**: Text or JSON for different use cases

## Installation

The handbook claude commands are included with the Coding Agent Tools gem:

```bash
# Install the gem
gem install coding_agent_tools

# Or add to your Gemfile
gem 'coding_agent_tools'
bundle install
```

Once installed, the `handbook` command with claude subcommands will be available in your PATH.

## Quick Start

```bash
# Basic validation
handbook claude validate

# Check for missing commands only
handbook claude validate --check missing

# Validate specific workflow
handbook claude validate --workflow draft-task

# Strict mode for CI
handbook claude validate --strict
```

## Command Reference

### Basic Usage

```bash
handbook claude validate [OPTIONS]
```

### Options

- `--check=VALUE` - Specific check to run: missing, outdated, or duplicates
- `--strict` - Exit with code 1 if issues found (default: false)
- `--workflow=VALUE` - Validate specific workflow (supports wildcards)
- `--format=VALUE` - Output format: text or json (default: "text")
- `--help, -h` - Print help information

### Examples

#### Full Validation

```bash
handbook claude validate
```

**Sample Output:**
```
Claude Command Validation Report

✓ Coverage Check: All workflows have corresponding commands
✓ Registry Check: All registry entries have valid files
✓ Duplicate Check: No duplicate commands found

Summary: All validation checks passed!
```

#### Check for Missing Commands

```bash
handbook claude validate --check missing
```

**Sample Output (when issues found):**
```
Claude Command Validation Report

✗ Missing Commands (3):
  - create-reflection-note (from create-reflection-note.wf.md)
  - update-blueprint (from update-blueprint.wf.md)
  - analyze-dependencies (from analyze-dependencies.wf.md)

Run 'handbook claude generate-commands' to create missing commands
```

#### Validate Specific Workflow

```bash
handbook claude validate --workflow draft-task
```

**Sample Output:**
```
Validating workflow: draft-task

✓ Workflow file exists: dev-handbook/workflow-instructions/draft-task.wf.md
✓ Command exists: dev-handbook/.integrations/claude/commands/_generated/draft-task.md
✓ Registry entry valid
✓ Command content matches workflow

Workflow 'draft-task' validation passed!
```

#### Strict Mode for CI/CD

```bash
# In CI pipeline
handbook claude validate --strict --format json
```

**Sample Output (with exit code 1 on failure):**
```json
{
  "validation_results": {
    "coverage": {
      "status": "failed",
      "missing_commands": [
        "create-reflection-note",
        "update-blueprint"
      ]
    },
    "registry": {
      "status": "passed",
      "invalid_entries": []
    },
    "duplicates": {
      "status": "passed",
      "duplicate_commands": []
    }
  },
  "summary": {
    "passed": false,
    "total_issues": 2,
    "exit_code": 1
  }
}
```

## Validation Checks

### Coverage Check

Ensures every workflow instruction file has a corresponding Claude command:

- Scans all `.wf.md` files in workflow-instructions directory
- Checks for matching command in _custom/ or _generated/ directories
- Reports any workflows without commands

### Registry Check

Validates the integrity of the command registry:

- Verifies all registry entries point to existing files
- Checks command metadata consistency
- Ensures proper JSON structure

### Duplicate Check

Detects conflicting command definitions:

- Finds commands with the same name in different locations
- Identifies registry conflicts
- Helps maintain clean command namespace

### Outdated Check

Identifies commands that may need updating:

- Compares command timestamps with source workflows
- Detects modified workflows with stale commands
- Suggests regeneration when needed

## Common Use Cases

### Pre-Commit Validation

Add to git hooks for automatic validation:

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Validating Claude commands..."
if ! handbook claude validate --strict; then
  echo "Claude command validation failed!"
  echo "Run 'handbook claude generate-commands' to fix"
  exit 1
fi
```

### CI/CD Integration

```yaml
# GitHub Actions example
- name: Validate Claude Commands
  run: |
    bundle exec handbook claude validate --strict --format json > validation.json
    if [ $? -ne 0 ]; then
      cat validation.json
      exit 1
    fi
```

### Development Workflow

During active development:

```bash
# After adding new workflow
echo "Creating new workflow..."
vim dev-handbook/workflow-instructions/new-feature.wf.md

# Validate coverage
handbook claude validate --check missing

# Generate if needed
handbook claude generate-commands

# Final validation
handbook claude validate --strict
```

### Maintenance Checks

Regular maintenance routine:

```bash
# Weekly maintenance script
#!/bin/bash

echo "Running Claude command maintenance..."

# Check everything
handbook claude validate

# Check for outdated commands
handbook claude validate --check outdated

# Generate report
handbook claude validate --format json > claude-validation-$(date +%Y%m%d).json
```

## Understanding Validation Results

### Success States

- **Green checkmarks (✓)**: Validation passed
- **"All validation checks passed!"**: Everything is properly configured
- **Exit code 0**: Success (important for scripts)

### Failure States

- **Red crosses (✗)**: Validation failed
- **Detailed error lists**: Specific issues to address
- **Exit code 1** (with --strict): Failure for CI/CD

### Warning States

- **Yellow warnings**: Non-critical issues
- **Suggestions**: Recommended actions
- **Exit code 0**: Not a failure unless --strict

## Troubleshooting

### Validation Always Fails

If validation consistently fails:

1. Check file permissions in dev-handbook directory
2. Verify git submodules are properly initialized
3. Ensure registry.json is not corrupted
4. Run with debug output: `HANDBOOK_DEBUG=1 handbook claude validate`

### Missing Commands Not Detected

If known missing commands aren't reported:

1. Check workflow file extensions (must be .wf.md)
2. Verify workflow files are in correct directory
3. Ensure no .gitignore rules are excluding files
4. Try explicit workflow validation: `handbook claude validate --workflow <name>`

### False Positives

If validation reports issues incorrectly:

1. Update the command registry: `handbook claude integrate`
2. Check for case sensitivity issues
3. Verify no symbolic links are causing confusion
4. Clear any caches and retry

### Performance Issues

For large projects with many workflows:

1. Use specific checks: `handbook claude validate --check missing`
2. Validate individual workflows: `handbook claude validate --workflow pattern*`
3. Use JSON format for faster parsing in scripts
4. Consider running validation in parallel for different checks

## Best Practices

1. **Regular Validation**: Run validation before committing changes
2. **CI Integration**: Always use --strict in CI/CD pipelines
3. **Specific Checks**: Use targeted checks during development
4. **JSON for Automation**: Use JSON format for scripted processing
5. **Fix Immediately**: Address validation issues before they accumulate

## Integration with Other Commands

The validation workflow typically follows this pattern:

```bash
# 1. Validate current state
handbook claude validate

# 2. If issues found, check what's missing
handbook claude list --type missing

# 3. Generate missing commands
handbook claude generate-commands --dry-run
handbook claude generate-commands

# 4. Re-validate
handbook claude validate --strict

# 5. Install if all validations pass
handbook claude integrate
```

## Exit Codes

- **0**: Validation passed (or passed with warnings in non-strict mode)
- **1**: Validation failed (only in --strict mode)
- **2**: Command error (invalid options, missing files, etc.)

## See Also

- [handbook claude list](./handbook-claude-list.md) - List available commands
- [handbook claude generate-commands](./handbook-claude-generate-commands.md) - Generate missing commands
- [handbook claude integrate](./handbook-claude-integrate.md) - Install commands to Claude

---

*For the most up-to-date information, run `handbook claude validate --help`*