---
id: idea-task-manager-agent-support
type: enhancement
status: pending
created: 2025-08-14
---

# Improve Task Manager for Agent Support

## Problem Statement

The task-manager agent needs better access to release and task information to effectively manage the development workflow. Current limitations:

1. **No release listing**: Can't list all available releases (current and backlog)
2. **Hard-coded paths**: Agent must know exact release names (v.0.5.0-insights)
3. **Limited file discovery**: Can't easily find all task files across releases
4. **No summary views**: Can't get quick overview of release status

## Proposed Enhancements

### 1. Release Management Commands

```bash
# List all releases
task-manager releases
# Output:
# CURRENT:
#   v.0.5.0-insights (15 tasks: 2 pending, 13 done)
# BACKLOG:
#   v.0.6.0 (planning)
#   ideas/ (47 ideas)

# Switch or view specific release
task-manager list --release current  # Always use current
task-manager list --release backlog  # Show backlog items
task-manager list --release all      # All releases
```

### 2. Enhanced File Discovery

```bash
# List all task files with metadata
task-manager files
# Output:
# dev-taskflow/current/v.0.5.0-insights/tasks/
#   v.0.5.0+task.001 [DONE] Remove Obsolete Binstub References
#   v.0.5.0+task.002 [DONE] Task Manager Release Command
#   ...

# Find task file by ID (partial match)
task-manager find 013
# Output: dev-taskflow/current/v.0.5.0-insights/tasks/v.0.5.0+task.013-context-loading-tool.md
```

### 3. Summary and Overview Commands

```bash
# Release summary
task-manager summary
# Output:
# Release: v.0.5.0-insights
# Progress: 87% complete (13/15 done)
# Pending: 2 tasks
# Blocked: 0 tasks
# Next ID: v.0.5.0+task.016

# Task statistics
task-manager stats
# Output:
# Total tasks: 62
# By status: done(45), pending(12), in-progress(3), blocked(2)
# By priority: high(8), medium(30), low(24)
# Average completion time: 2.3 hours
```

### 4. Agent-Friendly Output

```bash
# JSON output for parsing
task-manager list --format json

# Path-only output for file operations
task-manager list --format paths

# ID-only output for scripting
task-manager list --format ids
```

### 5. Context Auto-Discovery

```bash
# Generate context for current state
task-manager context
# Output: YAML template with current paths and commands

# Self-hydrating context
task-manager context --agent
# Output: Full context ready for agent consumption
```

## Implementation Benefits

1. **Dynamic Path Discovery**: Agent doesn't need hard-coded release names
2. **Better Overview**: Agent can understand full project state
3. **Efficient Navigation**: Quick file discovery by ID
4. **Self-Updating**: Context templates can auto-update with releases
5. **Agent Integration**: Output formats designed for parsing

## Technical Implementation

### Module Structure
```
TaskManager
├── ReleaseManager      # Handle release discovery
├── FileDiscovery       # Find task files efficiently  
├── SummaryGenerator    # Create overview reports
├── ContextBuilder      # Generate context templates
└── OutputFormatter     # Multiple output formats
```

### Priority
- **HIGH**: Critical for agent effectiveness
- **Effort**: 2-3 hours
- **Impact**: Significantly improves agent autonomy

## Additional Insights from Usage

Based on actual usage patterns, these improvements are also needed:

1. **Status Summary Display**: When listing tasks, show a one-line summary at top:
   ```
   Status: draft(2), pending(5), in-progress(1), done(20), total(28)
   ```

2. **Consistent Naming**: Rename all references from "all" to "list" for consistency

3. **Task Creation Migration**: Add `task-manager task-create` subcommand as more intuitive than `create-path task-new`

4. **Common Filter Support**:
   - `--filter needs_review:true` (with variations)
   - `--filter status:draft` (heavily used for planning)

5. **Limit Parameter for Next**: Make `--limit` more prominent as it's used frequently (5, 10 are most common)

## Success Criteria

- [ ] Agent can discover all releases without hard-coded paths
- [ ] Agent can get overview of project state in one command
- [ ] Agent can find any task file by partial ID match
- [ ] Context templates auto-update with release changes
- [ ] All commands have machine-parseable output options
- [ ] Status summary shown on all list operations
- [ ] Support for common filter patterns

## Related Work
- Task manager agent improvements
- Context loading enhancements
- MCP proxy integration for task management
- Usage research: dev-taskflow/current/v.0.5.0-insights/researches/task-manager-usage.md