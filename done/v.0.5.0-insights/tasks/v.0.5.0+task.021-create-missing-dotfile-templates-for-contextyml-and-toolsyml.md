---
id: v.0.5.0+task.021
status: done
priority: medium
estimate: 30m
dependencies: []
---

# Create missing dotfile templates for context.yml and tools.yml

## Behavioral Context

**Issue**: The `install-dotfiles` command was unable to install complete configuration templates because `context.yml` and `tools.yml` templates were missing from the source directory, despite being essential configuration files for the Coding Agent Tools.

**Key Behavioral Requirements**:
- The `install-dotfiles` command should be able to install all necessary configuration files
- Templates should provide sensible defaults with clear documentation
- New projects should get a complete set of configuration files

## Objective

Create missing template files for `context.yml` and `tools.yml` in the dotfiles template directory to ensure the `install-dotfiles` command can provide a complete configuration set for new projects.

## Scope of Work

- Created template for `context.yml` configuration file
- Created template for `tools.yml` configuration file  
- Tested installation with new templates
- Verified all 7 configuration files are now recognized

### Deliverables

#### Create
- `dev-handbook/.meta/tpl/dotfiles/context.yml` - Template for context tool configuration
- `dev-handbook/.meta/tpl/dotfiles/tools.yml` - Template for tools listing configuration

#### Modify
- None - only new files were created

#### Delete
- None

## Implementation Summary

### What Was Done

- **Problem Identification**: User reported that `install-dotfiles` was only recognizing 5 files instead of 7
- **Investigation**: Found that `context.yml` and `tools.yml` existed in `.coding-agent/` but had no corresponding templates in `dev-handbook/.meta/tpl/dotfiles/`
- **Solution**: Created generic template versions of both missing configuration files based on the existing customized versions
- **Validation**: Tested the `install-dotfiles` command to confirm it now recognizes all 7 configuration files

### Technical Details

**context.yml template**:
- Provides configuration for the `context` tool with preset definitions
- Includes examples for project, dev, and essentials presets
- Documents the template format with examples of file embedding, command output, conditional includes, and file globbing
- Includes security settings for restricting template and output paths

**tools.yml template**:
- Provides configuration for the `coding_agent_tools all` command
- Includes blacklist patterns for excluding certain tools
- Defines tool categories with descriptions and pattern matching
- Contains placeholder sections for future features (aliases, default options)
- Includes comprehensive documentation in comments

### Testing/Validation

```bash
# Test dry-run to see what would be installed
coding_agent_tools install-dotfiles --dry-run

# Test actual installation in clean environment
mv .coding-agent .coding-agent.backup
coding_agent_tools install-dotfiles
# Result: Successfully installed all 7 files

# Restore original configuration
rm -rf .coding-agent && mv .coding-agent.backup .coding-agent
```

**Results**: The `install-dotfiles` command now correctly identifies and can install all 7 configuration files:
- context.yml ✓
- create-path.yml ✓
- lint.yml ✓
- path.yml ✓
- task-manager.yml ✓
- tools.yml ✓
- tree.yml ✓

## References

- Original issue: User investigation of missing dotfiles
- Template directory: `dev-handbook/.meta/tpl/dotfiles/`
- Install command source: `dev-tools/lib/coding_agent_tools/cli/commands/install_dotfiles.rb`
- Related documentation: Context tool docs at `dev-tools/docs/exe/context.md`