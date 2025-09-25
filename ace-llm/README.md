# ace-llm

LLM provider integration for AI-assisted development. Query any LLM provider through a unified CLI interface with cost tracking and output formatting.

## Installation

Add this gem to your Gemfile:

```ruby
gem 'ace-llm', path: '../ace-llm'  # For local development
```

Or install it directly:

```bash
cd ace-llm
bundle install
bundle exec rake install
```

## Usage

### Basic Query

```bash
# Query with explicit provider and model
ace-llm-query google:gemini-2.5-flash "What is Ruby programming?"

# Use default model for provider
ace-llm-query google "Explain closures"

# Use aliases for quick access
ace-llm-query gflash "Write a haiku about coding"
```

### Common Aliases

- `gflash` → google:gemini-2.5-flash
- `gpro` → google:gemini-2.5-pro
- `opus` → anthropic:claude-3-opus-20240229
- `sonnet` → anthropic:claude-3-5-sonnet-20241022
- `gpt4o` → openai:gpt-4o
- `o4mini` → openai:gpt-4o-mini

### Advanced Options

```bash
# Save output to file
ace-llm-query gflash "Explain Docker" --output docker.md

# Control temperature
ace-llm-query gflash "Creative story" --temperature 1.5

# Limit output length
ace-llm-query gflash "Summary" --max-tokens 200

# Add system prompt
ace-llm-query gflash code.rb --system "You are a Ruby expert"

# Output as JSON
ace-llm-query gflash "List 5 tips" --format json --output tips.json
```

## Configuration

### API Keys

Set environment variables for each provider:

```bash
export GEMINI_API_KEY="your-key"      # or GOOGLE_API_KEY
export OPENAI_API_KEY="your-key"
export ANTHROPIC_API_KEY="your-key"
export MISTRAL_API_KEY="your-key"
export TOGETHER_API_KEY="your-key"    # or TOGETHERAI_API_KEY
```

### Aliases Configuration

Create custom aliases in `.ace/llm/aliases.yml`:

```yaml
global:
  mymodel: "google:gemini-2.5-flash"
  quick: "openai:gpt-4o-mini"

providers:
  google:
    flash: "gemini-2.5-flash"
    pro: "gemini-2.5-pro"
```

## Supported Providers

Currently implemented:
- **Google** (Gemini models)

Coming soon:
- **OpenAI** (GPT models)
- **Anthropic** (Claude models)
- **Mistral**
- **Together AI**
- **LM Studio** (local models)

## Development

```bash
# Run tests
bundle exec rake test

# Run linter
bundle exec rake standard

# Install gem locally
bundle exec rake install
```

## Architecture

The gem follows the ATOM architecture pattern:

- **Atoms**: Pure functions (env_reader, http_client, xdg_directory_resolver)
- **Molecules**: Composed operations (llm_alias_resolver, provider_model_parser, format_handlers)
- **Organisms**: Provider clients (base_client, google_client, etc.)
- **Commands**: CLI implementation using OptionParser

## License

MIT License - See LICENSE.txt for details