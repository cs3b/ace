# Claude Code Integration

The Coding Agent Workflow Toolkit provides unified CLI commands for managing Claude Code integration.

## Quick Start

```bash
# Install Claude commands
handbook claude integrate

# Check status
handbook claude list
handbook claude validate
```

## Overview

The handbook CLI provides a unified interface for managing Claude Code commands and agents, providing a robust, integrated solution for Claude Code integration.

## Features

- **Automatic Command Generation**: Creates commands from workflow instructions
- **Smart Categorization**: Separates custom and generated commands
- **Coverage Validation**: Ensures all workflows have corresponding commands
- **Agent Management**: Handles both commands and agent configurations

## Installation

### Prerequisites

- Ruby 3.x or higher
- Git installed and configured
- Access to the handbook CLI (via dev-tools)

### Setup Steps

1. **Install the dev-tools gem** (if not already installed):
   ```bash
   gem install dev-tools
   ```

2. **Run the integration command**:
   ```bash
   handbook claude integrate
   ```

   This will:
   - Generate missing commands from workflow instructions
   - Update the command registry
   - Install commands and agents into Claude Code

3. **Verify the installation**:
   ```bash
   handbook claude list --verbose
   handbook claude validate
   ```

## Command Reference

### handbook claude list

List all available Claude commands and their status.

**Options:**
- `--verbose`: Show detailed information including file paths
- `--type [command|agent]`: Filter by type

**Examples:**
```bash
# List all commands
handbook claude list

# Show detailed information
handbook claude list --verbose

# List only agents
handbook claude list --type agent
```

### handbook claude validate

Validate command coverage and check for issues.

**Options:**
- `--strict`: Fail on any validation warnings
- `--fix`: Attempt to fix issues automatically

**Examples:**
```bash
# Basic validation
handbook claude validate

# Strict validation for CI
handbook claude validate --strict

# Auto-fix issues
handbook claude validate --fix
```

### handbook claude generate-commands

Generate missing commands from workflow instructions.

**Options:**
- `--dry-run`: Preview changes without writing files
- `--force`: Overwrite existing generated commands

**Examples:**
```bash
# Preview what would be generated
handbook claude generate-commands --dry-run

# Generate missing commands
handbook claude generate-commands

# Regenerate all commands
handbook claude generate-commands --force
```

### handbook claude update-registry

Update the command registry JSON file.

**Options:**
- `--backup`: Create backup before updating
- `--validate`: Validate JSON structure after update

**Examples:**
```bash
# Update registry with backup
handbook claude update-registry --backup

# Update and validate
handbook claude update-registry --validate
```

### handbook claude integrate

Run the complete integration workflow.

**Options:**
- `--force`: Force reinstallation of all components
- `--skip-validation`: Skip validation checks

**Examples:**
```bash
# Standard integration
handbook claude integrate

# Force reinstall everything
handbook claude integrate --force

# Quick integration without validation
handbook claude integrate --skip-validation
```

## Command Organization

Commands are organized in two directories within `.integrations/claude/commands/`:

### _custom/

Hand-crafted commands with special behavior that cannot be auto-generated:

- **commit.md**: Intelligent git commit with conventional commit support
- **draft-tasks.md**: Multi-task creation from specifications
- **load-project-context.md**: Load project documentation and context
- **plan-tasks.md**: Task planning and breakdown
- **review-tasks.md**: Task review and validation
- **work-on-tasks.md**: Execute multiple tasks in sequence

### _generated/

Auto-generated commands from workflow instructions:

- Standard workflow references with consistent format
- Automatically updated when workflows change
- Should not be manually edited

## Common Workflows

### First-time Setup

```bash
# 1. Check what's available
handbook claude list

# 2. Generate missing commands
handbook claude generate-commands

# 3. Install everything
handbook claude integrate
```

### Regular Maintenance

After adding new workflow instructions:

```bash
# Run the maintenance workflow
handbook claude validate
handbook claude generate-commands
handbook claude integrate
```

### Troubleshooting Installation

If commands aren't appearing in Claude:

```bash
# 1. Validate the setup
handbook claude validate --strict

# 2. Check Claude's command directory
ls ~/.config/claude/commands/

# 3. Force reinstall
handbook claude integrate --force
```

## Configuration

### Environment Variables

- `CLAUDE_COMMANDS_DIR`: Override default Claude commands directory
- `HANDBOOK_DEBUG`: Enable debug output for troubleshooting

### Configuration File

The integration uses `.integrations/claude/registry.json` to track commands and agents. This file is automatically maintained by the CLI.

## Advanced Usage

### Creating Custom Commands

1. Create a new markdown file in `_custom/`
2. Follow the command template structure
3. Run `handbook claude update-registry` to register
4. Run `handbook claude integrate` to install

### Extending the Integration

See the [Developer Guide](../../../dev-tools/docs/development/claude-integration.md) for information on:
- Adding new subcommands
- Customizing command generation
- Extending validation rules

## Troubleshooting

### Commands Not Appearing

1. Verify Claude is installed and configured
2. Check file permissions in Claude's config directory
3. Run with debug output: `HANDBOOK_DEBUG=1 handbook claude integrate`

### Validation Failures

1. Review validation output for specific issues
2. Check workflow instruction format
3. Ensure all dependencies are installed

### Generation Issues

1. Verify workflow instructions follow the expected format
2. Check for naming conflicts with custom commands
3. Review generation output for errors

## Best Practices

1. **Regular Validation**: Run `handbook claude validate` before major changes
2. **Backup Registry**: Use `--backup` when updating registry
3. **Test Changes**: Use `--dry-run` to preview changes
4. **Document Custom Commands**: Include clear descriptions and examples
5. **Version Control**: Commit registry.json changes with command updates

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the [Developer Guide](../../../dev-tools/docs/development/claude-integration.md)
3. Check existing GitHub issues
4. Create a new issue with debug output

## Related Documentation

- [Command Structure](commands/README.md) - Detailed command organization
- [Developer Guide](../../../dev-tools/docs/development/claude-integration.md) - For contributors
- [Workflow Instructions](../../workflow-instructions/) - Source for generated commands