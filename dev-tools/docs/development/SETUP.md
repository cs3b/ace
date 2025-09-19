# Development Setup Guide

This guide will help you set up a complete development environment for Coding Agent Tools from scratch.

## Prerequisites

Before you begin, ensure you have the following installed on your system:

### Required
- **Ruby 3.4.2**
- **Git** (version 2.0+)
- **Bundler** gem

### Optional
- **LM Studio** (for offline LLM functionality)
- **GitHub CLI** (`gh`) for enhanced GitHub integration

## System-Specific Setup

### macOS

```bash
# Install Ruby via Homebrew (recommended)
brew install ruby

# Or use rbenv for version management
brew install rbenv
rbenv install 3.4.2
rbenv global 3.4.2

# Install Bundler
gem install bundler
```

### Ubuntu/Debian

```bash
# Install Ruby and development dependencies
sudo apt update
sudo apt install ruby-full ruby-bundler build-essential git

# Verify installation
ruby --version
bundler --version
```

### Windows

```bash
# Use RubyInstaller
# Download from: https://rubyinstaller.org/
# Install Ruby+Devkit version

# Verify installation in Command Prompt or PowerShell
ruby --version
bundler --version
```

## Project Setup

### 1. Clone the Repository

```bash
# Clone your fork (replace with your username)
git clone https://github.com/cs3b/coding-agent-tools.git
cd coding-agent-tools

# Or clone the main repository
git clone https://github.com/cs3b/coding-agent-tools.git
cd coding-agent-tools
```

### 2. Automated Setup

The project includes an automated setup script that handles all dependencies:

```bash
# Run the setup script
bin/setup
```

This script will:
- Install all Ruby gem dependencies via Bundler
- Set up development tools and configurations
- Verify the installation
- Create necessary local configuration files

### 3. Manual Setup (Alternative)

If you prefer manual setup or the automated script fails:

```bash
# Install dependencies
bundle install

# Verify installation
bundle exec ruby --version
```

## Verification

After setup, verify everything is working correctly:

### 1. Run Tests

```bash
# Run the full test suite
bin/test

# Expected output: All tests should pass
# Example output:
# Finished in 2.34 seconds (files took 0.5 seconds to load)
# 42 examples, 0 failures
```

### 2. Run Linter

```bash
# Check code style
bin/lint

# Expected output: No offenses detected
# If there are style issues, they will be listed
```

### 3. Build Gem

```bash
# Build the gem locally
bin/build

# Expected output: Successfully built RubyGem
# Creates: coding_agent_tools-X.X.X.gem
```

### 4. Interactive Console

```bash
# Start the development console
bin/console

# This opens an IRB session with the gem loaded
# You can test classes and methods interactively
```

## Configuration

### 1. Git Configuration

Set up Git commit message template:

```bash
# Configure commit template
git config commit.template .gitmessage

# Verify configuration
git config --list | grep commit.template
```

### 2. API Keys (Optional)

For full functionality, especially for features interacting with external APIs, configure your API keys using the provided example environment files.

1.  **Copy the example environment files**:
    ```bash
    cp .env.example .env
    cp spec/.env.example spec/.env
    ```

2.  **Edit the `.env` and `spec/.env` files**:
    - Open `.env` and `spec/.env` in your editor.
    - Add your actual `GEMINI_API_KEY` to both files.
    - The `spec/.env` file is specifically for testing and VCR recording. When you need to record new VCR cassettes for API integration tests, you will set `VCR_RECORD=true` in this file.

    Example `.env` (development settings):
    ```
    # .env
    GEMINI_API_KEY="your_actual_gemini_api_key_here"
    GITHUB_TOKEN="your_actual_github_token_here"
    ```

    Example `spec/.env` (testing settings for VCR):
    ```
    # spec/.env
    GEMINI_API_KEY="your_actual_gemini_api_key_here"
    VCR_RECORD=false # Set to true when recording new cassettes
    ```

3.  **Obtaining API Keys**:
    - **Google Gemini API Key**: Get this from [Google AI Studio](https://makersuite.google.com/app/apikey).
    - **GitHub Token** (if needed): Generate from [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens).

### 3. Cache Directory Configuration

The Coding Agent Tools gem uses XDG Base Directory Specification compliant cache storage for model lists, pricing data, and usage reports.

#### Default Cache Location

By default, cache files are stored in:
- **Linux/macOS**: `~/.cache/coding-agent-tools/`
- **Windows**: `%LOCALAPPDATA%\coding-agent-tools\cache\` (or `~/.cache/coding-agent-tools/`)

#### Environment Variable Configuration

You can customize the cache location using standard XDG environment variables:

**`XDG_CACHE_HOME`** (Primary):
```bash
# Set custom cache directory
export XDG_CACHE_HOME="/custom/cache/location"
# Cache will be stored at: /custom/cache/location/coding-agent-tools/
```

**`HOME`** (Fallback):
```bash
# If XDG_CACHE_HOME is not set, uses $HOME/.cache/
export HOME="/custom/home"
# Cache will be stored at: /custom/home/.cache/coding-agent-tools/
```

#### Cache Structure

The cache directory is organized by type:
```
~/.cache/coding-agent-tools/
├── models/           # Model information and lists
├── http/             # HTTP response caches
├── temp/             # Temporary files
└── pricing/          # LiteLLM pricing data
```

#### Configuration Examples

**Development Environment**:
```bash
# Keep cache in project directory for development
export XDG_CACHE_HOME="$(pwd)/.cache"
llm-models google  # Creates .cache/coding-agent-tools/models/
```

**CI/CD Environment**:
```bash
# Use temporary cache directory
export XDG_CACHE_HOME="/tmp/ci-cache"
# Cache will be at: /tmp/ci-cache/coding-agent-tools/
```

**Docker Container**:
```bash
# Mount cache volume and set environment
docker run -v /host/cache:/cache -e XDG_CACHE_HOME=/cache your-app
```

#### Cache Migration

If you have an existing cache in the legacy location (`~/.coding-agent-tools-cache`), it will be automatically migrated to the new XDG-compliant location on first use. See the [Migration Guide](./MIGRATION.md#cache-directory-location-change-v020) for details.

#### Cache Management

**View Cache Status**:
```bash
# Check cache contents
ls -la ~/.cache/coding-agent-tools/

# Check cache sizes
du -sh ~/.cache/coding-agent-tools/
```

**Clear Cache** (if needed):
```bash
# Remove all cached data
rm -rf ~/.cache/coding-agent-tools/

# Or remove specific cache types
rm -rf ~/.cache/coding-agent-tools/models/
```

### 4. LM Studio (Optional)

For offline LLM functionality:

1. Download and install LM Studio from https://lmstudio.ai/
2. Start LM Studio and load a compatible model
3. Ensure LM Studio is running on `localhost:1234` for offline LLM queries. **No API credentials required for default localhost usage.**

> **Note**: Unlike cloud-based LLM services, LM Studio running locally does not require any API keys or authentication when using the default localhost configuration.

## Development Tools

The project includes 25+ CLI tools for development automation, LLM integration, and workflow management. To see all available tools with descriptions:

```bash
# List all available tools with descriptions and categories
coding_agent_tools all

# Get help for specific commands
<command> --help
```

For detailed documentation, see [Tools Reference](docs/tools.md).

## IDE/Editor Setup

### VS Code

Recommended extensions:
- Ruby LSP
- StandardRB (Ruby formatter)
- GitLens
- Markdown All in One

Example `.vscode/settings.json`:
```json
{
  "ruby.useLanguageServer": true,
  "ruby.lint": {
    "standardrb": true
  },
  "ruby.format": "standardrb",
  "[ruby]": {
    "editor.defaultFormatter": "shopify.ruby-lsp",
    "editor.formatOnSave": true
  }
}
```

### RubyMine/IntelliJ

1. Install Ruby plugin
2. Configure StandardRB as the formatter
3. Enable "Format on save"
4. Set up Git integration

## Common Issues and Solutions

### Bundle Install Fails

```bash
# Clear Bundler cache
bundle clean --force

# Reinstall dependencies
rm Gemfile.lock
bundle install
```

### Permission Issues (macOS/Linux)

```bash
# If gem installation fails due to permissions
sudo gem install bundler

# Or use user-local installation
gem install --user-install bundler
```

### Ruby Version Issues

```bash
# Check current Ruby version
ruby --version

# If using rbenv, ensure correct version
rbenv versions
rbenv local 3.4.2
```

### Git Configuration Issues

```bash
# If commit template isn't working
git config --local commit.template .gitmessage

# Verify Git is properly configured
git config --list --local
```

## Testing Your Setup

Create a simple test to verify everything works:

```bash
# Create a test file
cat > test_setup.rb << 'EOF'
#!/usr/bin/env ruby

require_relative 'lib/coding_agent_tools'

puts "Ruby version: #{RUBY_VERSION}"
puts "Gem loaded successfully: #{defined?(CodingAgentTools) ? 'Yes' : 'No'}"
puts "Setup complete! 🎉"
EOF

# Run the test
ruby test_setup.rb

# Clean up
rm test_setup.rb
```

## Next Steps

Once your development environment is set up:

1. **Read the [Development Guide](DEVELOPMENT.md)** to understand the workflow
2. **Check [CONTRIBUTING.md](../.github/CONTRIBUTING.md)** for contribution guidelines
3. **Explore the codebase** structure in `lib/coding_agent_tools/`
4. **Run existing tests** to understand the current functionality
5. **Look for issues** labeled "good first issue" to start contributing

## Getting Help

If you encounter issues during setup:

1. **Check existing issues** on GitHub
2. **Review the troubleshooting section** above
3. **Create a new issue** with:
   - Your operating system and version
   - Ruby version (`ruby --version`)
   - Complete error messages
   - Steps you've already tried

## Quick Reference

```bash
# Complete setup workflow
git clone https://github.com/YOUR_USERNAME/coding-agent-tools.git
cd coding-agent-tools
bin/setup
bin/test
bin/lint

# Daily development workflow
git checkout -b feature/my-feature
# ... make changes ...
bin/test && bin/lint
git commit
git push origin feature/my-feature
```

Happy coding! 🚀
