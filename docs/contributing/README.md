# Contributing to ACE

## Development Setup

```bash
# Clone the repository
git clone https://github.com/cs3b/ace-meta.git
cd ace-meta

# Install dependencies
bundle install

# Run commands via mono-repo binstubs
./bin/ace-bundle project
./bin/ace-review --help
```

## Running Tests

```bash
# Test specific gem
cd ace-review && bundle exec rake test

# Test all gems
bundle exec ace-test-suite

# Run tests with profiling
ace-test --profile 10
```

## Project Structure

ACE is organized as a mono-repo where each gem is developed and versioned together:

```
ace-meta/
├── ace-*/                 # Individual gem packages
├── .ace/                  # Configuration cascade root
├── docs/                  # System documentation
└── Gemfile                # Shared dependencies
```

## Gem Development

See [docs/ace-gems.g.md](../ace-gems.g.md) for the complete guide on creating new ace-* gems.

Key patterns:
- **ATOM Architecture**: All gems follow Atoms/Molecules/Organisms/Models pattern
- **dry-cli**: CLI commands use dry-cli framework
- **Configuration cascade**: `.ace-defaults/` for gem defaults, `.ace/` for overrides
