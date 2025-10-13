# ace-lint

Ruby-only linting gem for markdown, YAML, and frontmatter validation. No Node.js or Python required!

## Overview

ace-lint provides comprehensive validation for markdown, YAML, and frontmatter documents using **only Ruby dependencies**:

- **Markdown**: Validation via kramdown + kramdown-parser-gfm (Ruby gems)
- **YAML**: Validation via Psych (Ruby built-in)
- **Frontmatter**: Schema validation using Psych
- **Auto-fix/format**: Kramdown formatter for consistent markdown styling
- **Colorized output**: Clear, colorized terminal output
- **Subprocess-callable**: Can be used by other ace-* gems

## Installation

Add to your Gemfile:

```ruby
gem 'ace-lint', path: 'ace-lint'  # Local development
# OR
gem 'ace-lint'  # When published to RubyGems
```

Then run:

```bash
bundle install
```

Or install directly:

```bash
gem install ace-lint
```

## Quick Start

Validate a markdown file (lint is the default command):

```bash
# Short form (recommended)
ace-lint docs/architecture.md

# Or explicit
ace-lint lint docs/architecture.md
```

Expected output:
```
docs/architecture.md: ✓

============================================================
Validated: 1 file
✓ All files passed
```

## Configuration

ace-lint uses the ace-core config cascade system for configuration:

### Config Files

- **General config**: `.ace/lint/config.yml` - General ace-lint settings (currently empty/defaults)
- **Kramdown config**: `.ace/lint/kramdown.yml` - Kramdown parser and formatter options

### Config Cascade

Configuration is loaded in this order (later overrides earlier):

1. Default configuration (built-in)
2. User configuration (`~/.ace/lint/kramdown.yml`)
3. Project configuration (`./.ace/lint/kramdown.yml`)
4. CLI options (`--line-width`, etc.)

### Kramdown Configuration

Create `.ace/lint/kramdown.yml` in your project:

```yaml
# Kramdown configuration for ace-lint
# Documentation: https://kramdown.gettalong.org/options.html

# Parser input format (GFM = GitHub Flavored Markdown)
input: GFM

# Line width for formatting (--fix, --format commands)
line_width: 120

# Generate anchor IDs for headings
# Set to false for clean markdown without {#anchor-id} tags
auto_ids: false

# Hard wrap lines at line_width
# Set to false for soft wrapping (recommended)
hard_wrap: false

# Parse block-level HTML tags
parse_block_html: true

# Parse span-level HTML tags
parse_span_html: true
```

See `.ace.example/lint/kramdown.yml` for the full example configuration.

### Configuration Options

Common kramdown options:

| Option | Default | Description |
|--------|---------|-------------|
| `input` | `GFM` | Input format (GFM = GitHub Flavored Markdown) |
| `line_width` | `120` | Line width for formatting |
| `auto_ids` | `false` | Generate anchor IDs for headings |
| `hard_wrap` | `false` | Hard wrap lines at line_width |
| `parse_block_html` | `true` | Parse block-level HTML tags |
| `parse_span_html` | `true` | Parse span-level HTML tags |

For all kramdown options, see: https://kramdown.gettalong.org/options.html

## Usage

### Basic Commands

```bash
# Lint single file (lint is the default command)
ace-lint docs/file.md

# Lint multiple files
ace-lint docs/*.md

# Lint YAML files
ace-lint config.yml --type yaml

# Auto-format markdown with kramdown
ace-lint docs/file.md --fix

# Show help
ace-lint --help

# Show version
ace-lint version
```

### Command Options

| Option | Short | Description |
|--------|-------|-------------|
| `--fix` | `-f` | Auto-format with kramdown |
| `--format` | | Format documents with kramdown |
| `--type TYPE` | `-t` | Specify validation type (markdown/yaml/frontmatter) |
| `--quiet` | `-q` | Suppress detailed output |
| `--line-width NUM` | | Line width for formatting (default: 120) |
| `--help` | `-h` | Show help message |

### Validation Types

- **markdown**: Validates markdown syntax via kramdown with GFM support
- **yaml**: Validates YAML syntax via Psych (Ruby built-in)
- **frontmatter**: Validates frontmatter schema and required fields

### Examples

```bash
# Validate all markdown files
ace-lint docs/*.md

# Format markdown files
ace-lint docs/*.md --fix

# Validate YAML configuration
ace-lint .ace/config.yml --type yaml

# Validate frontmatter
ace-lint docs/guide.md --type frontmatter

# Quiet mode (only show summary)
ace-lint docs/*.md --quiet
```

## Features

### Ruby-Only Stack

No Node.js or Python required:

```bash
# Traditional approach (multiple languages)
npm install -g markdownlint-cli  # Node.js
pip install yamllint              # Python

# ace-lint approach (Ruby only)
gem install ace-lint  # All dependencies included
```

### Kramdown-Based Validation

Uses kramdown for markdown parsing and formatting:

- GitHub Flavored Markdown support via kramdown-parser-gfm
- Configurable formatting options
- Consistent markdown styling
- Fast and reliable

### Psych-Based YAML Validation

Uses Ruby's built-in Psych parser:

- Comprehensive syntax checking
- Detailed error messages with line numbers
- No external dependencies
- Industry-standard YAML parsing

### Frontmatter Validation

Validates frontmatter schema:

- Required fields checking (doc-type, purpose)
- Field type validation
- YAML syntax validation
- Configurable validation rules

### Colorized Output

Clear, colorized terminal output:

- ✓ Green for passed files
- ✗ Red for failed files
- ⚠ Yellow for warnings
- Detailed error messages with line numbers

### Exit Codes

Proper exit codes for CI/CD integration:

- `0`: All files passed validation
- `1`: One or more files failed validation

## Architecture

ace-lint follows the ATOM architecture pattern:

```
lib/ace/lint/
├── atoms/           # Pure functions (no I/O)
│   ├── type_detector.rb         # Detect file type
│   ├── kramdown_parser.rb       # Parse markdown with kramdown
│   ├── yaml_parser.rb           # Parse YAML with Psych
│   └── frontmatter_extractor.rb # Extract frontmatter
├── molecules/       # Focused helpers (may do I/O)
│   ├── markdown_linter.rb       # Validate markdown
│   ├── yaml_linter.rb           # Validate YAML
│   ├── frontmatter_validator.rb # Validate frontmatter
│   └── kramdown_formatter.rb    # Format markdown
├── organisms/       # Complex business logic
│   ├── lint_orchestrator.rb     # Multi-file processing
│   └── result_reporter.rb       # Colorized output
├── models/          # Data structures
│   ├── lint_result.rb           # Validation result
│   └── validation_error.rb      # Error details
└── commands/        # CLI commands
    └── lint_command.rb          # Main CLI command
```

## Integration with Other Gems

ace-lint can be called as a subprocess from other ace-* gems:

```ruby
require 'open3'

# Call ace-lint from Ruby
stdout, stderr, status = Open3.capture3("ace-lint", "lint", file_path)

if status.exitstatus == 0
  puts "✓ Validation passed"
else
  puts "✗ Validation failed"
  puts stdout
end
```

## Development

After checking out the repo:

```bash
# Install dependencies
bundle install

# Run tests
rake test

# Run linter
bundle exec rubocop

# Test CLI locally
bundle exec exe/ace-lint lint test/fixtures/*.md
```

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

See LICENSE file for details.
