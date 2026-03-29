---
id: 8qr.t.zoz
status: pending
priority: medium
created_at: "2026-03-28 23:47:46"
estimate: TBD
dependencies: []
tags: [ace-llm, config, model-resolution]
bundle:
  presets: [project]
  files: [.ace/llm/config.yml, .ace/llm/providers/claude.yml, .ace/llm/providers/codex.yml, .ace/llm/providers/gemini.yml, ace-llm/lib/ace/llm/molecules/provider_model_parser.rb, ace-llm/lib/ace/llm/molecules/client_registry.rb, ace-llm/lib/ace/llm/molecules/llm_alias_resolver.rb, ace-llm/lib/ace/llm/models/fallback_config.rb, ace-llm/lib/ace/llm/configuration.rb, ace-llm/lib/ace/llm/molecules/config_loader.rb, ace-llm/lib/ace/llm.rb, ace-llm/.ace-defaults/llm/config.yml, ace-llm/test/molecules/provider_model_parser_test.rb, ace-llm/test/models/fallback_config_test.rb]
  commands: []
---

# Named Model Pools (Roles) for ace-llm

## Objective

Packages currently hardcode specific model identifiers (e.g., `doctor_agent_model: "gemini:flash-latest@yolo"`). If a provider is unavailable (no API key configured), there is no way to resolve to an alternative at configuration time. The existing fallback system only handles runtime HTTP errors.

This task introduces named "roles" — ordered model pools that resolve to the first available model at parse time. This enables portable, provider-agnostic model selection across the project.

Roles also provide stable indirection for system-wide model management: packages can reference role names while operators swap the underlying models or providers centrally in role config, without editing each consumer file.

## Behavioral Specification

### User Experience

- **Input:** Users define roles in config (`llm.roles` in `.ace/llm/config.yml` or `~/.ace/llm/config.yml`); reference them as `role:<name>` anywhere a model identifier is accepted
- **Process:** Transparent resolution at parse time — candidates are evaluated in order until one is available under the strict runtime rule: provider is active, registry-loadable, and has a present API key when that provider requires one. The winning model is then parsed through the normal alias/preset/thinking flow. Caller-supplied thinking and preset suffixes on the `role:` reference are applied last and always override any thinking/preset embedded in the resolved role entry. V1 uses ordered first-match; future work may add richer ranking metrics without changing `role:<name>` syntax
- **Output:** The resolved model is used seamlessly; if no models are available, a clear error lists all tried models and suggests checking API keys. Updating a role definition can also redirect many consuming configs at once without touching each consumer file

### Expected Behavior

When a model string like `role:reviewer` is passed to `ProviderModelParser.parse()`:

1. Parser detects `role:` prefix before normal parsing begins
2. Delegates to `RoleResolver` which loads role definitions from config cascade
3. Iterates through the role's model list, checking each candidate with the strict runtime availability rule: provider is allowed by `llm.providers.active` when filtering is enabled, provider config/gem/class can be loaded successfully, and any required API key is present
4. Returns the first available model string
5. Parser re-parses that string through the normal alias → provider → thinking → preset flow
6. Any thinking level or preset supplied on the original `role:` reference overrides the resolved role entry's thinking/preset
7. Result is transparent to callers — `ParseResult` contains the resolved provider/model with `original_input` preserving the `role:` reference

When no models in a role are available, a `ConfigurationError` is raised with an actionable message.

### Interface Contract

```yaml
# Config definition (.ace/llm/config.yml or ~/.ace/llm/config.yml)
llm:
  roles:
    reviewer:
      - claude:sonnet:high@yolo
      - codex:gpt@ro
    orchestrator:
      - claude:opus:medium@yolo
      - gemini:pro-latest@yolo
    fast:
      - gemini:flash-latest
      - claude:haiku
```

```ruby
# Usage in any package config YAML
model: "role:reviewer"          # resolves to first available
model: "role:fast@ro"           # caller preset overrides resolved model preset
model: "role:reviewer:low@ro"   # caller thinking/preset override role defaults

# Programmatic usage
parser = ProviderModelParser.new
result = parser.parse("role:reviewer")
# => ParseResult(provider: "claude", model: "claude-sonnet-4-6",
#                preset: "yolo", thinking_level: "high",
#                original_input: "role:reviewer")

result = parser.parse("role:reviewer:low@ro")
# => ParseResult(provider: "claude", model: "claude-sonnet-4-6",
#                preset: "ro", thinking_level: "low",
#                original_input: "role:reviewer:low@ro")
```

**Error Handling:**

- Unknown role → `"Unknown role: 'nonexistent'. Defined roles: reviewer, orchestrator, fast"`
- No available models → `"No available models for role 'reviewer'. Tried: claude:sonnet:high@yolo, codex:gpt@ro. Check API keys and provider configuration."`
- Circular reference (`role:X` inside a role definition) → rejected during `RoleConfig` validation
- Empty model list in role → rejected during `RoleConfig` validation

**Edge Cases:**

- Caller overrides win: `role:fast@ro` applies `@ro` even if the resolved model already has its own preset
- Caller thinking overrides win: `role:reviewer:low` applies `low` even if the resolved model already has its own thinking level
- Combined caller overrides win: `role:reviewer:low@ro` overrides both thinking level and preset from the resolved role entry
- Aliases inside roles: model entries like `opus` are valid — full alias resolution happens after role resolution via recursive `parse()`
- Config cascade: project `.ace/llm/config.yml` roles override user `~/.ace/llm/config.yml` roles (standard nearest-wins)
- Active-provider filtering: if `llm.providers.active` is configured, role resolution only considers providers on that allow-list
- Load failures: providers whose registry config, gem, or client class cannot be loaded are skipped as unavailable
- Optional-key CLI providers: providers without a required API key remain eligible if their registry config loads successfully

## Success Criteria

1. `role:<name>` syntax resolves to first available model in any model string field
2. Roles participate in config cascade (project overrides user overrides gem defaults)
3. Existing model identifiers (`claude:opus:high@yolo`) continue working unchanged — zero regression
4. Caller override passthrough works (`role:fast@ro`, `role:reviewer:low`, and `role:reviewer:low@ro` override preset/thinking from the resolved role entry)
5. Clear, actionable error messages for unknown roles and no-available-models conditions
6. Circular `role:` references inside role definitions are rejected at config validation time
7. Changing a role definition updates all consumers that reference that role without per-file config edits

## Validation Questions

- Resolved during review: availability uses strict runtime semantics today
- Future extensibility is intentionally preserved: role selection may later incorporate ranking signals such as cost or available tokens, but v1 remains ordered first-match
- No blocking human-input questions remain

## Vertical Slice Decomposition (Task/Subtask Model)

**Single standalone task** — all changes are within the ace-llm package.

- **Slice:** Add role config model, role resolver molecule, parser integration, config defaults, tests
- **Advisory size:** Small-Medium
- **Context dependencies:** ace-llm parser, config loader, client registry, fallback_config model pattern

## Verification Plan

### Unit/Component Validation

- `RoleConfig.from_hash` correctly parses YAML structure with string/symbol keys
- `RoleConfig.models_for` returns ordered array; returns nil for unknown roles
- `RoleConfig.validate!` rejects empty model lists, non-array values, nested `role:` refs
- `RoleResolver.role_reference?` detects `role:` prefix, ignores `claude:opus`
- `RoleResolver.resolve` returns first available model under strict runtime availability, skipping inactive providers, load-failing providers, and required-key-missing providers
- `RoleResolver.resolve` preserves caller-supplied thinking/preset overrides so the parser can apply them last
- `RoleResolver.resolve` allows optional-key CLI providers to win when they are active and loadable

### Integration/E2E Validation

- `ProviderModelParser.parse("role:reviewer")` returns valid `ParseResult` with resolved provider/model
- `ProviderModelParser.parse("role:fast@ro")` overrides any preset from the resolved role entry
- `ProviderModelParser.parse("role:reviewer:low")` overrides any thinking level from the resolved role entry
- `ProviderModelParser.parse("role:reviewer:low@ro")` overrides both thinking level and preset from the resolved role entry
- `ProviderModelParser.parse("role:unknown")` returns invalid result with clear error
- Role resolution honors `llm.providers.active` filtering when present
- Full `QueryInterface.query("role:fast", prompt)` works end-to-end (if provider available)

### Failure/Invalid Path Validation

- `parse("role:")` → error (empty role name)
- `parse("role:x")` where role `x` has all unavailable providers → actionable error
- `parse("role:x")` skips candidates whose provider gem/class cannot be loaded and continues to later candidates
- `parse("role:x")` skips candidates whose provider is configured but excluded by `llm.providers.active`
- Role config with `role:other` in model list → validation error at config load time

### Verification Commands

- `cd ace-llm && ace-test test/models/role_config_test.rb` → model tests pass
- `cd ace-llm && ace-test test/molecules/role_resolver_test.rb` → resolver tests pass
- `cd ace-llm && ace-test test/molecules/provider_model_parser_test.rb` → parser tests pass (existing + new)
- `cd ace-llm && ace-test` → full package suite green

## Scope of Work

### Included

- `RoleConfig` model (pure data carrier) — ATOM Models layer
- `RoleResolver` molecule (availability-based resolution) — ATOM Molecules layer
- Parser integration (pre-processing step in `ProviderModelParser.parse()`)
- Config defaults (`roles: {}` in `.ace-defaults/llm/config.yml`)
- Role resolution aligned with project-level provider overlays and `llm.providers.active`
- Requires wiring in `ace-llm/lib/ace/llm.rb`
- Unit tests for all new components + parser integration tests

### Out of Scope

- Migrating existing package configs to use `role:` references (future incremental work per package)
- Runtime fallback integration (roles resolve at config time, not runtime)
- CLI subcommand for listing/inspecting roles (can be added later)
- Role inheritance or composition (roles are flat ordered lists)

## Deliverables

### Behavioral Specifications

- Role config data model with validation
- Role resolution logic with availability checking
- Parser integration for transparent `role:` prefix handling

### Validation Artifacts

- Unit tests for RoleConfig model
- Unit tests for RoleResolver molecule
- Integration tests for parser with role references

## References

- Plan file: `/home/mc/.claude/plans/zesty-twirling-blossom.md`
- Existing pattern reference: `ace-llm/lib/ace/llm/models/fallback_config.rb` (model pattern)
- Existing pattern reference: `ace-llm/lib/ace/llm/molecules/provider_model_parser.rb` (integration point)
- ADR-022: Config cascade
- ADR-011: ATOM architecture
