---
update:
  update_frequency: weekly
  max_lines: 200
  required_sections:
  - overview
  - scope
  frequency: weekly
  last-updated: '2025-12-28'
---

# ACE Gem Development Guide

Quick reference based on production patterns from ace-lint, ace-docs, ace-taskflow, ace-search.

## Gem Naming Conventions

ACE gems follow a strict naming pattern to clarify their purpose:

### ace-* Pattern (Functional Gems with CLI Tools)
- **Purpose**: Provide direct functionality to users through CLI commands
- **Examples**: ace-search, ace-lint, ace-docs, ace-taskflow, ace-review, ace-prompt
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

### ace-integration-* Pattern (Integration Package Gems)
- **Purpose**: Bundle workflows, templates, and assets for integrating with external tools/platforms
- **Examples**: ace-integration-claude (Claude Code integration)
- **Characteristics**:
  - No CLI executables (`spec.executables = []`)
  - Integration assets in `integrations/` top-level directory
  - Workflows accessible via `wfi://` protocol through ace-nav
  - Templates, documentation, and custom commands bundled with gem
  - Pure workflow packages with asset packaging

## Standard Structure

### Standard ACE Gem (CLI Tools)
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

### Integration Package Gem (ace-integration-* pattern)
```
ace-integration-platform/
├── .ace.example/nav/protocols/wfi-sources/ace-integration-platform.yml  # ace-nav discovery
├── lib/ace/integration/platform.rb     # Gem entry point
├── lib/ace/integration/platform/version.rb  # Version constant
├── handbook/workflow-instructions/    # Integration workflows
│   └── update-integration-platform.wf.md
├── integrations/platform/             # Integration assets (OFFICIAL PATTERN)
│   ├── templates/                    # Command and agent templates
│   ├── commands/_custom/             # Custom command definitions
│   ├── README.md                     # Integration documentation
│   ├── metadata-field-reference.md  # Configuration reference
│   └── install-prompts.md           # Installation guide
├── README.md                         # This file
├── CHANGELOG.md                      # Version history
├── ace-integration-platform.gemspec  # Gem specification
└── Rakefile                          # Gem tasks
```

## Configuration

**ADR-022 Pattern: Load Gem Defaults + Merge User Overrides**

All ACE gems must follow the unified configuration pattern established in ADR-022. This pattern ensures:
- Defaults are loaded from `.ace.example/` (single source of truth)
- User overrides are merged via `Ace::Core::Atoms::DeepMerger`
- Test isolation via `reset_config!` method

### Implementation Pattern

```ruby
# lib/ace/gem.rb
require "yaml"
require "ace/core/atoms/deep_merger"

module Ace
  module Gem
    def self.config
      @config ||= begin
        defaults = load_gem_defaults
        user_config = Ace::Core.config.get("ace", "gem") || {}
        Ace::Core::Atoms::DeepMerger.merge(defaults, user_config)
      end
    end

    def self.load_gem_defaults
      gem_root = ::Gem.loaded_specs["ace-gem"]&.gem_dir ||
                 File.expand_path("../..", __dir__)
      defaults_path = File.join(gem_root, ".ace.example", "gem", "config.yml")

      # .ace.example/ MUST be included in gem - missing file is a packaging error
      unless File.exist?(defaults_path)
        raise "Default config not found: #{defaults_path}. " \
              "This is a gem packaging error - .ace.example/ must be included in the gem."
      end

      YAML.safe_load_file(defaults_path, permitted_classes: [], aliases: true) || {}
    end
    private_class_method :load_gem_defaults

    def self.reset_config!
      @config = nil
    end
  end
end
```

### Multi-Tool Configuration

For gems with multiple tools (like ace-lint):

```ruby
# .ace/lint/config.yml (nested) + .ace/lint/kramdown.yml (flat)
Ace::Core.config.get('ace', 'lint')              # General settings
Ace::Core.config.get('ace', 'lint', 'kramdown')  # Tool-specific
```

### Anti-Patterns

**DO NOT:**

```ruby
# Hardcoded defaults (BAD)
DEFAULT_CONFIG = {
  "root" => ".ace-taskflow",
  "directories" => { "completed" => "_archive" }
}.freeze

def self.config
  @config ||= DEFAULT_CONFIG.merge(user_config)  # Wrong!
end
```

**DO:**

```ruby
# Load from .ace.example/ (GOOD)
def self.config
  @config ||= Ace::Core::Atoms::DeepMerger.merge(
    load_gem_defaults,  # From .ace.example/gem/config.yml
    user_config         # From .ace/gem/config.yml cascade
  )
end
```

Note: Module name remains `Ace::Core` even though gem is `ace-support-core`.

## Prompt Caching Pattern

For gems that generate prompts for LLM interactions (like ace-review, ace-docs), use the standardized PromptCacheManager from ace-support-core.

### Standard Structure

```
.cache/
└── {gem-name}/
    └── sessions/
        └── {operation}-{timestamp}/
            ├── system.prompt.md    # System prompt
            ├── user.prompt.md      # User prompt
            └── metadata.yml        # Session metadata (optional)
```

### Usage

```ruby
require 'ace/core/molecules/prompt_cache_manager'

# Create session directory
session_dir = Ace::Core::Molecules::PromptCacheManager.create_session(
  "ace-my-gem",
  "my-operation"
)
# Returns: .cache/ace-my-gem/sessions/my-operation-20251116-143022/

# Save prompts
Ace::Core::Molecules::PromptCacheManager.save_system_prompt(
  system_prompt_content,
  session_dir
)

Ace::Core::Molecules::PromptCacheManager.save_user_prompt(
  user_prompt_content,
  session_dir
)

# Save metadata (optional)
metadata = {
  "timestamp" => Time.now.utc.iso8601,
  "gem" => "ace-my-gem",
  "operation" => "my-operation",
  "model" => "google:gemini-2.5-flash",
  "prompt_sizes" => { "system" => 1234, "user" => 5678 }
}
Ace::Core::Molecules::PromptCacheManager.save_metadata(metadata, session_dir)
```

### Benefits

* **Consistent locations**: All prompt caches in predictable `.cache/{gem}/sessions/` structure
* **Standard naming**: `system.prompt.md`, `user.prompt.md` across all gems
* **Git worktree support**: Uses ProjectRootFinder internally
* **Easy debugging**: Inspect exact prompts sent to LLMs
* **Metadata tracking**: Optional standardized metadata format

### Examples

* **ace-docs**: Uses PromptCacheManager for analyze-consistency operation
* **ace-prompt**: Uses caching for enhanced prompts with content-based deduplication
* **ace-review**: Already follows standard (migrating to use shared utility is optional)

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
- **Integration packages**: Use `integrations/` directory for integration assets (official pattern)
- **Integration packages**: Include ace-nav protocol registration for workflow discovery
- **Integration packages**: Bundle templates, documentation, and custom commands with workflows

❌ **DON'T**:
- Hardcode config paths or create custom ConfigLoader
- Use nested test structure
- Skip example configs or CHANGELOG updates

## Examples

**ace-lint**: Config patterns (flat+nested), complete structure
**ace-docs**: Handbook integration, usage.md
**ace-taskflow**: Comprehensive agents+workflows
**ace-search**: Clean agents, separation
**ace-integration-claude**: Reference implementation for integration packages (integrations/ pattern)

*See existing ace-* gems for implementations.*
