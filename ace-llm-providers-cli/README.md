# ace-llm-providers-cli

CLI-based LLM providers for ace-llm. This gem extends ace-llm with providers that interact with LLMs through command-line interfaces, including Claude Code, Codex, OpenCode, and Codex OSS.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ace-llm-providers-cli'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install ace-llm-providers-cli
```

### Configuration

Provider configurations are in `.ace.example/llm/providers/`. Copy these to your project's `.ace/llm/providers/` directory:

```bash
cp -r gems/ace-llm-providers-cli/.ace.example/llm/providers/*.yml .ace/llm/providers/
```

## Prerequisites

This gem requires at least one CLI tool to be installed. Each provider has its own CLI tool:

### Claude Code (cc)
```bash
# Install Claude CLI
npm install -g @anthropic-ai/claude-cli

# Authenticate
claude setup-token
```

### Codex (codex)
```bash
# Install Codex CLI
npm install -g @openai/codex
# Or visit https://codex.ai

# Authenticate
codex login
```

### OpenCode (opencode)
```bash
# Install OpenCode CLI
npm install -g opencode-cli
# Or visit https://opencode.dev

# Authenticate
opencode auth
```

### Codex OSS (codexoss)
```bash
# Install Codex OSS
pip install codex-oss
# Or visit https://github.com/codex-oss/codex

# Configure
codex-oss init
```

## Usage

Once installed, the CLI providers automatically register with ace-llm and can be used through the standard `ace-llm-query` interface:

```bash
# Claude Code examples
ace-llm-query cc:opus "Explain this Ruby pattern"
ace-llm-query cc:sonnet "Generate a test for this code" --output test.rb
ace-llm-query cc:haiku "Quick refactor suggestion"

# Codex examples
ace-llm-query codex:gpt-5 "Review this code for best practices"
ace-llm-query codex:mini "Generate documentation"

# OpenCode examples
ace-llm-query opencode "Generate unit tests" --output tests.rb
ace-llm-query opencode:google/gemini-2.5-flash "Analyze this architecture"

# Codex OSS examples
ace-llm-query codexoss "Suggest improvements"
```

### All Standard Options Work

```bash
# Output to file
ace-llm-query cc:opus "Generate README" --output README.md

# Different formats
ace-llm-query cc:sonnet "Explain" --format json
ace-llm-query cc:sonnet "Explain" --format markdown

# Temperature control
ace-llm-query codex:gpt-5 "Creative writing" --temperature 0.9

# Token limits
ace-llm-query opencode "Summary" --max-tokens 500

# System prompts
ace-llm-query cc:opus "Review" --system "You are a code reviewer"

# Timeout control
ace-llm-query codexoss "Complex analysis" --timeout 180
```

## Check CLI Tool Status

Use the included utility to check which CLI tools are installed and authenticated:

```bash
ace-llm-providers-cli-check
```

This will show:
- Which CLI tools are installed
- Their versions
- Authentication status
- Installation instructions for missing tools

Example output:
```
🔍 Checking CLI-based LLM providers for ace-llm-providers-cli

✅ Claude Code     (cc)
   Version: 1.2.3
   Auth: 🔓 Authenticated

❌ Codex          (codex)
   Status: Not installed
   Install: npm install -g @openai/codex
   URL: https://codex.ai

✅ OpenCode       (opencode)
   Version: 2.0.1
   Auth: 🔒 Run: opencode auth

❌ Codex OSS      (codexoss)
   Status: Not installed
   Install: pip install codex-oss
   URL: https://github.com/codex-oss/codex

──────────────────────────────────────────────────

📊 Summary:
   Available: 2/4 CLI tools installed
   Authenticated: 1/2 tools authenticated

💡 Some tools need authentication. Run the auth commands shown above.
```

## Provider Details

### Claude Code (cc)
- **Models**: opus, opus4, sonnet, haiku
- **Default**: sonnet
- **Context**: 200,000 tokens
- **Aliases**: claude-code, cc-opus, cc-sonnet, cc-haiku

### Codex (codex)
- **Models**: gpt-5, gpt-5-mini
- **Default**: gpt-5
- **Context**: 128,000 tokens
- **Aliases**: codex-gpt5, codex-mini

### OpenCode (opencode)
- **Models**: Multiple providers (Google, Anthropic, OpenAI)
- **Default**: google/gemini-2.5-flash
- **Context**: Varies by model (up to 2M tokens)
- **Aliases**: oc

### Codex OSS (codexoss)
- **Models**: default
- **Default**: default
- **Context**: 16,384 tokens
- **Aliases**: codex-oss

## Error Handling

The gem provides clear error messages for common issues:

### CLI Tool Not Found
```
Error: Claude CLI not found. Install with: npm install -g @anthropic-ai/claude-cli
```

### Not Authenticated
```
Error: Claude authentication required. Run 'claude setup-token' to configure
```

### Subprocess Timeout
```
Error: Claude CLI execution timed out after 120 seconds
```

## Architecture

This gem follows a plugin architecture:

1. **Dynamic Registration**: Providers auto-register when the gem is loaded
2. **Subprocess Execution**: Uses Ruby's Open3 for safe CLI interaction
3. **No External Dependencies**: Only requires ace-llm and Ruby stdlib
4. **Error Isolation**: CLI failures don't affect other providers

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

To test with a local ace-llm:

```ruby
# In Gemfile
gem "ace-llm", path: "../ace-llm"
```

## Testing

Run the test suite:

```bash
bundle exec rake test
```

Run the linter:

```bash
bundle exec rubocop
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

MIT License - see LICENSE file for details.

## Troubleshooting

### CLI tool works manually but not through the gem

Check that the tool is in your PATH:
```bash
which claude  # or codex, opencode, codex-oss
```

### Authentication seems to fail repeatedly

Some CLI tools cache authentication. Try:
1. Log out and log back in to the CLI tool
2. Check for expired tokens
3. Ensure network connectivity for token validation

### Subprocess timeouts on large prompts

Increase the timeout:
```bash
ace-llm-query cc:opus "large prompt" --timeout 300
```

Or set it in code:
```ruby
client = Ace::LLM::Providers::CLI::ClaudeCodeClient.new(timeout: 300)
```