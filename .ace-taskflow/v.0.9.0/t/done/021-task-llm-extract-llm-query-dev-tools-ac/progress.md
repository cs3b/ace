# Task 021: Extract llm-query from dev-tools to ace-llm gem - Progress Report

## Completed Work

### 1. Analysis Phase ✅
- Analyzed dev-tools llm-query structure comprehensively
- Identified all provider implementations (Google, OpenAI, Anthropic, LMStudio, Mistral, TogetherAI)
- Mapped dry-cli usage patterns for OptionParser conversion
- Identified ace-core integration points

### 2. Gem Structure Created ✅
- Created ace-llm gem scaffold at repository root
- Set up proper directory structure following ATOM pattern:
  - `lib/ace/llm/atoms/` - Pure functions
  - `lib/ace/llm/molecules/` - Composed operations
  - `lib/ace/llm/organisms/` - Provider clients
  - `lib/ace/llm/models/` - Data structures
  - `lib/ace/llm/commands/` - CLI commands
- Created gemspec with appropriate dependencies (ace-core, faraday, addressable, kramdown)
- Set up version.rb and main library file with Zeitwerk autoloading

### 3. Atoms Ported ✅
Successfully ported three essential atoms without dry-* dependencies:

- **env_reader.rb** - Environment variable utilities with provider-specific API key helpers
- **xdg_directory_resolver.rb** - XDG-compliant directory resolution for cache/config/data
- **http_client.rb** - HTTP operations using Faraday with built-in retry logic

### 4. Molecules (Partially Completed) 🔄
Ported two key molecules:

- **file_io_handler.rb** - File I/O operations with format detection and safety checks
- **llm_alias_resolver.rb** - Alias resolution with ace-core config cascade and backward compatibility

## Remaining Work

### Molecules to Port
- `provider_model_parser.rb` - Parse provider:model syntax
- `format_handlers.rb` - Handle text/json/markdown output formats
- `metadata_normalizer.rb` - Normalize response metadata
- Provider usage parsers (for each provider)

### Organisms to Port
- Base clients:
  - `base_client.rb` - Common client functionality
  - `base_chat_completion_client.rb` - Shared chat completion logic
- Provider clients:
  - `google_client.rb`
  - `openai_client.rb`
  - `anthropic_client.rb`
  - `lmstudio_client.rb`
  - `mistral_client.rb`
  - `togetherai_client.rb`

### Command Implementation
- Create `ace/llm/commands/query.rb` using OptionParser instead of dry-cli
- Port all command options and argument handling
- Integrate with molecules and organisms

### Cost Tracking & Pricing
- Port `cost_tracker.rb`
- Port `pricing_fetcher.rb`
- Port pricing models and usage metadata

### Executable & Configuration
- Create `ace-llm/exe/ace-llm-query` executable
- Set up .ace/llm/ configuration structure
- Implement backward compatibility with .coding-agent/

### Testing & Documentation
- Create test suite for provider integrations
- Write README.md with usage examples
- Create docs/usage.md with detailed documentation

## Technical Decisions Made

1. **Removed dry-* dependencies**: Replaced dry-cli with OptionParser, removed dry-monitor and dry-configurable
2. **Simplified retry logic**: Built retry functionality directly into http_client atom instead of separate middleware
3. **ace-core integration**: Using ace-core's ConfigResolver for configuration cascade
4. **Backward compatibility**: Supporting both .ace/ and .coding-agent/ config paths during migration

## Next Steps

The foundation is in place with the gem structure, atoms, and key molecules. The main remaining work is:

1. Port the provider clients (organisms)
2. Implement the query command with OptionParser
3. Port cost tracking functionality
4. Create the executable
5. Add tests and documentation

## Estimated Remaining Effort

Based on work completed (~40%) and remaining tasks:
- Molecules completion: 1-2 hours
- Organisms porting: 2-3 hours
- Command implementation: 1 hour
- Cost tracking: 1 hour
- Testing & documentation: 1-2 hours

Total estimated: 6-9 hours remaining