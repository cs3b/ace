# ace-prompt

Prompt workspace with automatic archiving and history management.

## Quick Start

```bash
# Create a prompt
mkdir -p .cache/ace-prompt/prompts
echo "Review this code for security issues" > .cache/ace-prompt/prompts/the-prompt.md

# Process it (archives and outputs to stdout)
ace-prompt

# Output to file
ace-prompt --output /tmp/prompt.md
```

## What It Does

1. Reads `.cache/ace-prompt/prompts/the-prompt.md`
2. Archives it to `archive/YYYYMMDD-HHMMSS.md`
3. Updates `_previous.md` symlink
4. Outputs content to stdout (or file with `--output`)

## Installation

Add to your Gemfile:

```ruby
gem 'ace-prompt'
```

## Usage

See the examples above for basic usage. Additional documentation is available in the task directory.

## Development

Run tests:

```bash
cd ace-prompt
ace-test
```

Build gem:

```bash
gem build ace-prompt.gemspec
```

## License

MIT
