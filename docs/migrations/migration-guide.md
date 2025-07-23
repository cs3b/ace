# Migration Guide: Higher-Order Tools for AI Agents

## Overview

This guide documents the migration from primitive command sequences to higher-order tools, designed specifically for AI agents working with the Coding Agent Tools (CAT) project. The migration emphasizes complete operations over primitive building blocks.

## Migration Philosophy

### From Primitive to Higher-Order

The migration follows this hierarchy:

1. **Highest Priority**: Complete workflow operations (`nav-path task-new`, `code-review`)
2. **High Priority**: Domain-specific operations (`task-manager`, `release-manager`)
3. **Medium Priority**: Individual gem executables (`llm-query`, `git-commit`)
4. **Lowest Priority**: Primitive building blocks (avoid where higher-order alternatives exist)

### Key Principles

- **Complete Operations**: Use single commands that handle entire workflows
- **Context Awareness**: Tools understand project structure and current state
- **Error Reduction**: Eliminate manual steps prone to inconsistency
- **AI-Friendly**: Designed for autonomous agent operation

## Command Mappings

### Task Management

#### Old Primitive Approach
```bash
# Multiple commands with manual coordination
bin/tal                    # List tasks
bin/tn                     # Get next task
bin/tnid v.0.3.0          # Generate task ID
```

#### New Higher-Order Approach
```bash
# Single commands with intelligent behavior
task-manager all          # List all tasks with filtering
task-manager next         # Get next task based on priority and dependencies
task-manager recent       # Show recent tasks
```

### Task Creation

#### Old Primitive Approach
```bash
# Multi-step manual process
output=$(bin/rc)                           # Get release context
task_dir=$(echo "$output" | sed -n '1p')   # Parse directory
version=$(echo "$output" | sed -n '2p')    # Parse version
task_id=$(bin/tnid $version)              # Generate ID
# Manual path construction and file creation
```

#### New Higher-Order Approach
```bash
# Single command for complete task creation
nav-path task-new --title "Implement OAuth" --priority high --estimate "8h"
# Automatically handles:
# - Release context detection
# - ID generation with proper sequencing
# - Directory creation
# - File creation with template
# - Returns full path
```

### File Navigation

#### Old Primitive Approach
```bash
# Manual file searching
find . -name "README*" -o -name "*architecture*"
ls -la docs/
```

#### New Higher-Order Approach
```bash
# Intelligent file resolution
nav-path file README        # Fuzzy matches README.md, README.txt, etc.
nav-path file architecture  # Finds architecture.md, arch-overview.md, etc.
```

### Session Management

#### Old Primitive Approach
```bash
# Manual session directory construction
RELEASE_DIR=$(ls -d dev-taskflow/current/*/ 2>/dev/null | head -1)
SESSION_DIR="${RELEASE_DIR}sessions/"
mkdir -p "$SESSION_DIR"
FILENAME="$(date +%Y%m%d-%H%M%S)-compact-log.md"
```

#### New Higher-Order Approach
```bash
# Complete session setup
nav-path reflection-new --title "oauth-implementation-review"
# Automatically handles:
# - Release detection
# - Directory creation
# - Timestamp generation
# - File creation
# - Returns full path
```

## Workflow Updates

### Documentation Files Updated

The following documentation has been updated to use higher-order tools:

#### High Priority Updates
- **CLAUDE.md**: Updated task management section and added higher-order tool guidance
- **22 Workflow Instructions**: All updated to use complete operations

#### Medium Priority Updates
- **README files**: Updated installation and usage instructions
- **docs/tools.md**: Reflects current tool categorization

### Key Workflow Changes

#### Task Creation Workflow
- **Before**: Manual `bin/rc` + `bin/tnid` + path construction
- **After**: Single `nav-path task-new` command
- **Benefit**: Atomic operation, no manual coordination needed

#### File Navigation Workflow
- **Before**: Manual `find` commands and path construction
- **After**: `nav-path file` with intelligent matching
- **Benefit**: Fuzzy matching, autocorrect, project awareness

#### Session Management Workflow
- **Before**: Manual directory creation and filename generation
- **After**: `nav-path reflection-new` with automatic setup
- **Benefit**: Consistent naming, automatic organization

## AI Agent Guidelines

### When to Use Higher-Order Tools

1. **Always prefer complete operations** over primitive sequences
2. **Use domain-specific tools** (`task-manager`) over generic tools when available
3. **Fallback to primitives** only when no higher-order alternative exists
4. **Combine tools intelligently** rather than chaining primitive commands

### Error Handling

Higher-order tools provide better error handling:

- **Context validation**: Tools verify project state before operation
- **Dependency checking**: Automatic validation of prerequisites
- **Rollback capability**: Failed operations can be safely retried
- **Informative errors**: Clear guidance on resolution steps

### Performance Benefits

- **Reduced API calls**: Single command vs. multiple primitive calls
- **Faster execution**: Optimized internal operations
- **Better caching**: Tools maintain state across operations
- **Atomic operations**: Consistent state guarantees

## Migration Checklist

### For Documentation Updates

- [ ] Replace primitive command sequences with higher-order tools
- [ ] Update examples to show complete operations
- [ ] Add context about tool hierarchy
- [ ] Include error handling for new tools
- [ ] Update prerequisites and dependencies

### For Workflow Instructions

- [ ] Replace `bin/rc` + `bin/tnid` with `nav-path task-new`
- [ ] Replace manual file searching with `nav-path file`
- [ ] Replace manual session setup with `nav-path reflection-new`
- [ ] Update task management commands to use `task-manager`
- [ ] Add validation steps for new tools

### For AI Agent Implementation

- [ ] Update tool selection logic to prefer higher-order tools
- [ ] Implement fallback strategies for tool failures
- [ ] Add context awareness for tool selection
- [ ] Update error handling for new tool responses
- [ ] Test tool combinations for efficiency

## Deprecated Tools

### Deprecated Primitive Commands

The following commands are deprecated in favor of higher-order alternatives:

- `bin/tn` → `task-manager next`
- `bin/tr` → `task-manager recent`
- `bin/tal` → `task-manager all`
- `bin/tnid` → Used internally by `nav-path task-new`
- `bin/rc` → Used internally by `nav-path` commands

### Transition Period

During the transition period:
- Old commands remain functional for backward compatibility
- New documentation emphasizes higher-order tools
- Gradual migration of existing workflows
- Deprecation notices guide users to new alternatives

## Future Enhancements

### Planned Higher-Order Tools

1. **code-review**: Complete code review workflow
2. **release-manager**: Release planning and execution
3. **test-runner**: Intelligent test execution with context
4. **doc-generator**: Automatic documentation generation

### Tool Evolution

The tool hierarchy will continue evolving:
- More complete operations for complex workflows
- Better context awareness and intelligence
- Enhanced error handling and recovery
- Improved performance and caching

## Support and Feedback

For issues with the migration or higher-order tools:
- Check tool documentation: `docs/tools.md`
- Review workflow instructions: `dev-handbook/workflow-instructions/`
- Report issues via project issue tracker
- Consult deprecation notices in `dev-tools/exe-old/`

This migration guide ensures AI agents can work efficiently with the new tool architecture while maintaining the flexibility to use primitive commands when necessary.