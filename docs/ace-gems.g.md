---
update:
  update_frequency: weekly
  max_lines: 250
  required_sections:
  - overview
  - scope
  frequency: weekly
  last-updated: '2026-01-19'
---

# ACE Gem Development Guide

Quick reference based on production patterns from ace-lint, ace-docs, ace-taskflow, ace-search.

## CLI Framework

All CLI gems use dry-cli (migration from Thor completed in Task 179, 2026-01):
- **CLI Base Module**: `Ace::Core::CLI::DryCli::Base` provides helper methods (quiet?, verbose?, debug?)
- **Registry Pattern**: Use `extend Dry::CLI::Registry` and register commands
- **CLI.start Method**: Implement testable `CLI.start(args)` with default command routing
- **Exit Codes**: Commands return status codes, exe/ handles exit (never call exit in commands)
- **Reserved Flags**: `-v` = verbose, `-q` = quiet, `-d` = debug, `-h` = help, `-o` = output
- **Version Command**: Use `Ace::Core::CLI::DryCli::VersionCommand.build()`
- **Type Conversion**: dry-cli returns strings; convert numeric options with `.to_i`

See `.ace-taskflow/v.0.9.0/tasks/179-task-migrate-cli/` for migration details.

## Gem Naming Conventions

ACE gems follow a naming pattern that clarifies their purpose:

### ace-* Pattern (Agentic Coding Tools)
- **Purpose**: Ready-to-use tools for AI-assisted development workflows
- **Examples**: ace-search, ace-lint, ace-docs, ace-taskflow, ace-review, ace-prompt, ace-llm, ace-test-e2e-runner
- **Characteristics**:
  - Complete, user-facing functionality
  - Have executables in `exe/` directory
  - Designed for direct use by developers and AI agents
  - Self-contained capabilities (may depend on ace-support-* gems)

### ace-support-* Pattern (Infrastructure Gems)
- **Purpose**: Shared infrastructure and utilities that support other gems
- **Examples**: ace-support-core, ace-support-config, ace-support-nav, ace-support-timestamp
- **Characteristics**:
  - Primarily used as dependencies by other ace-* gems
  - MAY have CLI executables if they provide user-facing tools (e.g., ace-nav, ace-timestamp)
  - Focus on reusable infrastructure, configuration, or utilities

**Naming Convention (Important)**:
- **Module namespace**: `Ace::Support::*` (e.g., `Ace::Support::Nav`, `Ace::Support::Config`)
- **Binary name**: `ace-<name>` (drop `ace-support-` prefix)
  - Example: `ace-support-nav` → `ace-nav` binary (NOT `ace-support-nav`)
- **Config folder**: `.ace/<name>/` (drop `ace-support-` prefix)
  - Example: `ace-support-nav` → `.ace/nav/` (NOT `.ace/support-nav/`)
- **Cache directory**: `.cache/ace-<name>` (use binary name, NOT gem name)
  - Example: `ace-support-nav` → `.cache/ace-nav/` (NOT `.cache/ace-support-nav/`)
  - **Rationale**: User-facing paths use binary name for consistency. Data/cache paths should remain stable even when internal gem structure changes.
- **Config namespace**: `<name>` (simple name, no "support" prefix)
  - Example: `ace-support-nav` uses namespace `nav` (not `support-nav`)
- **Rationale**: User configs, cache paths, and CLI commands remain compatible when gems are renamed (ace-nav → ace-support-nav). This separation ensures internal refactoring doesn't break user-facing conventions.

**Examples**:
```ruby
# ace-support-nav module structure
module Ace
  module Support
    module Nav
      # Implementation here
    end
  end
end

# Config resolution uses simple "nav" namespace
resolver = Ace::Support::Config.create
resolver.resolve_namespace("nav")  # NOT "support-nav"

# Binary is installed as "ace-nav" (not "ace-support-nav")
# $ ace-nav --help
```

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

### ace-test-e2e-runner (Infrastructure Package)

- **Purpose**: End-to-end test infrastructure for agent-executed testing
- **Characteristics**:
  - Workflow-first design (no CLI executable)
  - Test scenarios in `{package}/test/e2e/*.mt.md`
  - Executed via `/ace:run-e2e-test` skill
  - Provides templates and conventions for E2E testing

## Standard Structure

### Standard ACE Gem (CLI Tools)
```
ace-gem/
├── .ace-defaults/gem/config.yml    # REQUIRED
├── lib/ace/gem/
│   ├── atoms/, molecules/, organisms/, models/  # ATOM architecture
│   ├── cli/
│   │   └── commands/              # dry-cli command classes (Hanami pattern)
│   ├── cli.rb, version.rb
├── test/                          # FLAT: atoms/, molecules/, organisms/, models/
│   ├── cli/commands/, integration/, fixtures/
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
├── .ace-defaults/nav/protocols/wfi-sources/ace-integration-platform.yml  # ace-nav discovery
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
- Defaults are loaded from `.ace-defaults/` (single source of truth)
- User overrides are merged via ace-config's `Config.wrap()` or `DeepMerger`
- Test isolation via `reset_config!` method

### Implementation Pattern (using ace-config)

```ruby
# lib/ace/gem.rb
require 'ace/support/config'

module Ace
  module Gem
    def self.config
      @config ||= begin
        defaults = load_gem_defaults
        user_config = Ace::Support::Config.create
                        .resolve_namespace("gem")
                        .to_h
        Ace::Support::Config::Models::Config.wrap(defaults, user_config, source: "gem")
      end
    end

    def self.load_gem_defaults
      gem_root = ::Gem.loaded_specs["ace-gem"]&.gem_dir ||
                 File.expand_path("../..", __dir__)
      defaults_path = File.join(gem_root, ".ace-defaults", "gem", "config.yml")

      unless File.exist?(defaults_path)
        raise "Default config not found: #{defaults_path}. " \
              "This is a gem packaging error - .ace-defaults/ must be included in the gem."
      end

      YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
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
resolver = Ace::Support::Config.create
resolver.resolve_namespace("lint")                     # General settings
resolver.resolve_namespace("lint", filename: "kramdown")  # Tool-specific
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
# Load from .ace-defaults/ + use ace-config (GOOD)
def self.config
  @config ||= Ace::Support::Config::Models::Config.wrap(
    load_gem_defaults,  # From .ace-defaults/gem/config.yml
    user_config         # From .ace/gem/config.yml cascade via ace-config
  )
end
```

See [ace-config documentation](../ace-config/README.md) for complete API reference.

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

### Command Module Naming Convention (Hanami Pattern)

**REQUIRED**: Use `CLI::Commands::` module namespace (Hanami/dry-cli standard):

```ruby
# ✅ CORRECT - CLI::Commands:: pattern (Hanami standard)
module Ace::Gem
  module CLI
    module Commands
      class Process < Dry::CLI::Command
        # ...
      end
    end
  end
end

# ❌ WRONG - Commands:: pattern (inconsistent with Hanami)
module Ace::Gem::Commands
  class Process < Dry::CLI::Command
    # ...
  end
end
```

**Directory structure**: `lib/ace/gem/cli/commands/` (not `lib/ace/gem/commands/`)

This follows the Hanami CLI pattern (authoritative dry-cli source). The `CLI` module extends `Dry::CLI::Registry`, and individual command classes live in `CLI::Commands::` namespace under `cli/commands/` directory.

### dry-cli Pattern (Hanami Standard)

New and migrated gems use `dry-cli` with the `Ace::Core::CLI::DryCli::Base` module:

```ruby
# lib/ace/gem/cli.rb
require "dry/cli"
require "set"  # REQUIRED for KNOWN_COMMANDS pattern (Set.new)
require "ace/core"
require_relative "cli/commands/process"

module Ace::Gem
  module CLI
    extend Dry::CLI::Registry

    # Application commands registered in this CLI (single source of truth)
    REGISTERED_COMMANDS = %w[process].freeze

    # dry-cli built-in commands (standard across all CLI gems)
    BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

    # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
    # Using Set for O(1) lookup performance
    KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

    DEFAULT_COMMAND = "process"

    # Testable start method with default command routing
    def self.start(args)
      if args.empty? || !KNOWN_COMMANDS.include?(args.first)
        args = [DEFAULT_COMMAND] + args
      end
      Dry::CLI.new(self).call(arguments: args)
    end

    register "process", Commands::Process

    # Version command
    version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
      gem_name: "ace-gem",
      version: Ace::Gem::VERSION
    )
    register "version", version_cmd
    register "--version", version_cmd
  end
end

# lib/ace/gem/cli/commands/process.rb
module Ace::Gem
  module CLI
    module Commands
      class Process < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "Process file with auto-detection"

        argument :file, required: false, desc: "File to process"
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Debug output"

        def call(file: nil, **options)
          # Type conversion: dry-cli returns strings for numeric options
          # options[:limit] = options[:limit].to_i if options[:limit]

          ProcessCommand.new(file, options).execute
        end
      end
    end
  end
end

# exe/ace-gem
#!/usr/bin/env ruby
require_relative "../lib/ace/gem"
result = Ace::Gem::CLI.start(ARGV)
exit(result.is_a?(Integer) ? result : 0)
```

### dry-cli Migration Gotchas

1. **Type Conversion**: dry-cli returns strings for all options. Use the `convert_types` helper:
   ```ruby
   # Single option
   opts = convert_types(options, timeout: :integer)

   # Multiple options
   opts = convert_types(options, limit: :integer, ratio: :float)
   ```

2. **Default Task Routing**: Implement in `CLI.start` method, not as framework feature.

3. **KNOWN_COMMANDS Pattern**: Use the standardized three-constant pattern:
   ```ruby
   # Single source of truth for application commands
   REGISTERED_COMMANDS = %w[process].freeze

   # dry-cli built-ins (standard across all CLI gems)
   BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

   # Auto-derived - no manual maintenance needed
   KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze
   ```
   This ensures adding a new command only requires updating `REGISTERED_COMMANDS`.

   **Multi-command example** (e.g., ace-review):
   ```ruby
   # Single source of truth for application commands
   REGISTERED_COMMANDS = %w[review synthesize list-presets list-prompts].freeze

   # dry-cli built-ins (standard across all CLI gems)
   BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

   # Auto-derived - no manual maintenance needed
   KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze
   ```

4. **Help Documentation**: Use `desc` with heredoc and `example` array:
   ```ruby
   desc <<~DESC.strip
     Main description here.

     Additional context:
       - Point one
       - Point two
   DESC

   example ['pattern --flag', '"*.rb" -f']
   ```

5. **Boolean Options**: dry-cli generates `--[no-]flag` automatically.

### Standard Options

CLI commands include these standard options via `Ace::Core::CLI::DryCli::Base`:

| Option | Short | Description |
|--------|-------|-------------|
| `--quiet` | `-q` | Suppress config summary output |
| `--verbose` | `-v` | Enable verbose output |
| `--debug` | `-d` | Enable debug output |
| `--version` | | Show version (via `VersionCommand`) |
| `--help` | `-h` | Show help |

**Important**: `-v` is reserved for `--verbose`. Use `--version` for version output.

### ConfigSummary Output

Commands display effective configuration to stderr:

```ruby
Ace::Core::Atoms::ConfigSummary.display(
  command: "my_command",
  config: Gem.config,           # Effective config
  defaults: Gem.default_config, # Defaults for diffing
  options: options,             # dry-cli options hash
  quiet: options[:quiet],       # Suppress if --quiet
  summary_keys: %w[model preset] # Optional allowlist
)
# Output: "Config: model=gflash preset=pr"
```

Features:
- Only shows values that differ from defaults
- Filters sensitive keys (token, password, secret, key, api_key)
- Flattens nested config with dot notation
- Outputs to stderr (won't interfere with piping)

### Exit Code Handling

**CRITICAL**: Commands must return status codes, never call `exit`:

```ruby
# ❌ BAD - Terminates test process
def execute
  if invalid?
    puts "Error"
    exit 1  # Kills tests!
  end
end

# ✅ GOOD - Returns status code
def execute
  return 1 if invalid?
  0  # Success
end
```

The CLI entry point (exe/) handles exit:

```ruby
# exe/ace-gem
require 'ace/gem'
exit_code = Ace::Gem::CLI.start(ARGV)
exit(exit_code || 0)
```

### Reserved Short Flags

| Flag | Meaning | Notes |
|------|---------|-------|
| `-h` | help | dry-cli default |
| `-v` | verbose | NOT version |
| `-q` | quiet | Suppress config summary |
| `-d` | debug | Debug output |
| `-o` | output | Output destination |
| `-f` | Available | Package-specific |

### Default Command Routing

For single-purpose tools, implement default command routing via `CLI.start`:

```ruby
module CLI
  extend Dry::CLI::Registry

  REGISTERED_COMMANDS = %w[process].freeze
  BUILTIN_COMMANDS = %w[version help --help -h --version].freeze
  KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze
  DEFAULT_COMMAND = "process"

  def self.start(args)
    if args.empty? || !KNOWN_COMMANDS.include?(args.first)
      args = [DEFAULT_COMMAND] + args
    end
    Dry::CLI.new(self).call(arguments: args)
  end

  register "process", Commands::Process
end
```

This allows: `ace-gem file.txt` instead of `ace-gem process file.txt`

### Multi-Command CLIs

For tools with multiple subcommands (like ace-taskflow):

```ruby
module CLI
  extend Dry::CLI::Registry

  # Commands are registered hierarchically
  register "task show", Commands::TaskShow
  register "task list", Commands::TaskList
  register "tasks", Commands::Tasks  # Alias for task list

  # Use nested registration for subcommand groups
  register "worktree create", Commands::WorktreeCreate
  register "worktree delete", Commands::WorktreeDelete
end

# With nested directory structure for subcommands:
# lib/ace/gem/cli/commands/task/show.rb
module Ace::Gem
  module CLI
    module Commands
      module Task
        class Show < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base
          # ...
        end
      end
    end
  end
end
```

## Mono-Repo Dependency Management

### Gemfile vs Gemspec

**Key Principle**: Individual gems should NOT have their own `Gemfile`. The mono-repo uses a single root `Gemfile` for all development.

| File | Location | Purpose |
|------|----------|---------|
| `Gemfile` | Root only | Development dependencies for entire mono-repo |
| `*.gemspec` | Each gem | Runtime dependencies for gem distribution |

**Why no per-gem Gemfile?**
- All gems developed together in mono-repo context
- Root Gemfile includes all gems as path dependencies
- `ace-test` and binstubs use root Gemfile
- CI uses root Gemfile
- Simplifies dependency management and version consistency

### bin/ vs exe/ Distinction
- **bin/**: Mono-repo development binstubs for running executables without installation
- **exe/**: Gem distribution executables that get installed with the gem
- **Pattern**: bin/ wrappers use root Gemfile, exe/ uses gem's own gemspec dependencies

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

### Standard spec.files Pattern

All gemspecs must use this standardized pattern for file inclusion:

```ruby
spec.files = Dir.glob(%w[
  lib/**/*
  handbook/**/*
  exe/*
  .ace-defaults/**/*
  *.md
  LICENSE
  Rakefile
]).select { |f| File.file?(f) }
```

**Key requirements:**
- `handbook/**/*` must be included in ALL gems (even if empty today - for future AI integration)
- `lib/**/*` instead of `lib/**/*.rb` to include non-Ruby files
- `.select { |f| File.file?(f) }` to filter out directories
- `LICENSE` (not `LICENSE.txt`) for MIT license file

### Dependencies

```ruby
# For CLI gems with executables
spec.add_dependency "ace-support-core", "~> 0.10"  # CLI::Base, ConfigSummary
spec.add_dependency "ace-config", "~> 0.4"         # Configuration cascade
spec.add_dependency "thor", "~> 1.0"               # CLI framework

# For library gems (no CLI)
spec.add_dependency "ace-support-core", "~> 0.10"  # Only if needed
spec.add_dependency "ace-config", "~> 0.4"         # Only if needed

# Development
spec.add_development_dependency "ace-support-test-helpers", "~> 0.9"
```

## Essential Patterns

✅ **DO**:
- Use `Ace::Support::Config.create.resolve_namespace('gem')` for config cascade
- Use `Ace::Support::Config::Models::Config.wrap()` for merging defaults + overrides
- Include `handbook/**/*` in spec.files for ALL gems (required for AI-native architecture)
- Use standardized `Dir.glob(%w[...]).select { |f| File.file?(f) }` pattern for spec.files
- Flat test structure: `test/atoms/` not `test/ace/gem/atoms/`
- Provide .ace-defaults/ configs
- Maintain CHANGELOG.md in Keep a Changelog format
- Add ace-config dependency for configuration support
- Follow naming conventions: ace-* for CLI tools, ace-support-* for libraries
- **CLI gems**: Inherit from `Ace::Core::CLI::Base` for standard options
- **CLI gems**: Return status codes from commands, never call `exit`
- **CLI gems**: Use ConfigSummary.display() to show effective config
- **CLI gems**: Reserve `-v` for verbose, `--version` for version
- **CLI gems**: Use `CLI::Commands::` module namespace (Hanami pattern) for command classes
- **Integration packages**: Use `integrations/` directory for integration assets (official pattern)
- **Integration packages**: Include ace-nav protocol registration for workflow discovery
- **Integration packages**: Bundle templates, documentation, and custom commands with workflows

❌ **DON'T**:
- Include `Gemfile` in individual gems (use root Gemfile only)
- Hardcode config paths or create custom ConfigLoader
- Use nested test structure
- Skip example configs or CHANGELOG updates
- Use old-style `Dir[...]` or `Dir.glob("{lib,exe}/**/*") + %w[...]` patterns for spec.files
- Omit `handbook/**/*` from spec.files (violates AI-native architecture principle)
- **CLI gems**: Call `exit` in command methods (kills test processes)
- **CLI gems**: Use `-v` for version flag (reserved for verbose)
- **CLI gems**: Skip ConfigSummary display (users need to see effective config)
- **CLI gems**: Use `Commands::` module namespace (use `CLI::Commands::` instead - Hanami pattern)

## Examples

**ace-config**: Generic configuration cascade with customizable folder names (reference for new gems)
**ace-lint**: Config patterns (flat+nested), complete structure
**ace-docs**: Handbook integration, usage.md
**ace-taskflow**: Comprehensive agents+workflows
**ace-search**: Clean agents, separation
**ace-integration-claude**: Reference implementation for integration packages (integrations/ pattern)

*See existing ace-* gems for implementations.*
