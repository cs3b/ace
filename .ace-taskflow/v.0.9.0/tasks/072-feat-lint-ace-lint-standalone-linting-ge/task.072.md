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
- **Process**: Runs appropriate linters (external or built-in), validates syntax and structure, optionally applies fixes
- **Output**: Validation results (pass/fail) with detailed errors/warnings, auto-fixed files (if --fix used)

### Expected Behavior

The ace-lint tool provides standalone linting capabilities for markdown, YAML, and frontmatter validation that can be used by ace-docs and other ace-* gems.

**Document Validation:**
- Accepts one or more file paths: `ace-lint docs/file1.md docs/file2.md`
- Supports type filtering: `ace-lint --type markdown docs/*.md`
- Validates syntax, structure, and formatting
- Reports errors and warnings with line numbers and descriptions
- Supports auto-fix mode: `ace-lint --fix docs/file.md`

**External Linter Integration:**
- Detects availability of markdownlint (Node.js) for markdown files
- Detects availability of yamllint (Python) for YAML files
- Uses external linters when available for comprehensive validation
- Falls back gracefully to basic built-in validation when external linters not found
- Displays clear warnings when falling back to basic validation

**Built-in Validation (Graceful Fallbacks):**
- Markdown: Checks frontmatter presence, basic structure validation
- YAML: Uses Ruby YAML.parse for syntax validation
- Frontmatter: Validates YAML structure, required fields, field types (no external dependencies)

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
#   ✓ Markdown syntax valid
#   ✓ Frontmatter schema valid
# Validated: 1 document - Passed

# Lint with auto-fix
ace-lint docs/file.md --fix
# Output:
# Linting: docs/file.md
#   ✓ Markdown syntax valid
#   ⚠ Fixed 2 formatting issues
# Validated: 1 document - Passed with fixes

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
#   ✓ YAML syntax valid
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
- External linter not found: Display warning, fall back to basic validation
- File not found: Clear error message with file path
- Invalid file type: Error with supported types list
- Parsing errors: Display line number and error description
- Permission errors: Clear error message about file access

**Edge Cases:**
- Empty files: Validate as valid (unless frontmatter required)
- Very large files (>10MB): Warn about potential performance impact
- Binary files: Skip with informative message
- Mixed file types: Process each with appropriate linter
- Files without extensions: Attempt detection from content

### Success Criteria

- [ ] **CLI Interface**: `ace-lint [FILES...] [OPTIONS]` command available with --fix, --format, --type options
- [ ] **External Linter Detection**: Automatically detects markdownlint and yamllint availability
- [ ] **Graceful Fallbacks**: Works without external linters using built-in basic validation with clear warnings
- [ ] **Markdown Validation**: Validates markdown syntax via markdownlint (if available) or basic checks (built-in)
- [ ] **YAML Validation**: Validates YAML syntax via yamllint (if available) or Ruby YAML.parse (built-in)
- [ ] **Frontmatter Validation**: Validates frontmatter schema, required fields, field types (always built-in, no external dependency)
- [ ] **Auto-fix Support**: `--fix` flag applies automatic fixes when supported by external linters
- [ ] **Colorized Output**: Terminal output uses colors (green/red/yellow) for clear status indication
- [ ] **Exit Codes**: Returns 0 for success, 1 for failures (proper subprocess integration)
- [ ] **Reusable Design**: Can be called as subprocess by ace-docs and other ace-* gems
- [ ] **Error Messages**: Clear, actionable error messages with file paths and line numbers

### Validation Questions

- [ ] **Configuration**: Should ace-lint support configuration files (.ace/lint/config.yml) or rely only on command-line options?
- [ ] **Required Fields**: Should frontmatter required fields be hardcoded or configurable per project?
- [ ] **External Linter Versions**: Should we validate minimum versions for markdownlint/yamllint or accept any version?
- [ ] **Performance**: Should we parallelize validation of multiple files or process sequentially?
- [ ] **Output Format**: Should we support JSON output format for machine parsing in addition to human-readable terminal output?
- [ ] **Severity Levels**: Should warnings vs errors be distinguishable (warnings don't fail validation)?

## Objective

Create a standalone, reusable linting gem that provides comprehensive markdown, YAML, and frontmatter validation with optional external linter integration. The gem should be usable by ace-docs for validation delegation and by other ace-* gems that need document linting capabilities. Focus on graceful degradation when external linters are unavailable.

## Scope of Work

### User Experience Scope
- Command-line interface for file validation
- Auto-fix capabilities (when external linters support it)
- Clear, colorized terminal output
- Graceful fallback when external linters unavailable

### System Behavior Scope
- Markdown linting via markdownlint adapter (optional)
- YAML linting via yamllint adapter (optional)
- Frontmatter validation (always built-in)
- External command detection and availability checking
- Subprocess integration for external linters

### Interface Scope
- CLI: `ace-lint [FILES...] [OPTIONS]`
- Options: `--fix`, `--format`, `--type [markdown|yaml|frontmatter]`
- Exit codes: 0 (success), 1 (validation failures)
- Subprocess callable interface for other ace-* gems

### Deliverables

#### Behavioral Specifications
- CLI command interface with all options
- External linter detection and fallback logic
- Validation result format and output structure
- Error handling and edge case behaviors

#### Validation Artifacts
- Test scenarios for all linter types (external and built-in)
- Fallback behavior validation (when external linters missing)
- Integration test scenarios (subprocess calls from other gems)

#### Workflow Components
- Usage documentation (ux/usage.md)
- Example validation outputs for different scenarios
- Configuration examples (if configuration is included)

## Out of Scope

- ❌ **Semantic Validation**: Deep LLM-based content validation (future enhancement)
- ❌ **Custom Rules**: User-defined linting rules or plugins (use external linters' config files)
- ❌ **IDE Integration**: Editor plugins or language server protocol support
- ❌ **Continuous Monitoring**: Watch mode or file system monitoring
- ❌ **Multi-Repository**: Cross-repository linting or aggregated reporting
- ❌ **Auto-Installation**: Automatically installing markdownlint or yamllint (user responsibility)

## References

- Parent task: .ace-taskflow/v.0.9.0/tasks/071-docs-docs-complete-ace-docs-batch-analys/task.071.md (Phase 2: ace-lint Gem Creation)
- External linters:
  - markdownlint: https://github.com/DavidAnson/markdownlint
  - yamllint: https://github.com/adrienverge/yamllint
- Related gems:
  - ace-docs (will use ace-lint for validation delegation)
  - ace-core (configuration management)
- Architecture: docs/architecture.md (ATOM pattern)
- Testing: docs/testing-patterns.md
