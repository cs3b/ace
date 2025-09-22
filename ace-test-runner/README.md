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

### Command Line Options

```bash
ace-test [options]
  --format FORMAT        # Output format: progress (default), progress-file, json
  --report-dir DIR      # Report storage directory (default: test-reports/)
  --no-save             # Skip saving detailed reports
  --fail-fast           # Stop execution on first failure
  --stop-threshold N    # Stop tests after N failures (default: 21)
  --max-display N       # Maximum failures to display (default: 7)
  --fix-deprecations    # Auto-fix deprecated test patterns
  --filter PATTERN      # Run only tests matching pattern
  --verbose             # Show detailed test execution
  --per-file           # Execute each test file separately (slower, for debugging)
  --help                # Display help information
```

### Configuration

Ace-test looks for configuration in `.ace/test.yml` in your project root. Example:

```yaml
version: 1

# Failure limits
failure_limits:
  max_display: 7      # Show first 7 failures in output
  stop_threshold: 21  # Stop tests after 21 failures

# Test patterns
patterns:
  atoms: 'test/{unit/,}atoms/**/*_test.rb'
  molecules: 'test/{unit/,}molecules/**/*_test.rb'
  organisms: 'test/{unit/,}organisms/**/*_test.rb'
  models: 'test/{unit/,}models/**/*_test.rb'
  integration: 'test/integration/**/*_test.rb'
  system: 'test/system/**/*_test.rb'

# Test groups
groups:
  unit: [atoms, molecules, organisms, models]
  all: [unit, integration, system]
  quick: [atoms, molecules]

# Defaults
defaults:
  reporter: progress
  color: auto
  fail_fast: false
  save_reports: true
  report_dir: test-reports
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
  "report_path": "test-reports/2025-01-20-14-30-45/"
}
```

### Configuration

Configure via `.ace/test.yml`:

```yaml
test:
  format: ai
  report_dir: test-reports
  save_reports: true
  fail_fast: false
  verbose: false
  patterns:
    - test/**/*_test.rb
    - spec/**/*_spec.rb
```

### Report Structure

Reports are saved to timestamped directories:

```
test-reports/
├── 2025-01-20-14-30-45/
│   ├── summary.json       # Test run summary
│   ├── failures.json      # Detailed failure information
│   ├── report.md          # Human-readable markdown report
│   └── raw_output.txt     # Raw test output
└── latest -> 2025-01-20-14-30-45/  # Symlink to most recent run
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