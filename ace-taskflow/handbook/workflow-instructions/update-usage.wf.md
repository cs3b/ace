# Update Usage Documentation

## Goal

Systematically update usage documentation files based on user feedback, task requirements, or quality improvements, ensuring alignment with documentation best practices and project standards.

## Prerequisites

* Understanding of existing usage documentation patterns
* Access to target usage.md files or ability to create new ones
* Knowledge of Diátaxis framework (Tutorial, How-To, Reference, Explanation)
* Understanding of progressive disclosure principles
* Access to relevant feedback, task definitions, or improvement requests

## Project Context Loading

* Load workflow standards: `dev-handbook/.meta/gds/workflow-instructions-definition.g.md`
* Load project documentation: `docs/tools.md` for command examples
* Review existing patterns: Search for `usage.md` files in the project
* Load task context if applicable: Task definition file with requirements

## Process Steps

1. **Analyze Input and Requirements:**
   * Determine the input type:
     - User feedback or bug report
     - Task definition with usage requirements
     - Quality improvement request
     - Migration from old format
   * Identify target documentation:
     ```bash
     # Find existing usage documentation
     find . -name "usage.md" -path "*/ux/*" -o -name "usage.md" -path "*/docs/*"

     # Or check specific task folder
     ls -la .ace-taskflow/v.*/t/*/ux/usage.md
     ```
   * Extract key requirements:
     - What needs to be documented
     - Target audience (developers, AI agents, or both)
     - Scope of changes (new file, update, or complete rewrite)

2. **Classify Documentation Type:**
   * Determine which Diátaxis type best fits:

   | Type | Purpose | When to Use |
   |------|---------|-------------|
   | **Tutorial** | Learning-oriented, hands-on | New users getting started |
   | **How-To Guide** | Task-oriented, problem-solving | Specific scenarios/goals |
   | **Reference** | Information-oriented, technical | Command details, parameters |
   | **Explanation** | Understanding-oriented, concepts | Architecture, design decisions |

   * Most usage.md files are **How-To Guides** with **Reference** sections
   * Consider if multiple types should be separated into different sections

3. **Select Documentation Pattern:**
   Based on content type, choose the appropriate pattern:

   * **Pattern A: CLI Tool Guide** (for command-line tools like ace-git-commit)
     - Overview → Installation → Command Interface → Use Cases → Configuration

   * **Pattern B: Feature Demo** (for new features/changes)
     - Current Behavior (Before) → New Behavior (After) → Usage Scenarios → Benefits

   * **Pattern C: Workflow Integration** (for multi-step processes)
     - Overview → Command Types → Usage Scenarios → Command Reference → Tips

4. **Structure the Documentation:**
   * Create or update the usage.md file following the selected pattern
   * Use the appropriate embedded template (see templates section below)
   * Apply progressive disclosure:
     ```markdown
     ## Quick Start (5 minutes)
     [Minimal working example]

     ## Common Scenarios
     [Practical use cases]

     ## Complete Reference
     [Exhaustive documentation]

     ## Deep Dive (Optional)
     [Advanced concepts]
     ```

5. **Write Scenario-Based Content:**
   * For each major feature or command, create numbered scenarios:
   ```markdown
   ### Scenario N: [Descriptive Title]

   **Goal**: [What user wants to achieve]

   **Commands/Steps**:
   ```bash
   # Command with comments
   ace-taskflow command --flag value
   ```

   **Expected Output**:
   ```
   [Show actual output]
   ```

   **Next Steps**: [Optional continuation]
   ```

6. **Add Examples with Expected Output:**
   * EVERY example must show expected output
   * Use OpenAPI-inspired format for multiple examples:
   ```markdown
   **examples:**
     basic:
       summary: Simple usage
       command: ace-tool command
       output: |
         Success: Operation completed

     advanced:
       summary: With options
       command: ace-tool command --option value
       output: |
         Processing with option...
         Success: Operation completed with value
   ```

7. **Include Command Reference Tables:**
   * For tools with options, use consistent table format:
   ```markdown
   | Option | Short | Description | Example |
   |--------|-------|-------------|---------|
   | `--flag` | `-f` | What it does | `--flag value` |
   ```

8. **Add Troubleshooting Section:**
   * Use problem → solution format:
   ```markdown
   ### Problem: [Issue description]

   **Symptom**: [What user sees]

   **Solution**:
   ```bash
   # Fix command
   ```
   ```

9. **Distinguish Command Types:**
   * When both CLI and Claude commands exist:
   ```markdown
   ### Bash CLI Commands
   Commands without `/` are terminal/bash commands:
   ```bash
   ace-taskflow command
   ```

   ### Claude Code Commands (Slash Commands)
   Commands starting with `/` are executed within Claude Code:
   ```
   /ace:command
   ```
   ```

10. **Validate Documentation Quality:**
    * Check all commands work:
      ```bash
      # Test each command in documentation
      # Verify output matches documentation
      ```
    * Ensure consistency with existing patterns
    * Verify progressive disclosure is implemented
    * Confirm all examples have expected outputs
    * Check for completeness:
      - [ ] Overview/Purpose clear
      - [ ] Prerequisites listed
      - [ ] Installation/setup covered (if needed)
      - [ ] Common scenarios documented
      - [ ] Command reference complete
      - [ ] Troubleshooting included
      - [ ] Migration notes (if applicable)

11. **Review and Iterate:**
    * Compare with existing high-quality examples:
      - ace-git-commit usage (Pattern A)
      - Task 031/032/033 usage (Pattern B)
      - Batch operations usage (Pattern C)
    * Get feedback if available
    * Iterate based on user needs

## Success Criteria

* Usage documentation created or updated successfully
* Documentation type correctly classified (Tutorial/How-To/Reference/Explanation)
* Progressive disclosure implemented (Quick Start → Common → Complete → Deep)
* All examples include expected output
* Commands verified to work correctly
* Consistent with project documentation patterns
* Clear distinction between CLI and Claude commands (where applicable)
* Troubleshooting section included
* Quality validation completed

## Embedded Templates

<templates>

<template name="cli-tool-usage">
# [Tool Name] Usage Guide

## Document Type: How-To Guide + Reference

## Overview

[Brief description of what the tool does and its primary purpose]

**Key Features:**
- [Feature 1]
- [Feature 2]
- [Feature 3]

## Installation

```bash
# Installation command
[installation steps]
```

## Quick Start (5 minutes)

Get started with the most basic usage:

```bash
# Minimal working example
[command]

# Expected output:
[output]
```

**Success criteria:** [What indicates it worked]

## Command Interface

### Basic Usage

```bash
# Default behavior
[tool-name]

# With common flags
[tool-name] --flag value
```

### Command Options

| Option | Short | Description | Example |
|--------|-------|-------------|---------|
| `--help` | `-h` | Show help message | `tool -h` |
| `--verbose` | `-v` | Verbose output | `tool -v` |
| `--output` | `-o` | Output format | `tool -o json` |

## Common Scenarios

### Scenario 1: [Common Use Case]

**Goal**: [What user wants to achieve]

**Commands**:
```bash
# Step-by-step commands
[command 1]
[command 2]
```

**Expected Output**:
```
[Show actual output]
```

**Next Steps**: [What to do after]

### Scenario 2: [Another Use Case]

[Similar structure]

## Configuration

### Project Configuration

Create `.ace/[tool]/config.yml`:

```yaml
# Configuration example
[tool]:
  setting: value
```

### Global Configuration

Place in `~/.ace/[tool]/config.yml` for user-wide defaults.

## Complete Command Reference

### Main Commands

#### `[tool] [command]`

[Detailed description]

**Parameters:**
- `param1`: [Description]
- `param2`: [Description]

**Options:**
- `--option1`: [Description]

**Examples:**
```bash
# Example 1
[command]
# Output: [output]

# Example 2
[command with options]
# Output: [output]
```

## Troubleshooting

### Problem: [Common Issue]

**Symptom**: [What user sees]

**Solution**:
```bash
# How to fix
[solution commands]
```

## Best Practices

1. **[Practice 1]**: [Explanation]
2. **[Practice 2]**: [Explanation]
3. **[Practice 3]**: [Explanation]

## Migration Notes

[If updating from older version]

**From old version:**
```bash
[old command]
```

**To new version:**
```bash
[new command]
```
</template>

<template name="feature-demo-usage">
# [Feature Name] - Usage Examples

## Document Type: Tutorial + How-To Guide

## Overview

[Brief description of the feature and what problem it solves]

## Current Behavior (Before)

```bash
# How things work currently
[current commands]

# Current output:
[current output]

# Limitations:
- [Limitation 1]
- [Limitation 2]
```

## New Behavior (After)

```bash
# How things work with new feature
[new commands]

# New output:
[new output]

# Improvements:
- [Improvement 1]
- [Improvement 2]
```

## Usage Scenarios

### Scenario 1: [Primary Use Case]

**Goal**: [What user achieves with this feature]

**Before** (old approach):
```bash
[old complex process]
```

**After** (new approach):
```bash
[new simple process]
```

**Benefits**:
- Saves [X] steps
- Reduces complexity
- [Other benefit]

### Scenario 2: [Secondary Use Case]

[Similar before/after structure]

### Scenario 3: [Edge Case or Advanced Usage]

[Demonstrate advanced capabilities]

## Configuration Examples

[If feature requires configuration]

```yaml
# Example configuration
feature:
  enabled: true
  options:
    setting1: value
    setting2: value
```

## Benefits

1. **[Key Benefit]**: [Detailed explanation]
2. **[Another Benefit]**: [How it helps users]
3. **[Third Benefit]**: [Impact on workflow]

## Compatibility Notes

- Works with: [versions/tools]
- Requires: [dependencies]
- Conflicts: [known issues]
</template>

<template name="workflow-integration-usage">
# [Workflow Name] - Usage Guide

## Document Type: How-To Guide

## Overview

[Description of the workflow and its purpose]

**Available Commands:**
- `/ace:[command1]` - [Description]
- `/ace:[command2]` - [Description]
- `ace-taskflow [command]` - [CLI equivalent if exists]

## Command Types

### Claude Code Commands (Slash Commands)
Commands starting with `/` are executed **within Claude Code**:
```
/ace:[command]
```

### Bash CLI Commands
Commands without `/` are **terminal/bash commands**:
```bash
ace-taskflow [command]
```

## Usage Scenarios

### Scenario 1: [Complete Workflow]

**Goal**: [End-to-end process description]

```bash
# Step 1: Preparation (bash command)
ace-taskflow list

# Step 2: Execution (Claude command)
/ace:[command]

# Expected Output:
Processing...
✓ Item 1 processed
✓ Item 2 processed
Summary: 2 items completed
```

### Scenario 2: [Partial Workflow]

**Goal**: [Specific part of workflow]

[Steps with mixed command types]

### Scenario 3: [Error Recovery]

**Goal**: [How to handle failures]

[Recovery steps]

## Command Reference

### `/ace:[command1]`

**Purpose**: [What it does]

**Usage**:
```
/ace:[command1] [arguments]
```

**Process**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Output Example**:
```
[Sample output]
```

### `ace-taskflow [command]`

**Purpose**: [CLI tool purpose]

**Usage**:
```bash
ace-taskflow [command] [options]
```

**Options**:
| Option | Description |
|--------|-------------|
| `--flag` | [Description] |

## Workflow Integration

### Typical Weekly Workflow

```
Monday: [Step 1]
/ace:[command1]

Tuesday: [Step 2]
/ace:[command2]

Wednesday-Thursday: [Step 3]
/ace:[command3]

Friday: [Review]
/ace:[command4]
```

## Tips and Best Practices

### 1. Start Small
[Advice for beginners]

### 2. Batch Processing
[How to handle multiple items]

### 3. Error Handling
[How to recover from failures]

## Troubleshooting

### Command Not Found

**Symptom**: `command not found` error

**Solution**:
```bash
# Verify installation
which ace-taskflow

# Check workflow exists
ace-nav wfi://[workflow] --verify
```

### Permission Errors

[Common permission issues and fixes]

## Migration Notes

**Legacy Commands** (deprecated):
- `/old-command` → Use `/ace:new-command`

**Key Differences**:
- [Difference 1]
- [Difference 2]
</template>

<template name="command-reference-format">
## Command: `[command name]`

**Purpose**: [One-line description]

**Syntax**:
```bash
[command] [required] [<optional>] [--flags]
```

**Parameters**:
- `required`: [Description]
- `<optional>`: [Description] (default: value)

**Options**:
| Flag | Short | Type | Description | Default |
|------|-------|------|-------------|---------|
| `--flag` | `-f` | string | [Description] | [default] |

**Examples**:

```bash
# Example 1: Basic usage
[command] param1
# Output:
[expected output]

# Example 2: With options
[command] param1 --flag value
# Output:
[expected output]

# Example 3: Advanced usage
[command] param1 param2 --flag1 --flag2 value
# Output:
[expected output]
```

**Exit Codes**:
- `0`: Success
- `1`: General error
- `2`: [Specific error]

**See Also**:
- Related command 1
- Related command 2
</template>

</templates>

## Common Patterns

### Pattern Recognition

When updating existing usage documentation, identify which pattern it follows:

1. **CLI Tool Pattern** (ace-git-commit style):
   - Heavy emphasis on command options and configuration
   - Multiple installation/setup sections
   - Extensive troubleshooting

2. **Feature Demo Pattern** (Task 031/032/033 style):
   - Strong before/after comparisons
   - Focus on improvements and benefits
   - Visual examples of changes

3. **Workflow Pattern** (batch operations style):
   - Mixed command types (CLI + Claude)
   - Step-by-step scenarios
   - Integration with other tools

### Quality Checklist

Before completing updates, verify:

- [ ] Document type declared (Tutorial/How-To/Reference/Explanation)
- [ ] Progressive disclosure implemented (Quick Start → Advanced)
- [ ] All examples include expected output
- [ ] Scenario format consistent (Goal/Commands/Output/Next)
- [ ] Command reference tables properly formatted
- [ ] Troubleshooting section included
- [ ] Best practices or tips section added
- [ ] Migration notes included (if applicable)
- [ ] Commands tested and verified working
- [ ] Consistency with project patterns maintained

## Usage Example

> "Update the usage documentation for ace-taskflow retro commands based on user feedback that the examples are unclear"

**Expected Workflow:**
1. Analyze feedback to identify specific issues
2. Locate existing usage.md for retro commands
3. Classify as CLI Tool Guide pattern
4. Update with clearer scenarios and expected outputs
5. Add troubleshooting for common issues
6. Verify all commands work
7. Ensure progressive disclosure from basic to advanced usage