# Maybe and Anyday Scope Support - Usage Documentation

## Overview

This feature adds support for organizing ideas into "maybe" and "anyday" subdirectories, enabling better idea management through categorization by priority and timeline:

- **maybe/**: Ideas that might be pursued but are uncertain
- **anyday/**: Ideas that can be done anytime with no specific urgency

Users can both list ideas from these categories and create ideas directly in them, providing a complete idea management workflow.

## Available Commands

### Listing Ideas
- `ace-taskflow ideas maybe` - List ideas from maybe/ subdirectory
- `ace-taskflow ideas anyday` - List ideas from anyday/ subdirectory
- `ace-taskflow ideas all` - All ideas including main, maybe, anyday, and done
- `ace-taskflow ideas` (or `ideas next`) - Default: lists only main directory ideas (excludes maybe/anyday/done)

### Creating Ideas
- `ace-taskflow idea create "content" --maybe` - Create in maybe/ subdirectory
- `ace-taskflow idea create "content" --anyday` - Create in anyday/ subdirectory
- Combine with existing flags: `--backlog`, `--release`, `--current`, `--git-commit`, `--llm-enhance`

## Command Structure

### List Commands (Bash CLI)

```bash
# Basic preset usage
ace-taskflow ideas [preset] [options]

# Presets (new ones highlighted)
next        # Default - pending ideas only (excludes maybe/anyday/done)
maybe       # NEW - Ideas in maybe/ subdirectory
anyday      # NEW - Ideas in anyday/ subdirectory
all         # All ideas including maybe, anyday, and done
done        # Only completed ideas
recent      # Recently modified ideas

# Options apply to all presets
--backlog           # Work with backlog ideas
--release <name>    # Work with specific release
--limit <n>         # Limit results
--stats             # Show statistics
```

### Create Commands (Bash CLI)

```bash
# Basic create syntax
ace-taskflow idea create <content> [location-flags] [scope-flags] [behavior-flags]

# New scope flags
--maybe             # Create in ideas/maybe/ subdirectory
--anyday            # Create in ideas/anyday/ subdirectory

# Existing location flags (still work)
--backlog           # Create in backlog
--release <name>    # Create in specific release
--current           # Create in current release (default)

# Existing behavior flags (still work)
--git-commit, -gc   # Auto-commit
--llm-enhance, -llm # Enhance with LLM
--clipboard, -c     # Read from clipboard
```

## Usage Scenarios

### Scenario 1: List Maybe Ideas from Current Release

**Goal**: Review all uncertain/exploratory ideas for the current release

```bash
ace-taskflow ideas maybe
```

**Expected Output**:
```
v.0.9.0: 5 ideas • Mono-Repo Multiple Gems
Ideas: 💡 11 | 🤔 5 maybe | 📅 3 anyday | ✅ 31 done • 50 total
Tasks: ⚫ 2 | ⚪ 5 | 🟡 3 | 🟢 15 • 25 total • 60% complete
========================================
• Implement caching layer
  .ace-taskflow/v.0.9.0/ideas/maybe/20251024-214530-implement-caching-layer.md
• Add GraphQL support
  .ace-taskflow/v.0.9.0/ideas/maybe/20251024-215020-add-graphql-support.md
...
```

### Scenario 2: Create Idea in Anyday Subdirectory

**Goal**: Capture a low-priority idea that can be done anytime

```bash
ace-taskflow idea create "Refactor test helpers" --anyday
```

**Expected Output**:
```
Idea captured: .ace-taskflow/v.0.9.0/ideas/anyday/20251024-220530-refactor-test-helpers.md
```

**What happens internally**:
1. IdeaArgParser parses `--anyday` flag into `scope: "anyday"`
2. IdeaCommand determines location (current release: v.0.9.0)
3. IdeaCommand updates config directory to include anyday/ subdirectory: `.ace-taskflow/v.0.9.0/ideas/anyday/`
4. FileNamer generates path within anyday/ subdirectory
5. IdeaWriter creates file at the anyday path

### Scenario 3: Create in Backlog Maybe Subdirectory

**Goal**: Capture uncertain idea for future consideration (not tied to current release)

```bash
ace-taskflow idea create "Explore new authentication system" --maybe --backlog
```

**Expected Output**:
```
Idea captured: .ace-taskflow/backlog/ideas/maybe/20251024-221015-explore-new-authentication-system.md
```

**Subdirectory path**: `.ace-taskflow/backlog/ideas/maybe/`

### Scenario 4: List All Ideas Including Subdirectories

**Goal**: See complete picture of all ideas across all scopes

```bash
ace-taskflow ideas all
```

**Expected Output**:
```
v.0.9.0: 50 ideas • Mono-Repo Multiple Gems
Ideas: 💡 11 | 🤔 5 maybe | 📅 3 anyday | ✅ 31 done • 50 total
Tasks: ⚫ 2 | ⚪ 5 | 🟡 3 | 🟢 15 • 25 total • 60% complete
========================================
• Add feature X (main directory)
  .ace-taskflow/v.0.9.0/ideas/20251024-200000-add-feature-x.md
• Implement caching (maybe subdirectory)
  .ace-taskflow/v.0.9.0/ideas/maybe/20251024-214530-implement-caching-layer.md
• Refactor helpers (anyday subdirectory)
  .ace-taskflow/v.0.9.0/ideas/anyday/20251024-220530-refactor-test-helpers.md
• Completed idea (done subdirectory)
  .ace-taskflow/v.0.9.0/ideas/done/20251023-120000-completed-idea.md
```

### Scenario 5: Create Maybe Idea with Git Commit

**Goal**: Capture uncertain idea and immediately commit it

```bash
ace-taskflow idea create "Consider microservices architecture" --maybe --git-commit
```

**Expected Output**:
```
Idea captured: .ace-taskflow/v.0.9.0/ideas/maybe/20251024-222530-consider-microservices-architecture.md
[main abc123d] Add idea: Consider microservices architecture
 1 file changed, 5 insertions(+)
 create mode 100644 .ace-taskflow/v.0.9.0/ideas/maybe/20251024-222530-consider-microservices-architecture.md
```

### Scenario 6: Statistics Include All Scopes

**Goal**: See complete statistics including maybe/anyday counts

```bash
ace-taskflow ideas --stats
```

**Expected Output**:
```
Release Statistics: v.0.9.0
Mono-Repo Multiple Gems
==================================================

Ideas: 50 total
  💡 New: 11 (22%)
  🤔 Maybe: 5 (10%)
  📅 Anyday: 3 (6%)
  ✅ Done: 31 (62%)

Tasks: 25 total
Completion: 60%
  ...
```

## Command Reference

### Listing Command Details

**Preset: `maybe`**
- **Syntax**: `ace-taskflow ideas maybe [options]`
- **Scope**: Only ideas in `ideas/maybe/` subdirectory
- **Context**: Applies to current release, backlog, or specified release
- **Statistics**: Total count includes all scopes (main + maybe + anyday + done)
- **Internal**: Uses `IdeaLoader.load_all(scope: :maybe)` which scans `ideas/maybe/` directory

**Preset: `anyday`**
- **Syntax**: `ace-taskflow ideas anyday [options]`
- **Scope**: Only ideas in `ideas/anyday/` subdirectory
- **Context**: Applies to current release, backlog, or specified release
- **Statistics**: Total count includes all scopes (main + maybe + anyday + done)
- **Internal**: Uses `IdeaLoader.load_all(scope: :anyday)` which scans `ideas/anyday/` directory

**Preset: `all` (updated)**
- **Syntax**: `ace-taskflow ideas all [options]`
- **Scope**: Ideas from main + maybe/ + anyday/ + done/ subdirectories
- **Internal**: Uses `IdeaLoader.load_all(scope: :all)` which scans all subdirectories

**Preset: `next` (default, unchanged)**
- **Syntax**: `ace-taskflow ideas` or `ace-taskflow ideas next`
- **Scope**: Only ideas in main directory (excludes maybe, anyday, done)
- **Internal**: Uses `IdeaLoader.load_all(scope: :next)` which scans only main ideas/ directory

### Creation Command Details

**Flag: `--maybe`**
- **Purpose**: Create idea in maybe/ subdirectory
- **Mutually Exclusive With**: `--anyday`
- **Compatible With**: All location flags (`--backlog`, `--release`, `--current`)
- **Subdirectory Pattern**: `<location>/ideas/maybe/`
- **Examples**:
  - Current release: `.ace-taskflow/v.0.9.0/ideas/maybe/`
  - Backlog: `.ace-taskflow/backlog/ideas/maybe/`
  - Specific release: `.ace-taskflow/v.0.8.0/ideas/maybe/`
- **Auto-creates**: Directory is created if it doesn't exist

**Flag: `--anyday`**
- **Purpose**: Create idea in anyday/ subdirectory
- **Mutually Exclusive With**: `--maybe`
- **Compatible With**: All location flags (`--backlog`, `--release`, `--current`)
- **Subdirectory Pattern**: `<location>/ideas/anyday/`
- **Examples**:
  - Current release: `.ace-taskflow/v.0.9.0/ideas/anyday/`
  - Backlog: `.ace-taskflow/backlog/ideas/anyday/`
  - Specific release: `.ace-taskflow/v.0.8.0/ideas/anyday/`
- **Auto-creates**: Directory is created if it doesn't exist

## Error Handling

### Mutual Exclusivity Error
```bash
ace-taskflow idea create "Test" --maybe --anyday
# Error: Cannot use both --maybe and --anyday flags together. Choose one.
```

### Empty Subdirectory
```bash
ace-taskflow ideas maybe
# Output: No ideas found for preset 'maybe'.
```
*Note: Statistics still show total counts even if maybe subdirectory is empty*

### No Active Release with Default
```bash
# When no active release exists and user doesn't specify location
ace-taskflow idea create "Test" --maybe
# Creates in: .ace-taskflow/backlog/ideas/maybe/
```

## Tips and Best Practices

### Organizing Ideas
- **maybe/**: Use for exploratory ideas, uncertain features, or experimental concepts
- **anyday/**: Use for nice-to-have improvements, minor refactoring, or low-priority tasks
- **main directory**: Use for actionable ideas tied to current release goals
- **done/**: Automatically populated when marking ideas as done

### Workflow Recommendations
1. **Quick capture**: Create ideas in main directory first (`ace-taskflow idea create "..."`)
2. **Regular triage**: Review ideas and move to maybe/anyday using `idea done` or manual moves
3. **Periodic review**: Use `ideas maybe` and `ideas anyday` to revisit uncertain/low-priority items
4. **Statistics check**: Use `ideas --stats` to track distribution across scopes

### Common Patterns
```bash
# Capture uncertain idea quickly
ace-taskflow idea create "Try new framework" --maybe -gc

# Review all maybe ideas across releases
ace-taskflow ideas maybe

# Create low-priority backlog item
ace-taskflow idea create "Update dependencies" --anyday --backlog

# See everything
ace-taskflow ideas all
```

## Migration Notes

**From existing workflow**: If you have ideas in the main directory that should be in maybe/anyday:
1. Manually move files: `mv .ace-taskflow/v.0.9.0/ideas/idea.md .ace-taskflow/v.0.9.0/ideas/maybe/`
2. Or mark as done and recreate with new scope flags

**Statistics display**:
- Before: Only showed "new" and "done" counts
- After: Shows "new", "maybe", "anyday", and "done" counts with emojis (💡 🤔 📅 ✅)

**Default behavior unchanged**:
- `ace-taskflow ideas` still shows only main directory ideas (excludes maybe/anyday/done)
- Must explicitly use `ideas all` or `ideas maybe`/`ideas anyday` to see other scopes
