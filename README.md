# Coding Agent Tools (CAT) Ruby Gem

[![CI](https://github.com/cs3b/coding-agent-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/cs3b/coding-agent-tools/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/coding_agent_tools.svg)](https://badge.fury.io/rb/coding_agent_tools)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Ruby gem providing CLI tools designed for AI coding agents and developers to streamline development workflows through predictable, standardized commands.

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
Or, if you are working directly within this cloned repository:
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
  - Usage: `exe/llm-query provider:model "prompt or file path" [--output FILE] [--format json|markdown|text] [--temperature TEMP] [--max-tokens TOKENS] [--system "system prompt or file path"] [--debug]`
  - Examples: 
    - `exe/llm-query google:gemini-2.5-flash "What is Ruby?"`
    - `exe/llm-query anthropic:claude-4-0-sonnet-latest prompt.txt --output response.json`
    - `exe/llm-query openai:gpt-4o "Question" --system system.md --output result.md`
    - `exe/llm-query lmstudio "Explain SOLID principles"`
    - `exe/llm-query gflash "Quick question"` (using alias for google:gemini-2.5-flash)
  - Supports: Google Gemini, Anthropic Claude, OpenAI GPT, Mistral, Together AI, LM Studio
  - Provider aliases: `gflash`, `csonet`, `o4mini` and more
  - Requires: API keys for respective providers (see Setup Guide)

- **`exe/llm-models`**: List available AI models from various providers
  - Usage: `exe/llm-models [PROVIDER] [--filter FILTER] [--format json] [--refresh]`
  - Examples: 
    - `exe/llm-models google --filter "gemini-pro"`
    - `exe/llm-models lmstudio --filter "mistral"`
    - `exe/llm-models google --refresh` (refresh cache)
  - Providers: `google` (default), `lmstudio`
  - Requires: `GEMINI_API_KEY` for Google, LM Studio running on localhost:1234 for LMStudio

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
- [Documentation Structure Guide](docs-dev/guides/documentation.g.md) - Clarifies overall documentation organization and responsibilities

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](.github/CONTRIBUTING.md) for details on:

- Setting up your development environment
- Code style and quality standards
- Testing requirements and practices
- Pull request process and guidelines
- Commit message conventions

This project follows documentation-driven development with structured task management in `docs-project/`. See the [project blueprint](docs/blueprint.md) for navigation guidance.

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
