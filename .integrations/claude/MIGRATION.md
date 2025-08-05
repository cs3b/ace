# Migrating from claude-integrate Script

This guide helps you migrate from the legacy `claude-integrate` script to the new unified `handbook claude` commands.

## What's Changed

The standalone `claude-integrate` script has been replaced with unified `handbook claude` commands that provide:

- Better integration with the overall toolkit
- More robust error handling
- Additional features like validation and dry-run
- Consistent command-line interface
- Automatic command generation from workflows

## Quick Migration

If you just want to get started quickly:

```bash
# Old way
./bin/claude-integrate

# New way
handbook claude integrate
```

## Detailed Migration Steps

### 1. Update to Latest dev-tools

Ensure you have the latest version of dev-tools installed:

```bash
# Update the gem
gem update dev-tools

# Or if using bundler
bundle update dev-tools

# Verify the handbook CLI is available
handbook --version
```

### 2. Remove Old Script

The `bin/claude-integrate` script is no longer needed:

```bash
# Remove the old script
rm bin/claude-integrate

# If you have any custom scripts that call it, update them
```

### 3. Update Your Workflow

Replace any references to the old script with the new commands:

#### Installation
```bash
# Old
./bin/claude-integrate

# New
handbook claude integrate
```

#### Manual Command Generation
```bash
# Old (not available)
# Manual process was required

# New
handbook claude generate-commands
```

#### Validation
```bash
# Old (not available)
# No validation was provided

# New
handbook claude validate
```

## Command Mapping

| Old Method | New Command | Notes |
|------------|-------------|-------|
| `./bin/claude-integrate` | `handbook claude integrate` | Full integration workflow |
| Manual file copying | `handbook claude generate-commands` | Automatic generation |
| Manual verification | `handbook claude validate` | Built-in validation |
| N/A | `handbook claude list` | New feature: list all commands |
| N/A | `handbook claude update-registry` | New feature: registry management |

## Feature Comparison

### Old System (claude-integrate script)

- Single monolithic script
- No validation or verification
- Manual command updates required
- No dry-run capability
- Limited error handling
- Ruby script that could fail silently

### New System (handbook claude commands)

- Modular subcommands for specific tasks
- Built-in validation and coverage checking
- Automatic command generation from workflows
- Dry-run options for safe testing
- Comprehensive error handling and reporting
- Integrated with the broader toolkit

## Migration Scenarios

### Scenario 1: Regular User

If you regularly ran `claude-integrate` to update commands:

1. Run `handbook claude integrate` instead
2. Optionally add `handbook claude validate` to your routine
3. No other changes needed

### Scenario 2: Automated Scripts

If you have scripts that call `claude-integrate`:

```bash
# Old script
#!/bin/bash
cd /path/to/project
./bin/claude-integrate

# New script
#!/bin/bash
cd /path/to/project
handbook claude integrate
```

### Scenario 3: CI/CD Integration

For continuous integration:

```yaml
# Old CI configuration
- name: Install Claude commands
  run: ./bin/claude-integrate

# New CI configuration
- name: Install Claude commands
  run: |
    handbook claude validate --strict
    handbook claude integrate
```

## Handling Issues

### Command Not Found

If `handbook` command is not found:

1. Ensure dev-tools gem is installed: `gem install dev-tools`
2. Check your PATH includes the gem bin directory
3. Try using bundle exec: `bundle exec handbook claude integrate`

### Permission Errors

The new system handles permissions better, but if you encounter issues:

```bash
# Check Claude config directory permissions
ls -la ~/.config/claude/

# The new system will create directories as needed
handbook claude integrate --force
```

### Missing Commands

If some commands are missing after migration:

```bash
# List what's available
handbook claude list --verbose

# Validate coverage
handbook claude validate

# Generate any missing commands
handbook claude generate-commands

# Reinstall everything
handbook claude integrate --force
```

## Benefits of Migration

### Immediate Benefits

1. **Reliability**: Better error handling and reporting
2. **Visibility**: See what's being installed with `--dry-run`
3. **Validation**: Ensure all workflows have commands
4. **Consistency**: Unified CLI interface

### Long-term Benefits

1. **Maintainability**: Easier to update and extend
2. **Integration**: Works with other handbook commands
3. **Documentation**: Better help and examples
4. **Testing**: Can be tested in CI/CD pipelines

## Rollback Plan

If you need to temporarily rollback (not recommended):

1. The old `bin/claude-integrate` script can coexist with new commands
2. Both systems install to the same Claude directory
3. The new system is backward compatible

However, we strongly recommend completing the migration as the old script will be removed in future versions.

## FAQ

### Q: Do I need to uninstall old commands?

A: No, the new system will overwrite old commands automatically.

### Q: Will my custom commands be affected?

A: No, custom commands in `_custom/` are preserved and managed the same way.

### Q: Can I still manually edit commands?

A: Yes, custom commands can still be manually edited. Generated commands should not be edited as they will be overwritten.

### Q: What about the Ruby implementation?

A: The Ruby implementation (`ClaudeCommandsInstaller`) is still used internally by the new CLI commands. The change is in how you invoke it.

## Getting Help

If you encounter issues during migration:

1. Run with debug output: `HANDBOOK_DEBUG=1 handbook claude integrate`
2. Check the [main integration guide](README.md)
3. Review the [troubleshooting section](README.md#troubleshooting)
4. Create an issue with the debug output

## Next Steps

After successful migration:

1. Remove the old `bin/claude-integrate` script
2. Update any documentation referencing the old script
3. Add `handbook claude validate` to your regular workflow
4. Explore new features like `handbook claude list --verbose`

Welcome to the new integrated Claude command system!