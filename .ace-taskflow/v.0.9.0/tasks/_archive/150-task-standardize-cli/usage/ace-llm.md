# ace-llm CLI Interface

## Current Implementation

- **Framework**: OptionParser (custom, in exe)
- **Entry Point**: `ace-llm/exe/ace-llm-query`
- **Lines of Code**: ~357
- **Migration Needed**: Yes

## Commands

### query (default)

Query LLM providers with flexible provider/model syntax.

**Usage**: `ace-llm-query [PROVIDER[:MODEL]] [PROMPT] [options]`

**Provider Syntax**:
- `provider` - Use provider with default model
- `provider:model` - Use specific model
- Model aliases (e.g., `gflash`, `glite`) resolved via config

**Options**:
| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--prompt TEXT` | `-p` | string | Prompt text (alternative to positional) |
| `--file FILE` | `-f` | string | Read prompt from file |
| `--context FILE` | `-c` | string | System prompt/context file |
| `--model MODEL` | `-m` | string | Model override |
| `--temperature TEMP` | `-t` | float | Temperature (0.0-2.0) |
| `--max-tokens NUM` | | integer | Maximum output tokens |
| `--timeout SECONDS` | | integer | Request timeout |
| `--stream` | `-s` | flag | Stream output |
| `--json` | `-j` | flag | JSON output |
| `--raw` | `-r` | flag | Raw output (no formatting) |
| `--verbose` | `-v` | flag | Verbose output |
| `--debug` | `-d` | flag | Debug output |
| `--dry-run` | `-n` | flag | Show what would be sent |
| `--help` | `-h` | flag | Show help |
| `--version` | | flag | Show version |

### list-providers

List available LLM providers.

**Usage**: `ace-llm-query list-providers [options]`

**Examples**:
```bash
ace-llm-query "What is Ruby?"           # Default provider
ace-llm-query google "Explain git"      # Google provider
ace-llm-query google:gemini-2.5-flash "Hello"  # Specific model
ace-llm-query gflash "Hello"            # Model alias
ace-llm-query -f prompt.md              # From file
ace-llm-query -f prompt.md -c system.md # With context
ace-llm-query list-providers            # Show providers
```

## Provider/Model Resolution

1. Check if input is model alias (gflash → google:gemini-2.5-flash)
2. Check if input is provider name (google → google:default-model)
3. Parse provider:model syntax

## Proposed Thor Migration

### Thor CLI Structure

```ruby
# lib/ace/llm/cli.rb
class CLI < Thor
  desc "query [PROVIDER_MODEL] [PROMPT]", "Query LLM provider"
  option :prompt, type: :string, aliases: "-p", desc: "Prompt text"
  option :file, type: :string, aliases: "-f", desc: "Prompt file"
  option :context, type: :string, aliases: "-c", desc: "System prompt file"
  option :model, type: :string, aliases: "-m", desc: "Model override"
  option :temperature, type: :numeric, aliases: "-t"
  option :max_tokens, type: :numeric
  option :timeout, type: :numeric
  option :stream, type: :boolean, aliases: "-s"
  option :json, type: :boolean, aliases: "-j"
  option :raw, type: :boolean, aliases: "-r"
  option :verbose, type: :boolean, aliases: "-v"
  option :debug, type: :boolean, aliases: "-d"
  option :dry_run, type: :boolean, aliases: "-n"
  option :quiet, type: :boolean, aliases: "-q"
  def query(provider_model = nil, *prompt_parts)
    require_relative "commands/query_command"
    Commands::QueryCommand.new(provider_model, prompt_parts, options).execute
  end
  default_task :query

  desc "list_providers", "List available LLM providers"
  option :verbose, type: :boolean, aliases: "-v"
  option :json, type: :boolean, aliases: "-j"
  def list_providers
    require_relative "commands/list_providers_command"
    Commands::ListProvidersCommand.new(options).execute
  end
  map "list-providers" => :list_providers
end
```

### Migration Notes

- Handle flexible positional args (provider, model, prompt can be positional or flags)
- Thor varargs for prompt parts that span multiple args
- Use map for hyphenated command alias
- Preserve provider:model parsing in QueryCommand
- Model alias resolution via config
- Add ConfigSummary integration
