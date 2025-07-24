---
id: v.0.3.0+task.77
status: in-progress
priority: medium
estimate: 3h
dependencies: []
---

# Add Skip Patterns Configuration to nav-path

## 0. Directory Audit ✅

_Command run:_

```bash
nav-path file .git && echo "Current: .git is blocked" || echo "Current: .git blocking works"
```

_Result excerpt:_

```
nav-path already has some hardcoded forbidden patterns including .git
Need to make this configurable via .coding-agent/path.yml
```

## Objective

Enhance the `nav-path` tool to use configurable skip patterns from `.coding-agent/path.yml` instead of hardcoded patterns. This will allow users to customize which directories and files should be skipped during path resolution, making the tool more flexible while maintaining sensible defaults including `.git` folder exclusion.

## Scope of Work

- Add configuration parameter to `.coding-agent/path.yml` for skip patterns
- Update nav-path implementation to read skip patterns from configuration
- Maintain backward compatibility with existing hardcoded patterns as defaults
- Include `.git` folder in default skip patterns configuration

### Deliverables

#### Create

- Configuration schema documentation for skip patterns in path.yml

#### Modify

- dev-tools nav-path implementation to read from .coding-agent/path.yml
- Default .coding-agent/path.yml template to include skip patterns
- Documentation for the new configuration option

## Implementation Plan

### Planning Steps

- [ ] Analyze current hardcoded skip patterns in nav-path implementation
  > TEST: Pattern Analysis Check
  > Type: Pre-condition Check
  > Assert: All current hardcoded patterns are identified
  > Command: grep -r "forbidden\|skip\|ignore" dev-tools/lib --include="*nav*"
- [ ] Design configuration schema for skip patterns in path.yml
- [ ] Plan backward compatibility approach for existing installations

### Execution Steps

- [ ] Add skip_patterns configuration section to default .coding-agent/path.yml
- [ ] Update nav-path implementation to read skip patterns from configuration
- [ ] Include .git as default skip pattern in configuration
- [ ] Test configuration loading and pattern matching functionality
  > TEST: Configuration Loading Validation
  > Type: Action Validation
  > Assert: Skip patterns are correctly loaded from path.yml and applied
  > Command: nav-path file .git 2>&1 | grep -q "forbidden pattern"
- [ ] Update documentation to describe new configuration option
- [ ] Ensure backward compatibility for installations without the config

## Acceptance Criteria

- [ ] AC 1: nav-path reads skip patterns from .coding-agent/path.yml configuration
- [ ] AC 2: Default configuration includes .git folder as skip pattern
- [ ] AC 3: Users can customize skip patterns by modifying path.yml
- [ ] AC 4: Backward compatibility maintained for existing installations
- [ ] AC 5: Documentation explains how to configure skip patterns

## Out of Scope

- ❌ Changing the overall nav-path functionality beyond skip patterns
- ❌ Adding complex regex pattern matching (stick to simple glob patterns)
- ❌ Creating GUI configuration interface

## References

- Current nav-path implementation in dev-tools
- Existing .coding-agent/path.yml configuration structure
- XDG configuration standards for the coding agent tools