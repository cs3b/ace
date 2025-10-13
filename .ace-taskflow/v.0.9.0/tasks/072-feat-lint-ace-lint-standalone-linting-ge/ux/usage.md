# ace-lint - Usage Guide

## Document Type: How-To Guide + Reference

## Overview

ace-lint is a standalone linting gem that provides comprehensive validation for markdown, YAML, and frontmatter documents using **Ruby-only dependencies**. No Node.js or Python required. It follows proven patterns from the legacy dev-tools code-lint implementation.

**Key Features:**
- **Ruby-Only Stack**: Uses kramdown + kramdown-parser-gfm for markdown, Psych for YAML
- Validates markdown syntax and formatting via kramdown parser
- Validates YAML structure and syntax via Ruby's built-in Psych
- Validates frontmatter schema, required fields, and field types
- Auto-fix/format support via kramdown formatter
- Clear, colorized terminal output
- Subprocess-callable interface for reuse by other ace-* gems
- Zero required external dependencies

## Installation

```bash
# Via Bundler (when available as gem)
gem install ace-lint

# Or add to Gemfile
gem 'ace-lint'
gem 'kramdown', '~> 2.0'
gem 'kramdown-parser-gfm', '~> 1.0'
bundle install

# No Node.js or Python dependencies required!
```

## Quick Start (5 minutes)

Validate a markdown file with frontmatter:

```bash
# Basic validation
ace-lint docs/architecture.md

# Expected output:
Linting: docs/architecture.md
  ✓ Markdown syntax valid (kramdown)
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

# Auto-fix/format issues with kramdown
ace-lint docs/file.md --fix

# Format documents
ace-lint docs/*.md --format
```

### Command Options

| Option | Short | Description | Example |
|--------|-------|-------------|---------|
| `--fix` | `-f` | Auto-format with kramdown | `ace-lint file.md --fix` |
| `--format` | | Format documents with kramdown | `ace-lint file.md --format` |
| `--type TYPE` | `-t` | Specify validation type | `ace-lint file.md --type markdown` |
| `--help` | `-h` | Show help message | `ace-lint --help` |
| `--version` | `-v` | Show version | `ace-lint --version` |

**Validation Types:**
- `markdown`: Markdown syntax via kramdown + kramdown-parser-gfm
- `yaml`: YAML syntax via Psych (Ruby built-in)
- `frontmatter`: Frontmatter schema via Psych

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

### Scenario 2: Format Markdown with Kramdown

**Goal**: Automatically format markdown files for consistent styling

**Commands**:
```bash
# Run with auto-fix/format
ace-lint docs/readme.md --fix

# Expected output:
Linting: docs/readme.md
  ✓ Markdown syntax valid
  ⚠ Formatted with kramdown:
    - Normalized heading styles
    - Fixed list formatting
    - Applied consistent line wrapping
Validated: 1 document - Passed with formatting

# File is automatically updated with kramdown formatting applied
```

**Next Steps**: Review the changes and commit

### Scenario 3: Validate YAML Configuration

**Goal**: Validate YAML syntax in configuration files

**Commands**:
```bash
# Validate YAML file with Psych
ace-lint .ace/config.yml --type yaml

# Expected output:
Linting: .ace/config.yml
  ✓ YAML syntax valid (Psych)
Validated: 1 document - Passed
```

### Scenario 4: Pure Ruby Validation (No External Tools)

**Goal**: Validate documents using only Ruby dependencies

**Commands**:
```bash
# Run on any system with Ruby installed
ace-lint docs/guide.md

# Expected output:
Linting: docs/guide.md
  ✓ Markdown syntax valid (kramdown + GFM)
  ✓ Frontmatter present and valid (Psych)
  ✓ Required fields validated
Validated: 1 document - Passed

# Exit code: 0
# No Node.js (markdownlint) or Python (yamllint) needed!
```

**Note**: All core linting uses Ruby gems only

### Scenario 5: Batch Validation with Mixed Results

**Goal**: Validate multiple files and identify which ones have issues

**Commands**:
```bash
# Validate multiple files
ace-lint docs/architecture.md docs/invalid.md docs/tools.md

# Expected output:
Linting: docs/architecture.md ✓
Linting: docs/invalid.md ✗
  - Line 1: Missing required frontmatter
  - Line 15: Invalid YAML syntax in frontmatter (Psych::SyntaxError)
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

# Kramdown formatting options
kramdown:
  line_width: 120
  hard_wrap: false
  auto_ids: true
  gfm_quirks: [:paragraph_end, :no_auto_typographic]
  syntax_highlighter: rouge

# File size limits
limits:
  max_file_size_mb: 10
  warn_threshold_mb: 5

# Optional security scanning
security:
  gitleaks:
    enabled: true  # Only if gitleaks installed
    scan_secrets: true
```

### Global Configuration

Place in `~/.ace/lint/config.yml` for user-wide defaults (optional).

### Kramdown Configuration

All kramdown parser and formatter options are supported:

```yaml
kramdown:
  # Parser options
  input: GFM  # Use GitHub Flavored Markdown
  hard_wrap: false
  auto_ids: true
  footnote_nr: 1
  entity_output: :as_char
  toc_levels: 1..6
  smart_quotes: lsquo,rsquo,ldquo,rdquo

  # Formatter options
  line_width: 120
  remove_block_html_tags: false
  remove_span_html_tags: false
```

## Complete Command Reference

### `ace-lint [FILES...] [OPTIONS]`

**Purpose**: Validate markdown, YAML, and frontmatter documents using Ruby-only tools

**Syntax**:
```bash
ace-lint file1.md file2.md [OPTIONS]
```

**Parameters**:
- `FILES...`: One or more file paths to validate (required)

**Options**:
| Flag | Type | Description | Default |
|------|------|-------------|---------|
| `--fix` | boolean | Auto-format with kramdown | false |
| `--format` | boolean | Format documents with kramdown | false |
| `--type TYPE` | string | Validation type (markdown/yaml/frontmatter) | auto-detect |
| `--help` | boolean | Show help message | |
| `--version` | boolean | Show version | |

**Examples**:

```bash
# Example 1: Basic validation with kramdown
ace-lint docs/guide.md
# Output:
# Linting: docs/guide.md
#   ✓ Markdown syntax valid (kramdown)
#   ✓ Frontmatter schema valid (Psych)
# Validated: 1 document - Passed

# Example 2: Auto-format with kramdown
ace-lint docs/guide.md --fix
# Output:
# Linting: docs/guide.md
#   ✓ Markdown syntax valid
#   ⚠ Formatted with kramdown
# Validated: 1 document - Passed with formatting

# Example 3: Multiple files
ace-lint docs/*.md
# Output:
# Linting: docs/architecture.md ✓
# Linting: docs/tools.md ✓
# Linting: docs/blueprint.md ✓
# Validated: 3 documents - All passed

# Example 4: YAML validation with Psych
ace-lint config.yml --type yaml
# Output:
# Linting: config.yml
#   ✓ YAML syntax valid (Psych)
# Validated: 1 document - Passed
```

**Exit Codes**:
- `0`: All files passed validation
- `1`: One or more files failed validation

## Validation Behavior

### Markdown Validation

**Using kramdown + kramdown-parser-gfm (Ruby gems)**:
- Comprehensive syntax checking via kramdown parser
- GitHub Flavored Markdown support via kramdown-parser-gfm
- Auto-format support with kramdown formatter
- Customizable via kramdown options

**Features**:
- Parse and validate markdown structure
- Detect heading hierarchy issues
- Validate list formatting
- Check code block syntax
- Normalize formatting with --fix

### YAML Validation

**Using Psych (Ruby built-in)**:
- Comprehensive syntax checking
- Native Ruby YAML parser
- Detailed error messages with line numbers
- No external dependencies required

### Frontmatter Validation

**Using Psych (Ruby built-in)**:
- YAML syntax validation
- Required fields checking
- Field type validation
- Schema compliance
- Custom validation rules

## Troubleshooting

### Problem: Kramdown parse error

**Symptom**:
```
✗ Kramdown::Error: Failed to parse markdown
```

**Solution**:
```bash
# Check file encoding
file docs/problematic.md
# Output: docs/problematic.md: UTF-8 Unicode text

# If not UTF-8, convert:
iconv -f ISO-8859-1 -t UTF-8 file.md > file_utf8.md

# Or check for special characters:
cat -A docs/problematic.md | head -20
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

### Problem: Invalid YAML in frontmatter (Psych error)

**Symptom**:
```
✗ Line 5: Psych::SyntaxError: (<unknown>): mapping values are not allowed in this context
```

**Solution**:
```yaml
# Fix YAML syntax
---
# Incorrect (colon in unquoted string)
doc-type: How-To: Guide

# Correct (quoted string)
doc-type: "How-To: Guide"

# Or (alternative format)
doc-type: How-To Guide
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

### 1. Ruby-Only Stack Benefits

ace-lint uses only Ruby dependencies - no Node.js or Python required:

```bash
# Check what's installed
gem list | grep -E "kramdown|psych"
# kramdown (2.4.0)
# kramdown-parser-gfm (1.1.0)
# psych (5.1.0)  # Built into Ruby

# No need for:
# npm install -g markdownlint-cli
# pip install yamllint
```

**Benefits**:
- Simpler installation (Ruby only)
- Consistent with ace-* gem ecosystem
- No cross-language version conflicts
- Works in any Ruby environment

### 2. Configure Kramdown for Your Project

Create `.ace/lint/config.yml` to customize kramdown behavior:

```yaml
kramdown:
  line_width: 120  # Match your project's line width
  hard_wrap: false # Preserve soft wrapping
  auto_ids: true   # Generate heading IDs
  gfm_quirks: [:paragraph_end, :no_auto_typographic]
```

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

Auto-format with kramdown before manual review:

```bash
# Format before review
ace-lint docs/*.md --fix
git diff  # Review changes
git add docs/*.md
```

### 5. Validate Configuration Files

Include YAML configuration files in validation:

```bash
# Validate all YAML configs with Psych
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
    gem install kramdown kramdown-parser-gfm
    ace-lint docs/**/*.md
```

## Benefits Over External Tools

**Before** (Node.js/Python dependencies):
```bash
# Multiple language dependencies
npm install -g markdownlint-cli  # Node.js
pip install yamllint              # Python
gem install ace-lint              # Ruby

# Cross-language version conflicts possible
# Complex CI/CD setup
```

**After** (Ruby-only with ace-lint):
```bash
# Single language dependency
gem install ace-lint kramdown kramdown-parser-gfm

# Consistent Ruby environment
# Simpler CI/CD setup
# Native Psych for YAML (built into Ruby)
```

**Improvements:**
- Single unified interface for all validation types
- Ruby-only stack (no Node.js or Python)
- Consistent output format
- Reusable across ace-* gems
- Proven patterns from legacy code-lint implementation

## See Also

- ace-docs: Documentation management (uses ace-lint for validation)
- ace-core: Configuration management
- kramdown: Ruby markdown parser (https://kramdown.gettalong.org/)
- kramdown-parser-gfm: GFM support for kramdown
- Psych: Ruby's built-in YAML parser
- Legacy code-lint: _legacy/dev-tools/lib/coding_agent_tools/cli/commands/code_lint/
