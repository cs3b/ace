# Task Create with Flexible Metadata Flags - Usage Guide

## Document Type: How-To Guide + Reference

## Overview

Enhanced task creation in `ace-taskflow` with flexible metadata flags, fixing the critical `--help` bug and adding comprehensive flag support for all task frontmatter metadata, including arbitrary custom fields. This feature makes task creation more intuitive and powerful by supporting both positional arguments and named flags.

**Key Features:**

- Fix: `--help` now shows help instead of creating a task named "--help"
- `--title` flag as alternative to positional title argument
- Standard metadata flags: `--status`, `--estimate`, `--dependencies`
- Arbitrary metadata: Any `--key value` flag saved to frontmatter (e.g., `--assignee`, `--category`, `--sprint`)
- Full backwards compatibility with existing positional syntax
- Clear error messages with helpful usage hints

## Current Behavior (Before)

```bash
# Positional title only - works
ace-taskflow task create 'Add new feature'

# Help creates a task instead of showing help - BUG!
ace-taskflow task create --help
# Creates: .ace-taskflow/v.0.9.0/t/XXX---help/task.XXX.md

# No way to set metadata at creation time
# Must manually edit task file after creation to set:
# - status (defaults to 'pending')
# - estimate (defaults to 'TBD')
# - dependencies (defaults to empty array)
# - custom metadata fields (assignee, category, etc.)

# Limitations:
- --help flag is broken (creates task)
- Only positional title supported (not flexible)
- No metadata configuration at creation
- Must edit task file manually for metadata
- No dependencies support during creation
- No arbitrary/custom metadata support
```

## New Behavior (After)

```bash
# Positional title still works (backwards compatible)
ace-taskflow task create 'Add new feature'

# Help works correctly now - FIXED!
ace-taskflow task create --help
# Output: Usage: ace-taskflow task create [TITLE] [options]...

# Flag-based title (alternative syntax)
ace-taskflow task create --title 'Add new feature'

# Create with standard metadata configured
ace-taskflow task create \
  --title 'Implement caching layer' \
  --status pending \
  --estimate 3h \
  --dependencies 018,019

# Create with arbitrary metadata fields
ace-taskflow task create \
  --title 'Build API endpoint' \
  --assignee john \
  --category backend \
  --sprint 5

# Positional title with metadata
ace-taskflow task create 'My task' \
  --estimate 2d \
  --tags ui,refactor

# New output includes metadata confirmation:
Created task v.0.9.0+task.064
Path: /Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/t/064-implement-caching-layer/task.064.md

# Improvements:
- --help works correctly (no task created)
- Flexible title syntax (positional OR --title)
- Full metadata control at creation time (standard + arbitrary fields)
- Dependencies can be set immediately
- Custom metadata fields supported (assignee, category, tags, etc.)
- No manual file editing needed
```

## Quick Start (5 minutes)

The simplest way to use the new feature:

```bash
# Create task with help (verify help works!)
ace-taskflow task create --help

# Create simple task (backwards compatible)
ace-taskflow task create 'My first task'

# Create task with standard metadata
ace-taskflow task create --title 'My task' --estimate 3h

# Create task with arbitrary metadata
ace-taskflow task create --title 'Feature X' --assignee alice --category frontend

# Expected output:
Created task v.0.9.0+task.065
Path: /Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/t/065-my-task/task.065.md
```

**Success criteria:** Task file created with specified metadata in frontmatter (both standard and custom fields)

## Command Interface

### Basic Syntax

```bash
ace-taskflow task create [TITLE] [OPTIONS]
```

### Command Options

#### Standard Options

| Option | Short | Type | Description | Example |
|--------|-------|------|-------------|---------|
| `--title` | | string | Task title (alternative to positional) | `--title "My task"` |
| `--status` | | string | Initial status (pending, draft, in-progress, done, blocked) | `--status draft` |
| `--estimate` | | string | Effort estimate | `--estimate 3h` |
| `--dependencies` | | string | Comma-separated dependency list | `--dependencies 018,019` |
| `--backlog` | | flag | Create task in backlog | `--backlog` |
| `--release` | | string | Create task in specific release | `--release v.0.10.0` |
| `--help` | `-h` | flag | Show help message | `--help` |

#### Arbitrary Metadata

| Pattern | Description | Examples |
|---------|-------------|----------|
| `--<key> <value>` | Any flag not in standard options saved as metadata | `--assignee john`<br>`--category backend`<br>`--sprint 5`<br>`--tags ui,refactor` |

**Note:** All flags except the standard options above are treated as arbitrary metadata and saved directly to the task frontmatter.

## Usage Scenarios

### Scenario 1: Quick Task Creation (Backwards Compatible)

**Goal**: Create a simple task quickly using familiar positional syntax

**Before** (still works!):

```bash
ace-taskflow task create 'Implement user authentication'
```

**After** (same result, new flag syntax available):

```bash
# Option 1: Positional (original syntax)
ace-taskflow task create 'Implement user authentication'

# Option 2: Flag-based (new syntax)
ace-taskflow task create --title 'Implement user authentication'

# Both create identical output:
Created task v.0.9.0+task.066
Path: /Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/t/066-implement-user-authentication/task.066.md
```

**Benefits**:

- No workflow changes needed
- New flag syntax available when needed
- Choose syntax that fits your use case

### Scenario 2: Task with Estimate and Custom Metadata

**Goal**: Create a task with time estimate and custom urgency field set immediately

**Before** (required manual editing):

```bash
# Step 1: Create task
ace-taskflow task create 'Fix security vulnerability'

# Step 2: Manually edit task file to set:
# estimate: 2h
# urgency: high
```

**After** (one command):

```bash
ace-taskflow task create \
  --title 'Fix security vulnerability' \
  --estimate 2h \
  --urgency high

# Output:
Created task v.0.9.0+task.067
Path: /Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/t/067-fix-security-vulnerability/task.067.md
```

**Task file frontmatter:**

```yaml
---
id: v.0.9.0+task.067
status: pending
estimate: 2h
dependencies: []
urgency: high
---
```

**Benefits**:

- Saves 2 steps (open file, edit frontmatter)
- Reduces errors from manual editing
- Task ready to work on immediately
- Custom metadata (urgency) configured at creation

### Scenario 3: Task with Dependencies

**Goal**: Create a task that depends on other tasks being completed first

**Before** (not possible during creation):

```bash
# Step 1: Create task
ace-taskflow task create 'Write integration tests'

# Step 2: Add dependency manually using separate command
ace-taskflow task add-dependency 068 --depends-on 066
ace-taskflow task add-dependency 068 --depends-on 067
```

**After** (dependencies at creation):

```bash
ace-taskflow task create \
  --title 'Write integration tests' \
  --dependencies 066,067 \
  --estimate 4h

# Output:
Created task v.0.9.0+task.068
Path: /Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/t/068-write-integration-tests/task.068.md
```

**Task file frontmatter:**

```yaml
---
id: v.0.9.0+task.068
status: pending
estimate: 4h
dependencies: [066, 067]
---
```

**Benefits**:

- Dependencies set immediately
- Task correctly marked as blocked until dependencies complete
- No separate commands needed

### Scenario 4: Draft Task for Future Planning

**Goal**: Create a draft task (not ready for execution yet) with custom metadata

**Before** (manual file edit required):

```bash
# Create with default status (pending)
ace-taskflow task create 'Explore new architecture patterns'

# Manually edit to set status: draft and add research phase
```

**After** (draft status at creation):

```bash
ace-taskflow task create \
  --title 'Explore new architecture patterns' \
  --status draft \
  --phase research

# Output:
Created task v.0.9.0+task.069
Path: /Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/t/069-explore-new-architecture-patterns/task.069.md
```

**Task file frontmatter:**

```yaml
---
id: v.0.9.0+task.069
status: draft
estimate: TBD
dependencies: []
phase: research
---
```

**Benefits**:

- Clear status from creation
- Won't appear in "next task" queries (draft excluded)
- Ready for planning phase
- Custom metadata (phase) for workflow tracking

### Scenario 5: Task in Backlog with Metadata

**Goal**: Create a future task in backlog with all metadata configured

**Before**:

```bash
# Create in backlog (context flag works)
ace-taskflow task create 'Add GraphQL API' --backlog

# Manually edit to set estimate and team assignment
```

**After**:

```bash
ace-taskflow task create \
  --title 'Add GraphQL API' \
  --backlog \
  --estimate 8h \
  --status draft \
  --team backend \
  --type feature

# Output:
Created task backlog+task.025
Path: /Users/mc/Ps/ace-meta/.ace-taskflow/backlog/t/025-add-graphql-api/task.025.md
```

**Benefits**:

- Backlog tasks fully configured
- Ready to move to active release when prioritized
- No follow-up editing needed
- Custom metadata (team, type) configured from start

### Scenario 6: Verifying Help Works (Bug Fix)

**Goal**: Confirm that --help no longer creates a task

**Before** (BUG):

```bash
ace-taskflow task create --help

# WRONG: Created task v.0.9.0+task.XXX
# Path: .ace-taskflow/v.0.9.0/t/XXX---help/task.XXX.md
```

**After** (FIXED):

```bash
ace-taskflow task create --help

# CORRECT: Shows help, no task created
# Output:
Usage: ace-taskflow task create [TITLE] [options]

Options:
  --title TITLE           Task title (alternative to positional arg)
  --status STATUS         Initial status (pending, draft, in-progress, done, blocked)
  --urgency URGENCY      Urgency level (low, medium, high, critical)
  --estimate ESTIMATE     Effort estimate (e.g., 2h, 1d, TBD)
  --dependencies DEPS     Comma-separated dependency list (e.g., 018,019,020)
  --backlog              Create task in backlog
  --release VERSION      Create task in specific release
  -h, --help             Show help message

Examples:
  # Positional title
  ace-taskflow task create 'Implement feature X'

  # Flag-based with metadata
  ace-taskflow task create --title 'Fix bug Y' --urgency critical --status pending

  # With dependencies
  ace-taskflow task create 'Write tests' --dependencies 041,042 --estimate 4h
```

**Benefits**:

- Critical bug fixed
- Users can discover flags via --help
- Proper CLI behavior

## Complete Command Reference

### `ace-taskflow task create`

**Purpose**: Create a new task with optional metadata configuration

**Syntax**:

```bash
ace-taskflow task create [TITLE] [--title TITLE] [--status STATUS] [--estimate ESTIMATE] [--dependencies DEPS] [--backlog | --release VERSION] [--<key> <value>...] [--help]
```

**Parameters**:

- `TITLE` (positional): Task title (optional if --title provided)

**Standard Options**:

| Flag | Short | Type | Required | Description | Default | Valid Values |
|------|-------|------|----------|-------------|---------|--------------|
| `--title` | | string | no* | Task title | (from positional) | Any string |
| `--status` | | string | no | Initial status | `pending` | pending, draft, in-progress, done, blocked |
| `--estimate` | | string | no | Effort estimate | `TBD` | Any string (e.g., 2h, 1d, 3 days) |
| `--dependencies` | | string | no | Comma-separated task IDs | `[]` | 018, 018,019, task.018 |
| `--backlog` | | flag | no | Create in backlog | false | N/A (flag present or not) |
| `--release` | | string | no | Create in specific release | (current) | v.0.9.0, backlog |
| `--help` | `-h` | flag | no | Show help and exit | false | N/A |

**Arbitrary Metadata**:

| Pattern | Description | Examples |
|---------|-------------|----------|
| `--<key> <value>` | Any other flag saved to frontmatter | `--assignee john`, `--urgency high`, `--sprint 5`, `--tags ui,refactor` |

\* At least one of `TITLE` (positional) or `--title` is required

**Examples**:

```bash
# Example 1: Simple task (positional)
ace-taskflow task create 'Add logging'
# Output:
Created task v.0.9.0+task.070
Path: /Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/t/070-add-logging/task.070.md

# Example 2: Simple task (flag-based)
ace-taskflow task create --title 'Add logging'
# Output: (identical to Example 1)

# Example 3: Task with arbitrary metadata
ace-taskflow task create 'Fix crash on startup' --urgency critical --assignee alice
# Output:
Created task v.0.9.0+task.071
Path: /Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/t/071-fix-crash-on-startup/task.071.md

# Example 4: Full standard metadata
ace-taskflow task create \
  --title 'Implement caching' \
  --status pending \
  --estimate 3h \
  --dependencies 068,069
# Output:
Created task v.0.9.0+task.072
Path: /Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/t/072-implement-caching/task.072.md

# Example 5: Draft task with custom metadata
ace-taskflow task create \
  --title 'Research alternatives' \
  --status draft \
  --backlog \
  --category research \
  --sprint 6
# Output:
Created task backlog+task.026
Path: /Users/mc/Ps/ace-meta/.ace-taskflow/backlog/t/026-research-alternatives/task.026.md

# Example 6: Get help
ace-taskflow task create --help
# Output: (help text shown above)
```

**Exit Codes**:

- `0`: Success (task created OR help shown)
- `1`: Error (missing title, invalid flag, etc.)

**See Also**:

- `ace-taskflow task show <reference>` - View task details
- `ace-taskflow task start <reference>` - Start working on task
- `ace-taskflow task add-dependency <ref> --depends-on <dep>` - Add dependency after creation

## Troubleshooting

### Problem: "Task title is required" error

**Symptom**:

```bash
ace-taskflow task create --category urgent
# Error: Task title is required
#
# Usage: ace-taskflow task create <title> [options]
#    or: ace-taskflow task create --title 'Task title' [options]
```

**Solution**:

```bash
# Provide title as positional argument
ace-taskflow task create 'My task' --category urgent

# OR provide title via --title flag
ace-taskflow task create --title 'My task' --category urgent
```

### Problem: "invalid option" error

**Symptom**:

```bash
ace-taskflow task create 'Task' --invalid-flag value
# Error: invalid option: --invalid-flag
#
# Run 'ace-taskflow task create --help' for usage
```

**Solution**:

```bash
# Check available flags
ace-taskflow task create --help

# Use correct flag names
ace-taskflow task create 'Task' --category urgent --estimate 2h
```

### Problem: Dependencies not parsed correctly

**Symptom**:

```bash
# Spaces around commas cause issues?
ace-taskflow task create 'Task' --dependencies '018, 019, 020'
```

**Solution**:

```bash
# Spaces are handled correctly (trimmed automatically)
ace-taskflow task create 'Task' --dependencies '018, 019, 020'
# OR
ace-taskflow task create 'Task' --dependencies '018,019,020'

# Both work identically - spaces trimmed
```

### Problem: Both positional and --title provided

**Symptom**:

```bash
ace-taskflow task create 'Positional title' --title 'Flag title'
# Which one wins?
```

**Solution**:

```bash
# Positional argument takes precedence
# Task created with title: "Positional title"

# Best practice: Use only ONE syntax
ace-taskflow task create 'Positional title'
# OR
ace-taskflow task create --title 'Flag title'
```

## Best Practices

### 1. Use Flags for Complex Tasks

When creating tasks with multiple metadata fields, use flags for clarity:

```bash
# Good: Clear and explicit
ace-taskflow task create \
  --title 'Implement feature X' \
  --category urgent \
  --estimate 4h \
  --dependencies 070,071

# Avoid: Harder to read and maintain
ace-taskflow task create 'Implement feature X'
# (then manually edit file)
```

### 2. Set Dependencies Early

Add dependencies during creation to prevent accidental execution of blocked tasks:

```bash
# Good: Dependencies set immediately
ace-taskflow task create \
  --title 'Integration tests' \
  --dependencies 072

# Avoid: Task might be started before dependency complete
ace-taskflow task create 'Integration tests'
# (dependency added later)
```

### 3. Use Draft Status for Planning Tasks

Mark tasks as draft when they need more planning:

```bash
# Good: Clear that planning is needed
ace-taskflow task create \
  --title 'Explore architecture options' \
  --status draft

# Avoid: Task appears as "next" when not ready
ace-taskflow task create 'Explore architecture options'
```

### 4. Consistent Estimate Format

Use consistent format for estimates across your project:

```bash
# Good: Consistent format
--estimate 2h    # hours
--estimate 1d    # days
--estimate 3w    # weeks

# Acceptable but less consistent:
--estimate '2 hours'
--estimate 'half day'
```

### 5. Always Test Help First

After upgrading, verify help works correctly:

```bash
# Verify bug fix
ace-taskflow task create --help
# Should show help, NOT create task
```

## Migration Notes

**Upgrading from pre-0.9.x versions:**

### No Breaking Changes

All existing commands continue to work:

```bash
# Before: Works
ace-taskflow task create 'My task'

# After: Still works (backwards compatible)
ace-taskflow task create 'My task'

# After: NEW options available
ace-taskflow task create 'My task' --category urgent
```

### Key Improvements

| Feature | Before | After |
|---------|--------|-------|
| **Help flag** | Creates task! (BUG) | Shows help (FIXED) |
| **Title syntax** | Positional only | Positional OR --title |
| **Metadata** | Manual edit after creation | Flags during creation |
| **Dependencies** | Separate add-dependency command | `--dependencies` flag |
| **Draft status** | Manual edit | `--status draft` flag |

### Workflow Changes (Optional)

**Old workflow** (still works):

```bash
# Step 1: Create task
ace-taskflow task create 'My task'

# Step 2: Edit file to set metadata
vim .ace-taskflow/v.0.9.0/t/XXX-my-task/task.XXX.md

# Step 3: Add dependencies
ace-taskflow task add-dependency XXX --depends-on YYY
```

**New workflow** (recommended):

```bash
# Single command with all metadata
ace-taskflow task create \
  --title 'My task' \
  --category urgent \
  --estimate 3h \
  --dependencies YYY
```

**Benefits**:

- Faster task creation
- Fewer commands to remember
- Less prone to errors
- Consistent metadata from start

## Benefits Summary

### 1. Critical Bug Fixed

The `--help` flag now works correctly:

- Before: Created task named "--help"
- After: Shows help text as expected

### 2. Flexible Title Syntax

Choose the syntax that fits your workflow:

- Positional: `ace-taskflow task create 'Title'`
- Flag-based: `ace-taskflow task create --title 'Title'`

### 3. Immediate Metadata Configuration

Set all task metadata during creation:

- Status (pending, draft, in-progress, done, blocked)
- Priority (critical, high, medium, low)
- Estimate (2h, 1d, etc.)
- Dependencies (comma-separated task IDs)

### 4. Reduced Manual Editing

No need to open and edit task files after creation:

- Saves time and reduces errors
- Task ready to work on immediately
- Consistent metadata format

### 5. Better Dependency Management

Dependencies can be set at creation time:

- Tasks correctly marked as blocked
- Prevents accidental execution
- Clear task relationships from start

### 6. Full Backwards Compatibility

All existing commands continue to work:

- No workflow disruption
- Gradual adoption of new features
- No migration required

## Compatibility Notes

- **ACE version**: 0.9.0+
- **Ruby version**: 2.7+
- **Dependencies**: None (uses Ruby stdlib `optparse`)
- **Breaking changes**: None (fully backwards compatible)
- **Works with**:
  - All existing task commands
  - All context flags (--backlog, --release)
  - All task management workflows
