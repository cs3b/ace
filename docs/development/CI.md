# CI/CD Documentation

## GitHub Actions Configuration

This repository uses GitHub Actions for continuous integration testing. The CI pipeline runs all tests across multiple Ruby versions to ensure compatibility.

## CI Strategy

We use **Option 2: Independent Package Testing** with GitHub Actions Matrix strategy for CI because:

1. **Clean CI logs**: No ANSI escape codes or terminal UI issues
2. **Native parallelization**: GitHub Actions handles parallel jobs efficiently
3. **Better failure isolation**: Each package/Ruby version combo runs independently
4. **Easy debugging**: Each job has its own clean log output

## Test Execution

### Local Development

```bash
# Run all tests with nice UI (recommended for local development)
bundle exec rake test:suite

# Run all tests sequentially (simple output)
bundle exec rake test

# Run tests for a specific package
bundle exec rake 'test:package[ace-core]'

# Run in CI mode (no colors, simple output)
bundle exec rake test:ci
```

### In GitHub Actions

The CI runs a matrix of:
- **4 packages**: ace-core, ace-test-support, ace-test-runner, ace-context
- **3 Ruby versions**: 3.2, 3.3, 3.4
- **Total**: 12 parallel jobs

Each job runs:
```bash
cd <package>
bundle exec rake test
```

## Workflow Triggers

Tests run automatically on:
- Push to `main` or `master` branch
- Pull requests to `main` or `master`
- Manual workflow dispatch (via GitHub UI)

## Test Reports

Failed tests automatically upload artifacts including:
- Test reports from `test-reports/` directory
- Temporary files from `tmp/` directory
- Artifacts are retained for 7 days

## Caching

The CI uses Ruby's `bundler-cache` to cache dependencies:
- Cache key based on `Gemfile.lock`
- Separate cache per Ruby version
- Significantly speeds up CI runs

## Adding New Packages

To add a new package to the test suite:

1. Add it to the matrix in `.github/workflows/test.yml`:
```yaml
package:
  - ace-core
  - ace-test-support
  - ace-test-runner
  - ace-context
  - your-new-package  # Add here
```

2. Add it to the Rakefile test list:
```ruby
packages = %w[
  ace-core
  ace-test-support
  ace-test-runner
  ace-context
  your-new-package  # Add here
]
```

3. Ensure the package has:
   - A `Rakefile` with a `test` task
   - Tests in the `test/` directory
   - Proper dependencies in its `.gemspec`

## Debugging CI Failures

1. **Check the job logs**: Each package/Ruby combo has its own job log
2. **Download artifacts**: Failed jobs upload test reports as artifacts
3. **Run locally**: Reproduce with `cd <package> && bundle exec rake test`
4. **Use debug mode**: Trigger workflow with debug logging enabled

## Best Practices

1. **Keep tests fast**: CI runs on every PR
2. **Use descriptive test names**: Helps identify failures quickly
3. **Fix flaky tests**: Don't ignore intermittent failures
4. **Update Ruby versions**: Keep the matrix current with supported versions