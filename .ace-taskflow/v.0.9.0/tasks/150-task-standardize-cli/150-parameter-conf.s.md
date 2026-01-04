---
id: v.0.9.0+task.150
status: in-progress
priority: medium
estimate: M
dependencies: []
worktree:
  branch: 150-standardize-cli-parameter-configuration-and-output-summary
  path: "../ace-task.150"
  created_at: '2026-01-04 10:46:16'
  updated_at: '2026-01-04 10:46:16'
---

# Standardize CLI Parameter Configuration and Output Summary

## Objective

Improve transparency, predictability, and debuggability of ace-* CLI tools by standardizing parameter configuration patterns and providing immediate feedback on effective configuration. This benefits both human developers (clearer understanding of active settings) and AI agents (deterministic context for autonomous operations).

## Behavioral Specification

### User Experience
- **Input**: Users execute any `ace-*` CLI command with or without explicit parameters
- **Process**: Command starts with a concise 1-3 line configuration summary displayed, then proceeds with normal execution
- **Output**: Users receive immediate feedback on effective configuration (defaults + overrides + CLI args) before command results

### Expected Behavior

When any `ace-*` CLI command is executed, the system should:
1. Resolve configuration using ace-config cascade (CLI args > .ace/ config > gem defaults via ADR-022)
2. Display a concise, parseable summary of the effective configuration to stderr
3. Proceed with command execution using the resolved configuration
4. Allow users to suppress the summary with a `--no-summary` or `--quiet` flag

### Interface Contract

```bash
# CLI Interface - Configuration Summary Output
ace-review --pr 123
# Output to stderr (before main command execution):
# Config: preset=pr model=claude-sonnet-4.5 pr=123 format=markdown

ace-test test/file_test.rb --quiet
# No config summary (suppressed by --quiet flag)
# Only test results to stdout

ace-taskflow idea enhance 20251202-115955-cli-enhance
# Output to stderr:
# Config: llm_model=gflash idea=20251202-115955-cli-enhance verbosity=normal
```

**Configuration Sources (in precedence order):**
1. Explicit CLI arguments (highest priority)
2. `.ace/` project/user configuration files
3. Gem-defined defaults in `.ace-defaults/gem/config.yml`

**Summary Format:**
- Single line, key=value pairs, space-separated
- Machine-readable and human-friendly
- Output to stderr to avoid interfering with stdout
- Excludes sensitive data (tokens, credentials)

**Error Handling:**
- Missing configuration files: Use gem defaults silently
- Invalid configuration values: Display warning in summary, use defaults
- Malformed config: Display error and halt execution

**Edge Cases:**
- Empty configuration: Display minimal summary with gem defaults only
- Very large config: Summarize only CLI-relevant parameters (truncate if needed)
- Nested config keys: Flatten to dot-notation (e.g., `llm.provider=openrouter`)

## Scope of Work

### Deliverables

#### Create

- `ace-support-core/lib/ace/core/atoms/config_summary.rb`
  - Purpose: Core ConfigSummary module using ace-config for defaults comparison
  - Key components: `initialize`, `to_s`, `display`, sensitive key filtering
  - Dependencies: ace-config gem

- `ace-support-core/test/atoms/config_summary_test.rb`
  - Purpose: Test coverage for ConfigSummary

#### Modify

- `.ace-defaults/*/config.yml` files
  - Changes: Add `cli_defaults` section with `summary_keys`, `quiet`, `verbosity`

- `ace-review/lib/ace/review/cli.rb` (pilot)
  - Changes: Integrate ConfigSummary display before command execution

- All ace-* CLI entry points (rollout)
  - Changes: Add `--quiet`/`--no-summary` flags, integrate ConfigSummary

## Technical Approach

### Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Summary Format | Key=value | Most concise, machine-parseable, docker/kubectl pattern |
| Output Stream | stderr | Doesn't interfere with stdout pipelines |
| Summary Content | CLI-relevant only | Via configurable `summary_keys` |
| Adoption | Opt-in per gem | Backward compatible, incremental rollout |

### Implementation Strategy

ConfigSummary uses ace-config (per ADR-022):
- `Ace::Config.create.resolve_namespace()` for user config
- Loads gem defaults from `.ace-defaults/gem/config.yml`
- Only surfaces values that differ from defaults (diff mode)
- Filters sensitive keys, sorts output for determinism

## Implementation Plan

### Planning Steps

* [x] Research existing CLI summary patterns (docker, kubectl)
* [x] Design key=value format specification
* [x] Define cli_defaults schema for .ace-defaults/
* [x] Resolve validation questions (format, stream, content)

### Execution Steps

- [ ] Create `ace-support-core/lib/ace/core/atoms/config_summary.rb`
  > TEST: Module Creation
  > Type: Unit Test
  > Assert: ConfigSummary.new returns valid instance, to_s produces key=value format
  > Command: ace-test ace-support-core atoms

- [ ] Create `ace-support-core/test/atoms/config_summary_test.rb`
  > TEST: Test Coverage
  > Type: Unit Test
  > Assert: Covers initialize, to_s, display, sensitive filtering, defaults comparison
  > Command: ace-test ace-support-core atoms

- [ ] Add `cli_defaults` to `.ace-defaults/review/config.yml`

- [ ] Integrate ConfigSummary with ace-review CLI (pilot)
  > TEST: Pilot Integration
  > Type: Integration Test
  > Assert: ace-review displays config summary on stderr before execution
  > Command: ace-review --preset pr --dry-run 2>&1 | grep "Config:"

- [ ] Add `--quiet`/`--no-summary` flags to ace-review

- [ ] Rollout to remaining OptionParser CLIs (ace-test, ace-nav, ace-docs)

- [ ] Rollout to Thor CLIs (ace-git, ace-prompt, ace-git-commit)

- [ ] Integrate with ace-taskflow (custom dispatcher)

- [ ] Update ADR-022 with `cli_defaults` pattern documentation

- [ ] Run full test suite
  > TEST: Regression
  > Type: Full Suite
  > Assert: All existing tests pass
  > Command: ace-test-suite

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Breaking existing scripts | Low | Medium | Summary to stderr; opt-in adoption |
| Performance overhead | Low | Low | Minimal (single hash iteration) |
| Inconsistent adoption | Medium | Low | Clear pattern + documentation |
| Summary clutter | Low | Low | Default to brief; --quiet available |

## Acceptance Criteria

- [ ] ConfigSummary module passes unit tests
- [ ] ace-review displays summary on command start (pilot)
- [ ] `--quiet` flag suppresses summary output
- [ ] Sensitive keys (tokens, passwords) are filtered
- [ ] Key=value format is parseable by agents
- [ ] No regression in existing CLI behavior
- [ ] Documentation updated (ADR-022)

## Out of Scope

- ❌ Interactive configuration editing
- ❌ Config validation tools
- ❌ Performance optimization/caching
- ❌ Migration scripts for existing configs

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/done/20251202-115955-cli-enhance/`
- ADR-022: Configuration Default and Override Pattern (ace-config)
- Related: Existing `.ace-defaults/` configuration patterns