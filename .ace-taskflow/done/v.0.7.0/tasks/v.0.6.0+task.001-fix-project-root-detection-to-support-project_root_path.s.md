---
id: v.0.6.0+task.001
status: done
priority: high
estimate: 30m
dependencies: []
---

# Fix project root detection to support PROJECT_ROOT_PATH environment variable

## Behavioral Context

**Issue**: CLI tools (like `create-path`) failed when run outside the project directory, even though mise.toml sets `PROJECT_ROOT_PATH` environment variable. The tools were checking for `PROJECT_ROOT` but mise was setting `PROJECT_ROOT_PATH`.

**Key Behavioral Requirements**:
- Tools must work from any directory when PROJECT_ROOT_PATH is set
- Maintain backward compatibility with PROJECT_ROOT variable
- Configuration files from .coding-agent must be loaded correctly

## Objective

Updated ProjectRootDetector to check both PROJECT_ROOT_PATH and PROJECT_ROOT environment variables for maximum compatibility.

## Scope of Work

- Updated project root detection logic to check both environment variables
- Maintained backward compatibility with existing PROJECT_ROOT usage
- Fixed tools to work from any directory when environment is configured

### Deliverables

#### Modify

- `.ace/tools/lib/ace_tools/atoms/project_root_detector.rb`:
  - Updated cache key to include both environment variables
  - Modified detect_root method to check PROJECT_ROOT_PATH first (mise.toml), then PROJECT_ROOT (backward compatibility)
  - Updated error messages to mention both variables

## Implementation Summary

### What Was Done

- **Problem Identification**: Discovered mismatch between mise.toml setting PROJECT_ROOT_PATH and Ruby code expecting PROJECT_ROOT
- **Investigation**: Found that mise.toml defines PROJECT_ROOT_PATH but ProjectRootDetector only checked PROJECT_ROOT
- **Solution**: Updated detection logic to check both variables, prioritizing PROJECT_ROOT_PATH
- **Validation**: Tested that tools work from outside project directory with both variables

### Technical Details

The detection priority is now:
1. PROJECT_ROOT_PATH (highest priority - used by mise.toml)
2. PROJECT_ROOT (backward compatibility)
3. Special directory detection (.ace/* directories)
4. Standard marker-based traversal (.git, Gemfile, etc.)

### Testing/Validation

```bash
# Test with PROJECT_ROOT_PATH (set by mise)
cd /tmp && create-path file --title "test.md" --content "test"
# Result: Success

# Test backward compatibility with PROJECT_ROOT
cd /tmp && unset PROJECT_ROOT_PATH && PROJECT_ROOT=/Users/mc/Ps/ace-meta create-path file --title "test2.md" --content "test"
# Result: Success

# Test config loading from outside project
cd /tmp && create-path docs-new --title "Test Documentation"
# Result: Success - created file in correct location
```

**Results**: All tests passed. Tools now work correctly from any directory when environment variables are set.

## References

- Issue identified in: `/Users/mc/Ps/ace-meta/.ace/taskflow/current/v.0.6.0-ace-migration/ideas/2025-09-16-01-03-issue-with-project-root-path.md`
- Related configuration: `.mise.toml` sets PROJECT_ROOT_PATH
- Shell scripts also use PROJECT_ROOT_PATH in various codemods