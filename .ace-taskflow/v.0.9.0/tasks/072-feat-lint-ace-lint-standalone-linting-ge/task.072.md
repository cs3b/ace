---
id: v.0.9.0+task.072
status: draft
priority: high
estimate: 4-6h
dependencies: []
---

# Create ace-lint standalone linting gem

## Behavioral Specification

### User Experience
- **Input**: File paths (markdown, YAML, or documents with frontmatter), options for lint type, fix mode
- **Process**: Runs Ruby-based linters, validates syntax and structure, optionally applies fixes
- **Output**: Validation results (pass/fail) with detailed errors/warnings, auto-fixed files (if --fix used)

### Expected Behavior

The ace-lint tool provides standalone linting capabilities for markdown, YAML, and frontmatter validation that can be used by ace-docs and other ace-* gems. **Ruby-only dependencies** - no Node.js or Python required.

**Document Validation:**
- Accepts one or more file paths: `ace-lint docs/file1.md docs/file2.md`
- Supports type filtering: `ace-lint --type markdown docs/*.md`
- Validates syntax, structure, and formatting
- Reports errors and warnings with line numbers and descriptions
- Supports auto-fix mode: `ace-lint --fix docs/file.md`

**Ruby-Based Validation (Core Features):**
- **Markdown**: Uses kramdown + kramdown-parser-gfm (Ruby gems) for parsing and validation
- **YAML**: Uses Ruby's built-in Psych (YAML parser) for syntax validation
- **Frontmatter**: Validates YAML structure, required fields, field types using Ruby YAML parsing
- **Formatting**: kramdown formatter for consistent markdown styling
- **Zero external dependencies**: No Node.js (markdownlint) or Python (yamllint) required

**Optional External Tools (Security Only):**
- **Gitleaks**: Secrets scanning (optional, graceful fallback if not installed)
- Displays clear warnings when external security tools not available
- Core linting never depends on external tools

**Output Formatting:**
- Colorized terminal output (green for pass, red for fail, yellow for warnings)
- Clear error messages with file paths and line numbers
- Summary at end: "Validated: N documents - X passed, Y failed"
- Exit codes: 0 for success, 1 for validation failures

### Interface Contract

```bash
# Basic linting
ace-lint docs/architecture.md
# Output:
# Linting: docs/architecture.md
#   ✓ Markdown syntax valid (kramdown)
#   ✓ Frontmatter schema valid
# Validated: 1 document - Passed

# Lint with auto-fix/format
ace-lint docs/file.md --fix
# Output:
# Linting: docs/file.md
#   ✓ Markdown syntax valid
#   ⚠ Formatted with kramdown
# Validated: 1 document - Passed with formatting

# Lint multiple files
ace-lint docs/*.md
# Output:
# Linting: docs/architecture.md ✓
# Linting: docs/tools.md ✓
# Linting: docs/invalid.md ✗
#   - Line 15: Missing required frontmatter field 'doc-type'
# Validated: 3 documents - 2 passed, 1 failed

# Specify validation type
ace-lint config.yml --type yaml
# Output:
# Linting: config.yml
#   ✓ YAML syntax valid (Psych)
# Validated: 1 document - Passed

# Format documents
ace-lint docs/*.md --format
# Output:
# Formatting: docs/architecture.md ✓
# Formatting: docs/tools.md ✓
# Formatted: 2 documents

# Check help
ace-lint --help
# Output: Usage, options, examples

# Exit codes
# 0: All files passed validation
# 1: One or more files failed validation
```

**Error Handling:**
- File not found: Clear error message with file path
- Invalid file type: Error with supported types list
- Parsing errors: Display line number and error description
- Permission errors: Clear error message about file access
- Invalid YAML: Psych exception with line number
- Invalid markdown: kramdown parsing errors with context

**Edge Cases:**
- Empty files: Validate as valid (unless frontmatter required)
- Very large files (>10MB): Warn about potential performance impact
- Binary files: Skip with informative message
- Mixed file types: Process each with appropriate linter
- Files without extensions: Attempt detection from content

### Success Criteria

- [ ] **CLI Interface**: `ace-lint [FILES...] [OPTIONS]` command available with --fix, --format, --type options
- [ ] **Ruby-Only Stack**: Uses only Ruby gems (kramdown, kramdown-parser-gfm, Psych) - no Node.js or Python
- [ ] **Markdown Validation**: Validates markdown syntax via kramdown parser with GFM support
- [ ] **YAML Validation**: Validates YAML syntax via Ruby's Psych parser
- [ ] **Frontmatter Validation**: Validates frontmatter schema, required fields, field types using Psych
- [ ] **Auto-fix/Format Support**: `--fix` flag applies kramdown formatting to markdown files
- [ ] **Colorized Output**: Terminal output uses colors (green/red/yellow) for clear status indication
- [ ] **Exit Codes**: Returns 0 for success, 1 for failures (proper subprocess integration)
- [ ] **Reusable Design**: Can be called as subprocess by ace-docs and other ace-* gems
- [ ] **Error Messages**: Clear, actionable error messages with file paths and line numbers
- [ ] **Optional Security**: Gitleaks integration for secrets scanning (optional, not required)

### Validation Questions

- [ ] **Configuration**: Should ace-lint support configuration files (.ace/lint/config.yml) or rely only on command-line options?
- [ ] **Required Fields**: Should frontmatter required fields be hardcoded or configurable per project?
- [ ] **Kramdown Options**: Which kramdown options should be configurable (line_width, hard_wrap, etc.)?
- [ ] **Performance**: Should we parallelize validation of multiple files or process sequentially?
- [ ] **Output Format**: Should we support JSON output format for machine parsing in addition to human-readable terminal output?
- [ ] **Severity Levels**: Should warnings vs errors be distinguishable (warnings don't fail validation)?
- [ ] **Link Validation**: Should we include markdown link validation like the legacy system?

## Objective

Create a standalone, reusable linting gem that provides comprehensive markdown, YAML, and frontmatter validation using **Ruby-only dependencies**. The gem should be usable by ace-docs for validation delegation and by other ace-* gems that need document linting capabilities. Follow the proven patterns from the legacy dev-tools code-lint implementation.

## Scope of Work

### User Experience Scope
- Command-line interface for file validation
- Auto-fix/formatting capabilities via kramdown
- Clear, colorized terminal output
- Ruby-only stack (no Node.js or Python required)

### System Behavior Scope
- Markdown linting via kramdown + kramdown-parser-gfm (Ruby gems)
- YAML linting via Psych (Ruby built-in)
- Frontmatter validation via Psych
- Optional gitleaks integration for security scanning
- Subprocess callable interface for other gems

### Interface Scope
- CLI: `ace-lint [FILES...] [OPTIONS]`
- Options: `--fix`, `--format`, `--type [markdown|yaml|frontmatter]`
- Exit codes: 0 (success), 1 (validation failures)
- Subprocess callable interface for other ace-* gems

### Deliverables

#### Behavioral Specifications
- CLI command interface with all options
- Ruby-based validation logic (kramdown, Psych)
- Validation result format and output structure
- Error handling and edge case behaviors

#### Validation Artifacts
- Test scenarios for all linter types (kramdown, Psych)
- Integration test scenarios (subprocess calls from other gems)
- Kramdown formatting tests

#### Workflow Components
- Usage documentation (ux/usage.md)
- Example validation outputs for different scenarios
- Configuration examples (kramdown options, frontmatter schema)

## Out of Scope

- ❌ **Node.js Dependencies**: No markdownlint or other Node.js tools
- ❌ **Python Dependencies**: No yamllint or other Python tools
- ❌ **Semantic Validation**: Deep LLM-based content validation (future enhancement)
- ❌ **Custom Rules**: User-defined linting rules or plugins
- ❌ **IDE Integration**: Editor plugins or language server protocol support
- ❌ **Continuous Monitoring**: Watch mode or file system monitoring
- ❌ **Multi-Repository**: Cross-repository linting or aggregated reporting

## References

- Parent task: .ace-taskflow/v.0.9.0/tasks/071-docs-docs-complete-ace-docs-batch-analys/task.071.md (Phase 2: ace-lint Gem Creation)
- Legacy implementation: _legacy/dev-tools/lib/coding_agent_tools/cli/commands/code_lint/ (proven Ruby-based patterns)
- Ruby gems:
  - kramdown: https://github.com/gettalong/kramdown
  - kramdown-parser-gfm: https://github.com/kramdown/parser-gfm
  - Psych: Ruby built-in YAML parser
- Optional external tools:
  - gitleaks: https://github.com/gitleaks/gitleaks (secrets scanning)
- Related gems:
  - ace-docs (will use ace-lint for validation delegation)
  - ace-core (configuration management)
- Architecture: docs/architecture.md (ATOM pattern)
- Testing: docs/testing-patterns.md
