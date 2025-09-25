# ace-llm

LLM provider integration for AI-assisted development. Query any LLM provider through a unified CLI interface with cost tracking and output formatting. Features a configuration-based provider architecture that supports dynamic provider registration via YAML files.

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

# List available providers and their status
ace-llm-query --list-providers
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

### Provider Configuration

Providers are now configured via YAML files in `.ace/llm/providers/`. You can add custom providers or override default configurations:

```yaml
# .ace/llm/providers/custom-provider.yml
name: custom-provider
class: CustomProviders::MyLLMClient
gem: custom-llm-provider  # External gem
models:
  - model-1
  - model-2
api_key:
  env: CUSTOM_API_KEY
  required: true
capabilities:
  - text_generation
  - streaming
default_options:
  temperature: 0.7
  max_tokens: 4096
```

#### Configuration Search Paths

Provider configurations are loaded from (in order):
1. Project `.ace/llm/providers/` directory
2. User config `~/.config/ace-llm/providers/`
3. Gem built-in `providers/` directory

First configuration found wins if there are duplicates.

## Supported Providers

All providers are now configuration-based and support dynamic loading:

- **Google** (Gemini models) - `gemini-2.5-flash`, `gemini-2.5-pro`
- **OpenAI** (GPT models) - `gpt-4o`, `gpt-4o-mini`, `gpt-3.5-turbo`
- **Anthropic** (Claude models) - `claude-3-5-sonnet`, `claude-3-opus`
- **Mistral** - `mistral-large-latest`, `mistral-small-latest`
- **Together AI** - Various open-source models
- **LM Studio** (local models) - Custom local models

Use `ace-llm-query --list-providers` to see available providers and their configuration status.

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

- **Atoms**: Pure functions (env_reader, http_client, xdg_directory_resolver, provider_config_validator)
- **Molecules**: Composed operations (client_registry, provider_loader, llm_alias_resolver, provider_model_parser, format_handlers)
- **Organisms**: Provider clients (base_client, google_client, etc.)
- **Commands**: CLI implementation using OptionParser

### Configuration-Based Provider Architecture

The new architecture features:
- **ClientRegistry**: Manages provider configurations and instantiation
- **ProviderLoader**: Handles dynamic gem and class loading
- **ProviderConfigValidator**: Validates provider configuration schemas
- **YAML-based configuration**: Define providers without code changes
- **Dynamic discovery**: Auto-discover providers from multiple directories
- **Gem-based plugins**: Support for provider gems as separate packages

## License

MIT License - See LICENSE.txt for details