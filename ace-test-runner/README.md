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
  --format FORMAT        # Output format: ai (default), compact, json, markdown
  --report-dir DIR      # Report storage directory (default: test-reports/)
  --no-save             # Skip saving detailed reports
  --fail-fast           # Stop execution on first failure
  --fix-deprecations    # Auto-fix deprecated test patterns
  --filter PATTERN      # Run only tests matching pattern
  --verbose             # Show detailed test execution
  --help                # Display help information
```

### Output Examples

#### AI Format (Default)
```
✅ 150 passed, ❌ 0 failed, ⚠️ 1 skipped
Summary: All tests passed in 0.45s
Detailed reports: test-reports/2025-01-20-14-30-45/
```

#### Compact Format (CI-friendly)
```
..F.F.S...........
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