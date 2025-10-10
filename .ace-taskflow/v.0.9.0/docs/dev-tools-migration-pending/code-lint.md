# code-lint - Multi-Language Code Quality Tool

## Overview

`code-lint` is a comprehensive code quality validation and linting tool that supports multiple languages (Ruby, Markdown) with automatic fixing capabilities. It provides a unified interface for running language-specific linters with consistent options and output formatting.

## Purpose

The tool was created to:
- Provide consistent code quality validation across multiple languages
- Support automated fixing of common code issues
- Enable dry-run mode to preview changes before applying them
- Integrate with CI/CD pipelines for quality enforcement
- Support review workflows with diff generation

## Location

- **Executable**: `/dev-tools/exe/code-lint`
- **Command Implementation**: `/dev-tools/lib/coding_agent_tools/cli/commands/code_lint/*.rb`
- **Registration**: Via `ExecutableWrapper` pattern in dev-tools

## API Reference

### Subcommands

```bash
# Run all linters on all supported file types
code-lint all [paths...]

# Run Ruby-specific linting
code-lint ruby [paths...]

# Run Markdown-specific linting
code-lint markdown [paths...]

# Check documentation dependencies
code-lint docs-dependencies
```

### Common Options

| Option | Aliases | Type | Default | Description |
|--------|---------|------|---------|-------------|
| `--autofix` | `-a` | boolean | false | Apply moderate-level automatic fixes |
| `--config` | `-c` | string | - | Path to custom configuration file |
| `--dry-run` | `-n` | boolean | false | Show what would be done without making changes |
| `--review-diff` | `-r` | boolean | false | Review all changes made during autofix |

### Subcommand: `all`

Runs comprehensive linting on all supported file types.

```bash
code-lint all                    # Lint current directory
code-lint all lib/ spec/         # Lint specific paths
code-lint all --autofix          # Lint and fix issues
code-lint all --dry-run          # Preview without changes
code-lint all --review-diff      # Review changes after fix
```

**Additional Options**:
- `--validate-config`: Validate configuration file and exit

### Subcommand: `ruby`

Runs Ruby-specific linting (RuboCop).

```bash
code-lint ruby                   # Lint all Ruby files
code-lint ruby lib/              # Lint specific directory
code-lint ruby --autofix         # Auto-fix Ruby issues
```

**Validation Includes**:
- RuboCop style checks
- Ruby syntax validation
- Best practice enforcement
- Security vulnerability detection

### Subcommand: `markdown`

Runs Markdown-specific linting.

```bash
code-lint markdown               # Lint all Markdown files
code-lint markdown docs/         # Lint specific directory
code-lint markdown --autofix     # Auto-fix Markdown issues
```

**Validation Includes**:
- Markdown syntax validation
- Link checking (optional)
- Formatting consistency
- Header structure validation

### Subcommand: `docs-dependencies`

Validates documentation dependencies and references.

```bash
code-lint docs-dependencies
```

Checks:
- Cross-references between documents
- Template references in workflows
- Guide references in workflows
- Broken internal links

## How It Works

### Architecture (ATOM Pattern)

The code-lint system follows ATOM architecture:

#### Atoms
- **ConfigurationLoader**: Load and parse configuration files
- **PathResolver**: Resolve and expand file paths
- **ResultParser**: Parse linter output

#### Molecules
- **LanguageRunnerFactory**: Create language-specific runners
- **RubyRunner**: Execute RuboCop validation
- **MarkdownRunner**: Execute Markdown linting

#### Organisms
- **MultiPhaseQualityManager**: Orchestrate multi-language linting
  - Phase 1: Fast checks (syntax, basic formatting)
  - Phase 2: Deep analysis (complexity, security)
  - Phase 3: Auto-fix (safe automated corrections)

#### CLI Commands
- `CodeLint::All`: Entry point for all-languages mode
- `CodeLint::Ruby`: Ruby-specific interface
- `CodeLint::Markdown`: Markdown-specific interface

### Execution Flow

```
User Command
    ↓
CLI Command (parse options)
    ↓
ConfigurationLoader (load config)
    ↓
PathResolver (resolve target paths)
    ↓
LanguageRunnerFactory (create runners)
    ↓
LanguageRunner (execute linting)
    ↓
ResultFormatter (format output)
    ↓
Exit Code (0 = success, 1 = failure)
```

### Multi-Phase Quality Management

When running `code-lint all`, the system executes in phases:

1. **Phase 1 - Fast Validation**:
   - Syntax checking
   - Basic formatting issues
   - Quick wins for CI pipelines

2. **Phase 2 - Deep Analysis** (optional):
   - Complexity analysis
   - Security vulnerability scanning
   - Performance anti-patterns

3. **Phase 3 - Auto-fix** (with `--autofix`):
   - Apply safe automated corrections
   - Generate diff for review
   - Report unfixable issues

## Configuration

### Configuration File Format

```yaml
# .ace/code-quality/config.yml
code_quality:
  ruby:
    enabled: true
    rubocop:
      config: .rubocop.yml
      safe_autocorrect: true

  markdown:
    enabled: true
    mdl:
      style: .mdlrc
      rules:
        - MD001  # Header levels
        - MD003  # Header style
        - MD013  # Line length

  phases:
    fast_validation: true
    deep_analysis: false
    autofix_level: moderate  # none, safe, moderate, aggressive
```

### Loading Order

1. Custom config via `--config` flag
2. Project config: `.ace/code-quality/config.yml`
3. User config: `~/.ace/code-quality/config.yml`
4. Default embedded config

## Integration with ace-* Architecture

### Current Status

`code-lint` is a **subcommand suite within dev-tools** that uses ATOM architecture internally but is not yet extracted as a standalone gem.

### Migration Path: ace-lint

The natural migration is to create **ace-lint** as a focused code quality gem.

```ruby
# Future: ace-lint gem structure
ace-lint/
├── lib/ace/lint/
│   ├── atoms/
│   │   ├── configuration_loader.rb
│   │   ├── path_resolver.rb
│   │   └── result_parser.rb
│   ├── molecules/
│   │   ├── ruby_runner.rb
│   │   ├── markdown_runner.rb
│   │   └── language_runner_factory.rb
│   ├── organisms/
│   │   ├── multi_phase_manager.rb
│   │   └── result_formatter.rb
│   └── models/
│       ├── lint_result.rb
│       └── lint_config.rb
├── exe/
│   └── ace-lint
└── test/
    ├── atoms/
    ├── molecules/
    └── organisms/
```

### Future CLI Interface

```bash
# Unified interface
ace-lint                         # Lint all files
ace-lint ruby                    # Ruby-specific
ace-lint markdown                # Markdown-specific
ace-lint --autofix               # Auto-fix all
ace-lint --languages ruby,md     # Specific languages

# Advanced features
ace-lint --preset ci             # CI-optimized preset
ace-lint --preset pre-commit     # Pre-commit preset
ace-lint --watch                 # Watch mode for development
```

### Integration Points

#### With ace-test-runner
```bash
# Run tests and linting together
ace-test --lint                  # Test + lint
ace-test --lint-fix              # Test + auto-fix
```

#### With ace-git-commit
```bash
# Lint staged files before commit
ace-git-commit --lint            # Fail if linting errors
```

#### With ace-review
```bash
# Include linting in code review
ace-review --preset pr --lint    # Review + linting check
```

## Usage Examples

### Basic Linting

```bash
# Lint everything in current directory
code-lint all

# Lint specific paths
code-lint all lib/ spec/

# Check specific language
code-lint ruby lib/
code-lint markdown docs/
```

### Auto-fixing Issues

```bash
# Preview fixes without applying
code-lint all --dry-run

# Apply fixes
code-lint all --autofix

# Apply fixes and review changes
code-lint all --autofix --review-diff
```

### CI/CD Integration

```bash
# Fail fast in CI
code-lint all || exit 1

# Validate configuration
code-lint all --validate-config

# Use custom config for CI
code-lint all --config .ci/lint-config.yml
```

### Custom Configuration

```bash
# Use custom config file
code-lint all --config custom-lint.yml

# Validate config is correct
code-lint all --validate-config --config custom-lint.yml
```

## Output Examples

### Success Output
```
✓ Ruby linting passed (45 files)
✓ Markdown linting passed (12 files)
✓ Documentation dependencies valid

All quality checks passed!
```

### Failure Output
```
✗ Ruby linting failed (3 issues in 2 files)
  lib/ace/core.rb:42:10: Style/StringLiterals: Prefer single-quoted strings
  lib/ace/config.rb:15:5: Metrics/MethodLength: Method too long (15 lines)

✓ Markdown linting passed (12 files)

✗ Quality checks failed
```

### Auto-fix Output
```
🔧 Applying automatic fixes...

Fixed:
  ✓ lib/ace/core.rb: 5 style issues
  ✓ docs/README.md: 2 formatting issues

Unable to fix:
  ⚠ lib/ace/config.rb:15: Method too long (manual refactoring needed)

7 issues fixed, 1 requires manual attention
```

## Exit Codes

- `0` - All checks passed
- `1` - Linting errors found or execution error

## Limitations

1. **Language Support**: Currently only Ruby and Markdown (no JS, Python, etc.)
2. **Tool Dependency**: Requires external linters (RuboCop, mdl) to be installed
3. **Limited Auto-fix**: Only "moderate" level fixes, not aggressive refactoring
4. **No Incremental**: Always lints entire codebase, no incremental/cached mode
5. **No Parallel**: Runs linters sequentially, not in parallel

## Future Enhancements

### For ace-lint Migration

1. **Expanded Language Support**:
   - JavaScript/TypeScript (ESLint)
   - Python (Pylint, Black)
   - Shell scripts (ShellCheck)
   - YAML/JSON validation

2. **Performance Improvements**:
   - Parallel linting across languages
   - Incremental mode (only changed files)
   - Result caching

3. **Enhanced Reporting**:
   - JSON output for CI parsing
   - HTML reports
   - GitHub annotations format
   - SARIF format for security tools

4. **Watch Mode**:
   ```bash
   ace-lint --watch    # Auto-lint on file changes
   ```

5. **Preset System**:
   ```bash
   ace-lint --preset strict      # Strict mode
   ace-lint --preset relaxed     # Relaxed mode
   ace-lint --preset security    # Security-focused
   ```

6. **Editor Integration**:
   - LSP server for real-time linting
   - VS Code extension
   - Neovim plugin

## Related Tools

- **RuboCop**: Ruby linting backend
- **markdownlint**: Markdown linting backend
- **ace-review**: Could include linting in review workflow
- **ace-test-runner**: Could trigger linting alongside tests
- **ace-git-commit**: Could validate code before commit

## Historical Context

Originally developed as part of the dev-tools monolith to provide:
- Consistent code quality across the growing codebase
- Automated fixing to reduce manual cleanup
- Pre-commit and CI validation

The multi-phase approach emerged from the need to balance speed (CI pipelines) with thoroughness (pre-release checks).

## Migration Timeline

- **Current**: Available as `code-lint` in dev-tools
- **v0.10.0**: Begin extraction to `ace-lint` gem
- **v0.11.0**: Parallel support for both `code-lint` and `ace-lint`
- **v0.12.0**: Deprecation warning for `code-lint`
- **v1.0.0**: Remove from dev-tools, fully replaced by `ace-lint`

## See Also

- RuboCop configuration: `.rubocop.yml`
- Markdown style: `.mdlrc`
- Code quality patterns: `docs/code-quality-patterns.md`
- Testing patterns: `docs/testing-patterns.md`
