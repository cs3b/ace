# Coding Agent Tools (CAT) Ruby Gem

[![CI](https://github.com/cs3b/coding-agent-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/cs3b/coding-agent-tools/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/coding_agent_tools.svg)](https://badge.fury.io/rb/coding_agent_tools)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Ruby gem providing CLI tools designed for AI coding agents and developers to streamline development workflows through predictable, standardized commands.

> **⚠️ Breaking Changes in v0.2.0**: The LLM query commands have been unified and cache directory location has changed to XDG-compliant paths. If you're upgrading from v0.1.x, see the **[Migration Guide](docs/MIGRATION.md)** for instructions on updating your scripts and cache migration information.

## 🚀 Quick Start

### Installation

**1. Install as a published gem (once available):**

```bash
gem install coding_agent_tools
```

**2. Or, for local development/use from source:**

Add this line to your application's Gemfile if you are using it as a dependency from a local path (e.g., as a submodule or a local copy):

```ruby
gem 'coding_agent_tools', path: '.'
```

Then execute:

```bash
bundle install
```

After installation (either globally or via Bundler in a project), the `coding_agent_tools` command will be available.

## ✨ Key Features

- **LLM Integration**: Query multiple LLM providers using unified syntax
  - **Unified LLM Query**: Direct integration with multiple providers via `exe/llm-query provider:model`
- **Model Discovery**: List and filter available models from different providers
  - **Unified Model Discovery**: Discover available models via `exe/llm-models <provider>`
  - **Caching Support**: Model information is cached for faster response times
- **Cost Tracking**: Comprehensive cost analysis and usage reporting
  - **Automatic Cost Calculation**: Real-time cost tracking using LiteLLM pricing data
  - **Usage Reports**: Detailed breakdowns by provider, model, and time period via `exe/llm-usage-report`
  - **Multiple Export Formats**: JSON, CSV, and formatted table outputs
- **Enhanced Security**: Multi-layered security framework with comprehensive protections
  - **Path Validation**: Robust defense against directory traversal attacks and unauthorized access
  - **Interactive Confirmations**: Safe defaults with user prompts for file overwrites
  - **Credential Protection**: Automatic redaction of sensitive information from logs
  - **XDG Compliance**: Secure, standards-compliant file and cache management
- **Claude Code Integration**: Unified CLI for managing Claude Code commands and agents
  - **Command Generation**: Automatically create commands from workflow instructions
  - **Coverage Validation**: Ensure all workflows have corresponding commands
  - **Smart Organization**: Separate custom and generated commands
- **LM Studio Integration**: Direct integration with local LM Studio models
- **Git Automation**: Create repositories, generate commit messages with AI
- **Task Management**: Navigate documentation-based task backlogs
- **Context Tools**: Generate comprehensive project context documents
- **Offline Support**: Work with local language models via LM Studio

## 🛠 Core Commands (Planned Structure)

The primary executable for the gem is `coding_agent_tools`. Here's a look at the planned command structure (specific commands and options are illustrative and will be implemented in future tasks):

```bash
# General
coding_agent_tools --version
coding_agent_tools --help
coding_agent_tools help <command>

# LLM Communication
coding_agent_tools llm query --provider gemini --prompt "How to optimize Ruby performance?"
coding_agent_tools llm query --provider lm_studio --prompt "Explain SOLID principles"

# Source Control Management (SCM)
coding_agent_tools scm repository create --provider github my-new-repo
coding_agent_tools scm commit_with_message --intention "Refactor user authentication"
coding_agent_tools scm log --oneline

# Task Management
coding_agent_tools task next
coding_agent_tools task list --recent
coding_agent_tools task new_id

# Project Utilities
coding_agent_tools project release_context
# For development tasks related to the gem itself:
# coding_agent_tools project test (or bundle exec rspec)
# coding_agent_tools project lint (or bundle exec standardrb)
# coding_agent_tools project build_gem (or gem build coding_agent_tools.gemspec)
```

*Note: The existing `bin/*` scripts will be gradually replaced or wrapped by these new gem commands.*

## 🔧 Available Standalone Commands

### New Standalone Commands

- **`exe/llm-query`**: Query any supported LLM provider using unified syntax
  - Usage: `exe/llm-query provider:model "prompt or file path" [--output FILE] [--format json|markdown|text] [--temperature TEMP] [--max-tokens TOKENS] [--system "system prompt or file path"] [--force] [--debug]`
  - Examples:
    - `exe/llm-query google:gemini-2.5-flash "What is Ruby?"`
    - `exe/llm-query anthropic:claude-sonnet-4-20250514 prompt.txt --output response.json`
    - `exe/llm-query openai:gpt-4o "Question" --system system.md --output result.md`
    - `exe/llm-query lmstudio "Explain SOLID principles"`
    - `exe/llm-query gflash "Quick question"` (using alias for google:gemini-2.5-flash)
    - `exe/llm-query google "Overwrite example" --output existing.txt --force` (bypass confirmation)
  - Supports: Google Gemini, Anthropic Claude, OpenAI GPT, Mistral, Together AI, LM Studio
  - Provider aliases: `gflash`, `csonet`, `o4mini` and more
  - Requires: API keys for respective providers (see Setup Guide)
  - **File Operations**: When using `--output`, if the target file exists, you'll be prompted for confirmation unless `--force` (or `-f`) is specified. In non-interactive environments (CI/automation), use `--force` to bypass prompts.

- **`exe/llm-models`**: List available AI models from various providers
  - Usage: `exe/llm-models [PROVIDER] [--filter FILTER] [--format json] [--refresh]`
  - Examples:
    - `exe/llm-models google --filter "gemini-pro"`
    - `exe/llm-models lmstudio --filter "mistral"`
    - `exe/llm-models google --refresh` (refresh cache)
  - **New Output Fields**: Now includes `Context Size` and `Max Output` token limits for better model selection
  - **Sample Output**:

    ```
    Available LM Studio Models:
    ==================================================

    ID: mistralai/devstral-small-2505
    Name: Devstral Small
    Description: Specialized coding model, optimized for development tasks
    Context Size: 32.8K tokens
    Max Output: 16.4K tokens
    Status: Default model
    ```

  - Providers: `google` (default), `lmstudio`
  - Requires: `GOOGLE_API_KEY` for Google, LM Studio running on localhost:1234 for LMStudio

- **`exe/llm-usage-report`**: Generate comprehensive cost and usage reports
  - Usage: `exe/llm-usage-report [--format json|csv|table] [--date-range today|week|month|YYYY-MM-DD:YYYY-MM-DD] [--provider PROVIDER] [--model MODEL] [--output FILE] [--debug]`
  - Examples:
    - `exe/llm-usage-report` (basic table format)
    - `exe/llm-usage-report --format json --output monthly-report.json`
    - `exe/llm-usage-report --date-range week --provider google`
    - `exe/llm-usage-report --model claude-3-5-sonnet --format csv`
    - `exe/llm-usage-report --date-range 2024-01-01:2024-01-31`
  - Features: Automatic cost calculation using LiteLLM pricing data, provider/model filtering, multiple export formats
  - See: [Cost Tracking Guide](./docs/llm-integration/cost-tracking.md) for detailed usage

## 🛡️ File Operations & Security

### Interactive Overwrite Confirmation

When using the `--output` flag with `exe/llm-query`, the tool includes built-in security features for file operations:

**Interactive Mode** (terminals):

- If the output file already exists, you'll receive a confirmation prompt:

  ```
  File 'response.txt' already exists. Overwrite? [y/N]:
  ```

- Type `y` or `yes` to confirm overwrite, or `n`/`no` (or just press Enter) to cancel

**Non-Interactive Mode** (CI/automation):

- In CI environments or non-TTY contexts, overwrite attempts are automatically denied for safety
- Use the `--force` (or `-f`) flag to bypass confirmation prompts:

  ```bash
  exe/llm-query google "Question" --output response.txt --force
  ```

**Examples**:

```bash
# Interactive confirmation (will prompt if file exists)
exe/llm-query google "What is Ruby?" --output answer.txt

# Force overwrite without prompts (useful for scripts)
exe/llm-query google "What is Ruby?" --output answer.txt --force

# Alias for force flag
exe/llm-query google "What is Ruby?" --output answer.txt -f
```

This behavior ensures safe file operations while maintaining compatibility with automated workflows.

## 💰 Cost Tracking & Usage Analytics

All LLM queries automatically include cost tracking and usage analytics. Here's what you'll see:

**Basic Query with Cost Summary:**

```bash
$ exe/llm-query google:gemini-2.5-flash "What is Ruby programming?"

Ruby is a dynamic, object-oriented programming language...

Token Usage:
    Input:      234 tokens
   Output:      156 tokens

Cost Breakdown:
  Input cost:  $0.000292 (234 tokens × $0.00000125/token)
  Output cost: $0.000195 (156 tokens × $0.00000125/token)
  Total cost:  $0.000487
```

**Usage Report Generation:**

```bash
$ exe/llm-usage-report --date-range today

LLM Usage Report
================================================================================

Summary:
  Total Queries: 5
  Total Cost: $0.023847
  Total Tokens: 12,450
  Average Cost per Query: $0.004769

By Provider:
  Google: 3 queries, $0.012891
  Anthropic: 2 queries, $0.010956

Detailed Usage:
Timestamp           Provider     Model                   Input   Output   Cached       Cost     Time
--------------------------------------------------------------------------------
2024-01-15T10:30:45 google       gemini-2.5-flash          234      156        0 $0.000487    1.2s
2024-01-15T11:15:22 anthropic    claude-3-5-sonnet         892      445       50 $0.005234    2.8s
```

This helps you:

- **Monitor Costs**: Track spending across providers and models
- **Optimize Usage**: Compare model costs and performance
- **Budget Planning**: Generate reports for cost analysis
- **Token Efficiency**: Understand prompt and response sizes

## 🏗 Architecture

The gem's library code in `lib/coding_agent_tools/` is structured using an **ATOM-based hierarchy** (Atoms, Molecules, Organisms, Ecosystems), promoting modularity and reusability:

- **`lib/coding_agent_tools/atoms/`**: Smallest, indivisible utility functions or classes.
- **`lib/coding_agent_tools/molecules/`**: Simple compositions of Atoms forming reusable operations.
- **`lib/coding_agent_tools/organisms/`**: More complex units performing specific business logic or features.
- **`lib/coding_agent_tools/ecosystems/`**: The largest units, representing complete subsystems (the CLI app itself is an ecosystem).
- **`lib/coding_agent_tools/models/`**: Data structures (POROs) used across layers.
- **`lib/coding_agent_tools/cli/`**: Contains `dry-cli` command classes.
- **`lib/coding_agent_tools/cli.rb`**: Main `dry-cli` registry.

### Core Dependencies

- **Faraday**: HTTP client for API integrations (Google Gemini)
- **dry-cli**: Command-line interface framework

See the [Architecture Document](docs/architecture.md) for more details.

## 🔧 Configuration

For detailed instructions on configuring API keys (e.g., `GEMINI_API_KEY`) and setting up LM Studio, please refer to the [Setup Guide](docs/SETUP.md#api-keys-optional).

### LM Studio

Ensure LM Studio is running on `localhost:1234` for offline LLM queries. No API credentials required for default localhost usage.

## 📋 Requirements

- Ruby ≥ 3.4.2
- Git CLI
- Optional: LM Studio for offline LLM support

## 🎯 Use Cases

### For AI Agents

- Deterministic CLI interface for automation
- Reliable Git and task management operations
- Structured JSON output with `--json` flag

### For Developers

- Rapid repository setup and configuration
- AI-generated commit messages based on diffs
- Streamlined task navigation in documentation-driven workflows

## 🚧 Development Status

Currently in active development (v0.1.0 focusing on establishing the gem structure). See [roadmap](docs/roadmap.md) for planned releases.

## 💻 Development

For complete development information including environment setup, testing, build tools, and contribution workflow, see:

- **[Development Guide](docs/DEVELOPMENT.md)** - Complete development workflow and contributor quick start
- **[Setup Guide](docs/SETUP.md)** - Environment setup instructions
- **[Contributing](.github/CONTRIBUTING.md)** - Contribution guidelines and standards

## 📚 Documentation

### User Documentation

- **[Setup Guide](docs/SETUP.md)** - Development environment setup
- **[Development Guide](docs/DEVELOPMENT.md)** - Workflow and best practices
- **[Contributing](.github/CONTRIBUTING.md)** - How to contribute

### Project Documentation

- [Project Vision](docs/what-do-we-build.md) - Goals and use cases
- [Architecture](docs/architecture.md) - System design and patterns
- [Documentation Structure Guide](dev-handbook/guides/documentation.g.md) - Clarifies overall documentation organization and responsibilities

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](.github/CONTRIBUTING.md) for details on:

- Setting up your development environment
- Code style and quality standards
- Testing requirements and practices
- Pull request process and guidelines
- Commit message conventions

This project follows documentation-driven development with structured task management in `dev-taskflow/`. See the [project blueprint](docs/blueprint.md) for navigation guidance.

### Quick Contribution Workflow

1. Fork the repository and clone your fork
2. Set up development environment: `bin/setup`
3. Create a feature branch: `git checkout -b feature/name`
4. Make your changes following our standards
5. Test your changes: `bin/test && bin/lint`
6. Commit with conventional format and push
7. Open a pull request using our template

## 📄 License

[MIT License](LICENSE)
# Test fix
# Test correct behavior
