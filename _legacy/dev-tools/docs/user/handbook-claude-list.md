# Handbook Claude List User Guide

## Overview

The `handbook claude list` command provides a comprehensive view of all Claude Code commands and agents managed by the Coding Agent Workflow Toolkit. It displays the status, type, and location of commands, helping developers understand what's available and properly integrated with Claude Code.

### Key Features

- **Command Discovery**: View all available Claude commands and agents
- **Status Tracking**: See which commands are custom vs. generated
- **Type Filtering**: Filter by commands or agents
- **Format Options**: Output in text or JSON format
- **Verbose Mode**: Show detailed file paths and metadata

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
# List all Claude commands
handbook claude list

# Show detailed information
handbook claude list --verbose

# Filter by type
handbook claude list --type custom

# Output as JSON
handbook claude list --format json
```

## Command Reference

### Basic Usage

```bash
handbook claude list [OPTIONS]
```

### Options

- `--verbose` - Show detailed information including file paths (default: false)
- `--type=VALUE` - Filter by type: custom, generated, missing, or all (default: "all")
- `--format=VALUE` - Output format: text or json (default: "text")
- `--help, -h` - Print help information

### Examples

#### List All Commands

```bash
handbook claude list
```

**Sample Output:**
```
Claude Commands Status:

Custom Commands (6):
  ✓ commit                - Git commit with conventional commit format
  ✓ draft-tasks          - Create multiple tasks from specification
  ✓ load-project-context - Load project documentation and context
  ✓ plan-tasks           - Plan and break down complex tasks
  ✓ review-tasks         - Review and validate task specifications
  ✓ work-on-tasks        - Execute multiple tasks in sequence

Generated Commands (15):
  ✓ create-feature-spec  - Create a new feature specification
  ✓ create-migration     - Create a migration plan for changes
  ✓ create-task          - Create a new development task
  ✓ draft-task           - Draft a new task in the current release
  ✓ find-code            - Search for code patterns and implementations
  ... (10 more)

Total: 21 commands available
```

#### Show Verbose Information

```bash
handbook claude list --verbose
```

**Sample Output:**
```
Claude Commands Status:

Custom Commands (6):
  ✓ commit
    Path: dev-handbook/.integrations/claude/commands/_custom/commit.md
    Type: custom
    Description: Git commit with conventional commit format
    
  ✓ draft-tasks
    Path: dev-handbook/.integrations/claude/commands/_custom/draft-tasks.md
    Type: custom
    Description: Create multiple tasks from specification
    
  ... (4 more with full paths)

Generated Commands (15):
  ✓ create-feature-spec
    Path: dev-handbook/.integrations/claude/commands/_generated/create-feature-spec.md
    Type: generated
    Source: dev-handbook/workflow-instructions/create-feature-spec.wf.md
    Description: Create a new feature specification
    
  ... (14 more with full paths)

Registry: dev-handbook/.integrations/claude/registry.json
Total: 21 commands available
```

#### Filter by Type

```bash
# Show only custom commands
handbook claude list --type custom

# Show only generated commands
handbook claude list --type generated

# Show missing commands (if any)
handbook claude list --type missing
```

#### JSON Output

```bash
handbook claude list --format json
```

**Sample Output:**
```json
{
  "commands": {
    "custom": [
      {
        "name": "commit",
        "description": "Git commit with conventional commit format",
        "path": "dev-handbook/.integrations/claude/commands/_custom/commit.md",
        "type": "custom",
        "status": "available"
      }
    ],
    "generated": [
      {
        "name": "create-feature-spec",
        "description": "Create a new feature specification",
        "path": "dev-handbook/.integrations/claude/commands/_generated/create-feature-spec.md",
        "source": "dev-handbook/workflow-instructions/create-feature-spec.wf.md",
        "type": "generated",
        "status": "available"
      }
    ]
  },
  "summary": {
    "total": 21,
    "custom": 6,
    "generated": 15,
    "missing": 0
  }
}
```

## Understanding Command Types

### Custom Commands

Custom commands are hand-crafted with special behavior that cannot be auto-generated from workflow instructions. They typically:

- Have complex logic or multiple steps
- Require special formatting or validation
- Integrate multiple workflows or tools
- Provide enhanced user experience

Located in: `dev-handbook/.integrations/claude/commands/_custom/`

### Generated Commands

Generated commands are automatically created from workflow instruction files. They:

- Follow a consistent template structure
- Reference the source workflow file
- Are updated when workflows change
- Should not be manually edited

Located in: `dev-handbook/.integrations/claude/commands/_generated/`

### Missing Commands

Commands that should exist but haven't been generated yet. These indicate:

- New workflow instructions without corresponding commands
- Deleted commands that need regeneration
- Configuration issues with command generation

## Common Use Cases

### Verifying Installation

After installing or updating the toolkit:

```bash
# Check what's available
handbook claude list

# Verify all expected commands are present
handbook claude list --type missing
```

### Debugging Integration Issues

When commands aren't appearing in Claude:

```bash
# Get detailed information
handbook claude list --verbose

# Check specific command types
handbook claude list --type custom --verbose
handbook claude list --type generated --verbose

# Export for analysis
handbook claude list --format json > claude-commands.json
```

### Monitoring Command Coverage

As part of regular maintenance:

```bash
# Quick status check
handbook claude list | tail -n 1

# Detailed coverage report
handbook claude list --verbose | grep "Total:"

# Check for missing commands
handbook claude list --type missing
```

## Integration with Other Commands

The `list` command works seamlessly with other handbook claude subcommands:

```bash
# List commands, then validate
handbook claude list
handbook claude validate

# Check what's missing, then generate
handbook claude list --type missing
handbook claude generate-commands

# Full workflow
handbook claude list
handbook claude generate-commands --dry-run
handbook claude integrate
```

## Troubleshooting

### No Commands Listed

If no commands appear:

1. Verify the handbook is properly installed
2. Check the registry file exists: `dev-handbook/.integrations/claude/registry.json`
3. Run with verbose mode: `handbook claude list --verbose`
4. Check for error messages in debug output

### Incorrect Command Count

If the count seems wrong:

1. Check for duplicate entries: `handbook claude list --format json | jq '.commands'`
2. Verify registry is up to date: `handbook claude validate`
3. Regenerate if needed: `handbook claude generate-commands`

### Performance Issues

For large command sets:

1. Use type filtering to reduce output: `handbook claude list --type custom`
2. Use JSON format for scripting: `handbook claude list --format json`
3. Avoid verbose mode unless needed

## Best Practices

1. **Regular Checks**: Run `handbook claude list` after adding new workflows
2. **Use Filtering**: Filter by type when looking for specific commands
3. **Script Integration**: Use JSON format for automated checks
4. **Verbose for Debugging**: Use verbose mode when troubleshooting issues
5. **Monitor Missing**: Regularly check for missing commands to ensure coverage

## See Also

- [handbook claude validate](./handbook-claude-validate.md) - Validate command coverage
- [handbook claude generate-commands](./handbook-claude-generate-commands.md) - Generate missing commands
- [handbook claude integrate](./handbook-claude-integrate.md) - Install commands to Claude

---

*For the most up-to-date information, run `handbook claude list --help`*