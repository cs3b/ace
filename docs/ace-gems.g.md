---
update:
  update_frequency: weekly
  max_lines: 200
  required_sections:
  - overview
  - scope
  frequency: weekly
  last-updated: '2025-10-14'
---

# ACE Gem Development Guide

Quick reference based on production patterns from ace-lint, ace-docs, ace-taskflow, ace-search.

## Gem Naming Conventions

ACE gems follow a strict naming pattern to clarify their purpose:

### ace-* Pattern (Functional Gems with CLI Tools)
- **Purpose**: Provide direct functionality to users through CLI commands
- **Examples**: ace-search, ace-lint, ace-docs, ace-taskflow, ace-review
- **Characteristics**:
  - Have executables in `exe/` directory
  - Registered in gemspec: `spec.executables = ['ace-tool']`
  - User-facing functionality

### ace-support-* Pattern (Infrastructure Library Gems)
- **Purpose**: Provide shared infrastructure and utilities for other gems
- **Examples**: ace-support-core, ace-support-test-helpers, ace-support-markdown
- **Characteristics**:
  - No CLI executables (`spec.executables = []`)
  - Library-only functionality
  - Shared by multiple ace-* gems

### ace-llm-providers-* Pattern (Provider Extensions)
- **Purpose**: Extend ace-llm with specific provider implementations
- **Examples**: ace-llm-providers-cli, ace-llm-providers-openai (future)

## Standard Structure

```
ace-gem/
├── .ace.example/gem/config.yml    # REQUIRED
├── lib/ace/gem/
│   ├── atoms/, molecules/, organisms/, models/  # ATOM architecture
│   ├── commands/                  # Thor CLI commands
│   ├── cli.rb, version.rb
├── test/                          # FLAT: atoms/, molecules/, organisms/, models/
│   ├── commands/, integration/, fixtures/
│   └── test_helper.rb
├── handbook/                      # CRITICAL: AI integration
│   ├── agents/*.ag.md             # Single-purpose
│   └── workflow-instructions/*.wf.md  # Self-contained
├── docs/usage.md                  # Optional
├── exe/ace-gem, CHANGELOG.md, README.md, Rakefile
└── ace-gem.gemspec
```

## Configuration

Use ace-support-core config cascade. **Never hardcode paths**.

```ruby
# Single-purpose (flat): .ace/gem/config.yml
verbose: false

# lib/ace/gem.rb
def self.config
  @config ||= Ace::Core.config.get('ace', 'gem') || defaults
end

# Multi-tool: .ace/lint/config.yml (nested) + .ace/lint/kramdown.yml (flat)
Ace::Core.config.get('ace', 'lint')           # General
Ace::Core.config.get('ace', 'lint', 'kramdown')  # Tool-specific
```

Note: Module name remains `Ace::Core` even though gem is `ace-support-core`.

## Handbook

```
handbook/
├── agents/search.ag.md              # Composable, single-purpose
└── workflow-instructions/process.wf.md  # Complete per ADR-001
```

Symlink to `.claude/agents/` for Claude Code.

## CLI

```ruby
# lib/ace/gem/cli.rb
require 'thor'
module Ace::Gem
  class CLI < Thor
    desc "process FILE", "Process"
    option :verbose, type: :boolean
    def process(file)
      # Use config cascade
    end
  end
end

# exe/ace-gem
#!/usr/bin/env ruby
require 'ace/gem'
Ace::Gem::CLI.start(ARGV)
```

## Mono-Repo Binstubs (Development)

### bin/ vs exe/ Distinction
- **bin/**: Mono-repo development binstubs for running executables without installation
- **exe/**: Gem distribution executables that get installed with the gem
- **Pattern**: bin/ wrappers use root Gemfile, exe/ uses gem's own dependencies

### Mono-Repo Binstub Pattern
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

# Wrapper script to run ace-gem with proper bundler context
require "pathname"

# Find the ace-meta root directory
ace_meta_root = Pathname.new(__FILE__).dirname.parent.realpath

# Set the Gemfile location
ENV["BUNDLE_GEMFILE"] = ace_meta_root.join("Gemfile").to_s

# Load bundler
require "bundler/setup"

# Now require and run the actual ace-gem executable
load ace_meta_root.join("ace-gem/exe/ace-gem").to_s
```

### Development Workflow
```bash
# Run any ace gem directly without installation
./bin/ace-gem --help
./bin/ace-search --query "pattern"
./bin/ace-git-worktree --task 123

# All binstubs use root Gemfile for consistent environment
# No need to install gems locally during development
```

### Examples in Production
- **bin/ace-docs**: Wraps ace-docs/exe/ace-docs
- **bin/ace-search**: Wraps ace-search/exe/ace-search
- **bin/ace-lint**: Wraps ace-lint/exe/ace-lint
- **bin/ace-git-worktree**: Wraps ace-git-worktree/exe/ace-git-worktree

## Captured Feedback & Best Practices

### Context Awareness (Critical)
**Problem**: Agents don't always read roadmap/docs before drafting releases or solutions
**Solution**:
- Always read project roadmap, taskflow, and existing documentation first
- Check for existing patterns and solutions before creating new ones
- Understand project context and previous decisions

### Configuration Clarity
**Problem**: Users struggle with type definitions and sync behavior
**Solution**:
- Document configuration types clearly with examples
- Explain sync behavior and when it occurs
- Provide example configurations for common use cases
- Use validation with helpful error messages

### Git Integration Patterns
**Problem**: Handling renames, moves, whitespace, and diff filtering
**Solution**:
- Use git diff with proper filters for deterministic behavior
- Handle file renames and moves correctly
- Manage whitespace issues in text processing
- Prefer git diff over subagent file selection decisions

### Tool Delegation Principles
**Problem**: Unclear boundaries between tools
**Solution**:
- Delegate specialized work to appropriate tools (e.g., linting → lint tool)
- Avoid reimplementing functionality that exists in specialized tools
- Provide clear integration points between tools
- Document tool boundaries and responsibilities

### Development Environment Patterns
**Problem**: Inconsistent development setups across gems
**Solution**:
- Use mono-repo binstubs for consistent development environment
- Standardize on root Gemfile for dependency management
- Provide clear development documentation
- Include workspace awareness for git worktree development

## Testing

```ruby
# Rakefile
require "bundler/gem_tasks"
require "rake/testtask"
Rake::TestTask.new(:test) do |t|
  t.libs << "test" << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end
task :spec => :test
task default: :test

# test/test_helper.rb
require 'ace/test_support'
require 'ace/gem'
class GemTestCase < AceTestCase; end
```

## Documentation

**README.md**: Overview, installation, quick start, usage
**CHANGELOG.md** (REQUIRED): Keep a Changelog format, semantic versioning
**docs/usage.md** (Optional): Comprehensive guide

## Version

```ruby
# lib/ace/gem/version.rb
module Ace::Gem
  VERSION = "0.1.0"  # MAJOR.MINOR.PATCH
end
```

## Gemspec

```ruby
spec.add_dependency "ace-support-core", "~> 0.10"
spec.add_development_dependency "ace-support-test-helpers", "~> 0.9"
```

## Essential Patterns

✅ **DO**:
- Use `Ace::Core.config.get('ace', 'gem')` for config (module name unchanged)
- Include handbook/ with agents and workflows
- Flat test structure: `test/atoms/` not `test/ace/gem/atoms/`
- Provide .ace.example/ configs
- Maintain CHANGELOG.md in Keep a Changelog format
- Add ace-support-core dependency for configuration support
- Follow naming conventions: ace-* for CLI tools, ace-support-* for libraries

❌ **DON'T**:
- Hardcode config paths or create custom ConfigLoader
- Use nested test structure
- Skip example configs or CHANGELOG updates

## Examples

**ace-lint**: Config patterns (flat+nested), complete structure
**ace-docs**: Handbook integration, usage.md
**ace-taskflow**: Comprehensive agents+workflows
**ace-search**: Clean agents, separation

*See existing ace-* gems for implementations.*
