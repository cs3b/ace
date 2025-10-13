# ace-lint - Usage Guide

## Document Type: How-To Guide + Reference

## Overview

ace-lint is a standalone linting gem that provides comprehensive validation for markdown, YAML, and frontmatter documents. It integrates with external linters (markdownlint, yamllint) when available and gracefully falls back to built-in validation when they're not installed.

**Key Features:**
- Validates markdown syntax and formatting
- Validates YAML structure and syntax
- Validates frontmatter schema, required fields, and field types
- Auto-fix support for markdown and YAML (via external linters)
- Graceful fallbacks to built-in validation when external linters unavailable
- Clear, colorized terminal output
- Subprocess-callable interface for reuse by other ace-* gems
- Zero required external dependencies (all optional with fallbacks)

## Installation

```bash
# Via Bundler (when available as gem)
gem install ace-lint

# Or add to Gemfile
gem 'ace-lint'
bundle install

# Optional external linters (for best results)
npm install -g markdownlint-cli  # Markdown validation
pip install yamllint              # YAML validation
```

## Quick Start (5 minutes)

Validate a markdown file with frontmatter:

```bash
# Basic validation
ace-lint docs/architecture.md

# Expected output:
Linting: docs/architecture.md
  ✓ Markdown syntax valid
  ✓ Frontmatter schema valid
Validated: 1 document - Passed
```

**Success criteria:** Exit code 0 and green checkmarks indicate successful validation

## Command Interface

### Basic Usage

```bash
# Validate single file
ace-lint docs/file.md

# Validate multiple files
ace-lint docs/*.md

# Validate specific file type
ace-lint config.yml --type yaml

# Auto-fix issues (when external linters support it)
ace-lint docs/file.md --fix

# Format documents
ace-lint docs/*.md --format
```

### Command Options

| Option | Short | Description | Example |
|--------|-------|-------------|---------|
| `--fix` | `-f` | Auto-fix issues when possible | `ace-lint file.md --fix` |
| `--format` | | Format documents | `ace-lint file.md --format` |
| `--type TYPE` | `-t` | Specify validation type | `ace-lint file.md --type markdown` |
| `--help` | `-h` | Show help message | `ace-lint --help` |
| `--version` | `-v` | Show version | `ace-lint --version` |

**Validation Types:**
- `markdown`: Markdown syntax and structure
- `yaml`: YAML syntax and structure
- `frontmatter`: Frontmatter schema and required fields

## Common Scenarios

### Scenario 1: Validate Documentation Before Commit

**Goal**: Ensure all markdown documentation is valid before committing changes

**Commands**:
```bash
# Validate all markdown files in docs/
ace-lint docs/*.md

# Expected output:
Linting: docs/architecture.md ✓
Linting: docs/tools.md ✓
Linting: docs/blueprint.md ✓
Validated: 3 documents - All passed

# Exit code: 0 (success)
```

**Next Steps**: Commit the validated files with confidence

### Scenario 2: Fix Markdown Formatting Issues

**Goal**: Automatically fix common markdown formatting issues

**Commands**:
```bash
# Run with auto-fix
ace-lint docs/readme.md --fix

# Expected output:
Linting: docs/readme.md
  ✓ Markdown syntax valid
  ⚠ Fixed 3 formatting issues:
    - Line 15: Added blank line before list
    - Line 23: Fixed heading increment
    - Line 45: Removed trailing spaces
Validated: 1 document - Passed with fixes

# File is automatically updated with fixes applied
```

**Next Steps**: Review the changes and commit

### Scenario 3: Validate YAML Configuration

**Goal**: Validate YAML syntax in configuration files

**Commands**:
```bash
# Validate YAML file
ace-lint .ace/config.yml --type yaml

# Expected output:
Linting: .ace/config.yml
  ✓ YAML syntax valid
Validated: 1 document - Passed
```

### Scenario 4: Validation Without External Linters

**Goal**: Validate documents when markdownlint/yamllint are not installed

**Commands**:
```bash
# Run on system without external linters
ace-lint docs/guide.md

# Expected output:
Linting: docs/guide.md
  ⚠ markdownlint not found - using built-in validation
  ✓ Basic markdown structure valid
  ✓ Frontmatter present and parseable
Validated: 1 document - Passed (basic validation)

# Exit code: 0 (still succeeds with fallback)
```

**Note**: Install markdownlint via `npm install -g markdownlint-cli` for comprehensive validation

### Scenario 5: Batch Validation with Mixed Results

**Goal**: Validate multiple files and identify which ones have issues

**Commands**:
```bash
# Validate multiple files
ace-lint docs/architecture.md docs/invalid.md docs/tools.md

# Expected output:
Linting: docs/architecture.md ✓
Linting: docs/invalid.md ✗
  - Line 15: Missing required frontmatter field 'doc-type'
  - Line 23: Invalid YAML syntax in frontmatter
Linting: docs/tools.md ✓
Validated: 3 documents - 2 passed, 1 failed

# Exit code: 1 (failure)
```

**Next Steps**: Fix issues in `docs/invalid.md` and re-run validation

### Scenario 6: Integration with ace-docs

**Goal**: Use ace-lint as subprocess from ace-docs validate command

**Commands**:
```bash
# Called from ace-docs (subprocess)
ace-docs validate docs/architecture.md

# Internally calls:
# ace-lint docs/architecture.md

# Expected output (from ace-docs):
Validating: docs/architecture.md
  ✓ Valid

# ace-docs parses ace-lint output and formats accordingly
```

## Configuration

ace-lint can be used without configuration, but optional configuration provides customization.

### Project Configuration

Create `.ace/lint/config.yml` for project-specific settings:

```yaml
# Frontmatter validation rules
frontmatter:
  required_fields:
    - doc-type
    - purpose
  field_types:
    doc-type: string
    purpose: string
    priority: string

# External linter detection
linters:
  markdownlint:
    enabled: true
    fallback_warning: true
  yamllint:
    enabled: true
    fallback_warning: true

# File size limits
limits:
  max_file_size_mb: 10
  warn_threshold_mb: 5
```

### Global Configuration

Place in `~/.ace/lint/config.yml` for user-wide defaults (optional).

### External Linter Configuration

Configure external linters using their own config files:

**markdownlint** (`.markdownlintrc`):
```json
{
  "default": true,
  "MD013": false,
  "MD033": false
}
```

**yamllint** (`.yamllint`):
```yaml
extends: default
rules:
  line-length:
    max: 120
  indentation:
    spaces: 2
```

## Complete Command Reference

### `ace-lint [FILES...] [OPTIONS]`

**Purpose**: Validate markdown, YAML, and frontmatter documents

**Syntax**:
```bash
ace-lint file1.md file2.md [OPTIONS]
```

**Parameters**:
- `FILES...`: One or more file paths to validate (required)

**Options**:
| Flag | Type | Description | Default |
|------|------|-------------|---------|
| `--fix` | boolean | Auto-fix issues when possible | false |
| `--format` | boolean | Format documents | false |
| `--type TYPE` | string | Validation type (markdown/yaml/frontmatter) | auto-detect |
| `--help` | boolean | Show help message | |
| `--version` | boolean | Show version | |

**Examples**:

```bash
# Example 1: Basic validation
ace-lint docs/guide.md
# Output:
# Linting: docs/guide.md
#   ✓ Markdown syntax valid
#   ✓ Frontmatter schema valid
# Validated: 1 document - Passed

# Example 2: Auto-fix issues
ace-lint docs/guide.md --fix
# Output:
# Linting: docs/guide.md
#   ✓ Markdown syntax valid
#   ⚠ Fixed 2 issues
# Validated: 1 document - Passed with fixes

# Example 3: Multiple files
ace-lint docs/*.md
# Output:
# Linting: docs/architecture.md ✓
# Linting: docs/tools.md ✓
# Linting: docs/blueprint.md ✓
# Validated: 3 documents - All passed

# Example 4: YAML validation
ace-lint config.yml --type yaml
# Output:
# Linting: config.yml
#   ✓ YAML syntax valid
# Validated: 1 document - Passed
```

**Exit Codes**:
- `0`: All files passed validation
- `1`: One or more files failed validation

## Validation Behavior

### Markdown Validation

**With markdownlint (preferred)**:
- Comprehensive syntax checking
- Style rule enforcement
- Auto-fix support for many issues
- Customizable via `.markdownlintrc`

**Without markdownlint (fallback)**:
- Basic structure validation
- Frontmatter presence check
- Heading hierarchy verification
- Warning displayed about using fallback

### YAML Validation

**With yamllint (preferred)**:
- Comprehensive syntax checking
- Style rule enforcement
- Customizable via `.yamllint`

**Without yamllint (fallback)**:
- Ruby YAML.parse validation
- Basic syntax error detection
- Warning displayed about using fallback

### Frontmatter Validation

**Always Built-in** (no external dependency):
- YAML syntax validation
- Required fields checking
- Field type validation
- Schema compliance

## Troubleshooting

### Problem: External linter not found

**Symptom**:
```
⚠ markdownlint not found - using built-in validation
```

**Solution**:
```bash
# Install markdownlint globally
npm install -g markdownlint-cli

# Verify installation
which markdownlint
# Output: /usr/local/bin/markdownlint

# Or install yamllint
pip install yamllint

# Verify installation
which yamllint
# Output: /usr/local/bin/yamllint
```

### Problem: Missing required frontmatter field

**Symptom**:
```
✗ Line 1: Missing required frontmatter field 'doc-type'
```

**Solution**:
```markdown
<!-- Add missing field to frontmatter -->
---
doc-type: guide
purpose: Usage documentation
---

# Document Title
```

### Problem: Invalid YAML in frontmatter

**Symptom**:
```
✗ Line 5: Invalid YAML syntax - expected ':' after key
```

**Solution**:
```yaml
# Fix YAML syntax
---
# Incorrect (missing colon)
doc-type guide

# Correct
doc-type: guide
---
```

### Problem: Permission denied error

**Symptom**:
```
Error: Permission denied - /path/to/file.md
```

**Solution**:
```bash
# Check file permissions
ls -la /path/to/file.md

# Fix permissions if needed
chmod 644 /path/to/file.md

# Or run with appropriate permissions
sudo ace-lint /path/to/file.md
```

### Problem: File too large warning

**Symptom**:
```
⚠ Warning: File size exceeds 5MB - validation may be slow
```

**Solution**:
- Split large files into smaller documents
- Or adjust limit in `.ace/lint/config.yml`:
  ```yaml
  limits:
    warn_threshold_mb: 10
  ```

## Best Practices

### 1. Install External Linters for Best Results

While ace-lint works without external linters, installing them provides comprehensive validation:

```bash
# Markdown validation
npm install -g markdownlint-cli

# YAML validation
pip install yamllint
```

### 2. Configure External Linters

Create configuration files to customize validation rules:

- `.markdownlintrc` - Markdown rules
- `.yamllint` - YAML rules

### 3. Run Before Committing

Add ace-lint to your pre-commit workflow:

```bash
# In .git/hooks/pre-commit
#!/bin/bash
ace-lint docs/*.md
if [ $? -ne 0 ]; then
  echo "Markdown validation failed. Fix issues before committing."
  exit 1
fi
```

### 4. Use Auto-fix Regularly

Auto-fix common formatting issues automatically:

```bash
# Fix before manual review
ace-lint docs/*.md --fix
git diff  # Review changes
git add docs/*.md
```

### 5. Validate Configuration Files

Include YAML configuration files in validation:

```bash
# Validate all YAML configs
ace-lint .ace/**/*.yml --type yaml
```

## Integration Patterns

### From ace-docs

ace-docs uses ace-lint as subprocess for validation:

```ruby
# ace-docs internal usage
result = Open3.capture3("ace-lint", file_path, "--type", "markdown")
exit_code = result[2].exitstatus
# Parse output and format for ace-docs display
```

### From Other ace-* Gems

Any ace-* gem can use ace-lint via subprocess:

```ruby
# Generic subprocess pattern
require 'open3'

def validate_file(path)
  stdout, stderr, status = Open3.capture3("ace-lint", path)
  {
    success: status.exitstatus == 0,
    output: stdout,
    errors: stderr
  }
end
```

### From CI/CD Pipelines

```yaml
# GitHub Actions example
- name: Validate documentation
  run: |
    gem install ace-lint
    npm install -g markdownlint-cli
    ace-lint docs/**/*.md
```

## Benefits Over Manual Validation

**Before** (manual validation):
```bash
# Check each file manually
markdownlint docs/file1.md
markdownlint docs/file2.md
# Check frontmatter separately
# Parse YAML manually
# Check required fields manually
```

**After** (with ace-lint):
```bash
# Single command validates everything
ace-lint docs/*.md
# - Markdown syntax ✓
# - YAML frontmatter ✓
# - Required fields ✓
# - Automatic fallbacks ✓
```

**Improvements:**
- Single unified interface for all validation types
- Automatic detection and graceful fallbacks
- Consistent output format
- Reusable across ace-* gems
- Zero required dependencies (all optional)

## See Also

- ace-docs: Documentation management (uses ace-lint for validation)
- ace-core: Configuration management
- markdownlint: External markdown linter (optional)
- yamllint: External YAML linter (optional)
