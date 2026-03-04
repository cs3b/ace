---
update:
  update_frequency: weekly
  max_lines: 250
  required_sections:
  - overview
  - scope
  frequency: weekly
  last-updated: '2026-02-23'
---

# ACE Gem Development Guide

## Overview

Quick reference for ace-* gem development patterns covering CLI framework, configuration, testing, and handbook integration.

## Scope

This guide covers patterns for developing ace-* gems: CLI setup with dry-cli, configuration cascade (ADR-022), ATOM architecture, handbook integration, and testing conventions.

## CLI Framework

All CLI gems use dry-cli ([ADR-023](decisions/ADR-023-dry-cli-framework.md)):

- **CLI Base Module**: `Ace::Core::CLI::DryCli::Base` provides helper methods
- **Two Patterns**: Multi-command (Registry) or single-command (direct class)
- **Help Command**: Use `Ace::Core::CLI::DryCli::HelpCommand.build()` for multi-command CLIs
- **Exit Codes**: Commands raise `Ace::Core::CLI::Error`, exe/ handles exit
- **Reserved Flags**: `-v`=verbose, `-q`=quiet, `-d`=debug, `-h`=help, `-o`=output
- **Version Command**: Use `Ace::Core::CLI::DryCli::VersionCommand.build()`

See [cli-dry-cli.g.md](../ace-handbook/handbook/guides/cli-dry-cli.g.md) for complete patterns.

## Gem Naming Conventions

| Pattern | Purpose | Examples |
|---------|---------|----------|
| `ace-*` | Ready-to-use CLI tools | ace-search, ace-lint, ace-docs |
| `ace-support-*` | Shared infrastructure | ace-support-core, ace-support-config |
| `ace-llm-providers-*` | LLM provider extensions | ace-llm-providers-cli |
| `ace-integration-*` | Integration packages | ace-integration-claude |

**ace-support-* naming rules**:
- Module namespace: `Ace::Support::*` (e.g., `Ace::Support::Nav`)
- Binary name: `ace-<name>` (drop `ace-support-` prefix)
- Config folder: `.ace/<name>/` (not `.ace/support-<name>/`)
- Cache directory: `.ace-local/ace-<name>` (use binary name)

## Standard Structure

### CLI Tool Gem
```
ace-gem/
├── .ace-defaults/gem/config.yml    # REQUIRED
├── lib/ace/gem/
│   ├── atoms/, molecules/, organisms/, models/  # ATOM architecture
│   ├── cli/commands/              # dry-cli command classes
│   └── cli.rb, version.rb
├── test/                          # FLAT: atoms/, molecules/, etc.
├── handbook/
│   ├── agents/*.ag.md
│   └── workflow-instructions/*.wf.md
├── exe/ace-gem, CHANGELOG.md, README.md
└── ace-gem.gemspec
```

### Integration Package Gem
```
ace-integration-platform/
├── .ace-defaults/nav/protocols/wfi-sources/ace-integration-platform.yml
├── lib/ace/integration/platform.rb
├── handbook/workflow-instructions/
├── integrations/platform/         # Integration assets
│   ├── templates/, commands/_custom/
│   └── README.md
└── ace-integration-platform.gemspec
```

## Configuration

All gems follow [ADR-022](decisions/ADR-022-configuration-default-and-override-pattern.md):

```ruby
# lib/ace/gem.rb
require 'ace/support/config'

module Ace::Gem
  def self.config
    @config ||= begin
      defaults = load_gem_defaults
      user_config = Ace::Support::Config.create.resolve_namespace("gem").to_h
      Ace::Support::Config::Models::Config.wrap(defaults, user_config, source: "gem")
    end
  end

  def self.load_gem_defaults
    gem_root = ::Gem.loaded_specs["ace-gem"]&.gem_dir || File.expand_path("../..", __dir__)
    defaults_path = File.join(gem_root, ".ace-defaults", "gem", "config.yml")
    raise "Default config not found: #{defaults_path}" unless File.exist?(defaults_path)
    YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
  end
  private_class_method :load_gem_defaults

  def self.reset_config!
    @config = nil
  end
end
```

**Priority** (highest to lowest): CLI options > ENV > project `.ace/` > home `~/.ace/` > `.ace-defaults/`

## Prompt Caching

For LLM prompt generation, use PromptCacheManager. See [prompt-caching.g.md](../ace-handbook/handbook/guides/prompt-caching.g.md).

## Handbook

```
handbook/
├── agents/*.ag.md              # Composable, single-purpose
└── workflow-instructions/*.wf.md  # Complete per ADR-001
```

Symlink to `.claude/agents/` for Claude Code integration.

## CLI Commands

Use `CLI::Commands::` namespace (Hanami pattern):

```ruby
module Ace::Gem::CLI::Commands
  class Process < Dry::CLI::Command
    include Ace::Core::CLI::DryCli::Base
    desc "Process file"
    argument :file, required: false
    option :quiet, type: :boolean, aliases: %w[-q]

    def call(file: nil, **options)
      ProcessCommand.new(file, options).execute
    end
  end
end
```

**Standard options** (via `Ace::Core::CLI::DryCli::Base`):
- `--quiet/-q`: Suppress output
- `--verbose/-v`: Verbose output
- `--debug/-d`: Debug output
- `--version`: Show version
- `--help/-h`: Show help

**Exit codes**: Commands raise `Ace::Core::CLI::Error` for non-zero exit. Never call `exit` in commands.

See [cli-dry-cli.g.md](../ace-handbook/handbook/guides/cli-dry-cli.g.md) for multi-command and single-command CLI patterns.

## Mono-Repo Development

No per-gem Gemfile; use root Gemfile. See [mono-repo-patterns.g.md](../ace-handbook/handbook/guides/mono-repo-patterns.g.md).

## Best Practices

**DO:**
- Load defaults from `.ace-defaults/` (single source of truth)
- Use `Ace::Support::Config.create.resolve_namespace()` for config cascade
- Flat test structure: `test/atoms/` not `test/ace/gem/atoms/`
- Include `handbook/**/*` in spec.files for ALL gems
- Use exception-based exit codes (see ADR-023)
- Use `CLI::Commands::` namespace (Hanami pattern)
- Handle SIGINT and return exit code 130

**DON'T:**
- Hardcode default values in Ruby
- Include `Gemfile` in individual gems
- Use `-v` for version (reserved for verbose)
- Skip CHANGELOG updates
- Call `exit()` directly in command classes

## CLI Development Checklist

When developing CLI commands, verify these items before PR:

### Exit Code Handling
- [ ] Commands raise `Ace::Core::CLI::Error` for failures (not `return 1`)
- [ ] Exit codes documented in `docs/usage.md` or command help
- [ ] SIGINT handled with exit code 130 in exe wrapper
- [ ] Exit code semantics match documented behavior

### Error Messages
- [ ] Error messages are actionable (tell user what to do)
- [ ] Consistent prefix handling (messages via `Error#to_s` get "Error: " prefix)
- [ ] No duplicate "Error: " prefixes in output

### Input Validation
- [ ] Required arguments validated before processing
- [ ] Data file schemas validated (e.g., job.yaml required fields)
- [ ] Graceful handling of missing/malformed input files

### Resource Cleanup
- [ ] Temp files cleaned up on failure (atomic write patterns)
- [ ] Partial state cleaned up on interruption
- [ ] No orphan `.tmp.*` files on error paths

### Concurrency Safety
- [ ] File operations are atomic where needed
- [ ] No TOCTOU (time-of-check-time-of-use) race conditions
- [ ] Session/ID generation handles concurrent access

### Dependencies
- [ ] All required modules explicitly `require`d
- [ ] No reliance on load order for implicit requires
- [ ] `FileUtils` and other stdlib modules explicitly required

## Testing

```ruby
# Rakefile
require "bundler/gem_tasks"
require "rake/testtask"
Rake::TestTask.new(:test) { |t| t.libs << "test" << "lib"; t.test_files = FileList["test/**/*_test.rb"] }
task :spec => :test
task default: :test

# test/test_helper.rb
require 'ace/test_support'
require 'ace/gem'
class GemTestCase < AceTestCase; end
```

## E2E Testing

For end-to-end tests (agent-executed), use the TS-format (directory-based):

- **Location**: `{package}/test/e2e/TS-*/scenario.yml`
- **Format**: See [E2E Testing Guide](../ace-test-runner-e2e/handbook/guides/e2e-testing.g.md)
- **Examples**: `ace-git-commit/test/e2e/`, `ace-lint/test/e2e/`

E2E tests are for scenarios too slow/complex for unit tests, requiring real tool installations or full workflow validation.

## Documentation

- **README.md**: Overview, installation, quick start
- **CHANGELOG.md** (REQUIRED): Keep a Changelog format
- **docs/usage.md** (Optional): Comprehensive guide

## Gemspec

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

# Dependencies for CLI gems
spec.add_dependency "ace-support-core", "~> 0.10"
spec.add_dependency "ace-support-config", "~> 0.4"
spec.add_dependency "dry-cli", "~> 1.0"
```

## Examples

| Gem | Notable Pattern |
|-----|-----------------|
| ace-lint | Multi-tool config (flat+nested) |
| ace-docs | Handbook integration |
| ace-taskflow | Complete agents+workflows |
| ace-integration-claude | Integration package reference |

*See existing ace-* gems for implementations.*
