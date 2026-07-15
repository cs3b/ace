# CI/CD Documentation

## GitHub Actions Configuration

This repository uses GitHub Actions for continuous integration testing. The CI pipeline validates the repository test inventory, then runs every test project across multiple Ruby versions.

## CI Strategy

We use **Option 2: Independent Package Testing** with GitHub Actions Matrix strategy for CI because:

1. **Clean CI logs**: No ANSI escape codes or terminal UI issues
2. **Native parallelization**: GitHub Actions handles parallel jobs efficiently
3. **Better failure isolation**: Each package/Ruby version combo runs independently
4. **Easy debugging**: Each job has its own clean log output

## Test Execution

### Local Development

```bash
# Run all deterministic tests with nice UI (recommended for local development)
ace-test-suite

# Run all tests sequentially without color
ace-test-suite --no-color

# Run tests for a specific package
ace-test ace-support-core all

# Preview monorepo E2E scenario coverage without invoking an agent provider
ace-test-e2e ace-monorepo-e2e --dry-run
```

### In GitHub Actions

The CI matrix is generated from `.ace/test/suite.yml` by `.ace-bin/ci_package_inventory.rb`.

It validates that:

- Every `ace-*` gem with a `test/` directory is listed exactly once.
- The `ace-monorepo-e2e` test project is included.
- No removed or misspelled package is present in the suite configuration.

Each validated project runs on Ruby 3.2, 3.3, and 3.4. The handbook projection contract also runs as a dedicated release-blocking job.

Each deterministic package job runs:

```bash
bundle exec ace-test <package> all
```

The `ace-monorepo-e2e` entry runs `bundle exec ace-test-e2e ace-monorepo-e2e --dry-run` to validate scenario discovery without requiring an agent provider in CI.

## Workflow Triggers

Tests run automatically on:

- Push to `main` or `master` branch
- Pull requests to `main` or `master`
- Manual workflow dispatch (via GitHub UI)

## Test Reports

Failed tests automatically upload artifacts including:

- Test reports from `.ace-local/test/reports/`
- E2E dry-run artifacts from `.ace-local/test-e2e/`
- Artifacts are retained for 7 days

## Caching

The CI uses Ruby's `bundler-cache` to cache dependencies:

- Cache key based on `Gemfile.lock`
- Separate cache per Ruby version
- Significantly speeds up CI runs

## Adding New Packages

To add a new test project to the suite:

1. Add it to `.ace/test/suite.yml`:

```yaml
packages:
  - name: your-new-package
    path: your-new-package
```

2. Ensure the package has:
   - Tests in the `test/` directory
   - Proper dependencies in its `.gemspec`

3. Run `ruby .ace-bin/ci_package_inventory.rb` locally. GitHub Actions generates the matrix from the validated suite; do not edit the workflow matrix manually.

## Debugging CI Failures

1. **Check the job logs**: Each package/Ruby combo has its own job log
2. **Download artifacts**: Failed jobs upload test reports as artifacts
3. **Run locally**: Reproduce with `ace-test <package> all`
4. **Use debug mode**: Trigger workflow with debug logging enabled

## Best Practices

1. **Keep tests fast**: CI runs on every PR
2. **Use descriptive test names**: Helps identify failures quickly
3. **Fix flaky tests**: Don't ignore intermittent failures
4. **Update Ruby versions**: Keep the matrix current with supported versions
