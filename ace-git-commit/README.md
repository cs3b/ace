# ace-git-commit

LLM-powered git commit tool for streamlined, meaningful commit messages.

## Overview

`ace-git-commit` simplifies the git commit process by leveraging LLM technology to generate clear, conventional commit messages based on your changes. It's designed for monorepo workflows and integrates seamlessly with the ACE ecosystem.

## Features

- 🤖 **LLM-powered message generation** - Uses ace-llm to generate meaningful commit messages
- 📝 **Conventional commits** - Follows conventional commit format automatically
- 🎯 **Intention-based commits** - Provide context for better message generation
- 🚀 **Smart staging** - Automatically stages all changes by default
- ✅ **Transparent feedback** - Clear staging progress and error reporting with actionable suggestions
- 🔧 **Flexible configuration** - Customize via `.ace/git/commit.yml` with path-aware overrides
- 💎 **Ruby integration** - Direct integration with ace-llm (no subprocess overhead)

## Installation

As part of the ace monorepo:

```bash
# From ace root
bundle install
```

The `ace-git-commit` command will be available in your bundle.

## Usage

### Basic Commands

```bash
# Generate commit message for all changes
ace-git-commit

# Provide intention for better context
ace-git-commit -i "fixing authentication bug"

# Use specific message (bypass LLM)
ace-git-commit -m "fix: resolve auth issue"

# Commit specific files
ace-git-commit src/auth.rb src/user.rb

# Commit only staged changes
ace-git-commit --only-staged
```

### Options

- `-i, --intention INTENTION` - Provide context for LLM generation
- `-m, --message MESSAGE` - Use specific message (no LLM)
- `--model MODEL` - Override default model (e.g., glite, gflash)
- `-s, --only-staged` - Commit only staged changes
- `-n, --dry-run` - Preview without committing
- `--no-split` - Force a single commit even when multiple config scopes are detected
- `-d, --debug` - Enable debug output
- `--verbose` - Enable verbose output (default: on, shows staging progress)
- `-q, --quiet` - Suppress informational messages (errors only)
- `-h, --help` - Show help

**Note**: Staging progress messages are visible by default. Use `--quiet` to suppress them.

## Configuration

### Project Configuration

Create `.ace/git/commit.yml`:

```yaml
git:
  model: glite  # Default LLM model
  conventions:
    format: conventional
    scopes:
      enabled: true
      detect_from_paths: true
      custom:
        - auth
        - api
        - ui
```

### Path-Based Config Splitting

When staged files span multiple packages with different configs, `ace-git-commit` automatically splits them into separate commits. Use `--no-split` to force a single commit.

Centralized scope rules (project-level):

```yaml
git:
  model: glite
  scopes:
    taskflow-specs:
      glob: ".ace-taskflow/**"
      type_hint: spec
      description: "Task specifications and workflow documentation"
    handbook:
      glob: "ace-handbook/**"
      model: gflash
```

Each scope can include:
- `glob` - Pattern(s) to match files (string or array)
- `model` - LLM model override for this scope
- `type_hint` - Preferred commit type (docs, chore, feat, fix, etc.)
- `description` - Context for better commit messages

#### Glob Arrays

When a scope needs to match multiple unrelated patterns, use an array:

```yaml
git:
  scopes:
    ace-config:
      glob:
        - ".ace/**"
        - "*/.ace/**"
        - "**/.ace/**"
      type_hint: chore
      description: "Project configuration files"
```

This matches `.ace/` directories at any level of the project hierarchy.

#### Distributed Package Config

You can also place config files directly in packages (co-located):

```
ace-handbook/.ace/git/commit.yml
```

Distributed configs take precedence over centralized `scopes` rules.

### Root-Level Override Behavior

Keys at the root level of your config file override values nested under `git:`. This allows shorthand configuration:

```yaml
# Full nested form
git:
  model: glite
  conventions:
    format: conventional

# Shorthand - root keys override nested git: values
git:
  conventions:
    format: conventional
model: gflash  # Overrides git.model
```

Both forms produce the same result, with `model: gflash` taking precedence. This is useful for quick overrides without restructuring your config.

### Available Models

The tool uses ace-llm providers. Common aliases:
- `glite` - Google Gemini 2.0 Flash Lite (default)
- `gflash` - Google Gemini 2.5 Flash
- `anthropic:claude-3.5-sonnet` - Claude 3.5 Sonnet
- `openai:gpt-4` - OpenAI GPT-4

## Architecture

The gem follows the ATOM architecture:

```
ace-git-commit/
├── atoms/
│   └── git_executor.rb       # Git command execution
├── molecules/
│   ├── diff_analyzer.rb      # Diff analysis
│   ├── file_stager.rb        # File staging logic
│   └── message_generator.rb  # LLM message generation
├── organisms/
│   └── commit_orchestrator.rb # Main workflow coordination
└── models/
    └── commit_options.rb      # Options data model
```

## Integration with ace-llm

The gem uses the new `QueryInterface` in ace-llm for direct Ruby integration:

```ruby
response = Ace::LLM::QueryInterface.query(
  "glite",           # Model alias
  user_prompt,       # Prompt
  system: system,    # System prompt
  temperature: 0.7,  # Generation temperature
  timeout: 60        # Timeout in seconds
)
```

This provides:
- No subprocess overhead
- Better error handling
- Direct Ruby exceptions
- Easier testing

## Development

### Running Tests

```bash
cd ace-git-commit
bundle exec rake test
```

### Testing the CLI

```bash
# From ace root
bundle exec ace-git-commit --dry-run
```

## System Prompt

The system prompt for commit message generation is maintained in:
```
ace-git-commit/handbook/prompts/git-commit.system.md
```

This centralized location allows for consistent prompt management across the project.

## Comparison with dev-tools git-commit

| Feature | ace-git-commit | dev-tools git-commit |
|---------|---------------|---------------------|
| Scope | Single repo only | Multi-repo support |
| LLM Integration | Direct Ruby (ace-llm) | Subprocess (ace-llm-query) |
| Default Behavior | Stage all changes | Requires explicit staging |
| Configuration | YAML-based | Mixed (YAML + Ruby) |
| Architecture | ATOM pattern | Procedural scripts |

## Contributing

1. Follow the ATOM architecture pattern
2. Write tests for new functionality
3. Update documentation as needed
4. Use conventional commits for contributions

## License

MIT

## See Also

- [ace-llm](../ace-llm/) - LLM provider integration
- [ace-core](../ace-core/) - Core utilities
- [Usage Guide](../.ace-taskflow/v.0.9.0/t/007-feat-git-ace-git-gem-ace-gc-only/ux/usage.md) - Detailed usage documentation
