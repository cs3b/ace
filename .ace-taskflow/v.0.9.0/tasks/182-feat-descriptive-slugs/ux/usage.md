# Descriptive Slugs for Idea Filenames - Usage Guide

## Overview

This feature extends idea file naming to include descriptive slugs in the filename itself, not just the folder name. This improves discoverability and readability when browsing idea files directly.

## What Changes

### Before (Current Behavior)
```
.ace-taskflow/v.0.9.0/ideas/8o6jap-taskflow-add/idea.s.md
```

### After (New Behavior)
```
.ace-taskflow/v.0.9.0/ideas/8o6jap-taskflow-add/taskflow-add.idea.s.md
```

## Command Reference

### Creating Ideas

```bash
# Basic idea creation - unchanged interface
ace-taskflow idea create "Implement user authentication"
# Creates: .ace-taskflow/v.X.Y.Z/ideas/8o6xyz-user-auth/user-auth.idea.s.md

# With LLM enhancement
ace-taskflow idea create "Add dark mode support" --enhance
# Creates: .ace-taskflow/v.X.Y.Z/ideas/8o6abc-dark-mode/dark-mode.idea.s.md
```

### Listing Ideas

```bash
# List all ideas - displays new .idea.s.md paths
ace-taskflow ideas
# Output shows: .ace-taskflow/v.0.9.0/ideas/8o6xyz-user-auth/user-auth.idea.s.md

# Short format (without paths)
ace-taskflow ideas --short
# Output shows: [8o6xyz] User Authentication
```

## Usage Scenarios

### Scenario 1: Creating a New Idea

**Goal**: Capture a feature idea with descriptive naming

```bash
$ ace-taskflow idea create "Add export to PDF functionality"
```

**Expected Output**:
```
Idea created: .ace-taskflow/v.0.9.0/ideas/8o7abc-export-pdf/export-pdf.idea.s.md
```

**Result**: A new idea directory with:
- `8o7abc-export-pdf/` - Folder with compact ID and slug
- `export-pdf.idea.s.md` - File with slug and `.idea.s.md` extension

### Scenario 2: Browsing Ideas in File Explorer

**Goal**: Find and identify ideas quickly in a file manager

**Before**: All files named `idea.s.md` - indistinguishable without opening
```
8o6abc-dark-mode/idea.s.md
8o6def-export-pdf/idea.s.md
8o6ghi-user-auth/idea.s.md
```

**After**: Files have descriptive names
```
8o6abc-dark-mode/dark-mode.idea.s.md
8o6def-export-pdf/export-pdf.idea.s.md
8o6ghi-user-auth/user-auth.idea.s.md
```

### Scenario 3: Backward Compatibility with Legacy Ideas

**Goal**: Existing ideas with `idea.s.md` continue to work

```bash
$ ace-taskflow ideas
```

**Expected Output** (mixed formats):
```
v.0.9.0: 3 ideas
  [8o6abc] Dark Mode Support
    .ace-taskflow/v.0.9.0/ideas/8o6abc-dark-mode/dark-mode.idea.s.md
  [8o6def] Export to PDF
    .ace-taskflow/v.0.9.0/ideas/8o6def-export-pdf/export-pdf.idea.s.md
  [8o5xyz] Legacy Idea
    .ace-taskflow/v.0.9.0/ideas/8o5xyz-legacy-idea/idea.s.md
```

Both old (`idea.s.md`) and new (`slug.idea.s.md`) formats appear correctly.

### Scenario 4: Finding Ideas by Reference

```bash
# By compact ID
$ ace-taskflow idea show 8o6abc
# Finds: .ace-taskflow/v.0.9.0/ideas/8o6abc-dark-mode/dark-mode.idea.s.md

# By partial name
$ ace-taskflow idea show dark
# Finds: .ace-taskflow/v.0.9.0/ideas/8o6abc-dark-mode/dark-mode.idea.s.md
```

## File Discovery Priority

When an idea directory contains multiple `.s.md` files, they are discovered in this order:

1. `{slug}.idea.s.md` - New format (highest priority)
2. `{slug}.s.md` - Other `.s.md` files (excluding `idea.s.md`)
3. `idea.s.md` - Legacy format (fallback)

## Tips and Best Practices

### Naming Conventions
- Slugs are generated from the idea title
- Lowercase, hyphen-separated words
- Special characters removed
- Example: "Add User Auth!" becomes "add-user-auth"

### Fallback Behavior
- If slug generation fails, falls back to `idea.s.md`
- Manual creation with `idea.s.md` still works

### Migration
- **No migration required** - existing `idea.s.md` files continue to work
- New ideas automatically use the new format
- Can manually rename files if desired (optional)

## Troubleshooting

### Issue: Idea not found
**Cause**: Multiple `.s.md` files in directory
**Solution**: Remove extra files or ensure correct file has proper extension

### Issue: Old idea.s.md not appearing
**Cause**: Priority order gives preference to new format
**Solution**: Check if there's a `{slug}.idea.s.md` file taking precedence

## Internal Implementation Notes

### Files Modified
- `idea_writer.rb:112-116` - Filename generation
- `idea_loader.rb:211-223` - File discovery
- `ideas_command.rb:327-332` - Display path resolution

### Glob Patterns
- New pattern: `**/*.idea.s.md`
- Legacy support: `**/idea.s.md`
- Both included in discovery
