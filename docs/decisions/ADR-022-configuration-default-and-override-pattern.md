# ADR-022: Configuration Default and Override Pattern

## Status

Accepted
Date: 2025-12-13
Supersedes: ADR-019-configuration-architecture

### Status Update (December 2025)

**Task 143 Implementation Complete**

Task 143 (Unified Configuration Loading and Merging Defaults Across ACE Packages) has been completed, migrating the following packages to the ADR-022 pattern:

- 143.01: ace-taskflow - Full ConfigLoader rewrite with `load_gem_defaults` + DeepMerger
- 143.02: ace-git-worktree - Uses ace-taskflow's ConfigLoader (no separate config)
- 143.03: ace-nav - Migrated to load defaults from `.ace-defaults/nav/config.yml`
- 143.04: ace-test-runner - Full ConfigLoader with gem defaults pattern
- 143.05: ace-git-commit, ace-docs, ace-lint, ace-prompt, ace-review, ace-search - All migrated

**Note on `.ace-defaults/` Rename**

ADR-022 originally proposed renaming `.ace.example/` to `.ace-defaults/`. This rename was **completed in Task 157.08** as part of the ace-config extraction work. All gems now use `.ace-defaults/` as the standard source location.

**ace-config Gem Extraction (Task 157)**

The configuration cascade functionality has been extracted into a standalone `ace-support-config` gem as part of Task 157. This provides:

- **Generic API**: `Ace::Support::Config.create()` with customizable folder names (`config_dir`, `defaults_dir`)
- **External Compatibility**: Projects outside the ACE ecosystem can use ace-config independently
- **Namespace Resolution**: New `resolve_namespace()` method for simplified config access
- **Config.wrap()**: Quick merge helper for common defaults + overrides pattern
- **Simplified Integration**: Gems use `Ace::Support::Config.create(gem_path: __dir__)` instead of manual loading

All ace-* gems now use ace-config for configuration cascade. See [docs/migrations/ace-config-migration.md](../migrations/ace-config-migration.md) for migration details.

## Context

ADR-019 established ace-support-core's configuration cascade for ACE gems but left ambiguity around:

1. **Where default configuration lives** - Some gems hardcode defaults in Ruby, others use `.ace-defaults/` files
2. **How defaults merge with user overrides** - Unclear priority and merge strategy
3. **Backward compatibility** - How to handle renamed config keys without breaking existing configs

Current problems in practice:
- ace-taskflow has defaults hardcoded in `ConfigLoader::DEFAULT_CONFIG` hash
- Defaults in code become stale and diverge from `.ace-defaults/` examples
- Users can't see complete default configuration without reading source code
- Config key renames (like `done` → `completed`) require code changes for backward compatibility

## Decision

All ace-* gems **must** follow a three-tier configuration pattern:

### 1. Default Configuration (in gem)

Location: `ace-gem/.ace-defaults/gem-name/config.yml`

This file contains:
- Complete configuration with all available options
- Sensible defaults for all values
- Comments explaining each option
- Is the single source of truth for defaults

```yaml
# ace-taskflow/.ace-defaults/taskflow/config.yml
taskflow:
  root: ".ace-taskflow"
  directories:
    completed: "_archive"    # Use semantic names
    backlog: "_backlog"
```

### 2. User Configuration (project or home)

Location: `.ace/gem-name/config.yml` (project) or `~/.ace/gem-name/config.yml` (home)

- Partial configuration - only overrides what differs from defaults
- Project config overrides home config
- Nearest wins (current dir → parent → home)

### 3. Loading Pattern

```ruby
module Ace
  module GemName
    class Configuration
      # Load default config from gem's .ace-defaults directory
      def self.default_config
        @default_config ||= load_gem_defaults
      end

      def self.load_gem_defaults
        gem_root = File.expand_path("../../..", __dir__)
        default_file = File.join(gem_root, ".ace-defaults", "gem-name", "config.yml")

        # .ace-defaults/ MUST be included in gem - missing file is a packaging error
        unless File.exist?(default_file)
          raise "Default config not found: #{default_file}. " \
                "This is a gem packaging error - .ace-defaults/ must be included in the gem."
        end

        YAML.load_file(default_file)&.dig("gem_name") || {}
      end

      # Full config = defaults + user overrides
      def self.config
        @config ||= deep_merge(default_config, user_config)
      end

      def self.user_config
        Ace::Core.config.get('ace', 'gem-name') || {}
      end
    end
  end
end
```

### 4. Backward Compatibility for Renamed Keys

When renaming config keys, support both old and new keys with deprecation:

```ruby
# Get directory name with backward compatibility
def done_dir
  # New key first, then old key, then default
  config.dig("directories", "completed") ||
    config.dig("directories", "done") ||
    "_archive"
end
```

Optionally log deprecation warnings:

```ruby
def done_dir
  if config.dig("directories", "done") && !config.dig("directories", "completed")
    warn "DEPRECATION: 'directories.done' is deprecated, use 'directories.completed'"
  end
  config.dig("directories", "completed") ||
    config.dig("directories", "done") ||
    "_archive"
end
```

### 5. Configuration Priority (highest to lowest)

1. CLI options (runtime)
2. Environment variables (where applicable)
3. Project config: `.ace/gem-name/config.yml` (nearest wins)
4. User config: `~/.ace/gem-name/config.yml`
5. Gem defaults: `ace-gem/.ace-defaults/gem-name/config.yml`

### Requirements Summary

**DO:**
- ✅ Put complete defaults in `.ace-defaults/gem-name/config.yml`
- ✅ Load defaults from `.ace-defaults/` at runtime (not hardcoded)
- ✅ Merge user config over defaults (deep merge)
- ✅ Support old config keys with deprecation path
- ✅ Document config options with comments in `.ace-defaults/`
- ✅ Provide `reset_config!` for testing
- ✅ Use semantic key names (`completed` not `done` for directories)
- ✅ Include `.ace-defaults/` in gemspec (MUST be packaged with gem)
- ✅ Raise error if `.ace-defaults/` config missing (packaging error, not fallback)

**DON'T:**
- ❌ Hardcode default values in Ruby (use `.ace-defaults/` instead)
- ❌ Break backward compatibility without deprecation path
- ❌ Require users to copy entire config file to override one value
- ❌ Use config keys that conflict with status values (e.g., `done` directory vs `done` status)
- ❌ Silently fallback if `.ace-defaults/` missing (this hides packaging errors)

## Consequences

### Positive

- **Single source of truth**: Defaults in `.ace-defaults/` are authoritative
- **Discoverability**: Users see all options by looking at `.ace-defaults/`
- **Minimal user config**: Only override what differs from defaults
- **Backward compatible**: Renamed keys still work with deprecation warnings
- **Testable**: `reset_config!` clears cached config for test isolation
- **No code changes for defaults**: Update `.ace-defaults/` to change defaults

### Negative

- **File I/O at startup**: Loading `.ace-defaults/` file adds minor startup cost
- **Migration effort**: Existing gems need refactoring to use this pattern
- **Gem packaging**: `.ace-defaults/` must be included in gem distribution (raises error if missing)

### Neutral

- **YAML-only**: Configuration must be YAML format
- **Convention over configuration**: Standard locations reduce flexibility

## Migration from ADR-019

Gems currently following ADR-019 should:

1. Move hardcoded defaults to `.ace-defaults/gem-name/config.yml`
2. Update config loading to read from `.ace-defaults/` first
3. Add backward compatibility for any renamed keys
4. Add deprecation warnings for old key names
5. Update documentation to reference `.ace-defaults/` as authoritative source

## Examples from Production

### ace-taskflow (Target State)

Default config:
```yaml
# ace-taskflow/.ace-defaults/taskflow/config.yml
taskflow:
  root: ".ace-taskflow"
  task_dir: "t"
  directories:
    completed: "_archive"     # Renamed from 'done' for clarity
    backlog: "_backlog"
    deferred: "_deferred"
    parked: "_parked"
  terminal_statuses:
    - done
    - cancelled
    - suspended
    - superseded
```

Loading:
```ruby
def done_dir
  config.dig("directories", "completed") ||
    config.dig("directories", "done") ||  # backward compat
    "_archive"
end
```

### ace-lint (Multi-Tool)

```yaml
# ace-lint/.ace-defaults/lint/config.yml
lint:
  enabled_linters:
    - markdown
    - yaml
  fail_fast: false
```

Tool-specific (flat):
```yaml
# ace-lint/.ace-defaults/lint/kramdown.yml
input: GFM
line_width: 120
```

## Related Decisions

- **ADR-019**: Configuration Architecture (superseded by this ADR)
- **ADR-015**: Mono-Repo Migration - ace-core provides config cascade
- **ADR-018**: Thor CLI Commands - commands use config with CLI overrides

## References

- **ace-config**: Standalone configuration cascade gem (extracted from ace-support-core)
- **ace-support-core**: Shared utilities and core functionality
- **docs/ace-gems.g.md**: Configuration patterns guide
- **docs/migrations/ace-config-migration.md**: Migration guide from ace-support-core patterns

## Compliance Status (December 2025)

### Compliant Packages

The following packages have been migrated to the ADR-022 pattern:

| Package | Subtask | Implementation |
|---------|---------|----------------|
| ace-taskflow | 143.01 | Full ConfigLoader with `load_gem_defaults` + DeepMerger |
| ace-git-worktree | 143.02 | Uses ace-taskflow's ConfigLoader |
| ace-nav | 143.03 | ConfigLoader with gem defaults pattern |
| ace-test-runner | 143.04 | ConfigLoader with gem defaults pattern |
| ace-git-commit | 143.05 | `load_gem_defaults` + DeepMerger in orchestrator |
| ace-docs | 143.05 | `load_gem_defaults` + DeepMerger in module |
| ace-lint | 143.05 | `load_gem_defaults` + DeepMerger in module |
| ace-prompt | 143.05 | `load_gem_defaults` + DeepMerger in module |
| ace-review | 143.05 | `load_gem_defaults` + DeepMerger in module |
| ace-search | 143.05 | `load_gem_defaults` + DeepMerger in module |
| ace-git | Pre-143 | Already compliant with pattern |
| ace-git-secrets | Pre-143 | Already compliant with pattern |

### Deferred Packages

| Package | Reason |
|---------|--------|
| ace-llm | ENV-based configuration, requires separate task |
| ace-llm-providers-cli | ENV-based configuration, requires separate task |

### Implementation Pattern Summary

**Recommended Pattern (using ace-config)**

With ace-support-config gem, the configuration pattern simplifies to:

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
              "This is a gem packaging error."
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

Key implementation details:
- Uses `Ace::Support::Config.create` for configuration cascade
- Uses `resolve_namespace("gem")` to load user config from `.ace/gem/config.yml`
- Uses `Ace::Support::Config::Models::Config.wrap()` for clean defaults + overrides merging
- Loads defaults from `.ace-defaults/gem/config.yml`
- Provides `reset_config!` for test isolation

**Legacy Pattern (pre-ace-config)**

The previous pattern using ace-support-core directly:

```ruby
# In lib/ace/gem.rb or lib/ace/gem/molecules/config_loader.rb
require "ace/core/atoms/deep_merger"

def self.load_gem_defaults
  gem_root = Gem.loaded_specs["ace-gem"]&.gem_dir ||
             File.expand_path("../..", __dir__)
  defaults_path = File.join(gem_root, ".ace-defaults", "gem", "config.yml")

  unless File.exist?(defaults_path)
    raise "Default config not found: #{defaults_path}. " \
          "This is a gem packaging error."
  end

  YAML.safe_load_file(defaults_path, permitted_classes: [], aliases: true) || {}
end

def self.config
  @config ||= begin
    defaults = load_gem_defaults
    user_config = Ace::Core.config.get("ace", "gem") || {}
    Ace::Support::Config::Atoms::DeepMerger.merge(defaults, user_config)
  end
end

def self.reset_config!
  @config = nil
end
```

---

This ADR supersedes ADR-019 by making explicit that default configuration should live in `.ace-defaults/` files rather than being hardcoded in Ruby, and establishes the pattern for backward-compatible config key changes.
