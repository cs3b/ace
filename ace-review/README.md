# ace-review

Automated code review tool for the ACE framework. Provides preset-based code analysis using LLM-powered insights with configurable focus areas and flexible prompt composition.

## Features

- **Preset-based reviews** - Predefined configurations for common scenarios (PR, security, docs, etc.)
- **Flexible prompt composition** - Modular prompts with base, format, focus, and guidelines
- **Prompt cascade** - Override built-in prompts at project or user level
- **Multiple focus modules** - Combine architecture, language, and quality focuses
- **Release integration** - Stores reviews in `.ace-taskflow/<release>/reviews/`
- **LLM provider support** - Works with any provider supported by ace-llm
- **Custom presets** - Create team-specific review configurations

## Installation

Add this gem to your Gemfile:

```ruby
gem 'ace-review'
```

Or install it directly:

```bash
gem install ace-review
```

## Quick Start

```bash
# Review pull request changes (default)
ace-review code

# Security-focused review
ace-review code --preset security

# List available presets
ace-review code --list-presets

# List available prompt modules
ace-review code --list-prompts

# Execute review with LLM automatically
ace-review code --preset pr --auto-execute
```

## Configuration

### Main Configuration

Create `.ace/review/code.yml` in your project:

```yaml
defaults:
  model: "google:gemini-2.5-flash"
  output_format: "markdown"
  context: "project"

storage:
  base_path: ".ace-taskflow/%{release}/reviews"
  auto_organize: true

presets:
  pr:
    description: "Pull request review"
    prompt_composition:
      base: "prompt://base/system"
      format: "prompt://format/standard"
      guidelines:
        - "prompt://guidelines/tone"
        - "prompt://guidelines/icons"
    context: "project"
    subject:
      commands:
        - "git diff origin/main...HEAD"
```

### Custom Presets

Create preset files in `.ace/review/presets/`:

```yaml
# .ace/review/presets/team-review.yml
description: "Team-specific review criteria"
prompt_composition:
  base: "prompt://base/system"
  format: "prompt://format/detailed"
  focus:
    - "prompt://focus/architecture/atom"
    - "prompt://focus/languages/ruby"
    - "prompt://project/focus/team/standards"  # Custom team focus
  guidelines:
    - "prompt://guidelines/tone"
context:
  files:
    - "docs/team-guidelines.md"
subject:
  commands:
    - "git diff HEAD~1..HEAD"
```

## Prompt System

### Prompt Cascade

Prompts are resolved in this order:
1. Project: `./.ace/review/prompts/`
2. User: `~/.ace/review/prompts/`
3. Built-in: Gem's internal prompts

### Prompt Structure

```
.ace/review/prompts/
├── base/           # Core system prompts
├── format/         # Output formats
├── focus/          # Review focus areas
│   ├── architecture/
│   ├── languages/
│   ├── quality/
│   └── scope/
└── guidelines/     # Style guidelines
```

### prompt:// Protocol

Reference prompts using URIs:

```yaml
prompt_composition:
  base: "prompt://base/system"              # Cascade lookup
  base: "prompt://project/base/custom"      # Project only
  base: "./my-prompt.md"                    # Relative to config
  base: "prompts/my-prompt.md"              # From project root
```

## Focus Modules

Combine multiple focus modules for comprehensive reviews:

```yaml
focus:
  - "prompt://focus/architecture/atom"      # ATOM pattern
  - "prompt://focus/languages/ruby"         # Ruby best practices
  - "prompt://focus/quality/security"       # Security analysis
```

Available focus modules:
- **Architecture**: atom, microservices, mvc
- **Languages**: ruby, javascript, python
- **Frameworks**: rails, vue-firebase
- **Quality**: security, performance
- **Scope**: tests, docs

## CLI Reference

### ace-review code

```bash
ace-review code [options]
```

Options:
- `--preset <name>` - Use specific preset (default: pr)
- `--output-dir <path>` - Custom output directory
- `--output <file>` - Specific output file path
- `--model <model>` - Override LLM model
- `--auto-execute` - Execute LLM query automatically
- `--dry-run` - Prepare review without executing
- `--list-presets` - List available presets
- `--list-prompts` - List available prompt modules
- `--verbose` - Enable verbose output

Advanced options for prompt composition:
- `--prompt-base <module>` - Override base prompt
- `--prompt-format <module>` - Override format module
- `--prompt-focus <modules>` - Set focus modules (comma-separated)
- `--add-focus <modules>` - Add focus to preset
- `--prompt-guidelines <modules>` - Set guideline modules

## Migration from code-review

This gem replaces the previous `code-review` commands:

| Old Command | New Command |
|-------------|-------------|
| `code-review` | `ace-review code` |
| `code-review-synthesize` | Use workflow: `wfi://synthesize-reviews` |

### Migration Steps

1. **Install ace-review gem**
   ```bash
   gem install ace-review
   ```

2. **Copy configuration**
   ```bash
   cp .coding-agent/code-review.yml .ace/review/code.yml
   ```

3. **Update workflow files**
   - Replace `code-review` with `ace-review code`
   - Remove `code-review-synthesize` CLI usage

## Architecture

ace-review follows the ATOM architecture pattern:

- **Atoms**: Pure functions (git_extractor, file_reader)
- **Molecules**: Composed operations (preset_manager, prompt_composer)
- **Organisms**: Business orchestration (review_manager)
- **Models**: Data structures (review_config, preset)

## Development

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rake test

# Run with local changes
bundle exec exe/ace-review code --list-presets

# Console for debugging
bundle exec rake console
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Create a Pull Request

## License

MIT License - see LICENSE.txt for details