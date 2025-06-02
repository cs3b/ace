# Coding Agent Tools (CAT) Ruby Gem

A Ruby gem providing CLI tools designed for AI coding agents and developers to streamline development workflows through predictable, standardized commands.

## 🚀 Quick Start

```bash
# Install the gem
gem install coding_agent_tools

# Or add to your Gemfile
gem 'coding_agent_tools'
```

## ✨ Key Features

- **LLM Integration**: Query Google Gemini and local LM Studio models
- **Git Automation**: Create repositories, generate commit messages with AI
- **Task Management**: Navigate documentation-based task backlogs
- **Context Tools**: Generate comprehensive project context documents
- **Offline Support**: Work with local language models via LM Studio

## 🛠 Core Commands

### LLM Communication
```bash
# Query Google Gemini
bin/llm-gemini-query --prompt "How to optimize Ruby performance?"

# Query local LM Studio
bin/lms-studio-query --prompt "Explain SOLID principles"
```

### Git Workflows
```bash
# Create GitHub repository and set as origin
bin/github-repository-create my-project

# Generate AI-powered commit messages
bin/git-commit-with-message --intention "refactor authentication"

# Git shortcuts
bin/gs          # git status (short format)
bin/gl          # git log (oneline format)
bin/gp          # git push
```

### Task Management
```bash
# Find next actionable task
bin/tn

# List recent tasks
bin/tr

# Get current release context
bin/rc
```

### Development Tools

```bash
# Run tests
bin/test

# Run linting
bin/lint

# Build gem
bin/build
```

## 🏗 Architecture

Built using the **ATOM pattern** (Action, Transformation, Operation, Model):

- **Actions** (`lib/coding_agent_tools/actions/`): CLI handlers
- **Transformations** (`lib/coding_agent_tools/transformations/`): Business logic
- **Operations** (`lib/coding_agent_tools/operations/`): External adapters
- **Models** (`lib/coding_agent_tools/models/`): Data structures

## 🔧 Configuration

### API Keys
```bash
# Google Gemini
export GEMINI_API_KEY="your-api-key"

# GitHub (for repository creation)
export GITHUB_TOKEN="your-token"
```

### LM Studio
Ensure LM Studio is running on `localhost:1234` for offline LLM queries.

## 📋 Requirements

- Ruby ≥ 3.2
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

Currently in active development. See [roadmap](docs-project/roadmap.md) for planned releases:

## 📚 Documentation

- [Architecture](docs-project/architecture.md) - System design and patterns
- [Project Vision](docs-project/what-do-we-build.md) - Goals and use cases
- [Development Guides](docs-dev/guides/) - Standards and best practices

## 🤝 Contributing

This project follows documentation-driven development with structured task management in `docs-project/`. See the [project blueprint](docs-project/blueprint.md) for navigation guidance.

## 📄 License

[MIT License](LICENSE.txt)
