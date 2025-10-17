# ace-context Preset Composition Usage

## Overview

The preset composition feature allows users to build complex context configurations by composing multiple presets together. This enables modular, reusable context definitions that can be combined and extended without duplication.

### Key Features

- Compose multiple presets in configuration files via `presets:` array
- Load multiple presets from CLI using `-p` flags or comma-separated lists
- Intelligent merging with array deduplication and scalar override
- Transitive preset loading (presets can include other presets)
- Inspect merged configuration without execution using `--inspect-config`

## Command Types

### CLI Commands (bash)

```bash
# Load multiple presets via repeated flags
ace-context -p base -p project-specific

# Load multiple presets via comma-separated list
ace-context --presets base,project,team

# Mix preset composition with other options
ace-context -p base -p custom --output cache --format yaml

# Inspect configuration only (no file/command execution)
ace-context -p base --inspect-config
ace-context -p base -p team --inspect-config
ace-context --presets base,project,team --inspect-config
```

### Configuration (YAML)

```yaml
# In .ace/context/presets/my-preset.md frontmatter
context:
  presets:
    - base
    - project-base
  files:
    - additional-file.md
  commands:
    - git status
```

## Usage Scenarios

### Scenario 1: Extending a Base Preset

**Goal**: Create a team-specific preset that builds on the project base

**Configuration** (`.ace/context/presets/team-backend.md`):

```yaml
---
description: Backend team context configuration
context:
  presets:
    - project-base    # Inherit all project files/commands
  files:
    - backend/README.md
    - backend/architecture.md
  commands:
    - docker ps
    - redis-cli ping
---
# Backend Team Context
```

**Usage**:

```bash
ace-context team-backend
```

**Expected Output**: Combined context with all files from `project-base` plus backend-specific files, all commands deduplicated.

### Scenario 2: CLI Multi-Preset Loading

**Goal**: Load multiple presets for comprehensive analysis

**Command**:

```bash
ace-context -p project -p testing -p performance --output analysis.md
```

**Expected Result**:

1. Loads `project` preset with base files/commands
2. Merges `testing` preset, adding test-related files
3. Merges `performance` preset, adding perf metrics
4. Deduplicates any repeated files/commands
5. Saves unified context to `analysis.md`

### Scenario 3: Overriding Scalar Values

**Goal**: Use different timeout for CI environment

**Base Preset** (`base.md`):

```yaml
context:
  params:
    timeout: 30
    max_size: 1048576
```

**CI Preset** (`ci.md`):

```yaml
context:
  presets:
    - base
  params:
    timeout: 120  # Override for slower CI
```

**Usage**:

```bash
ace-context ci
```

**Expected**: Timeout of 120 seconds (overrides base's 30), max_size remains 1048576.

### Scenario 4: Handling Missing Presets

**Goal**: Gracefully handle nonexistent preset references

**Command**:

```bash
ace-context -p base -p nonexistent -p project
```

**Expected Output**:

```
Warning: Preset 'nonexistent' not found, skipping...
Loading preset 'base'...
Loading preset 'project'...
Context generated successfully.
```

The system continues processing valid presets despite the missing one.

### Scenario 5: Transitive Preset Loading

**Goal**: Load presets that reference other presets

**Structure**:

- `minimal.md`: Basic files only
- `standard.md`: includes `minimal` + common commands
- `full.md`: includes `standard` + extensive analysis

**Command**:

```bash
ace-context full
```

**Loading Order**:

1. `full` references `standard`
2. `standard` references `minimal`
3. Load `minimal` first
4. Merge `standard` on top
5. Merge `full` on top
6. Apply deduplication

### Scenario 6: Inspecting Merged Configuration

**Goal**: Debug preset composition by viewing the merged configuration without execution

**Command**:

```bash
ace-context -p base -p team -p custom --inspect-config
```

**Expected Output**:

```yaml
description: Merged configuration
context:
  params:
    output: cache        # from base
    max_size: 10485760   # from base
    timeout: 120         # from team (overrides base's 30)
  files:                 # deduplicated union from all presets
    - docs/architecture.md
    - docs/blueprint.md
    - team/guidelines.md
    - custom/setup.md
  commands:              # deduplicated union from all presets
    - git status
    - docker ps
    - npm test
```

**Benefits**:
- No files are loaded or read from disk
- No commands are executed
- Pure configuration merging for debugging
- Helps understand exact merge behavior
- Useful for troubleshooting unexpected results

## Command Reference

### CLI Options

#### Multiple Preset Flags

```bash
ace-context -p <preset1> -p <preset2> [options]
```

- Loads presets in order specified
- Later presets override earlier ones for scalars
- Arrays are concatenated and deduplicated

#### Comma-Separated Presets

```bash
ace-context --presets <preset1>,<preset2>,<preset3> [options]
```

- Alternative syntax for multiple presets
- No spaces after commas
- Same merge behavior as multiple flags

#### Configuration Inspection

```bash
ace-context -p <preset> --inspect-config
ace-context --presets <preset1>,<preset2> --inspect-config
```

- Shows merged configuration only in YAML format
- No file loading or command execution
- Useful for debugging preset composition
- Single preset shows its configuration directly
- Multiple presets show merged result

### Configuration Reference

#### Preset Composition in YAML

```yaml
context:
  presets:
    - preset-name-1
    - preset-name-2
  files:
    - additional-file.md
  commands:
    - additional-command
```

**Processing Order**:

1. Load each preset in `presets:` array recursively
2. Merge loaded presets in order (left to right)
3. Apply current preset's explicit `files:` and `commands:`
4. Deduplicate arrays while preserving order

#### Merge Strategy

**Arrays (files, commands)**:

- Concatenated in order
- Duplicates removed (keeps first occurrence)
- Order preserved after deduplication

**Scalars (timeout, max_size, output)**:

- Last value wins
- Later presets override earlier ones
- Explicit values override inherited ones

## Tips and Best Practices

### Organizing Presets

- Create a base preset with common elements
- Build specialized presets that extend the base
- Use descriptive names (e.g., `project-base`, `team-frontend`, `ci-testing`)

### Avoiding Circular Dependencies

- Keep preset hierarchies shallow (max 3-4 levels)
- Document preset dependencies in descriptions
- Test preset combinations during development

### Performance Considerations

- Presets are loaded once and cached during execution
- Deduplication happens after all merging is complete
- Large preset chains may increase startup time slightly

### Debugging Preset Composition

```bash
# List all available presets
ace-context --list-presets

# Inspect merged configuration without execution
ace-context -p preset1 -p preset2 --inspect-config

# Test preset composition with debug output
ace-context -p preset1 -p preset2 --debug

# Verify merged output with full context
ace-context -p base -p custom --output test.md

# Compare configuration vs full output
ace-context -p base -p custom --inspect-config > config.yml
ace-context -p base -p custom > full-context.md
```

## Migration from Single Presets

### Before (Single Preset)

```bash
# Had to maintain separate, complete presets
ace-context project-with-tests
ace-context project-with-docs
ace-context project-with-all
```

### After (Composed Presets)

```bash
# Compose what you need
ace-context -p project -p tests
ace-context -p project -p docs
ace-context -p project -p tests -p docs
```

### Benefits

- Reduced duplication in preset definitions
- More flexible context generation
- Easier maintenance of preset configurations
- Better reusability across teams and projects

