# Claude Code Git Workflow Hooks

Intelligent hooks that guide developers toward semantic commits and proper tool usage in Claude Code.

## Installation

These hooks are automatically installed when you run:

```bash
coding-agent-tools integrate claude
```

The integration command will:
1. Copy hook files to `.claude/hooks/`
2. Set executable permissions on Ruby scripts
3. Merge settings into `.claude/settings.json`
4. Preserve any existing customizations

## Features

### 1. Semantic Commit Suggestions

When you use `git add`, the hook suggests using `git-commit` with intention instead:

```bash
# Instead of:
git add file.rb
git commit -m "fixed bug"

# The hook suggests:
git-commit file.rb --intention "fix"
# or
git-commit file.rb --message "fix: resolve authentication timeout"
```

### 2. Wrapper Tool Enforcement

The hook enforces the use of wrapper tools for git commands that have enhanced versions:

- `git-status` instead of `git status` (multi-repo awareness)
- `git-commit` instead of `git commit` (semantic commits)
- `git-log` instead of `git log` (enhanced formatting)
- And more...

### 3. Helpful Examples

The hook provides context-specific examples for each command, making it easy to learn the wrapper tools.

## Configuration

### Enabling/Disabling Features

Edit `.claude/hooks/wrapper-tools-config.json`:

```json
{
    "commit_workflow": {
        "enabled": true  // Set to false to disable git add suggestions
    },
    "enforcements": [
        {
            "name": "git",
            "enabled": true  // Set to false to disable git wrapper enforcement
        }
    ]
}
```

### Debug Mode

To enable debug logging for troubleshooting:

```json
{
    "debug": {
        "enabled": true,
        "log_file": "/tmp/wrapper-tools-hook.log",
        "save_individual_files": true
    }
}
```

### Customizing Suggestions

You can customize which commands are enforced or allowed by modifying:

1. **command_mappings**: Maps native commands to wrapper tools
2. **no_wrapper_available**: Commands that should be allowed without wrapper
3. **semantic_types**: Types of commits for suggestions

## Semantic Commit Types

The hook encourages these standard commit types:

- **feat**: A new feature
- **fix**: A bug fix  
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

## Benefits

### For Individual Developers
- Consistent, meaningful commit messages
- Faster commits with AI assistance
- Learn best practices through helpful suggestions

### For Teams
- Standardized commit format across the team
- Better change tracking and code review
- Automated changelog generation
- Improved collaboration

## Troubleshooting

### Hook Not Working

1. Check if hooks are executable:
   ```bash
   ls -la .claude/hooks/*.rb
   ```

2. Verify Ruby is installed:
   ```bash
   ruby --version
   ```

3. Check debug logs:
   ```bash
   tail -f /tmp/wrapper-tools-hook.log
   ```

### Disabling Temporarily

To temporarily disable hooks without removing them:

1. Rename the hook file:
   ```bash
   mv .claude/hooks/enforce-wrapper-tools.rb .claude/hooks/enforce-wrapper-tools.rb.disabled
   ```

2. Or edit settings.json to remove the hook:
   ```json
   {
       "hooks": {
           "PreToolUse": []
       }
   }
   ```

## Customization

### Adding Custom Enforcement Rules

You can add enforcement for other tools (docker, npm, etc.) by adding to the config:

```json
{
    "enforcements": [
        {
            "name": "docker",
            "enabled": true,
            "pattern": "\\bdocker\\s+(\\w+)",
            "wrapper_tools": {
                "docker-compose": "Multi-container orchestration"
            }
        }
    ]
}
```

### Modifying Suggestions

Edit the `commit_workflow` section to customize suggestion behavior:

```json
{
    "commit_workflow": {
        "suggestions": {
            "show_tips": true,
            "show_examples": true,
            "show_benefits": false  // Hide benefits section
        }
    }
}
```

## Permissions

The hooks respect Claude Code's permission system. Ensure your settings.json includes appropriate allow/deny rules for git commands.

## Updates

Hooks are distributed through the dev-handbook and updated when you run:

```bash
coding-agent-tools integrate claude --update
```

This will preserve your customizations while updating the core hook logic.

## Support

For issues or questions:
- Check the debug logs
- Review this documentation
- Report issues in the dev-taskflow repository

---

*These hooks are part of the Coding Agent Workflow Toolkit, designed to improve development workflows through intelligent automation and guidance.*