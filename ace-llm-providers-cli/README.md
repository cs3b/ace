# ace-llm-providers-cli

CLI-based LLM providers for ace-llm.

## Purpose

`ace-llm-providers-cli` extends `ace-llm` with providers that run through command-line tools,
including Claude Code, Codex, OpenCode, and Codex OSS.

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

Provider configurations are in `.ace-defaults/llm/providers/`. Copy these to your project's `.ace/llm/providers/` directory:

```bash
cp -r gems/ace-llm-providers-cli/.ace-defaults/llm/providers/*.yml .ace/llm/providers/
```

## Prerequisites

This gem requires at least one CLI tool to be installed. Each provider has its own CLI tool:

### Claude Code (claude)
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

**Minimum version requirement**: The `--output-last-message <path>` flag is required for stall
diagnosis (progressive last-message capture). Verify your installed version supports it:

```bash
codex --help | grep output-last-message
```

If the flag is absent, upgrade: `npm install -g @openai/codex@latest`. Without this flag the
provider falls back to Layer 1 capture (text from the query response), so stall diagnostics still
work but may lose partial output written mid-session.

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

Once installed, the CLI providers automatically register with ace-llm and can be used through the standard `ace-llm` interface:

```bash
# Claude Code examples (using cc alias or claude directly)
ace-llm cc "Explain this Ruby pattern"  # Uses cc alias -> claude:sonnet
ace-llm claude:opus "Explain this Ruby pattern"
ace-llm claude:sonnet "Generate a test for this code" --output test.rb
ace-llm claude:haiku "Quick refactor suggestion"

# Codex examples
ace-llm codex:gpt-5 "Review this code for best practices"
ace-llm codex:mini "Generate documentation"

# OpenCode examples
ace-llm opencode "Generate unit tests" --output tests.rb
ace-llm opencode:google/gemini-2.5-flash "Analyze this architecture"

# Codex OSS examples
ace-llm codexoss "Suggest improvements"
```

### All Standard Options Work

```bash
# Output to file
ace-llm claude:opus "Generate README" --output README.md

# Different formats
ace-llm claude:sonnet "Explain" --format json
ace-llm claude:sonnet "Explain" --format markdown

# Temperature control
ace-llm codex:gpt-5 "Creative writing" --temperature 0.9

# Token limits
ace-llm opencode "Summary" --max-tokens 500

# System prompts
ace-llm claude:opus "Review" --system "You are a code reviewer"

# Timeout control
ace-llm codexoss "Complex analysis" --timeout 180
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

✅ Claude Code     (claude)
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

### Claude Code (claude)
- **Models**: claude-opus-4-1, claude-sonnet-4-0, claude-3-5-haiku-latest
- **Default**: claude-sonnet-4-0
- **Context**: 200,000 tokens
- **Aliases**: cc (maps to claude:sonnet), claude-code, cc-opus, cc-sonnet, cc-haiku

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

After checking out the repo, run `bin/setup` to install dependencies.

To test with a local ace-llm:

```ruby
# In Gemfile
gem "ace-llm", path: "../ace-llm"
```

## Testing

Run the test suite:

```bash
ace-test ace-llm-providers-cli
```

Run markdown lint checks:

```bash
ace-lint ace-llm-providers-cli/README.md
```

## Contributing

1. Create or confirm a task specification before implementation.
2. Make focused changes that follow existing package conventions.
3. Run verification commands (`ace-test`, `ace-lint`) before committing.
4. Create scoped commits with `ace-git-commit`.
5. Open a pull request with task context and verification evidence.

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
ace-llm cc:opus "large prompt" --timeout 300
```

Or set it in code:
```ruby
client = Ace::LLM::Providers::CLI::ClaudeCodeClient.new(timeout: 300)
```

## Part of ACE

Part of [ACE](../README.md) - Modular CLI toolkit for AI-assisted development.

## License

MIT License - see LICENSE file for details.
