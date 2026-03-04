# Ace::TestRunner

Test execution and reporting tool for ace-* gems with AI-friendly output formats.

## Features

- **Multiple Output Formats**: AI-optimized, compact (CI), JSON, and Markdown formats
- **Dual Output Mode**: Immediate stdout feedback + persistent detailed reports
- **Test Discovery**: Automatically finds and executes all test files
- **Failure Analysis**: Detailed failure information with fix suggestions
- **Report Persistence**: Timestamped reports saved to disk for historical analysis
- **Configuration Support**: Integrates with ace-core configuration cascade

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ace-test-runner'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ace-test-runner

## Usage

### Basic Usage

Run all tests with default AI-friendly format:

```bash
ace-test
```

### Running Tests for a Specific Package

In a mono-repo with multiple ace-* packages, you can run tests for any package from any directory:

```bash
# Run all tests in a package by name
ace-test ace-bundle

# Run specific test group in a package
ace-test ace-nav atoms

# Run with options
ace-test ace-lint --profile 10

# Using relative paths
ace-test ./ace-search

# Using absolute paths
ace-test /path/to/ace-docs
```

When running from within a different package directory, this allows you to easily run tests across the mono-repo without changing directories:

```bash
cd ace-search
ace-test ace-bundle atoms  # Run ace-bundle atom tests from within ace-search
```

#### Usage Matrix

| Command | What It Runs |
|---------|--------------|
| `ace-test` | All tests in current package |
| `ace-test atoms` | Only atom tests in current package |
| `ace-test ace-support-nav` | All tests in ace-support-nav package |
| `ace-test ace-support-nav atoms` | Only atom tests in ace-support-nav |
| `ace-test ace-support-nav/test/file.rb` | Specific file in ace-support-nav (from project root) |
| `ace-test ace-support-nav/test/file.rb:42` | Specific line in ace-support-nav (from project root) |
| `ace-test ./ace-support-nav` | All tests using relative path |
| `ace-test test/atoms/file.rb` | Specific file in current package |

**Note:** Package names match `ace-*` directories in the mono-repo root, enabling shell tab completion.

**Shell Completion:** For bash/zsh completion support, add: `complete -C ace-test ace-test`

### Explicit File Execution

Run specific test files or line numbers for focused testing during development:

```bash
# Run a single test file
ace-test test/atoms/path_expander_test.rb

# Run a specific test at line number
ace-test test/atoms/path_expander_test.rb:42

# Run multiple specific files
ace-test test/atoms/path_expander_test.rb test/molecules/config_loader_test.rb
```

When explicit file paths are provided, ace-test will execute **only** those files, bypassing any configured test groups for fast, focused feedback.

### Command Line Options

```bash
ace-test [package] [target] [options] [file-paths]
```

**Arguments:**
- `package` - Optional package name (e.g., `ace-bundle`) or path (`./ace-search`, `/path/to/ace-docs`)
- `target` - Optional test group (e.g., `atoms`, `molecules`, `unit`, `all`)
- `file-paths` - Optional specific test files to run

**Options:**
```bash
  --format FORMAT        # Output format: progress (default), progress-file, json
  --report-dir DIR      # Report root directory (default: .ace-local/test/reports)
  --no-save             # Skip saving detailed reports
  --fail-fast           # Stop execution on first failure
  --stop-threshold N    # Stop tests after N failures (default: 21)
  --max-display N       # Maximum failures to display (default: 7)
  --fix-deprecations    # Auto-fix deprecated test patterns
  --filter PATTERN      # Run only tests matching pattern
  --verbose             # Show detailed test execution
  --per-file           # Execute each test file separately (slower, for debugging)
  --profile [N]        # Show N slowest tests (default: 10)
  --help                # Display help information
```

**File Path Arguments:**
- Provide explicit test file paths to run only those files
- Use `file:line` syntax to run specific tests at line numbers
- Multiple files can be provided
- When files are specified, they take precedence over group configuration

### Configuration

Ace-test uses the ace-config cascade to find configuration files. The following paths are supported (in priority order):

1. **Project config**: `.ace/test-runner/config.yml` or `.ace/test/runner.yml`
2. **User config**: `~/.ace/test-runner/config.yml` or `~/.ace/test/runner.yml`
3. **Gem defaults**: Built-in defaults from ace-test-runner

> **Breaking Change (v0.9.x)**: Previous config paths (`.ace/test.yml`, `.ace/test-runner.yml`, root-level `test-runner.yml`) are no longer supported. Migrate your configuration to `.ace/test-runner/config.yml`.

Example configuration:

```yaml
version: 1

# Failure limits
failure_limits:
  max_display: 7      # Show first 7 failures in output
  stop_threshold: 21  # Stop tests after 21 failures

# Test patterns
patterns:
  smoke: 'test/*_test.rb'  # Root-level smoke tests
  atoms: 'test/{unit/,}atoms/**/*_test.rb'
  molecules: 'test/{unit/,}molecules/**/*_test.rb'
  organisms: 'test/{unit/,}organisms/**/*_test.rb'
  models: 'test/{unit/,}models/**/*_test.rb'
  integration: 'test/integration/**/*_test.rb'
  system: 'test/system/**/*_test.rb'

# Test groups
groups:
  unit: [smoke, atoms, molecules, organisms, models]
  all: [unit, integration, system]
  quick: [atoms, molecules]

# Defaults
defaults:
  reporter: progress
  color: auto
  fail_fast: false
  save_reports: true
  report_dir: .ace-local/test/reports
```

Command-line options override configuration file settings.

### Output Examples

#### Progress Format (Default)
```
....F.F.S...........
FAILURES (2):
  test/atoms/parser_test.rb:42 - Expected 5 but got 4
  test/molecules/executor_test.rb:15 - Timeout error

Finished in 0.45s
18 passed, 2 failed, 1 skipped
```

#### Progress-File Format (One dot per file)
```
..F.F.S
```

#### JSON Format
```json
{
  "summary": {
    "passed": 150,
    "failed": 0,
    "skipped": 1,
    "duration": 0.45
  },
  "failures": [],
  "report_path": ".ace-local/test/reports/task/i50jj3/"
}
```

### Test Organization

Tests can be organized using patterns and groups:

- **smoke**: Root-level tests (e.g., `test/*_test.rb`) for basic sanity checks
- **atoms**: Pure function tests in `test/atoms/`
- **molecules**: Composed operation tests in `test/molecules/`
- **organisms**: Business logic tests in `test/organisms/`
- **models**: Data structure tests in `test/models/`
- **integration**: Integration tests in `test/integration/`
- **system**: System tests in `test/system/`

Run specific test groups:

```bash
ace-test smoke        # Root-level smoke tests only
ace-test atoms        # Atom tests only
ace-test unit         # All unit tests (smoke + atoms + molecules + organisms + models)
ace-test integration  # Integration tests only
ace-test all          # All tests (default)
```

**Note:** When explicit file paths are provided, they always take precedence over group configuration. For example, `ace-test atoms test/atoms/foo_test.rb` will run only the specified file, not the entire atoms group.

### Report Structure

Reports are saved under package-specific timestamped directories:

```
.ace-local/test/reports/
└── test-runner/
    ├── i50jj3/
    │   ├── summary.json       # Test run summary
    │   ├── failures.json      # Detailed failure information
    │   ├── report.md          # Human-readable markdown report
    │   └── raw_output.txt     # Raw test output
    └── latest -> i50jj3/      # Symlink to most recent run
```

## Architecture

Following the ATOM pattern:

- **Atoms**: Basic utilities (test detection, command building, result parsing)
- **Molecules**: Composed operations (test execution, failure analysis, report storage)
- **Organisms**: Business logic (orchestration, report generation, AI reporting)
- **Models**: Pure data structures (results, failures, configurations, reports)

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ace-meta/ace-test-runner.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).
