# Implementation Plan: Task 150 - Standardize CLI Parameter Configuration and Output Summary

## Executive Summary

This plan implements a standardized configuration summary system across all ace-* CLI tools. The core deliverable is a reusable infrastructure in ace-support-core that CLI tools can opt into, providing transparent configuration feedback without breaking existing behavior.

## Current State Analysis

### What Exists

1. **Configuration Cascade (ADR-022)**: Mature 5-tier priority system
   - CLI args > ENV > project .ace/ > home ~/.ace/ > gem .ace-defaults/
   - All gems migrated via Task 143/157
   - ace-config gem provides `Ace::Config.create()` API

2. **CLI Implementation Patterns**:
   - **OptionParser-based**: ace-review, ace-test, ace-nav (majority)
   - **Thor-based**: ace-git, ace-prompt, ace-git-commit
   - **Custom dispatcher**: ace-taskflow (complex subcommand routing)

3. **Existing Summary Patterns**:
   - ace-taskflow: `show_config()` method (manual, verbose output)
   - ace-review: Success messages with checkmarks
   - No automatic startup summary in any tool

### Gaps to Address

1. No unified `cli_defaults` section in `.ace-defaults/` configs
2. No automatic configuration summary output on command start
3. No `--quiet`/`--no-summary` flag pattern across tools
4. No machine-readable summary format (key=value) standard
5. Inconsistent CLI-to-config parameter tracking

## Design Decisions

### D1: Summary Format - Key=Value

**Decision**: Use space-separated `key=value` format on single line

```bash
# Output to stderr:
Config: preset=pr model=claude-sonnet-4.5 pr=123 format=markdown
```

**Rationale**:
- Most concise format for 1-3 line output
- Machine-parseable (simple regex or split)
- Human-readable without context switching
- Aligns with common CLI tool patterns (docker, kubectl)

### D2: Output Stream - stderr

**Decision**: Configuration summary outputs to stderr, not stdout

**Rationale**:
- Doesn't interfere with stdout pipelines (`ace-review | jq`)
- Standard pattern for diagnostics/metadata
- Allows suppression without affecting command output

### D3: Summary Content - CLI-Relevant Parameters Only

**Decision**: Summary includes only parameters relevant to CLI invocation:
- Explicit CLI arguments passed
- Config values that override defaults
- Key operational parameters (model, preset, target)

**Excluded**:
- Deeply nested configuration details
- Internal implementation settings
- Sensitive data (API keys, tokens) - always filtered

### D4: Opt-In Architecture

**Decision**: Summary functionality is opt-in per gem, not forced

**Rationale**:
- Backward compatible by default
- Gems can adopt incrementally
- Allows testing before broad rollout

## Implementation Plan

### Phase 1: Core Infrastructure (ace-support-core)

**Subtask 150.01: Create ConfigSummary Module**

Create `Ace::Core::Atoms::ConfigSummary` in ace-support-core, leveraging ace-config for defaults comparison:

```ruby
# ace-support-core/lib/ace/core/atoms/config_summary.rb
require "ace/config"

module Ace
  module Core
    module Atoms
      class ConfigSummary
        SENSITIVE_KEYS = %w[token key secret password credential api_key].freeze

        def initialize(gem_name:, cli_args: {}, summary_keys: [])
          @gem_name = gem_name
          @cli_args = cli_args
          @summary_keys = summary_keys

          # Use ace-config to load defaults and user overrides separately
          @defaults = load_gem_defaults
          @user_config = Ace::Config.create
                           .resolve_namespace(gem_name)
                           .to_h
        end

        def to_s
          params = build_summary_params
          return "" if params.empty?
          "Config: #{params.map { |k, v| "#{k}=#{format_value(v)}" }.join(' ')}"
        end

        def display(io: $stderr, quiet: false)
          return if quiet
          summary = to_s
          io.puts summary unless summary.empty?
        end

        private

        def load_gem_defaults
          gem_spec = Gem.loaded_specs["ace-#{@gem_name}"]
          return {} unless gem_spec

          defaults_path = File.join(gem_spec.gem_dir, ".ace-defaults", @gem_name, "config.yml")
          return {} unless File.exist?(defaults_path)

          YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
        end

        def build_summary_params
          params = {}
          # CLI args always shown (highest priority)
          @cli_args.each { |k, v| params[k] = v unless sensitive?(k) }
          # Show config values that differ from defaults (for summary_keys only)
          add_overrides_from_defaults(params)
          # Sort keys for deterministic output
          params.sort.to_h
        end

        def add_overrides_from_defaults(params)
          @summary_keys.each do |key|
            user_val = dig_key(@user_config, key)
            default_val = dig_key(@defaults, key)
            # Only show if user has overridden the default
            if user_val && user_val != default_val && !sensitive?(key)
              params[key] = user_val
            end
          end
        end

        def dig_key(hash, key)
          keys = key.to_s.split(".")
          keys.reduce(hash) { |h, k| h.is_a?(Hash) ? h[k] : nil }
        end

        def sensitive?(key)
          SENSITIVE_KEYS.any? { |s| key.to_s.downcase.include?(s) }
        end

        def format_value(val)
          case val
          when Array then val.join(",")
          when Hash then "{...}"
          else val.to_s
          end
        end
      end
    end
  end
end
```

**Key Design Points (per ADR-022)**:
- Uses `ace-config` gem's `Ace::Config.create.resolve_namespace()` for user config
- Loads gem defaults from `.ace-defaults/gem/config.yml`
- Only surfaces values that differ from defaults (diff mode)
- Filters sensitive keys (tokens, passwords, etc.)
- Sorts output keys for deterministic, testable output

**Files to create/modify**:
- `ace-support-core/lib/ace/core/atoms/config_summary.rb` (new)
- `ace-support-core/lib/ace/core/atoms.rb` (require new file)
- `ace-support-core/test/atoms/config_summary_test.rb` (new)

**Subtask 150.02: Add CLI Defaults Schema**

Define standard `cli_defaults` key structure for `.ace-defaults/`:

```yaml
# .ace-defaults/gem-name/config.yml
gem-name:
  # ... existing config ...

  cli_defaults:
    # Parameters to surface in summary
    summary_keys:
      - preset
      - model
      - format
    # Default quiet mode (false = show summary)
    quiet: false
    # Verbosity level: brief | normal | detailed
    verbosity: normal
```

**Documentation update**: Add section to ADR-022 about `cli_defaults` key.

### Phase 2: Pilot Implementation (1 gem)

**Subtask 150.03: Integrate with ace-review**

ace-review is ideal pilot:
- OptionParser-based (common pattern)
- Heavy config usage (presets, models, outputs)
- High visibility tool

Changes:
1. Add `cli_defaults` to `.ace-defaults/review/config.yml`
2. Add `--quiet` / `--no-summary` flags to CLI
3. Call `ConfigSummary.new(...).display` before `execute_review`
4. Define summary_keys: `preset, model, pr, format, output_dir`

**Example output**:
```bash
$ ace-review --preset pr --pr 123
Config: preset=pr model=claude-sonnet-4.5 pr=123 format=markdown
✓ Review saved: .ace-review/sessions/...
```

### Phase 3: Rollout to Remaining Gems

**Subtask 150.04: Integrate with OptionParser-based CLIs**

Apply pattern to:
- ace-test (summary_keys: config_path, group, profile, fail_fast)
- ace-nav (summary_keys: source, protocol, resource)
- ace-docs (summary_keys: type, format, output)

**Subtask 150.05: Integrate with Thor-based CLIs**

Apply pattern to:
- ace-git (summary_keys: command, format, range)
- ace-prompt (summary_keys: model, enhance, context)
- ace-git-commit (summary_keys: scope, type, model)

Note: Thor allows before_action hooks which simplifies integration.

**Subtask 150.06: Integrate with ace-taskflow**

Special handling needed due to custom dispatcher:
- Add summary display in main dispatch method
- Define summary_keys per subcommand
- Leverage existing `show_config()` logic

### Phase 4: Documentation & Validation

**Subtask 150.07: Update Documentation**

- Update ADR-022 with `cli_defaults` pattern
- Add "CLI Summary Configuration" section to docs/tools.md
- Create examples in docs/examples/

**Subtask 150.08: Validation Test Suite**

Create integration tests verifying:
- Summary appears on stderr before command output
- `--quiet` suppresses summary
- Sensitive keys are filtered
- Key=value format is parseable
- Summary doesn't break existing behavior

## Subtask Summary

| ID | Description | Scope | Dependencies |
|----|-------------|-------|--------------|
| 150.01 | Create ConfigSummary module in ace-support-core | Core | None |
| 150.02 | Define cli_defaults schema, update ADR-022 | Core | 150.01 |
| 150.03 | Pilot integration with ace-review | Pilot | 150.02 |
| 150.04 | Integrate OptionParser CLIs (ace-test, ace-nav, ace-docs) | Rollout | 150.03 |
| 150.05 | Integrate Thor CLIs (ace-git, ace-prompt, ace-git-commit) | Rollout | 150.03 |
| 150.06 | Integrate ace-taskflow (custom dispatcher) | Rollout | 150.03 |
| 150.07 | Update documentation (ADR-022, tools.md) | Docs | 150.03 |
| 150.08 | Create validation test suite | QA | 150.04-150.06 |

## Validation Questions (Resolved)

| Question | Resolution |
|----------|------------|
| Summary Format | Key=value (most concise, machine-readable) |
| Summary Content | CLI-relevant only (via summary_keys config) |
| Output Stream | stderr (doesn't interfere with pipelines) |
| Verbosity Levels | Support brief/normal/detailed via config |
| Global Flag | Yes, via .ace/gem/config.yml cli_defaults.quiet |
| Config Source Logging | Defer to verbose mode (--verbose shows sources) |

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Breaking existing scripts | Summary to stderr; opt-in adoption |
| Performance overhead | Minimal (single hash iteration) |
| Inconsistent adoption | Clear pattern + documentation |
| Summary clutter | Default to brief; --quiet available |

## Success Metrics

- [ ] ConfigSummary module passes unit tests
- [ ] ace-review displays summary on command start
- [ ] 80%+ ace-* CLIs adopt summary pattern within 2 sprints
- [ ] No regression in existing CLI behavior
- [ ] Agent tools can parse summary format reliably

## Out of Scope (Confirmed)

- Interactive configuration editing
- Config validation tools
- Performance optimization/caching
- Migration scripts for existing configs
- Detailed implementation of Thor hooks/mixins (left to implementer)
