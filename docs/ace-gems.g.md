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
