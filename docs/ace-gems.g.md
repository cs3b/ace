---
update:
  update_frequency: weekly
  max_lines: 150
  required_sections:
  - overview
  - scope
  frequency: weekly
  last-updated: '2025-10-14'
---

# ACE Gem Development Guide

Quick reference based on production patterns from ace-lint, ace-docs, ace-taskflow, ace-search.

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

Use ace-core config cascade. **Never hardcode paths**.

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
spec.add_dependency "ace-core", "~> 0.9"
spec.add_development_dependency "ace-test-support", "~> 0.9"
```

## Essential Patterns

✅ **DO**:
- Use `Ace::Core.config.get('ace', 'gem')` for config
- Include handbook/ with agents and workflows
- Flat test structure: `test/atoms/` not `test/ace/gem/atoms/`
- Provide .ace.example/ configs
- Maintain CHANGELOG.md in Keep a Changelog format
- Add ace-core dependency

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
