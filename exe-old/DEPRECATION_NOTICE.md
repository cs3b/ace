# DEPRECATION NOTICE

## Status: DEPRECATED

The tools in this directory (`dev-tools/exe-old/`) are **DEPRECATED** and will be removed in a future version.

## Migration Required

### Deprecated Tools

The following tools have been replaced with higher-order alternatives:

| **Deprecated Tool** | **Replacement** | **Migration Notes** |
|---------------------|-----------------|---------------------|
| `bin/tn` | `task-manager next` | Gets next task with priority and dependency awareness |
| `bin/tr` | `task-manager recent` | Shows recent tasks with filtering |
| `bin/tal` | `task-manager all` | Lists all tasks with status and priority |
| `bin/tnid` | *Internal to `nav-path task-new`* | No direct replacement - use higher-order task creation |
| `bin/rc` | *Internal to `nav-path` commands* | No direct replacement - use higher-order navigation |

### Replacement Pattern

#### Task Management
```bash
# OLD: Primitive commands
bin/tal                    # List tasks
bin/tn                     # Get next task
bin/tnid v.0.3.0          # Generate task ID

# NEW: Higher-order commands
task-manager all          # List all tasks with filtering
task-manager next         # Get next task based on priority
task-manager recent       # Show recent tasks
```

#### Task Creation
```bash
# OLD: Multi-step primitive process
output=$(bin/rc)                           # Get release context
task_dir=$(echo "$output" | sed -n '1p')   # Parse directory
version=$(echo "$output" | sed -n '2p')    # Parse version
task_id=$(bin/tnid $version)              # Generate ID
# Manual path construction and file creation...

# NEW: Single higher-order command
nav-path task-new --title "Feature Name" --priority high --estimate "4h"
# Automatically handles context, ID generation, path creation, file creation
```

## Why These Tools Are Deprecated

1. **Primitive Operations**: These tools require manual coordination and error-prone chaining
2. **Limited Context**: Tools don't understand project state or dependencies
3. **Inconsistent Behavior**: Manual operations lead to inconsistent naming and structure
4. **AI Agent Inefficiency**: Primitive tools require multiple API calls and complex orchestration

## Higher-Order Tool Benefits

1. **Complete Operations**: Single commands handle entire workflows
2. **Context Awareness**: Tools understand project structure and current state
3. **Error Reduction**: Atomic operations eliminate manual coordination errors
4. **AI-Friendly**: Designed for autonomous agent operation with better error handling

## Migration Timeline

- **Current**: Deprecated tools remain functional for backward compatibility
- **Documentation**: All documentation updated to use higher-order tools
- **Future Release**: Deprecated tools will be removed

## Migration Resources

- **Migration Guide**: See `docs/migration-guide.md` for comprehensive migration information
- **Tool Documentation**: See `docs/tools.md` for current tool reference
- **Workflow Instructions**: See `dev-handbook/workflow-instructions/` for updated workflows
- **CLAUDE.md**: Updated with higher-order tool guidance for AI agents

## Getting Help

If you encounter issues during migration:

1. **Check Documentation**: Review migration guide and tool documentation
2. **Test Higher-Order Tools**: Verify new tools work in your environment
3. **Report Issues**: Use project issue tracker for migration problems
4. **Fallback Strategy**: Old tools remain available during transition period

## Tool Hierarchy

When selecting tools, follow this priority order:

1. **Highest Priority**: Complete workflow operations (`nav-path task-new`, `code-review`)
2. **High Priority**: Domain-specific operations (`task-manager`, `release-manager`)
3. **Medium Priority**: Individual gem executables (`llm-query`, `git-commit`)
4. **Lowest Priority**: Primitive building blocks (avoid where higher-order alternatives exist)

---

**For AI Agents**: Always prefer higher-order tools over primitive commands. The deprecated tools in this directory represent the old primitive approach that should be avoided in favor of complete operations.