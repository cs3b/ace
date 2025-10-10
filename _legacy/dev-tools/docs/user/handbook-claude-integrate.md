# Handbook Claude Integrate User Guide

## Overview

The `handbook claude integrate` command is the main installation tool that sets up Claude Code commands and agents from the Coding Agent Workflow Toolkit. It performs a complete integration workflow including validation, generation of missing commands, and installation to Claude's configuration directory.

### Key Features

- **One-Command Setup**: Complete Claude integration in a single command
- **Automatic Generation**: Creates any missing commands before installing
- **Safe Installation**: Backup options and dry-run mode for safety
- **Force Reinstall**: Update existing installations when needed
- **Verbose Feedback**: Detailed progress reporting during installation
- **Cross-Platform**: Works on macOS, Linux, and Windows (WSL)

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
# Standard integration
handbook claude integrate

# Preview what would be installed
handbook claude integrate --dry-run

# Force reinstall with backup
handbook claude integrate --force --backup

# Verbose installation
handbook claude integrate --verbose
```

## Command Reference

### Basic Usage

```bash
handbook claude integrate [OPTIONS]
```

### Options

- `--dry-run` - Show what would be installed without modifying files (default: false)
- `--verbose` - Show detailed installation information (default: false)
- `--backup` - Backup existing installation before installing (default: false)
- `--force` - Overwrite existing files without prompting (default: false)
- `--source=VALUE` - Custom source directory for commands
- `--help, -h` - Print help information

### Examples

#### Standard Integration

```bash
handbook claude integrate
```

**Sample Output:**
```
Starting Claude Code integration...

✓ Validation passed
✓ Generated 3 missing commands
✓ Installing commands to ~/.config/claude/commands/

Installed:
  ✓ commit.md
  ✓ draft-tasks.md
  ✓ create-task.md
  ... (18 more)

✓ Successfully installed 21 commands
✓ Claude Code integration complete!

Restart Claude Code to see the new commands.
```

#### Dry Run Mode

```bash
handbook claude integrate --dry-run
```

**Sample Output:**
```
Dry run mode - no files will be modified

Would perform:
  ✓ Generate 2 missing commands
  ✓ Install 21 commands to ~/.config/claude/commands/
  ✓ Create 0 new directories

Commands to install:
  - commit.md (custom)
  - draft-tasks.md (custom)
  - create-task.md (generated)
  ... (18 more)

No changes made. Remove --dry-run to perform installation.
```

#### Force Reinstall with Backup

```bash
handbook claude integrate --force --backup
```

**Sample Output:**
```
Starting Claude Code integration...

✓ Creating backup at ~/.config/claude/commands.backup.20240115-143022/
✓ Backed up 19 existing files
✓ Validation passed
✓ Force installing all commands...

Updated:
  ✓ commit.md (updated)
  ✓ draft-tasks.md (updated)
  ✓ create-task.md (updated)
  ... (18 more)

✓ Successfully installed 21 commands
✓ Previous installation backed up to: ~/.config/claude/commands.backup.20240115-143022/
```

#### Verbose Installation

```bash
handbook claude integrate --verbose
```

**Sample Output:**
```
Starting Claude Code integration...

[INFO] Claude directory: ~/.config/claude/commands/
[INFO] Source directory: dev-handbook/.integrations/claude/commands/
[INFO] Registry file: dev-handbook/.integrations/claude/registry.json

[VALIDATE] Checking command coverage...
[VALIDATE] ✓ All workflows have commands

[GENERATE] Checking for missing commands...
[GENERATE] ✓ All commands already exist

[INSTALL] Installing custom commands...
[INSTALL] ✓ Copying: _custom/commit.md → ~/.config/claude/commands/commit.md
[INSTALL] ✓ Copying: _custom/draft-tasks.md → ~/.config/claude/commands/draft-tasks.md
... (4 more)

[INSTALL] Installing generated commands...
[INSTALL] ✓ Copying: _generated/create-task.md → ~/.config/claude/commands/create-task.md
[INSTALL] ✓ Copying: _generated/draft-task.md → ~/.config/claude/commands/draft-task.md
... (13 more)

[SUMMARY] Installation complete:
  - Custom commands: 6
  - Generated commands: 15
  - Total installed: 21
  - Errors: 0

✓ Claude Code integration complete!
```

## Installation Process

### Step 1: Validation

The integration first validates the current state:
- Checks command coverage
- Verifies registry integrity
- Ensures source files exist

### Step 2: Generation

If missing commands are detected:
- Automatically generates them from workflows
- Updates the command registry
- Prepares for installation

### Step 3: Directory Setup

Prepares the Claude configuration:
- Locates Claude config directory
- Creates commands directory if needed
- Handles platform-specific paths

### Step 4: Installation

Copies commands to Claude:
- Installs custom commands from `_custom/`
- Installs generated commands from `_generated/`
- Preserves file permissions and structure

### Step 5: Verification

Confirms successful installation:
- Verifies all files copied correctly
- Reports any errors or warnings
- Provides restart instructions

## Platform-Specific Paths

### macOS
```
~/.config/claude/commands/
```

### Linux
```
~/.config/claude/commands/
```

### Windows (WSL)
```
~/.config/claude/commands/
```

### Custom Paths

Override with environment variable:
```bash
export CLAUDE_COMMANDS_DIR=/custom/path/to/commands
handbook claude integrate
```

## Common Use Cases

### First-Time Setup

Initial Claude integration:

```bash
# 1. Check prerequisites
handbook claude list

# 2. Run integration
handbook claude integrate

# 3. Restart Claude Code
# 4. Verify commands appear in Claude
```

### Updating After Changes

After modifying workflows:

```bash
# 1. Validate changes
handbook claude validate

# 2. Re-integrate
handbook claude integrate

# 3. Only changed files are updated
```

### Complete Reinstallation

For troubleshooting or updates:

```bash
# 1. Backup current installation
handbook claude integrate --backup --dry-run

# 2. Force reinstall
handbook claude integrate --force --backup

# 3. Verify in Claude Code
```

### CI/CD Integration

Automated installation:

```bash
#!/bin/bash
# ci-install-claude.sh

# Validate first
if ! handbook claude validate --strict; then
  echo "Validation failed!"
  exit 1
fi

# Install without prompts
handbook claude integrate --force

# Verify installation
if [ -d "$HOME/.config/claude/commands" ]; then
  echo "Installation successful"
  ls -la "$HOME/.config/claude/commands" | wc -l
else
  echo "Installation failed!"
  exit 1
fi
```

## Backup and Recovery

### Automatic Backups

When using `--backup`:
- Creates timestamped backup directory
- Copies all existing commands
- Preserves directory structure
- Allows easy rollback

### Manual Backup

```bash
# Backup before integration
cp -r ~/.config/claude/commands ~/.config/claude/commands.backup

# Integrate
handbook claude integrate

# Restore if needed
rm -rf ~/.config/claude/commands
mv ~/.config/claude/commands.backup ~/.config/claude/commands
```

### Backup Naming

Backups follow the pattern:
```
~/.config/claude/commands.backup.YYYYMMDD-HHMMSS/
```

## Troubleshooting

### Commands Not Appearing in Claude

If commands don't show up after integration:

1. **Restart Claude Code** - Required for Claude to detect new commands
2. **Check Installation Path** - Verify files exist in `~/.config/claude/commands/`
3. **Verify Permissions** - Ensure Claude can read the command files
4. **Check Claude Version** - Ensure you have a compatible version

### Permission Denied Errors

If you get permission errors:

```bash
# Check directory permissions
ls -la ~/.config/claude/

# Fix permissions if needed
chmod 755 ~/.config/claude
chmod 755 ~/.config/claude/commands
chmod 644 ~/.config/claude/commands/*.md
```

### Installation Path Not Found

If Claude directory doesn't exist:

```bash
# Create directory structure
mkdir -p ~/.config/claude/commands

# Retry integration
handbook claude integrate
```

### Partial Installation

If some commands fail to install:

1. Run with verbose mode: `handbook claude integrate --verbose`
2. Check specific error messages
3. Verify source files exist
4. Try force mode: `handbook claude integrate --force`

## Best Practices

1. **Always Backup**: Use `--backup` when updating existing installations
2. **Dry Run First**: Preview changes with `--dry-run` before installing
3. **Restart Claude**: Always restart Claude Code after integration
4. **Regular Updates**: Re-integrate after workflow changes
5. **Version Control**: Commit registry.json after successful integration

## Advanced Configuration

### Custom Source Directory

Install from alternative location:

```bash
handbook claude integrate --source /path/to/custom/commands
```

### Environment Variables

Configure behavior with environment variables:

```bash
# Custom Claude directory
export CLAUDE_COMMANDS_DIR=/custom/claude/commands

# Enable debug output
export HANDBOOK_DEBUG=1

# Run integration
handbook claude integrate
```

### Selective Installation

While the tool installs all commands, you can post-process:

```bash
# Install everything
handbook claude integrate

# Remove unwanted commands
rm ~/.config/claude/commands/unwanted-*.md
```

## Integration Workflow

The complete workflow for Claude integration:

```bash
# 1. Check current state
handbook claude list

# 2. Validate coverage
handbook claude validate

# 3. Preview integration
handbook claude integrate --dry-run

# 4. Backup and integrate
handbook claude integrate --backup

# 5. Restart Claude Code

# 6. Verify in Claude
# Commands should appear in Claude's command palette
```

## See Also

- [handbook claude list](./handbook-claude-list.md) - List available commands
- [handbook claude validate](./handbook-claude-validate.md) - Validate command coverage
- [handbook claude generate-commands](./handbook-claude-generate-commands.md) - Generate missing commands

---

*For the most up-to-date information, run `handbook claude integrate --help`*