# Claude Code Integration - Quick Start Guide

Get started with Claude Code integration in 5 minutes using the Coding Agent Workflow Toolkit.

## Quick Start

```bash
# 1. Ensure dev-tools is available (via git submodule)
cd handbook-meta/dev-tools
bundle install

# 2. Install Claude commands (one command does it all!)
bundle exec handbook claude integrate

# 3. Restart Claude Code to see new commands
```

That's it! You now have 20+ AI workflow commands available in Claude Code.

## What You Get

After integration, Claude Code will have access to:

- **Workflow Commands**: Execute any workflow instruction directly from Claude
- **Smart Git Integration**: Enhanced commit messages and repository management  
- **Task Management**: Create, plan, and execute development tasks
- **Project Context**: Load and manage project documentation

## First-Time Setup

### Prerequisites

- Ruby 3.x or higher
- Git installed and configured
- Claude Code installed
- The handbook-meta repository cloned with submodules:
  ```bash
  git clone --recursive [repository-url]
  # Or if already cloned:
  git submodule update --init --recursive
  ```

### Installation Steps

1. **Navigate to dev-tools directory**:
   ```bash
   cd handbook-meta/dev-tools
   ```

2. **Install dependencies**:
   ```bash
   bundle install
   ```

3. **Run integration**:
   ```bash
   bundle exec handbook claude integrate
   ```

4. **Restart Claude Code** to load the new commands

5. **Verify installation**:
   ```bash
   bundle exec handbook claude list
   ```

## Maintenance Workflow

Keep your Claude commands up to date as workflows evolve:

```bash
# Weekly maintenance routine
cd handbook-meta/dev-tools

# 1. Check for issues
bundle exec handbook claude validate

# 2. Update if needed
bundle exec handbook claude integrate

# 3. Restart Claude Code
```

### After Workflow Changes

When you add or modify workflow instruction files:

```bash
# 1. Validate coverage
bundle exec handbook claude validate --check missing

# 2. Re-integrate (generates missing commands automatically)
bundle exec handbook claude integrate

# 3. Restart Claude Code
```

### Regular Health Check

```bash
# Monthly maintenance script
#!/bin/bash
cd handbook-meta/dev-tools

echo "Claude Integration Health Check"
echo "==============================="

# Check current status
bundle exec handbook claude list | tail -n 1

# Validate all checks
bundle exec handbook claude validate

# Check for outdated commands
bundle exec handbook claude validate --check outdated

echo "Health check complete!"
```

## Common Tasks

### Quick Status Check

```bash
# See summary
bundle exec handbook claude list | tail -n 1
# Output: "Total: 21 commands available"

# Check for issues
bundle exec handbook claude validate
```

### Force Update Everything

```bash
# Complete refresh (with backup)
bundle exec handbook claude integrate --force --backup
```

### Debug Integration Issues

```bash
# Verbose output
bundle exec handbook claude integrate --verbose

# With debug logging
HANDBOOK_DEBUG=1 bundle exec handbook claude integrate
```

## Next Steps

For detailed documentation on specific features:

- **[handbook claude list](../../../dev-tools/docs/user/handbook-claude-list.md)** - View and filter available commands
- **[handbook claude validate](../../../dev-tools/docs/user/handbook-claude-validate.md)** - Validate command coverage and integrity
- **[handbook claude generate-commands](../../../dev-tools/docs/user/handbook-claude-generate-commands.md)** - Generate commands from workflows
- **[handbook claude integrate](../../../dev-tools/docs/user/handbook-claude-integrate.md)** - Complete integration reference

## Quick Reference

| Task | Command |
|------|---------|
| Install everything | `bundle exec handbook claude integrate` |
| Check status | `bundle exec handbook claude list` |
| Validate setup | `bundle exec handbook claude validate` |
| Update after changes | `bundle exec handbook claude integrate` |
| Force reinstall | `bundle exec handbook claude integrate --force` |

## Troubleshooting

### Commands not appearing in Claude?

1. **Restart Claude Code** (always required after installation)
2. **Verify installation**: `ls ~/.config/claude/commands/`
3. **Check permissions**: `ls -la ~/.config/claude/`

### Quick Fixes

```bash
# Permission issues
chmod -R 755 ~/.config/claude

# Installation issues
bundle exec handbook claude integrate --verbose

# Missing commands
bundle exec handbook claude validate --check missing
bundle exec handbook claude integrate
```

### Need Help?

- Use `--help` with any command for options
- Check the detailed guides linked in Next Steps
- Enable debug mode: `HANDBOOK_DEBUG=1`

---

*Remember: The handbook-meta repository uses git submodules. Always work from within the dev-tools directory and use `bundle exec` to run commands.*