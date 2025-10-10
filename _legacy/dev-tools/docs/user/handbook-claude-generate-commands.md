# Handbook Claude Generate-Commands User Guide

## Overview

The `handbook claude generate-commands` command automatically creates Claude Code commands from workflow instruction files. It scans for `.wf.md` files in the workflow-instructions directory and generates corresponding command files that Claude can use, ensuring complete coverage of all available workflows.

### Key Features

- **Automatic Command Generation**: Creates commands from workflow files
- **Smart Detection**: Only generates missing commands
- **Dry-Run Mode**: Preview changes before applying them
- **Force Regeneration**: Update existing generated commands
- **Pattern Matching**: Generate commands for specific workflows
- **Template-Based**: Uses consistent command structure

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
# Preview what would be generated
handbook claude generate-commands --dry-run

# Generate missing commands
handbook claude generate-commands

# Force regenerate all commands
handbook claude generate-commands --force

# Generate for specific workflow
handbook claude generate-commands --workflow draft-task
```

## Command Reference

### Basic Usage

```bash
handbook claude generate-commands [OPTIONS]
```

### Options

- `--dry-run` - Show what would be generated without creating files (default: false)
- `--force` - Overwrite existing generated commands (default: false)
- `--workflow=VALUE` - Generate for specific workflow (supports glob patterns)
- `--help, -h` - Print help information

### Examples

#### Preview Generation (Dry Run)

```bash
handbook claude generate-commands --dry-run
```

**Sample Output:**
```
Dry run mode - no files will be created

Would generate commands:
  ✓ create-reflection-note.md (from create-reflection-note.wf.md)
  ✓ update-blueprint.md (from update-blueprint.wf.md)
  ✓ analyze-dependencies.md (from analyze-dependencies.wf.md)

Total: 3 commands would be generated
```

#### Generate Missing Commands

```bash
handbook claude generate-commands
```

**Sample Output:**
```
Generating missing Claude commands...

Generated:
  ✓ Created: _generated/create-reflection-note.md
  ✓ Created: _generated/update-blueprint.md
  ✓ Created: _generated/analyze-dependencies.md

✓ Successfully generated 3 commands
✓ Registry updated

Run 'handbook claude integrate' to install the new commands
```

#### Force Regenerate All Commands

```bash
handbook claude generate-commands --force
```

**Sample Output:**
```
Force regenerating all commands...

Regenerated:
  ✓ Updated: _generated/create-task.md
  ✓ Updated: _generated/draft-task.md
  ✓ Updated: _generated/work-on-task.md
  ... (12 more)

✓ Successfully regenerated 15 commands
✓ Registry updated

Note: Custom commands in _custom/ were not affected
```

#### Generate Specific Workflow

```bash
# Single workflow
handbook claude generate-commands --workflow draft-task

# Using glob patterns
handbook claude generate-commands --workflow "create-*"
handbook claude generate-commands --workflow "*-task"
```

**Sample Output:**
```
Generating commands for workflow pattern: create-*

Generated:
  ✓ Created: _generated/create-task.md
  ✓ Created: _generated/create-feature-spec.md
  ✓ Created: _generated/create-reflection-note.md

✓ Successfully generated 3 commands matching pattern
```

## Understanding Command Generation

### Source Files

The generator looks for workflow instruction files:
- **Location**: `dev-handbook/workflow-instructions/*.wf.md`
- **Format**: Markdown files with `.wf.md` extension
- **Structure**: Must contain title and description

### Generated Files

Commands are created in the generated directory:
- **Location**: `dev-handbook/.integrations/claude/commands/_generated/`
- **Naming**: Matches workflow name (e.g., `draft-task.wf.md` → `draft-task.md`)
- **Content**: Standardized command template with workflow reference

### Command Template

Generated commands follow this structure:

```markdown
---
name: command-name
description: Extracted from workflow instruction
type: generated
source: workflow-instructions/command-name.wf.md
---

# Command Name

Execute the [Command Name workflow](/path/to/workflow.wf.md):

[Workflow description extracted from source]

## Usage

Run this command when you need to [purpose of workflow].

The workflow will guide you through:
- Key step 1
- Key step 2
- Key step 3

For detailed instructions, see the full workflow documentation.
```

### Registry Updates

After generation, the command registry is automatically updated:
- **File**: `dev-handbook/.integrations/claude/registry.json`
- **Format**: JSON with command metadata
- **Purpose**: Tracks all available commands for validation

## Common Use Cases

### Initial Setup

Setting up Claude integration for the first time:

```bash
# 1. Check what needs to be generated
handbook claude validate --check missing

# 2. Preview generation
handbook claude generate-commands --dry-run

# 3. Generate missing commands
handbook claude generate-commands

# 4. Verify generation
handbook claude list --type generated
```

### After Adding New Workflows

When new workflow instructions are added:

```bash
# 1. Create new workflow
vim dev-handbook/workflow-instructions/new-feature.wf.md

# 2. Generate command for it
handbook claude generate-commands --workflow new-feature

# 3. Install to Claude
handbook claude integrate
```

### Updating Existing Commands

When workflow instructions change:

```bash
# 1. See what would be updated
handbook claude generate-commands --dry-run --force

# 2. Regenerate specific workflow
handbook claude generate-commands --workflow updated-workflow --force

# 3. Or regenerate all
handbook claude generate-commands --force
```

### Batch Operations

Working with multiple workflows:

```bash
# Generate all task-related commands
handbook claude generate-commands --workflow "*task*"

# Generate all creation commands
handbook claude generate-commands --workflow "create-*"

# Regenerate everything except custom
handbook claude generate-commands --force
```

## Workflow Patterns

### Pattern Matching

The `--workflow` option supports glob patterns:

- `*` - Matches any characters
- `?` - Matches single character
- `[abc]` - Matches any character in set
- `{a,b}` - Matches alternatives

Examples:
```bash
# All workflows ending with -task
--workflow "*-task"

# All workflows starting with create-
--workflow "create-*"

# Specific alternatives
--workflow "{draft,create,update}-task"
```

### Generation Rules

1. **Skip Existing**: By default, existing commands are not overwritten
2. **Force Update**: Use `--force` to regenerate existing commands
3. **Custom Protected**: Commands in `_custom/` are never overwritten
4. **Source Required**: Workflow file must exist for generation

## Troubleshooting

### No Commands Generated

If no commands are generated:

1. Check workflow files exist with `.wf.md` extension
2. Verify workflow files are in correct directory
3. Ensure workflow files have proper markdown structure
4. Check file permissions allow reading

### Generation Errors

If generation fails:

1. Verify write permissions in _generated/ directory
2. Check for valid markdown in workflow files
3. Ensure no file system issues (disk space, etc.)
4. Run with debug: `HANDBOOK_DEBUG=1 handbook claude generate-commands`

### Pattern Not Matching

If workflow patterns don't match:

1. Check exact workflow file names
2. Remember patterns are case-sensitive
3. Use quotes around patterns with special characters
4. Try simpler patterns first

### Registry Update Failures

If registry updates fail:

1. Check registry.json file permissions
2. Verify JSON structure is valid
3. Ensure no concurrent modifications
4. Backup and regenerate if corrupted

## Best Practices

1. **Always Dry Run First**: Preview changes before generating
2. **Use Specific Patterns**: Target specific workflows when possible
3. **Regular Regeneration**: Keep generated commands up to date
4. **Validate After**: Run validation after generation
5. **Commit Changes**: Version control generated commands

## Integration with Other Commands

The generation workflow typically follows this pattern:

```bash
# 1. Check current state
handbook claude list

# 2. Validate coverage
handbook claude validate --check missing

# 3. Preview generation
handbook claude generate-commands --dry-run

# 4. Generate commands
handbook claude generate-commands

# 5. Verify generation
handbook claude list --type generated --verbose

# 6. Install to Claude
handbook claude integrate
```

## Advanced Usage

### Scripted Generation

For automated workflows:

```bash
#!/bin/bash
# Auto-generate after workflow changes

# Detect changed workflows
CHANGED=$(git diff --name-only HEAD^ HEAD | grep "\.wf\.md$")

if [ -n "$CHANGED" ]; then
  echo "Regenerating commands for changed workflows..."
  for workflow in $CHANGED; do
    name=$(basename "$workflow" .wf.md)
    handbook claude generate-commands --workflow "$name" --force
  done
  
  handbook claude integrate
fi
```

### Custom Templates

While the tool uses standard templates, you can post-process:

```bash
# Generate commands
handbook claude generate-commands

# Post-process with custom script
ruby customize_commands.rb _generated/*.md

# Validate and install
handbook claude validate
handbook claude integrate
```

## See Also

- [handbook claude list](./handbook-claude-list.md) - List available commands
- [handbook claude validate](./handbook-claude-validate.md) - Validate command coverage  
- [handbook claude integrate](./handbook-claude-integrate.md) - Install commands to Claude

---

*For the most up-to-date information, run `handbook claude generate-commands --help`*