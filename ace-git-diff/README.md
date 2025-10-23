# ace-git-diff

Unified git diff functionality for the ACE ecosystem. Provides consistent, configurable git diff operations across all ACE tools with user-controllable filtering and global configuration support.

## Key Features

- **Unified Configuration**: Configure diff behavior once in `.ace/diff/config.yml` for all ACE tools
- **No Hardcoded Patterns**: All exclude patterns are user-configurable
- **Smart Filtering**: Raw, filtered, or compact output formats
- **Smart Defaults**: Automatically shows unstaged changes or branch diffs
- **Fast Execution**: No caching needed - diffs generate in <500ms
- **Flexible Integration**: Use `diff:` key for consistency or `commands:` for custom needs

## Installation

Add to your Gemfile:

```ruby
gem 'ace-git-diff', '~> 0.1.0'
```

Or install directly:

```bash
gem install ace-git-diff
```

## Quick Start

```bash
# Show diff with smart defaults
ace-git-diff

# Specific diff range
ace-git-diff HEAD~5..HEAD
ace-git-diff origin/main...HEAD

# Date-based diff
ace-git-diff --since "7d"
ace-git-diff --since "1 week ago"

# Path filtering
ace-git-diff --paths "lib/**/*.rb"
ace-git-diff --exclude "test/**/*"
```

## Configuration

Create `.ace/diff/config.yml` in your project root:

```yaml
# Project-wide diff configuration
exclude_patterns:
  - "test/**/*"
  - "spec/**/*"
  - "**/*.lock"
  - "vendor/**/*"
  - "node_modules/**/*"
  - "coverage/**/*"

# Diff options
exclude_whitespace: true
exclude_renames: false
exclude_moves: false
max_lines: 10000
```

## Ruby API

```ruby
require 'ace/git_diff'

# Generate diff with options
result = Ace::GitDiff::Organisms::DiffOrchestrator.generate(
  ranges: ["origin/main...HEAD"],
  paths: ["lib/**/*.rb"],
  exclude_patterns: ["test/**/*"]
)

puts result.content
puts result.summary  # "15 files, +450 -120"
```

## Integration with ACE Tools

Use the `diff:` key in ACE gem configurations:

**ace-docs**:
```yaml
ace-docs:
  subject:
    diff:
      paths: ["lib/**/*.rb"]
      since: 7d
```

**ace-review**:
```yaml
pr:
  subject:
    diff:
      ranges: ["origin/main...HEAD"]
```

**ace-context**:
```yaml
context:
  diff:
    ranges: ["origin/main...HEAD"]
    exclude_patterns: []  # Include all files
```

## CLI Reference

### `ace-git-diff [RANGE]`

Generate git diff with filtering.

**Options:**
- `--format, -f`: Output format (diff or summary)
- `--since, -s`: Show changes since date/duration
- `--paths, -p`: Include only matching paths (glob)
- `--exclude, -e`: Exclude matching paths (glob)
- `--config, -c`: Load config from path
- `--raw`: Raw output (no filtering)
- `--help, -h`: Show help
- `--version, -v`: Show version

## Development

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rake test

# Run linting
ace-lint "**/*.rb"
```

## Architecture

Follows ACE's ATOM architecture pattern:

- **Atoms**: Pure functions (CommandExecutor, PatternFilter, DiffParser, DateResolver)
- **Molecules**: Composed operations (DiffGenerator, ConfigLoader, DiffFilter)
- **Organisms**: Business logic (DiffOrchestrator, IntegrationHelper)
- **Models**: Data structures (DiffResult, DiffConfig)

## Contributing

See the main ACE repository for contribution guidelines.

## License

MIT License - see LICENSE file for details.

## Documentation

For comprehensive usage guide, see `ux/usage.md` in the task folder or the [online documentation](https://github.com/your-org/ace-git-diff/blob/main/docs/usage.md).
