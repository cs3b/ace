# /ace:load-context - Usage Documentation

## Overview

The `/ace:load-context` slash command loads project context into the current Claude Code session. It supports multiple input types for flexible context loading:

- **Preset names**: Named context configurations (e.g., `project`, `base`)
- **File paths**: Direct context file loading (relative or absolute paths)
- **Protocol URLs**: Protocol-based context loading (e.g., `wfi://workflow-name`)

## Command Types

This is a **Claude Code slash command** (not a bash CLI command). It's invoked within Claude Code conversations using the `/ace:` prefix.

## Command Structure

```bash
/ace:load-context [input]
```

**Parameters:**
- `input` (optional): Preset name, file path, or protocol URL
  - If omitted: Defaults to `project` preset
  - Preset: Simple name without path separators (e.g., `project`, `base`)
  - File path: Relative or absolute path (e.g., `./context.md`, `/full/path/to/file.yml`)
  - Protocol: URL format (e.g., `wfi://workflow-name`, `guide://testing`)

**Default Behavior:**
- No argument: Loads `project` preset
- Output saved to `.cache/ace-context/[source-name].md`

## Usage Scenarios

### Scenario 1: Load Default Project Context

**Goal:** Start a session with standard project context

**Command:**
```bash
/ace:load-context
```

**Expected Output:**
```
Context saved (1089 lines, 35.6 KB), output file:
/Users/mc/Ps/ace-meta/.cache/ace-context/project.md

**Presets Loaded:** project
**Preset Stats:** 1089 lines, 35.6 KB
**Context File:** /Users/mc/Ps/ace-meta/.cache/ace-context/project.md
**Understanding Achieved:** [Summary of project purpose, structure, and conventions]
```

**Internal Implementation:** Runs `ace-context project`

---

### Scenario 2: Load Named Preset

**Goal:** Load a specific preset configuration

**Command:**
```bash
/ace:load-context base
```

**Expected Output:**
```
Context saved (X lines, Y KB), output file:
/Users/mc/Ps/ace-meta/.cache/ace-context/base.md

**Presets Loaded:** base
**Preset Stats:** X lines, Y KB
**Context File:** /Users/mc/Ps/ace-meta/.cache/ace-context/base.md
**Understanding Achieved:** [Summary of base context]
```

**Internal Implementation:** Runs `ace-context base`

---

### Scenario 3: Load Task-Specific Context File

**Goal:** Load context specific to a task during workflow execution

**Command:**
```bash
/ace:load-context .ace-taskflow/v.0.9.0/tasks/084-task-context-enable-file-path-arguments-ace/context.md
```

**Expected Output:**
```
Context saved (X lines, Y KB), output file:
/Users/mc/Ps/ace-meta/.cache/ace-context/context.md

**Presets Loaded:** .ace-taskflow/v.0.9.0/tasks/084-task-context-enable-file-path-arguments-ace/context.md
**Preset Stats:** X lines, Y KB
**Context File:** /Users/mc/Ps/ace-meta/.cache/ace-context/context.md
**Understanding Achieved:** [Summary of task-specific context]
```

**Internal Implementation:** Runs `ace-context .ace-taskflow/v.0.9.0/tasks/084-task-context-enable-file-path-arguments-ace/context.md`

---

### Scenario 4: Load Context from Absolute Path

**Goal:** Load context from a specific file using absolute path

**Command:**
```bash
/ace:load-context /Users/mc/Ps/ace-meta/.ace/context.yml
```

**Expected Output:**
```
Context saved (X lines, Y KB), output file:
/Users/mc/Ps/ace-meta/.cache/ace-context/context.md

**Presets Loaded:** /Users/mc/Ps/ace-meta/.ace/context.yml
**Preset Stats:** X lines, Y KB
**Context File:** /Users/mc/Ps/ace-meta/.cache/ace-context/context.md
**Understanding Achieved:** [Summary from custom context file]
```

**Internal Implementation:** Runs `ace-context /Users/mc/Ps/ace-meta/.ace/context.yml`

---

### Scenario 5: Load Context via Protocol URL

**Goal:** Load context using protocol-based navigation

**Command:**
```bash
/ace:load-context wfi://load-project-context
```

**Expected Output:**
```
Context saved (X lines, Y KB), output file:
/Users/mc/Ps/ace-meta/.cache/ace-context/load-project-context.md

**Presets Loaded:** wfi://load-project-context
**Preset Stats:** X lines, Y KB
**Context File:** /Users/mc/Ps/ace-meta/.cache/ace-context/load-project-context.md
**Understanding Achieved:** [Summary from workflow context]
```

**Internal Implementation:** Runs `ace-context wfi://load-project-context`

---

### Scenario 6: Error - File Not Found

**Goal:** Handle missing file gracefully

**Command:**
```bash
/ace:load-context ./nonexistent/context.md
```

**Expected Output:**
```
Error: Context file not found: ./nonexistent/context.md
```

**Internal Implementation:** `ace-context` returns error, command reports it clearly

---

### Scenario 7: Error - Preset Not Found

**Goal:** Handle missing preset gracefully

**Command:**
```bash
/ace:load-context nonexistent-preset
```

**Expected Output:**
```
Error: Preset 'nonexistent-preset' not found. Use --list-presets to see available presets
```

**Internal Implementation:** `ace-context` returns error, command reports it clearly

---

## Command Reference

### /ace:load-context

**Syntax:**
```bash
/ace:load-context [input]
```

**Parameters:**
- `input` (optional, string): Preset name, file path, or protocol URL

**Input Type Detection:**
- Protocol URLs: Identified by `://` pattern
- File paths: Identified by `/`, `./`, `../`, or file extensions
- Preset names: Single word without path separators

**Supported Formats:**
- Preset names: `project`, `base`, `custom-preset`
- Relative paths: `./path/to/file.md`, `../context.yml`, `.ace/config.yml`
- Absolute paths: `/full/path/to/context.md`
- Protocol URLs: `wfi://workflow`, `guide://pattern`

**Output:**
- Success: Context loaded summary with file path, size, and understanding summary
- Error: Clear error message indicating failure reason

**Internal Tools Used:**
- `ace-context` CLI: Context loading and caching
- `Read` tool: Reading generated context file
- `Bash` tool: Executing ace-context command

---

## Tips and Best Practices

### When to Use Each Input Type

**Use Presets for:**
- Standard project context (`project`)
- Team-shared configurations (`base`, `team`)
- Commonly used context combinations

**Use File Paths for:**
- Task-specific context during workflows
- Custom one-off context requirements
- Experimenting with new context configurations
- Loading context from different projects (absolute paths)

**Use Protocol URLs for:**
- Workflow-embedded context
- Guide-based context loading
- Dynamic context discovery

### Common Pitfalls

1. **Ambiguous Names**: If you have both a preset named `test` and a file `test.md`, the command will use input detection. Use `./test.md` for the file.

2. **Working Directory**: Relative paths are resolved from the current working directory (`$PROJECT_ROOT_PATH`).

3. **Missing Files**: Always verify file paths exist before using them in slash commands.

### Troubleshooting

**Problem:** Context doesn't load
- **Check:** Verify input exists (preset or file)
- **Command:** `ace-context --list-presets` to see available presets
- **Command:** `ls -la <file-path>` to verify file exists

**Problem:** Wrong context loaded
- **Check:** Input type detection - use explicit paths for files (`./file.md` vs `file`)
- **Fix:** Use full path or path separators to force file detection

**Problem:** Permission errors
- **Check:** File permissions allow reading
- **Fix:** `chmod +r <file-path>`

---

## Migration Notes

### Legacy vs New Command

**Before (Preset Only):**
```bash
/ace:load-context project    # Only presets worked
/ace:load-context ./file.md  # Would fail - treated as preset name
```

**After (Flexible Input):**
```bash
/ace:load-context project    # Still works - preset
/ace:load-context ./file.md  # Now works - file path
/ace:load-context wfi://wf   # Now works - protocol
```

### Key Differences

1. **Input Detection**: Automatic detection of input type (no manual flags needed)
2. **File Support**: Can now load arbitrary context files
3. **Protocol Support**: Supports protocol-based context loading
4. **Backward Compatible**: Existing preset usage unchanged

### Transition Guidance

- **No Changes Required**: Existing `/ace:load-context` and `/ace:load-context project` usage works unchanged
- **New Capabilities**: Can now use file paths and protocols when needed
- **Documentation**: Update any custom workflows to leverage new file/protocol support
