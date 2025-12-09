---
id: v.0.9.0+task.150
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Standardize CLI Parameter Configuration and Output Summary

## Behavioral Specification

### User Experience
- **Input**: Users execute any `ace-*` CLI command with or without explicit parameters
- **Process**: Command starts with a concise 1-3 line configuration summary displayed, then proceeds with normal execution
- **Output**: Users receive immediate feedback on effective configuration (defaults + overrides + CLI args) before command results

### Expected Behavior

When any `ace-*` CLI command is executed, the system should:
1. Resolve configuration using the existing ace-support-core cascade (CLI args > .ace/ config > gem defaults)
2. Display a concise, parseable summary of the effective configuration to stderr
3. Proceed with command execution using the resolved configuration
4. Allow users to suppress the summary with a `--no-summary` or `--quiet` flag

This provides transparency for both human developers and AI agents, showing exactly what parameters are active without requiring inspection of multiple configuration files.

### Interface Contract

```bash
# CLI Interface - Configuration Summary Output
ace-review --pr 123
# Output to stderr (before main command execution):
# Config: provider=openrouter model=claude-sonnet-4.5 pr=123 format=markdown summary=enabled

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
3. Gem-defined defaults in `.ace.example/gem/config.yml`

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

### Success Criteria

- [ ] **Configuration Transparency**: Every ace-* command displays a 1-3 line config summary at start
- [ ] **Standardized Defaults**: Each ace-* gem defines CLI defaults in `.ace.example/gem/config.yml` under `cli_defaults` key
- [ ] **Cascade Integration**: Configuration resolution uses ace-support-core cascade correctly (CLI > project > gem defaults)
- [ ] **Summary Suppression**: `--no-summary` or `--quiet` flag successfully suppresses config output
- [ ] **Machine Readability**: Summary format is parseable by agents (key=value format)
- [ ] **Security**: No sensitive data (tokens, credentials) exposed in summary output
- [ ] **Backward Compatibility**: Existing ace-* command usage remains unaffected (summary is additive)

### Validation Questions

- [ ] **Summary Format**: Should we use JSON, YAML, or key=value format for the config summary? Key=value seems most concise.
- [ ] **Summary Content**: Which configuration keys should be included in the summary? All? Only CLI-relevant? Configurable?
- [ ] **Output Stream**: Is stderr the right choice for summary output to avoid interfering with stdout pipelines?
- [ ] **Verbosity Levels**: Should there be different verbosity levels for the summary (brief, detailed)?
- [ ] **Global Flag**: Should there be a global .ace/ config option to disable summaries permanently?
- [ ] **Config Resolution Logging**: Should there be a verbose mode that shows WHERE each config value came from (CLI, project, default)?

## Objective

Improve transparency, predictability, and debuggability of ace-* CLI tools by standardizing parameter configuration patterns and providing immediate feedback on effective configuration. This benefits both human developers (clearer understanding of active settings) and AI agents (deterministic context for autonomous operations).

## Scope of Work

- **User Experience Scope**:
  - All ace-* CLI command executions
  - Configuration summary display at command start
  - Summary suppression via flags
  - Clear feedback on effective configuration

- **System Behavior Scope**:
  - Unified configuration resolution across all ace-* gems
  - Standardized default parameter loading
  - Concise configuration summary generation
  - Security filtering of sensitive data

- **Interface Scope**:
  - All ace-* CLI commands receive summary capability
  - New `--no-summary`/`--quiet` flag support
  - `.ace.example/gem/config.yml` structure for CLI defaults
  - Configuration summary output format

### Deliverables

#### Behavioral Specifications
- Configuration summary output format specification
- CLI parameter precedence rules documentation
- Configuration file structure for gem defaults
- Summary suppression behavior specification

#### Validation Artifacts
- Test scenarios for configuration cascade
- Examples of summary output for different commands
- Edge case handling specifications
- Security filtering requirements

## Out of Scope

- ❌ **Implementation Details**: Specific module/class organization in ace-support-core
- ❌ **Technology Decisions**: Whether to use Thor hooks, mixins, or base classes
- ❌ **Performance Optimization**: Caching strategies for configuration resolution
- ❌ **Future Enhancements**: Interactive configuration editing, config validation tools
- ❌ **Migration Scripts**: Automated migration of existing config to new format

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/done/20251202-115955-cli-enhance/standardize-parameter-configuration-and-output-summary.s.md`
- Related: ace-support-core configuration cascade documentation
- Related: Existing `.ace.example/` configuration patterns
