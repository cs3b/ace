# Migration Guide: llm-query to ace-llm-query

## Command API Comparison

### Command Name
- **Original**: `llm-query` (via dev-tools)
- **New**: `ace-llm-query` (via ace-llm gem)

### Basic Syntax (Identical)
Both commands use the same basic syntax:
```bash
[command] PROVIDER[:MODEL] PROMPT [options]
```

### Options Comparison

| Option | llm-query | ace-llm-query | Notes |
|--------|-----------|---------------|-------|
| `--output, -o FILE` | ✅ | ✅ | Same behavior |
| `--format FORMAT` | ✅ | ✅ | text, json, markdown |
| `--temperature FLOAT` | ✅ | ✅ | 0.0-2.0 range |
| `--max-tokens INT` | ✅ | ✅ | Same behavior |
| `--system TEXT` | ✅ | ✅ | System prompt |
| `--timeout SECONDS` | ✅ | ✅ | Request timeout |
| `--force, -f` | ✅ | ✅ | Force overwrite |
| `--debug, -d` | ✅ | ✅ | Debug output |
| `--help, -h` | ✅ | ✅ | Help message |
| `--version, -v` | ❌ | ✅ | Added in ace-llm |

### Provider Support

| Provider | llm-query | ace-llm-query |
|----------|-----------|---------------|
| Google (Gemini) | ✅ | ✅ |
| OpenAI | ✅ | ✅ |
| Anthropic | ✅ | ✅ |
| Mistral | ✅ | ✅ |
| Together AI | ✅ | ✅ |
| LM Studio | ✅ | ✅ |

### Alias Support (Identical)
Both support the same aliases:
- `gflash` → google:gemini-2.5-flash
- `opus` → anthropic:claude-3-opus-20240229
- `sonnet` → anthropic:claude-3-5-sonnet-20241022
- `gpt4o` → openai:gpt-4o
- etc.

## Implementation Differences

### 1. Dependencies

**llm-query (original)**:
- dry-cli (command framework)
- dry-monitor (observability)
- dry-configurable (configuration)
- dotenv (environment loading)
- Custom retry middleware
- Custom security validators

**ace-llm-query (new)**:
- OptionParser (Ruby stdlib) - replaced dry-cli
- ace-core (optional, for config cascade)
- Faraday (HTTP client) - same as original
- No dry-* dependencies
- Built-in retry logic in HTTPClient atom
- Simplified security checks

### 2. Architecture

**llm-query**:
```
dev-tools/
├── cli/commands/llm/query.rb  # dry-cli command class
├── molecules/
│   ├── llm_alias_resolver.rb
│   ├── provider_model_parser.rb
│   └── client_factory.rb      # Dynamic client registration
└── organisms/
    └── *_client.rb             # Provider clients
```

**ace-llm-query**:
```
ace-llm/
├── exe/ace-llm-query           # Direct executable
├── lib/ace/llm/
│   ├── atoms/                  # Pure functions
│   ├── molecules/               # Composed operations
│   └── organisms/               # Provider clients
```

### 3. Configuration Paths

**llm-query**:
- Primary: `.coding-agent/llm-aliases.yml`
- User: `~/.config/coding-agent-tools/llm-aliases.yml`

**ace-llm-query**:
- Primary: `.ace/llm/aliases.yml`
- Legacy support: `.coding-agent/llm-aliases.yml`
- User: `~/.config/ace-llm/aliases.yml`

### 4. Code Organization

**Key Differences**:

1. **Command Implementation**:
   - llm-query: Uses Dry::CLI::Command class
   - ace-llm-query: Plain Ruby class with OptionParser

2. **Client Registration**:
   - llm-query: Dynamic registration via ClientFactory
   - ace-llm-query: Explicit require and case statement

3. **Error Handling**:
   - llm-query: Complex security validators and middleware
   - ace-llm-query: Simplified inline validation

4. **Observability**:
   - llm-query: dry-monitor events and notifications
   - ace-llm-query: Simple debug output (no event system)

### 5. Feature Differences

| Feature | llm-query | ace-llm-query | Notes |
|---------|-----------|---------------|-------|
| Basic queries | ✅ | ✅ | Identical |
| File input/output | ✅ | ✅ | Same behavior |
| Alias resolution | ✅ | ✅ | Same aliases |
| Format output | ✅ | ✅ | text/json/markdown |
| Cost tracking | ✅ | ❌ | Deferred to future |
| Usage reports | ✅ | ❌ | Not implemented |
| Security logging | ✅ | ❌ | Simplified |
| Event notifications | ✅ | ❌ | No dry-monitor |

## Migration Steps

### For Users

1. **Install ace-llm**:
   ```bash
   cd ace-llm
   bundle install
   ```

2. **Update PATH or create alias**:
   ```bash
   alias llm-query='ace-llm/exe/ace-llm-query'
   ```

3. **Copy configuration** (optional):
   ```bash
   cp .coding-agent/llm-aliases.yml .ace/llm/aliases.yml
   ```

4. **Environment variables** (same):
   - Keep same API keys: GEMINI_API_KEY, OPENAI_API_KEY, etc.

### For Developers

1. **Update imports**:
   ```ruby
   # Old
   require "coding_agent_tools/cli/commands/llm/query"

   # New
   require "ace/llm"
   ```

2. **Update client instantiation**:
   ```ruby
   # Old (with ClientFactory)
   client = ClientFactory.build("google", model: "gemini-2.5-flash")

   # New (direct instantiation)
   client = Ace::LLM::Organisms::GoogleClient.new(model: "gemini-2.5-flash")
   ```

3. **Update error handling**:
   ```ruby
   # Old
   rescue CodingAgentTools::Error => e

   # New
   rescue Ace::LLM::Error => e
   ```

## Advantages of ace-llm-query

1. **Fewer Dependencies**: No dry-* gems reduces complexity
2. **Simpler Architecture**: Direct execution without framework overhead
3. **Better Modularity**: Standalone gem can be used independently
4. **Clearer Code**: Less abstraction, easier to understand
5. **Faster Startup**: No framework initialization overhead

## Compatibility Notes

- **API Compatible**: Command-line interface is 100% compatible
- **Output Compatible**: Same output formats and structure
- **Alias Compatible**: All aliases work identically
- **Config Semi-Compatible**: Supports legacy paths with fallback

## What's Not Migrated

1. **Cost Tracking**: The CostTracker and PricingFetcher components
2. **Usage Reports**: The usage-report subcommand
3. **Event System**: dry-monitor notifications
4. **Security Logging**: SecurityLogger component
5. **Advanced Middleware**: Custom retry and monitoring middleware

These features can be added in future iterations if needed.