# ace-prompt

Simple queue-based prompt workflow for AI development.

## Overview

`ace-prompt` solves the problem of Claude Code's limited in-editor prompt writing by allowing developers to write prompts in their full-featured editor with automatic archiving and optional enhancements.

**Core Concept**: Think of it like a print queue - you write to ONE file (`the-prompt.md`), run the command, it archives and outputs. Simple.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ace-prompt'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ace-prompt

## Quick Start

```bash
# First time setup - initialize with template
ace-prompt setup

# Edit your prompt
vim .cache/ace-prompt/prompts/the-prompt.md

# Run it (no arguments needed!)
ace-prompt

# What happens:
# 1. Reads .cache/ace-prompt/prompts/the-prompt.md
# 2. Archives to .cache/ace-prompt/prompts/archive/YYYYMMDD-HHMMSS.md
# 3. Updates _previous.md symlink
# 4. Outputs prompt content to stdout
```

## Usage

### Basic Commands

```bash
ace-prompt                    # Process prompt (default)
ace-prompt setup              # Initialize with template
ace-prompt reset              # Reset to template (archives current)
```

### With Options

```bash
ace-prompt --ace-context      # Load context from frontmatter
ace-prompt -c                 # Short form

ace-prompt --enhance          # Enhance via LLM
ace-prompt -e                 # Short form

ace-prompt -ce                # Both context and enhance

ace-prompt --task 117         # Task-specific prompt
ace-prompt -t 117             # Short form

ace-prompt --raw              # Skip enhancement if configured
ace-prompt --no-context       # Skip context if configured
```

### File Structure

```
.cache/ace-prompt/prompts/
├── the-prompt.md              # Your active prompt (edit this!)
├── _previous.md               # Symlink to last archived prompt
└── archive/
    ├── 20251119-120000.md
    ├── 20251119-143000.md
    └── 20251119-155500.md
```

### Optional Frontmatter

```yaml
---
context:
  files:
    - path/to/file.rb
  commands:
    - git diff HEAD~1
  presets:
    - project
---
[Your prompt content here]
```

## Features

- **Queue Workflow**: Single active prompt file, no naming or discovery
- **Auto-Archiving**: Timestamp-based archive with full history
- **Context Loading**: Optional integration with ace-context
- **Enhancement**: Optional LLM enhancement with caching
- **Task Support**: Task-specific prompts for focused work
- **Template System**: Base templates with tmpl:// protocol support

## Configuration

Create `.ace/prompt/config.yml`:

```yaml
prompt:
  default_dir: .cache/ace-prompt/prompts
  default_file: the-prompt.md

  template: tmpl://ace-prompt/base-prompt

  context:
    enabled: false  # CLI flags override

  enhancement:
    enabled: false  # CLI flags override
    model: glite    # google:gemini-2.0-flash-lite
    temperature: 0.3
```

## Documentation

See `docs/usage.md` for comprehensive usage guide with examples and flow diagrams.

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake test` to run the tests.

## Contributing

Bug reports and pull requests are welcome.

## License

The gem is available as open source under the terms of the MIT License.
