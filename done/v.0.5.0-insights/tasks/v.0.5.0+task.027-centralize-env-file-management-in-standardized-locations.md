---
id: v.0.5.0+task.027
status: done
priority: high
estimate: 2h
dependencies: []
---

# Centralize .env file management in standardized locations

## Behavioral Context

**Issue**: The dev-tools were searching for .env files in multiple directories, making it difficult to manage API keys consistently across projects. Need a standardized approach for global and project-specific environment configurations.

**Key Behavioral Requirements**:
- Single global configuration in `~/.coding-agent/.env`
- Project-specific overrides in `<project_root>/.coding-agent/.env`
- No backward compatibility with root `.env` files (force migration)
- Clear deprecation warnings for old locations
- Standardized template for new installations

## Objective

Implement centralized .env file management that allows global configuration with project-specific overrides, forcing migration to the new standardized locations.

## Scope of Work

- Updated EnvReader atom to support new standardized paths only
- Modified APICredentials to use new search logic
- Created .env.sample template in dev-handbook dotfiles
- Added deprecation warnings for old .env locations
- Updated .gitignore to exclude new locations

### Deliverables

#### Create
- `dev-handbook/.meta/tpl/dotfiles/.env.sample` - Comprehensive environment template

#### Modify
- `dev-tools/lib/coding_agent_tools/atoms/env_reader.rb` - Added standardized env loading methods
- `dev-tools/lib/coding_agent_tools/molecules/api_credentials.rb` - Updated to use new search logic
- `.gitignore` - Added .coding-agent/.env exclusion

#### Delete
- None (old .env files remain but trigger deprecation warnings)

## Implementation Summary

### What Was Done

- **Problem Identification**: Tools were loading .env files from current directory and walking up parent directories, making configuration management inconsistent
- **Investigation**: Found EnvReader and APICredentials were the core components handling env loading
- **Solution**: Implemented standardized paths with priority order:
  1. Project-specific: `<project_root>/.coding-agent/.env`
  2. Global: `~/.coding-agent/.env`
  3. No fallback to root `.env` (shows deprecation warning)
- **Validation**: All tests pass, rubocop linting clean, manual testing confirms new loading works

### Technical Details

**EnvReader Changes**:
- Added `load_standardized_env` method for new path loading
- Added `find_standardized_env_path` to locate env files
- Shows deprecation warning if old .env found in project root

**APICredentials Changes**:
- Updated `find_standardized_env_file` to use new locations
- Added `find_project_root` to detect project boundaries (.git, Gemfile, package.json, .coding-agent)
- Properly chains project-specific and global configurations

**Template Creation**:
- Comprehensive .env.sample with all API keys and settings
- Clear documentation for each variable
- Instructions for installation locations
- Lives in dev-handbook/.meta/tpl/dotfiles/ for installation with other dotfiles

### Testing/Validation

```bash
# Ran full test suite
bundle exec rspec
# Result: 2660 examples, 0 failures, 5 pending

# Tested new env loading
ruby -I lib -e "require 'coding_agent_tools/atoms/env_reader'; ..."
# Confirmed loading from .coding-agent/.env

# Linting passed
bundle exec rubocop -a [modified files]
# All issues auto-corrected
```

**Results**: New env loading works correctly, deprecation warnings display, all tests pass

## References

- Migration performed: Moved existing .env to .coding-agent/.env
- Documentation: Created comprehensive .env.sample template
- Follow-up needed: Update installation documentation to reference new .env locations