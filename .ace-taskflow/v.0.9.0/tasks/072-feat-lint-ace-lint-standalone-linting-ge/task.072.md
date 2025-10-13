---
id: v.0.9.0+task.072
status: pending
priority: high
estimate: 4-6h
dependencies: []
---

# Create ace-lint standalone linting gem

## 0. Directory Audit ✅

_Command run:_

```bash
ls -la | grep ace
```

_Result excerpt:_

```
drwxr-xr-x@ ace-docs/
drwxr-xr-x@ ace-core/
drwxr-xr-x@ ace-taskflow/
drwxr-xr-x@ ace-nav/
... (other ace-* gems)
```

**Current State:**
- No ace-lint directory exists yet
- ace-docs uses inline validation (needs extraction)
- Legacy code-lint in _legacy/dev-tools/ for reference
- kramdown and psych gems already in environment

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

## Phases

1. **Gem Scaffolding** - Create gem structure with ATOM architecture
2. **Core Linters** - Implement kramdown, Psych, and frontmatter validators
3. **CLI Interface** - Build Thor-based CLI with options
4. **Testing** - Comprehensive test coverage for all linters
5. **Integration** - Connect with ace-docs and verify subprocess interface

## Technical Approach

### Architecture Pattern

**ATOM Architecture (Following ace-* gem conventions):**

```
ace-lint/
├── lib/ace/lint/
│   ├── atoms/           # Pure functions (no I/O)
│   │   ├── type_detector.rb         # Detect file type from extension/content
│   │   ├── kramdown_parser.rb       # Parse markdown with kramdown
│   │   ├── yaml_parser.rb           # Parse YAML with Psych
│   │   └── frontmatter_extractor.rb # Extract frontmatter from documents
│   ├── molecules/       # Focused helpers (may do I/O)
│   │   ├── markdown_linter.rb       # Validate markdown via kramdown
│   │   ├── yaml_linter.rb           # Validate YAML via Psych
│   │   ├── frontmatter_validator.rb # Validate frontmatter schema
│   │   └── kramdown_formatter.rb    # Format markdown with kramdown
│   ├── organisms/       # Complex business logic
│   │   ├── lint_orchestrator.rb     # Multi-file processing
│   │   └── result_reporter.rb       # Colorized output formatting
│   ├── models/          # Pure data structures
│   │   ├── lint_result.rb           # Validation result data
│   │   └── validation_error.rb      # Error details
│   ├── commands/        # CLI commands
│   │   └── lint_command.rb          # Main CLI command
│   ├── cli.rb           # Thor CLI registration
│   └── version.rb       # Version constant
├── exe/
│   └── ace-lint         # Executable
├── test/
│   ├── atoms/           # Atom tests
│   ├── molecules/       # Molecule tests
│   ├── organisms/       # Organism tests
│   └── integration/     # End-to-end tests
└── ace-lint.gemspec
```

**Integration with existing architecture:**
- Follows ace-docs, ace-taskflow, ace-core patterns
- Uses ace-core for configuration discovery
- Returns structured results for programmatic use

### Technology Stack

**Ruby Gems (Runtime Dependencies):**
- `kramdown` ~> 2.5 - Markdown parser and formatter
- `kramdown-parser-gfm` ~> 1.1 - GitHub Flavored Markdown support
- `psych` (built-in) - YAML parser
- `ace-core` ~> 0.1 - Shared configuration and utilities
- `thor` ~> 1.3 - CLI framework
- `colorize` ~> 1.1 - Terminal colors

**Ruby Gems (Development Dependencies):**
- `minitest` ~> 5.19 - Testing framework
- `rake` ~> 13.0 - Build tasks
- `rubocop` ~> 1.57 - Ruby linting
- `simplecov` ~> 0.22 - Code coverage

**Optional External Tools:**
- `gitleaks` - Secrets scanning (graceful fallback if not installed)

**Performance Implications:**
- kramdown: Fast for files up to 10MB, warning for larger files
- Psych: Built-in Ruby parser, very fast
- Sequential processing: Acceptable for typical documentation sets (<100 files)

**Security Considerations:**
- No arbitrary code execution (unlike some markdown processors)
- kramdown is actively maintained and security-patched
- Psych is Ruby standard library (well-tested)
- Optional gitleaks adds secrets detection

### Implementation Strategy

**Phase 1: Gem Scaffolding**
1. Create gem structure with bundler
2. Set up ATOM directory structure
3. Configure gemspec with dependencies
4. Create executable script

**Phase 2: Core Atoms (Pure Functions)**
1. TypeDetector: Detect file type from extension or content
2. KramdownParser: Wrap kramdown parsing with error handling
3. YamlParser: Wrap Psych parsing with error handling
4. FrontmatterExtractor: Extract and parse frontmatter blocks

**Phase 3: Validation Molecules**
1. MarkdownLinter: Validate markdown via kramdown parser
2. YamlLinter: Validate YAML via Psych parser
3. FrontmatterValidator: Check required fields, field types
4. KramdownFormatter: Apply kramdown formatting

**Phase 4: Orchestration Organisms**
1. LintOrchestrator: Process multiple files, collect results
2. ResultReporter: Format and colorize output

**Phase 5: CLI Interface**
1. Build Thor-based CLI with options (--fix, --type, --help)
2. Handle file arguments and glob expansion
3. Exit codes and error handling

**Phase 6: Testing Strategy**
1. Unit tests for all atoms (pure functions)
2. Integration tests for molecules (with fixtures)
3. End-to-end tests for CLI (subprocess invocation)
4. Test coverage target: >90%

**Rollback Considerations:**
- Gem is standalone - easy to uninstall
- ace-docs can keep inline validation until ace-lint is stable
- No database or state changes

## File Modifications

### Create

**Gem Structure:**
- `ace-lint/` - Root directory
- `ace-lint/lib/ace/lint.rb` - Main entry point
- `ace-lint/lib/ace/lint/version.rb` - Version constant
- `ace-lint/lib/ace/lint/cli.rb` - Thor CLI registration
- `ace-lint/exe/ace-lint` - Executable script
- `ace-lint/ace-lint.gemspec` - Gem specification
- `ace-lint/Gemfile` - Bundler dependencies
- `ace-lint/Rakefile` - Build and test tasks
- `ace-lint/README.md` - Gem documentation
- `ace-lint/.rubocop.yml` - RuboCop configuration

**Atoms (Pure Functions):**
- `ace-lint/lib/ace/lint/atoms/type_detector.rb`
  - Purpose: Detect file type from extension or content
  - Key components: Extension mapping, content sniffing
  - Dependencies: None (pure Ruby)

- `ace-lint/lib/ace/lint/atoms/kramdown_parser.rb`
  - Purpose: Wrap kramdown parsing with error capture
  - Key components: Parser initialization, error handling
  - Dependencies: kramdown, kramdown-parser-gfm

- `ace-lint/lib/ace/lint/atoms/yaml_parser.rb`
  - Purpose: Wrap Psych parsing with error capture
  - Key components: Psych.safe_load, error handling
  - Dependencies: psych (built-in)

- `ace-lint/lib/ace/lint/atoms/frontmatter_extractor.rb`
  - Purpose: Extract frontmatter block from markdown
  - Key components: Regex matching, YAML extraction
  - Dependencies: None (pure Ruby)

**Molecules (Focused Helpers):**
- `ace-lint/lib/ace/lint/molecules/markdown_linter.rb`
  - Purpose: Validate markdown syntax via kramdown
  - Key components: Parse document, collect errors, line numbers
  - Dependencies: KramdownParser atom

- `ace-lint/lib/ace/lint/molecules/yaml_linter.rb`
  - Purpose: Validate YAML syntax via Psych
  - Key components: Parse YAML, collect syntax errors
  - Dependencies: YamlParser atom

- `ace-lint/lib/ace/lint/molecules/frontmatter_validator.rb`
  - Purpose: Validate frontmatter schema and required fields
  - Key components: Field presence checks, type validation
  - Dependencies: FrontmatterExtractor, YamlParser atoms

- `ace-lint/lib/ace/lint/molecules/kramdown_formatter.rb`
  - Purpose: Format markdown with kramdown
  - Key components: Kramdown converter, file writing
  - Dependencies: kramdown

**Organisms (Business Logic):**
- `ace-lint/lib/ace/lint/organisms/lint_orchestrator.rb`
  - Purpose: Process multiple files, orchestrate linters
  - Key components: File iteration, linter selection, result aggregation
  - Dependencies: All molecules, TypeDetector

- `ace-lint/lib/ace/lint/organisms/result_reporter.rb`
  - Purpose: Format and display validation results
  - Key components: Colorized output, summary generation
  - Dependencies: colorize gem

**Models (Data Structures):**
- `ace-lint/lib/ace/lint/models/lint_result.rb`
  - Purpose: Represent validation result for one file
  - Key components: Struct with file_path, success, errors, warnings
  - Dependencies: None

- `ace-lint/lib/ace/lint/models/validation_error.rb`
  - Purpose: Represent a single validation error
  - Key components: Struct with line, message, severity
  - Dependencies: None

**Commands (CLI):**
- `ace-lint/lib/ace/lint/commands/lint_command.rb`
  - Purpose: Thor command implementation
  - Key components: Argument parsing, orchestrator invocation
  - Dependencies: LintOrchestrator, ResultReporter

**Tests:**
- `ace-lint/test/test_helper.rb` - Test configuration and helpers
- `ace-lint/test/atoms/type_detector_test.rb` - Unit tests
- `ace-lint/test/atoms/kramdown_parser_test.rb` - Unit tests
- `ace-lint/test/atoms/yaml_parser_test.rb` - Unit tests
- `ace-lint/test/atoms/frontmatter_extractor_test.rb` - Unit tests
- `ace-lint/test/molecules/markdown_linter_test.rb` - Integration tests
- `ace-lint/test/molecules/yaml_linter_test.rb` - Integration tests
- `ace-lint/test/molecules/frontmatter_validator_test.rb` - Integration tests
- `ace-lint/test/molecules/kramdown_formatter_test.rb` - Integration tests
- `ace-lint/test/organisms/lint_orchestrator_test.rb` - Integration tests
- `ace-lint/test/organisms/result_reporter_test.rb` - Integration tests
- `ace-lint/test/integration/cli_test.rb` - End-to-end tests
- `ace-lint/test/fixtures/valid.md` - Test fixture
- `ace-lint/test/fixtures/invalid.md` - Test fixture
- `ace-lint/test/fixtures/valid.yml` - Test fixture
- `ace-lint/test/fixtures/invalid.yml` - Test fixture

### Modify

**None** - This is a new gem, no existing files need modification.

**Future Integration (separate task):**
- `ace-docs/lib/ace/docs/organisms/validator.rb` - Add ace-lint delegation
- `ace-docs/ace-docs.gemspec` - Add ace-lint dependency

### Delete

**None** - No files to delete.

## Risk Assessment

### Technical Risks

- **Risk:** kramdown may not validate all markdown features that developers expect
  - **Probability:** Medium
  - **Impact:** Medium (users may expect more validation rules)
  - **Mitigation:** Document kramdown behavior, focus on syntax correctness, consider plugin system in future
  - **Rollback:** Keep legacy code-lint available for comparison

- **Risk:** Psych YAML validation may be too strict for some documents
  - **Probability:** Low
  - **Impact:** Low (Psych is the Ruby standard)
  - **Mitigation:** Document YAML requirements, provide clear error messages
  - **Monitoring:** Collect user feedback on YAML validation errors

- **Risk:** kramdown formatting may change document structure unexpectedly
  - **Probability:** Medium
  - **Impact:** Medium (users may lose formatting preferences)
  - **Mitigation:** Make --fix opt-in, show diff before writing, document formatting behavior
  - **Rollback:** Users can git revert changes

### Integration Risks

- **Risk:** ace-docs subprocess integration may have exit code issues
  - **Probability:** Low
  - **Impact:** Medium (validation failures may not be detected)
  - **Mitigation:** Comprehensive integration tests, document exit codes
  - **Monitoring:** Test ace-docs integration before releasing

- **Risk:** Gem dependencies may conflict with other ace-* gems
  - **Probability:** Low
  - **Impact:** Low (kramdown is widely compatible)
  - **Mitigation:** Use version ranges, test with other ace-* gems
  - **Rollback:** Adjust dependency versions in gemspec

### Performance Risks

- **Risk:** Large files (>10MB) may slow down validation
  - **Mitigation:** Warn users about large files, process sequentially
  - **Monitoring:** Track validation time in tests
  - **Thresholds:** Warn at 10MB, fail at 50MB

- **Risk:** Many files may slow down CI/CD pipelines
  - **Mitigation:** Document sequential processing, consider future parallelization
  - **Monitoring:** Measure validation time in integration tests
  - **Thresholds:** Aim for <5s for 100 typical markdown files

## Implementation Plan

### Planning Steps

* [ ] Review kramdown API and formatter options
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: kramdown parsing and formatting options documented
  > Command: ruby -rkramdown -e "puts Kramdown::Parser::Kramdown::OPTIONS.keys"

* [ ] Review ace-docs validation requirements
  > TEST: Requirements Check
  > Type: Pre-condition Check
  > Assert: ace-docs validation needs identified
  > Command: grep -r "validate" ace-docs/lib/ | head -10

* [ ] Design frontmatter schema validation approach
  > TEST: Design Validation
  > Type: Pre-condition Check
  > Assert: Required fields and validation rules documented
  > Command: # Review task.072.md behavioral specification

### Execution Steps

- [ ] **Phase 1: Gem Scaffolding**
  - [ ] Create gem structure with `bundle gem ace-lint`
    > TEST: Gem Structure Created
    > Type: Action Validation
    > Assert: ace-lint/ directory exists with standard gem structure
    > Command: ls -la ace-lint/ | grep -E "lib|exe|test"

  - [ ] Set up ATOM directory structure (atoms/, molecules/, organisms/, models/)
    > TEST: ATOM Structure Created
    > Type: Action Validation
    > Assert: All ATOM directories exist
    > Command: ls -la ace-lint/lib/ace/lint/ | grep -E "atoms|molecules|organisms|models|commands"

  - [ ] Configure gemspec with dependencies (kramdown, thor, colorize, ace-core)
    > TEST: Dependencies Configured
    > Type: Action Validation
    > Assert: Gemspec lists all required dependencies
    > Command: grep "add_dependency" ace-lint/ace-lint.gemspec

  - [ ] Create executable script at exe/ace-lint
    > TEST: Executable Created
    > Type: Action Validation
    > Assert: Executable is present and has execute permission
    > Command: test -x ace-lint/exe/ace-lint && echo "Executable OK"

  - [ ] Run `bundle install` to verify dependencies
    > TEST: Dependencies Install
    > Type: Action Validation
    > Assert: Bundle installs successfully
    > Command: cd ace-lint && bundle install

- [ ] **Phase 2: Core Atoms (Pure Functions)**
  - [ ] Implement TypeDetector atom (detect file type from extension/content)
    > TEST: TypeDetector Works
    > Type: Unit Test
    > Assert: Detects .md as markdown, .yml as yaml, frontmatter detection
    > Command: cd ace-lint && ruby -Ilib -Itest test/atoms/type_detector_test.rb

  - [ ] Implement KramdownParser atom (wrap kramdown with error handling)
    > TEST: KramdownParser Works
    > Type: Unit Test
    > Assert: Parses valid markdown, captures parsing errors
    > Command: cd ace-lint && ruby -Ilib -Itest test/atoms/kramdown_parser_test.rb

  - [ ] Implement YamlParser atom (wrap Psych with error handling)
    > TEST: YamlParser Works
    > Type: Unit Test
    > Assert: Parses valid YAML, captures syntax errors with line numbers
    > Command: cd ace-lint && ruby -Ilib -Itest test/atoms/yaml_parser_test.rb

  - [ ] Implement FrontmatterExtractor atom (extract frontmatter from markdown)
    > TEST: FrontmatterExtractor Works
    > Type: Unit Test
    > Assert: Extracts frontmatter block, handles missing frontmatter
    > Command: cd ace-lint && ruby -Ilib -Itest test/atoms/frontmatter_extractor_test.rb

- [ ] **Phase 3: Validation Molecules**
  - [ ] Implement MarkdownLinter molecule (validate via kramdown)
    > TEST: MarkdownLinter Works
    > Type: Integration Test
    > Assert: Validates markdown, returns LintResult with errors
    > Command: cd ace-lint && ruby -Ilib -Itest test/molecules/markdown_linter_test.rb

  - [ ] Implement YamlLinter molecule (validate via Psych)
    > TEST: YamlLinter Works
    > Type: Integration Test
    > Assert: Validates YAML syntax, returns LintResult
    > Command: cd ace-lint && ruby -Ilib -Itest test/molecules/yaml_linter_test.rb

  - [ ] Implement FrontmatterValidator molecule (check required fields, types)
    > TEST: FrontmatterValidator Works
    > Type: Integration Test
    > Assert: Validates required fields, detects type mismatches
    > Command: cd ace-lint && ruby -Ilib -Itest test/molecules/frontmatter_validator_test.rb

  - [ ] Implement KramdownFormatter molecule (format markdown)
    > TEST: KramdownFormatter Works
    > Type: Integration Test
    > Assert: Formats markdown, writes to file or string
    > Command: cd ace-lint && ruby -Ilib -Itest test/molecules/kramdown_formatter_test.rb

- [ ] **Phase 4: Orchestration Organisms**
  - [ ] Implement LintOrchestrator organism (multi-file processing)
    > TEST: LintOrchestrator Works
    > Type: Integration Test
    > Assert: Processes multiple files, selects correct linters, aggregates results
    > Command: cd ace-lint && ruby -Ilib -Itest test/organisms/lint_orchestrator_test.rb

  - [ ] Implement ResultReporter organism (colorized output)
    > TEST: ResultReporter Works
    > Type: Integration Test
    > Assert: Formats results with colors, summary, exit codes
    > Command: cd ace-lint && ruby -Ilib -Itest test/organisms/result_reporter_test.rb

- [ ] **Phase 5: Models and CLI**
  - [ ] Implement LintResult and ValidationError models (Structs)
    > TEST: Models Work
    > Type: Unit Test
    > Assert: Models hold data, provide accessors
    > Command: cd ace-lint && ruby -Ilib -Itest test/models/lint_result_test.rb

  - [ ] Implement LintCommand (Thor command with options)
    > TEST: LintCommand Works
    > Type: Integration Test
    > Assert: Parses arguments, invokes orchestrator, returns exit code
    > Command: cd ace-lint && ruby -Ilib -Itest test/commands/lint_command_test.rb

  - [ ] Configure CLI registration (Thor setup in cli.rb)
    > TEST: CLI Registration Works
    > Type: Integration Test
    > Assert: ace-lint --help shows command options
    > Command: cd ace-lint && bundle exec exe/ace-lint --help

- [ ] **Phase 6: Integration and End-to-End Tests**
  - [ ] Create test fixtures (valid/invalid markdown, YAML, frontmatter)
    > TEST: Fixtures Created
    > Type: Action Validation
    > Assert: Fixture files exist in test/fixtures/
    > Command: ls -la ace-lint/test/fixtures/ | grep -E "valid|invalid"

  - [ ] Write end-to-end CLI tests (subprocess invocation)
    > TEST: E2E Tests Pass
    > Type: End-to-End Test
    > Assert: CLI validates files, returns correct exit codes
    > Command: cd ace-lint && ruby -Ilib -Itest test/integration/cli_test.rb

  - [ ] Test --fix option (formatting behavior)
    > TEST: Fix Option Works
    > Type: End-to-End Test
    > Assert: --fix formats files, reports formatting
    > Command: cd ace-lint && ruby -Ilib -Itest test/integration/fix_test.rb

  - [ ] Test subprocess integration (exit codes, stdout/stderr)
    > TEST: Subprocess Integration Works
    > Type: Integration Test
    > Assert: Exit code 0 for success, 1 for failures
    > Command: cd ace-lint && ruby -Ilib -Itest test/integration/subprocess_test.rb

- [ ] **Phase 7: Documentation and Polish**
  - [ ] Write README.md (installation, usage, examples)
    > TEST: README Complete
    > Type: Documentation Check
    > Assert: README has all required sections
    > Command: grep -E "Installation|Usage|Examples" ace-lint/README.md

  - [ ] Add inline documentation (YARD comments for public APIs)
    > TEST: Documentation Added
    > Type: Documentation Check
    > Assert: Public methods have YARD comments
    > Command: grep -r "@param\|@return" ace-lint/lib/ | wc -l

  - [ ] Run RuboCop and fix style issues
    > TEST: RuboCop Passes
    > Type: Quality Check
    > Assert: No RuboCop offenses
    > Command: cd ace-lint && bundle exec rubocop

  - [ ] Run full test suite with coverage
    > TEST: Full Test Suite Passes
    > Type: Quality Check
    > Assert: All tests pass, coverage >90%
    > Command: cd ace-lint && bundle exec rake test

- [ ] **Phase 8: Integration with ace-docs**
  - [ ] Test ace-lint from command line
    > TEST: CLI Works Standalone
    > Type: Manual Test
    > Assert: ace-lint validates files from command line
    > Command: cd ace-lint && bundle exec exe/ace-lint ../ace-docs/README.md

  - [ ] Test ace-lint as subprocess (from Ruby script)
    > TEST: Subprocess Works
    > Type: Integration Test
    > Assert: Can call ace-lint from Ruby, get exit codes
    > Command: ruby -e "result = system('ace-lint', 'ace-docs/README.md'); puts result"

  - [ ] Document integration pattern for ace-docs
    > TEST: Integration Documented
    > Type: Documentation Check
    > Assert: README explains subprocess integration
    > Command: grep "subprocess\|ace-docs" ace-lint/README.md

## Acceptance Criteria

- [ ] **AC 1: CLI Interface Complete**
  - ace-lint command available with --fix, --format, --type options
  - Help output shows all options and examples
  - Version output shows gem version

- [ ] **AC 2: Ruby-Only Stack**
  - No Node.js or Python dependencies
  - Uses only kramdown, kramdown-parser-gfm, Psych, ace-core, thor, colorize
  - Gem installs with `gem install ace-lint`

- [ ] **AC 3: Markdown Validation Works**
  - Validates markdown syntax via kramdown
  - Reports parsing errors with line numbers
  - Supports GitHub Flavored Markdown

- [ ] **AC 4: YAML Validation Works**
  - Validates YAML syntax via Psych
  - Reports syntax errors with line numbers
  - Handles YAML edge cases (empty files, scalars, etc.)

- [ ] **AC 5: Frontmatter Validation Works**
  - Validates frontmatter structure (---)
  - Checks required fields (doc-type, purpose)
  - Validates field types (string, date, etc.)

- [ ] **AC 6: Auto-fix/Format Support**
  - --fix flag applies kramdown formatting
  - Only formats valid files (not files with errors)
  - Reports formatted files in output

- [ ] **AC 7: Colorized Output**
  - Green checkmarks for passed files
  - Red X marks for failed files
  - Yellow warnings for non-critical issues
  - Summary at end with counts

- [ ] **AC 8: Exit Codes Correct**
  - Returns 0 for all files passing
  - Returns 1 for any file failing
  - Proper integration with CI/CD and ace-docs

- [ ] **AC 9: Subprocess Integration**
  - Can be called from Ruby scripts with system() or backticks
  - Exit codes are reliable
  - stdout/stderr are properly formatted

- [ ] **AC 10: Error Messages Clear**
  - File paths included in all messages
  - Line numbers for syntax errors
  - Actionable suggestions (e.g., "Missing required field 'doc-type'")

- [ ] **AC 11: Test Coverage >90%**
  - Unit tests for all atoms
  - Integration tests for molecules and organisms
  - End-to-end tests for CLI
  - Coverage report shows >90%

- [ ] **AC 12: Documentation Complete**
  - README.md with installation, usage, examples
  - YARD documentation for public APIs
  - ux/usage.md with comprehensive scenarios
  - Integration guide for ace-docs

## Out of Scope

- ❌ **Node.js Dependencies**: No markdownlint or other Node.js tools
- ❌ **Python Dependencies**: No yamllint or other Python tools
- ❌ **Semantic Validation**: Deep LLM-based content validation (future enhancement)
- ❌ **Custom Rules**: User-defined linting rules or plugins (future enhancement)
- ❌ **Configuration Files**: .ace/lint/config.yml support (future enhancement)
- ❌ **Parallel Processing**: Sequential processing only (future enhancement)
- ❌ **JSON Output**: Human-readable terminal output only (future enhancement)
- ❌ **Link Validation**: Markdown link checking (future enhancement)
- ❌ **IDE Integration**: Editor plugins or language server protocol support
- ❌ **Continuous Monitoring**: Watch mode or file system monitoring
- ❌ **Multi-Repository**: Cross-repository linting or aggregated reporting

## References

- Parent task: .ace-taskflow/v.0.9.0/tasks/071-docs-docs-complete-ace-docs-batch-analys/task.071.md (Phase 2: ace-lint Gem Creation)
- Usage documentation: .ace-taskflow/v.0.9.0/tasks/072-feat-lint-ace-lint-standalone-linting-ge/ux/usage.md
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
- Architecture: dev-handbook/guides/atom-pattern.g.md (ATOM pattern)
- Testing: dev-handbook/guides/testing.g.md
