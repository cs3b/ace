# ACE Tools - Development Tools Reference

## Current ace-* Gem Tools

### Core Tools Available Now

| Tool | Purpose | Gem | Key Features |
|------|---------|-----|--------------|
| **`ace-context`** | **Load project context** | **ace-context** | Smart caching, multi-format output, preset support |
| **`ace-test`** | **Run individual tests** | **ace-test-runner** | Detailed output, failure analysis, single file focus |
| **`ace-test-suite`** | **Run test suites** | **ace-test-runner** | CI-optimized, parallel execution, multi-source |

## Setup Requirements

### Dependencies

* **Ruby** >= 3.0.0 (3.2.0 recommended)
* **Bundler** for dependency management
* **Git** for repository operations

### Environment Setup

```bash
# Initial setup (run from repository root)
bundle install

# Development mode - use bundle exec
bundle exec ace-context --help
bundle exec ace-test --help
bundle exec ace-test-suite --help

# After gem installation (future)
ace-context --preset project
ace-test ace-core/test/ace/core/atoms/test_yaml_parser.rb
ace-test-suite
```

## ace-context - Context Loading Tool

### Basic Usage
```bash
ace-context [OPTIONS]
```

### Key Options
- `--preset NAME` - Use a preset configuration (default: project)
- `--format FORMAT` - Output format: yaml, json, toml, xml (default: yaml)
- `--output PATH` - Output file path (default: stdout)
- `--cache` / `--no-cache` - Enable/disable smart caching

### Examples
```bash
# Load project context with caching
ace-context --preset project

# Output as JSON without cache
ace-context --preset project --format json --no-cache

# Save to file
ace-context --preset project --output context.yml

# Use different preset
ace-context --preset development
```

### Configuration
Create `.ace/context.yml` for custom presets:
```yaml
presets:
  custom:
    files:
      - "README.md"
      - "docs/*.md"
    commands:
      git_status:
        command: "git status --short"
      recent_commits:
        command: "git log --oneline -5"
```

## ace-test - Individual Test Runner

### Basic Usage
```bash
ace-test [TEST_FILES...] [OPTIONS]
```

### Key Options
- `--name PATTERN` - Run only tests matching pattern
- `--verbose` - Show detailed output
- `--seed SEED` - Set random seed for test order

### Examples
```bash
# Run specific test file
ace-test ace-core/test/ace/core/atoms/test_yaml_parser.rb

# Run tests matching pattern
ace-test ace-core/test/**/*_test.rb --name "/parse/"

# Run with verbose output
ace-test ace-context/test --verbose
```

## ace-test-suite - CI Test Suite Runner

### Basic Usage
```bash
ace-test-suite [OPTIONS]
```

### Key Options
- `--parallel` - Run tests in parallel
- `--format FORMAT` - Output format: progress, documentation, json
- `--fail-fast` - Stop on first failure

### Examples
```bash
# Run all tests across gems
ace-test-suite

# Run in parallel with fail-fast
ace-test-suite --parallel --fail-fast

# CI-optimized run
ace-test-suite --format json --parallel
```

## Gem Architecture

### ace-core (Foundation)
- **Purpose**: Configuration management with cascade resolution
- **No executables**: Library gem only
- **Key Features**:
  - YAML/environment configuration loading
  - Deep hash merging
  - Path expansion
  - Zero external dependencies

### ace-context (Context Loading)
- **Executable**: `ace-context`
- **Dependencies**: ace-core
- **Key Features**:
  - Smart file-based caching
  - Multi-format output (YAML, JSON, TOML, XML)
  - Command execution integration
  - Template processing

### ace-test-runner (Test Execution)
- **Executables**: `ace-test`, `ace-test-suite`
- **Dependencies**: ace-core, ace-test-support
- **Key Features**:
  - Multi-source test discovery
  - Parallel execution support
  - CI-optimized output
  - Detailed failure reporting

### ace-test-support (Testing Infrastructure)
- **Purpose**: Shared test utilities
- **No executables**: Support library only
- **Key Features**:
  - TestEnvironment for isolation
  - ConfigHelpers for testing
  - Minitest extensions

## Legacy Tools (Being Migrated)

The following tools from dev-tools are being migrated to individual ace-* gems:

### Planned ace-git
- `git-add`, `git-commit`, `git-status`, `git-log`, `git-push`, `git-pull`
- `git-fetch`, `git-tag`

### Planned ace-llm
- `llm-query` - Multi-provider LLM integration

### Planned ace-handbook
- `handbook` - Workflow and template management
- `task-manager` - Task tracking
- `release-manager` - Release coordination

### Planned ace-dev
- `search` - Unified file/content search
- `create-path` - File/directory creation
- `nav-ls`, `nav-path`, `nav-tree` - Navigation utilities
- `code-review`, `code-review-synthesize` - Code review tools
- `reflection-synthesize` - Development reflections

## Development Workflow

### Testing a Gem
```bash
# Run tests for specific gem
cd ace-core
bundle exec rake test

# Run with coverage
COVERAGE=true bundle exec rake test
```

### Using in Development
```bash
# Always use bundle exec in development
bundle exec ace-context --preset project
bundle exec ace-test ace-*/test/**/*_test.rb
```

### CI Integration
```yaml
# GitHub Actions example
- name: Run tests
  run: bundle exec ace-test-suite --format json
```

## Configuration

### Global Configuration
ACE uses a cascade resolution system for configuration:
1. `.ace/[tool].yml` in current directory
2. `.ace/[tool].yml` in parent directories (up to home)
3. Built-in defaults

### Example Configuration Files

`.ace/settings.yml` (ace-core):
```yaml
app_name: my-project
environment: development
```

`.ace/context.yml` (ace-context):
```yaml
cache:
  enabled: true
  directory: .cache/context
presets:
  project:
    files: ["README.md", "docs/*.md"]
```

`.ace/test-runner.yml` (ace-test-runner):
```yaml
parallel: true
format: progress
sources:
  - "test/**/*_test.rb"
  - "spec/**/*_spec.rb"
```

---

*Note: This document reflects the current state of the ACE mono-repo migration. As more ace-* gems are created, this reference will be updated with their tools and usage.*