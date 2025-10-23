# task:// Protocol Usage Guide

## Overview

The `task://` protocol adds unified task navigation to ace-nav by delegating to `ace-taskflow task` commands. This provides a single entry point for all resource navigation, maintaining consistency with existing protocols like `wfi://`, `guide://`, and `tmpl://`.

**Key Benefits:**
- Unified navigation interface across all ACE resources
- Leverage ace-taskflow's task management without duplication
- Consistent URI-based resource access pattern
- Simple command delegation architecture

## Command Types

### ace-nav Commands (Bash CLI)
Standard command-line tool invocation:
```bash
ace-nav task://083
ace-nav task://083 --path
ace-nav task://083 --content
```

### Internal Implementation
The task:// protocol delegates to:
```bash
ace-taskflow task <reference> [options]
```

## Command Structure

### Basic Invocation
```bash
ace-nav task://<task-reference> [options]
```

**Components:**
- `ace-nav` - The navigation command
- `task://` - Protocol identifier
- `<task-reference>` - Any valid task reference format
- `[options]` - Pass-through options for ace-taskflow

### Supported Reference Formats

All ace-taskflow task reference formats are supported:

```bash
task://018                    # Task number only
task://task.018               # Prefixed with "task."
task://v.0.9.0+task.018       # Full task ID with release
task://backlog+025            # Backlog task
task://current+018            # Explicit current context
```

### Available Options

Options are passed through to `ace-taskflow task`:

- `--path` - Show only the task file path
- `--content` - Show full task content
- `--tree` - Show task dependency tree
- (default) - Show formatted task with status

## Usage Scenarios

### Scenario 1: Quick Task Path Lookup

**Goal**: Get the file path for a task to open in editor

**Commands:**
```bash
# Using ace-nav (new way)
ace-nav task://083 --path

# Equivalent to (traditional way)
ace-taskflow task 083 --path
```

**Expected Output:**
```
.ace-taskflow/v.0.9.0/tasks/083-feat-nav-protocol-support-ace-nav-via-c/task.083.md
```

**Use Case**: Opening task in editor via shell substitution
```bash
nvim $(ace-nav task://083 --path)
```

### Scenario 2: View Task Content

**Goal**: Read the full task specification without opening an editor

**Commands:**
```bash
# Using task number
ace-nav task://083 --content

# Using full task ID
ace-nav task://v.0.9.0+task.083 --content
```

**Expected Output:**
Full task markdown content including behavioral specification, implementation plan, and acceptance criteria.

**Use Case**: Quick review of task details in terminal

### Scenario 3: Check Task Status

**Goal**: See formatted task summary with current status

**Commands:**
```bash
# Default output (no --path or --content)
ace-nav task://083
```

**Expected Output:**
```
Task: v.0.9.0+083 ⚫ Add task:// Protocol Support to ace-nav via Command Delegation
  Path: .ace-taskflow/v.0.9.0/tasks/083-feat-nav-protocol-support-ace-nav-via-c/task.083.md
```

**Use Case**: Quick status check without full content

### Scenario 4: Navigate to Backlog Task

**Goal**: Access task from backlog (not in active release)

**Commands:**
```bash
# Backlog task reference
ace-nav task://backlog+025 --path
```

**Expected Output:**
```
.ace-taskflow/backlog/tasks/025-some-backlog-task/task.025.md
```

**Use Case**: Reviewing or planning backlog items

### Scenario 5: View Task Dependencies

**Goal**: Understand task relationships and dependencies

**Commands:**
```bash
ace-nav task://083 --tree
```

**Expected Output:**
Dependency tree showing related tasks (format depends on ace-taskflow implementation)

**Use Case**: Planning work order and identifying blockers

### Scenario 6: Error Handling - Invalid Reference

**Goal**: Understand error messages when task doesn't exist

**Commands:**
```bash
ace-nav task://999
```

**Expected Output:**
```
Error: Task not found: 999
```

**Use Case**: Understanding what happens with invalid references

### Scenario 7: Error Handling - Missing ace-taskflow

**Goal**: Clear error when ace-taskflow is not installed

**Commands:**
```bash
# When ace-taskflow not in PATH
ace-nav task://083
```

**Expected Output:**
```
Error: ace-taskflow command not found. Install ace-taskflow gem.
```

**Use Case**: Installation troubleshooting

## Command Reference

### task:// Protocol Syntax

```bash
ace-nav task://<reference> [options]
```

**Parameters:**
- `<reference>` - Task reference in any supported format (required)

**Options:**
| Option | Description | Example |
|--------|-------------|---------|
| (none) | Formatted task summary | `ace-nav task://083` |
| `--path` | File path only | `ace-nav task://083 --path` |
| `--content` | Full task content | `ace-nav task://083 --content` |
| `--tree` | Dependency tree | `ace-nav task://083 --tree` |

**Exit Codes:**
- `0` - Success (task found and displayed)
- `1` - Error (task not found, invalid reference, or command error)

### Internal Implementation

The task:// protocol uses a new "cmd" delegation type in ace-nav:

1. **Protocol Config**: `.ace/nav/protocols/task.yml`
   ```yaml
   protocol: task
   type: cmd  # Indicates command delegation (not file resolution)
   command_template: "ace-taskflow task %{ref}"
   ```

2. **Delegation Flow**:
   - ace-nav parses `task://083`
   - Detects protocol type is "cmd"
   - Extracts reference: `083`
   - Builds command: `ace-taskflow task 083 [options]`
   - Executes via `Kernel.system`
   - Forwards exit code

3. **Argument Pass-through**:
   All ace-nav options are passed directly to ace-taskflow:
   - `ace-nav task://083 --path` → `ace-taskflow task 083 --path`
   - `ace-nav task://083 --content` → `ace-taskflow task 083 --content`

## Tips and Best Practices

### Consistent Navigation Pattern

Use ace-nav for all resource navigation to maintain consistency:

```bash
# Workflows
ace-nav wfi://load-context

# Tasks
ace-nav task://083

# Guides
ace-nav guide://testing-patterns

# Templates
ace-nav tmpl://task-draft
```

### Shell Integration

Combine with shell features for powerful workflows:

```bash
# Open task in editor
nvim $(ace-nav task://083 --path)

# Change to task directory
cd $(dirname $(ace-nav task://083 --path))

# Search task content
ace-nav task://083 --content | grep -i "test"
```

### Reference Format Choice

Choose reference format based on context:

- **Local context** (in same release): `task://083`
- **Explicit release**: `task://v.0.9.0+task.083`
- **Backlog**: `task://backlog+025`

### Performance Considerations

Command delegation adds subprocess overhead (~150ms):
- Acceptable for interactive task lookups
- Use `ace-taskflow task` directly in scripts for better performance
- Not suitable for high-frequency programmatic access

## Troubleshooting

### "Error: ace-taskflow command not found"

**Problem**: ace-taskflow gem not installed or not in PATH

**Solution**:
```bash
# Check if installed
which ace-taskflow

# Install if missing
gem install ace-taskflow

# Or if using bundler
bundle exec ace-nav task://083
```

### "Error: Resource not found: task://..."

**Problem**: Invalid protocol or ace-nav doesn't recognize task://

**Solution**:
```bash
# Check protocol configuration
ls ~/.ace/nav/protocols/task.yml
ls .ace/nav/protocols/task.yml

# Copy example config if missing
cp ace-nav/.ace.example/nav/protocols/task.yml ~/.ace/nav/protocols/
```

### Task Not Found

**Problem**: Valid protocol but task doesn't exist

**Solution**:
```bash
# List available tasks
ace-taskflow tasks all

# Check if task is in different context
ace-taskflow tasks all-releases | grep 083
```

## Migration Notes

### From Direct ace-taskflow Usage

**Before** (direct command):
```bash
ace-taskflow task 083 --path
```

**After** (unified navigation):
```bash
ace-nav task://083 --path
```

**Key Differences:**
- URI syntax: `task://` prefix required
- Functionality: Identical (delegation to same command)
- Benefits: Consistent with other ace-nav protocols

**When to Use Each:**
- **ace-nav task://**  - Interactive navigation, consistency with other protocols
- **ace-taskflow task** - Scripts, automation, when performance matters

### No Breaking Changes

The task:// protocol is additive:
- Existing ace-taskflow commands work unchanged
- No migration required
- Choose based on workflow preference

---

**Related Documentation:**
- ace-taskflow task command: `ace-taskflow task --help`
- ace-nav protocols: `ace-nav --help`
- Protocol configuration: `ace-nav/.ace.example/nav/protocols/`
