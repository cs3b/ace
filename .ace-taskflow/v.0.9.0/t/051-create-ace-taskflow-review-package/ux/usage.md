# ace-review Usage Guide

## Document Type: How-To Guide + Reference

## Overview

**ace-review** is a dedicated code review tool that enables automated code analysis and quality improvement across releases. It provides preset-based review workflows using LLM-powered analysis to identify code quality issues, architectural concerns, and improvement opportunities.

**Key Features:**
- Preset-based code review with configurable analysis criteria
- Release-aware storage and organization
- Flexible configuration with preset overrides
- LLM-powered analysis using multiple providers
- Integration with ace-taskflow release structure

**Note**: Review synthesis is handled via workflow instructions (`wfi://synthesize-reviews`), not as a CLI command.

## Quick Start (5 minutes)

Get started with a basic pull request review:

```bash
# Review current PR changes
ace-review code --preset pr

# Expected output:
Analyzing code with preset 'pr'...
Running git diff origin/main...HEAD
Generating review with google:gemini-2.5-flash...
✓ Review saved: .ace-taskflow/v.0.9.0/reviews/review-2025-10-03-143022.md
```

**Success criteria:** Review document created in `.ace-taskflow/<release>/reviews/`

## Command Interface

### Basic Usage

```bash
# Review code using default preset
ace-review code

# Review code with specific preset
ace-review code --preset security

# Review code with custom output location
ace-review code --preset pr --output-dir ./reviews
```

### Command Options

#### `ace-review code`

| Option | Short | Description | Example |
|--------|-------|-------------|---------|
| `--preset` | `-p` | Preset name to use | `--preset security` |
| `--output-dir` | `-o` | Custom output directory | `--output-dir ./reviews` |
| `--help` | `-h` | Show help message | `--help` |

## Common Scenarios

### Scenario 1: Pull Request Review

**Goal**: Review code changes in a pull request before merging

**Commands**:
```bash
# Review PR changes with default preset
ace-review code --preset pr
```

**Expected Output**:
```
Analyzing code with preset 'pr'...
Loading context: project documentation
Extracting subject: git diff origin/main...HEAD
Generating review with google:gemini-2.5-flash...

Review Summary:
- 5 files changed
- 12 suggestions generated
- 3 high-priority items
- 2 security considerations

✓ Review saved: .ace-taskflow/v.0.9.0/reviews/review-2025-10-03-143022.md
```

**Next Steps**: Review the generated markdown file and address high-priority items

### Scenario 2: Security-Focused Review

**Goal**: Perform deep security analysis of recent changes

**Commands**:
```bash
# Security review of last 5 commits
ace-review code --preset security
```

**Expected Output**:
```
Analyzing code with preset 'security'...
Focus: Security and vulnerability analysis
Analyzing last 5 commits...

Security Findings:
⚠️  3 potential security issues detected
✓  2 best practices confirmed
ℹ️  4 recommendations for hardening

✓ Review saved: .ace-taskflow/v.0.9.0/reviews/security-review-2025-10-03.md
```

**Next Steps**: Address critical security findings before deployment

### Scenario 3: Documentation Review

**Goal**: Review documentation changes for clarity and completeness

**Commands**:
```bash
# Review markdown documentation changes
ace-review code --preset docs
```

**Expected Output**:
```
Analyzing code with preset 'docs'...
Focus: Documentation quality and completeness
Analyzing *.md files...

Documentation Analysis:
✓  Structure follows Diátaxis framework
✓  All examples include expected output
⚠️  2 sections missing cross-references
ℹ️  3 opportunities for progressive disclosure

✓ Review saved: .ace-taskflow/v.0.9.0/reviews/docs-review-2025-10-03.md
```

### Scenario 4: Custom Preset Review

**Goal**: Review code with a custom preset for specific project needs

**Commands**:
```bash
# First, create custom preset at .ace/review/presets/my-preset.yml
# Then run review with custom preset
ace-review code --preset my-preset
```

**Expected Output**:
```
Analyzing code with preset 'my-preset'...
Loading custom preset from .ace/review/presets/my-preset.yml
Applying custom focus areas and guidelines...

✓ Review saved: .ace-taskflow/v.0.9.0/reviews/my-preset-review-2025-10-03.md
```

## Configuration

### Project Configuration

Main configuration file at `.ace/review/code.yml`:

```yaml
# Default settings
defaults:
  model: "google:gemini-2.5-flash"
  output_format: "markdown"
  context: "project"

# Storage configuration
storage:
  base_path: ".ace-taskflow/%{release}/reviews"
  auto_organize: true

# Preset definitions
presets:
  pr:
    description: "Pull request review"
    prompt_composition:
      base: "system"
      format: "standard"
      guidelines:
        - "tone"
        - "icons"
    context: "project"
    subject:
      commands:
        - git diff origin/main...HEAD
        - git log origin/main..HEAD --oneline
```

### Custom Presets

Create individual preset files in `.ace/review/presets/`:

```yaml
# .ace/review/presets/my-team-review.yml
description: "Team-specific review criteria"
prompt_composition:
  base: "system"
  format: "detailed"
  focus:
    - "quality/performance"
    - "architecture/patterns"
  guidelines:
    - "tone"
    - "icons"
context:
  files:
    - docs/team-guidelines.md
    - docs/architecture.md
subject:
  commands:
    - git diff HEAD~1..HEAD
```

### Configuration Cascade

Configuration follows ace-core cascade pattern:

1. Project: `./.ace/review/code.yml`
2. User: `~/.ace/review/code.yml`
3. Defaults: Built-in preset definitions

Preset files in `.ace/review/presets/` override main config presets with the same name.

## Complete Command Reference

### `ace-review code`

Perform code review using preset-based configuration.

**Syntax**:
```bash
ace-review code [--preset <name>] [--output-dir <path>]
```

**Parameters**:
- None (uses current working directory)

**Options**:
| Flag | Short | Type | Description | Default |
|------|-------|------|-------------|---------|
| `--preset` | `-p` | string | Preset configuration to use | `pr` |
| `--output-dir` | `-o` | path | Custom output directory | `.ace-taskflow/<release>/reviews` |
| `--verbose` | `-v` | flag | Verbose output | `false` |
| `--help` | `-h` | flag | Show help message | - |

**Examples**:

```bash
# Example 1: Basic PR review
ace-review code
# Output:
# Analyzing code with preset 'pr'...
# ✓ Review saved: .ace-taskflow/v.0.9.0/reviews/review-2025-10-03.md

# Example 2: Security review
ace-review code --preset security
# Output:
# Analyzing code with preset 'security'...
# ⚠️ 3 potential security issues detected
# ✓ Review saved: .ace-taskflow/v.0.9.0/reviews/security-review-2025-10-03.md

# Example 3: Custom output location
ace-review code --preset docs --output-dir ./my-reviews
# Output:
# Analyzing code with preset 'docs'...
# ✓ Review saved: ./my-reviews/docs-review-2025-10-03.md
```

**Exit Codes**:
- `0`: Success
- `1`: General error (invalid preset, configuration error)
- `2`: Review generation failed

**See Also**:
- Configuration documentation in `.ace/review/code.yml`
- Preset configuration in `.ace/review/presets/`

**Note on Review Synthesis**:
Synthesis of multiple reviews is handled via workflow instructions (`wfi://synthesize-reviews`), not as a CLI command. This allows for flexible manual analysis of 2-4 review files to identify patterns and systemic issues.

## Available Presets

Built-in presets (from `.ace/review/code.yml`):

| Preset | Focus | Use Case |
|--------|-------|----------|
| `pr` | General review | Pull request reviews |
| `code` | Code quality | Architecture and conventions |
| `docs` | Documentation | Documentation changes |
| `security` | Security | Vulnerability analysis |
| `performance` | Performance | Optimization opportunities |
| `test` | Test quality | Test coverage and quality |
| `agents` | Agent definitions | Agent file reviews |

## Troubleshooting

### Problem: Preset Not Found

**Symptom**: `Error: Preset 'my-preset' not found`

**Solution**:
```bash
# List available presets (check config file)
cat .ace/review/code.yml | grep -A 2 "presets:"

# Verify custom preset file exists
ls -la .ace/review/presets/

# Use built-in preset
ace-review code --preset pr
```

### Problem: Output Directory Not Found

**Symptom**: `Error: Output directory './reviews' does not exist`

**Solution**:
```bash
# Create output directory
mkdir -p ./reviews

# Or use default location
ace-review code --preset pr
```

### Problem: LLM Provider Error

**Symptom**: `Error: Failed to connect to LLM provider`

**Solution**:
```bash
# Check LLM configuration
cat .ace/review/code.yml | grep "model:"

# Verify API keys are set
echo $GOOGLE_API_KEY

# Test with different model
# Edit .ace/review/code.yml and change model
```

## Best Practices

1. **Use Appropriate Presets**: Choose presets that match your review focus (security for security reviews, docs for documentation, etc.)

2. **Regular Review**: Run `ace-review code --preset pr` before merging pull requests

3. **Custom Presets for Teams**: Create team-specific presets in `.ace/review/presets/` that encode your team's standards and focus areas

4. **Manual Synthesis**: Periodically review 2-4 recent reviews together using `wfi://synthesize-reviews` to identify patterns and systemic issues

5. **Archive Old Reviews**: Reviews are stored per-release, making it easy to see quality evolution over time

6. **Actionable Findings**: Convert review findings into tasks using `ace-taskflow task draft`

## Migration Notes

This package replaces the previous `code-review` commands from `dev-tools`.

### Command Migration

| Old Command | New Command | Notes |
|-------------|-------------|-------|
| `code-review` | `ace-review code` | Direct replacement |
| `code-review-synthesize` | `wfi://synthesize-reviews` | Workflow only, no CLI |
| `code-review --preset pr` | `ace-review code --preset pr` | Preset system unchanged |

### Configuration Migration

Old configuration location:
```
.coding-agent/code-review.yml
```

New configuration location:
```
.ace/review/code.yml
.ace/review/presets/*.yml
```

**Migration Steps**:
```bash
# 1. Copy existing config
cp .coding-agent/code-review.yml .ace/review/code.yml

# 2. Extract custom presets to separate files (optional)
# Create .ace/review/presets/ and move preset definitions

# 3. Update workflow files to use new commands
# Replace 'code-review' with 'ace-review code'
# Synthesis is now via workflow instructions only (no CLI)
```

### Breaking Changes

1. **No backward compatibility**: Old `code-review` commands will not work after migration
2. **Configuration location**: Must update config path from `.coding-agent/` to `.ace/review/`
3. **Storage location**: Reviews now default to `.ace-taskflow/<release>/reviews/` instead of previous location
4. **Synthesis CLI removed**: `code-review-synthesize` replaced with workflow instructions (`wfi://synthesize-reviews`)

### What Stays the Same

- Preset structure and format
- Review output format
- LLM provider configuration
- Core review analysis logic
