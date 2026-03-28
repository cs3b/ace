---
id: 8qr.t.zoz
status: draft
priority: medium
created_at: "2026-03-28 23:47:46"
estimate: TBD
dependencies: []
tags: [ace-llm, config, model-resolution]
bundle:
  presets: ["project"]
  files:
    - ace-llm/lib/ace/llm/molecules/provider_model_parser.rb
    - ace-llm/lib/ace/llm/molecules/client_registry.rb
    - ace-llm/lib/ace/llm/molecules/llm_alias_resolver.rb
    - ace-llm/lib/ace/llm/models/fallback_config.rb
    - ace-llm/lib/ace/llm/configuration.rb
    - ace-llm/lib/ace/llm/molecules/config_loader.rb
    - ace-llm/lib/ace/llm.rb
    - ace-llm/.ace-defaults/llm/config.yml
    - ace-llm/test/molecules/provider_model_parser_test.rb
    - ace-llm/test/models/fallback_config_test.rb
  commands: []
---

# Named Model Pools (Roles) for ace-llm

## Objective

Packages currently hardcode specific model identifiers (e.g., `doctor_agent_model: "gemini:flash-latest@yolo"`). If a provider is unavailable (no API key configured), there is no way to resolve to an alternative at configuration time. The existing fallback system only handles runtime HTTP errors.

This task introduces named "roles" — ordered model pools that resolve to the first available model at parse time. This enables portable, provider-agnostic model selection across the project.

## Behavioral Specification

### User Experience

- **Input:** Users define roles in config (`llm.roles` in `.ace/llm/config.yml` or `~/.ace/llm/config.yml`); reference them as `role:<name>` anywhere a model identifier is accepted
- **Process:** Transparent resolution at parse time — the first model whose provider is available (API key present, provider configured) is selected, then parsed through normal alias/preset/thinking flow
- **Output:** The resolved model is used seamlessly; if no models are available, a clear error lists all tried models and suggests checking API keys

### Expected Behavior

When a model string like `role:reviewer` is passed to `ProviderModelParser.parse()`:

1. Parser detects `role:` prefix before normal parsing begins
2. Delegates to `RoleResolver` which loads role definitions from config cascade
3. Iterates through the role's model list, checking each provider's availability (API key presence via env var lookup)
4. Returns the first available model string
5. Parser re-parses that string through the normal alias → provider → thinking → preset flow
6. Result is transparent to callers — `ParseResult` contains the resolved provider/model with `original_input` preserving the `role:` reference

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
model: "role:fast@ro"           # preset passthrough to resolved model

# Programmatic usage
parser = ProviderModelParser.new
result = parser.parse("role:reviewer")
# => ParseResult(provider: "anthropic", model: "claude-sonnet-4-5",
#                preset: "yolo", thinking_level: "high",
#                original_input: "role:reviewer")
```

**Error Handling:**

- Unknown role → `"Unknown role: 'nonexistent'. Defined roles: reviewer, fast"`
- No available models → `"No available models for role 'reviewer'. Tried: claude:sonnet:high@yolo, codex:gpt@ro. Check API keys and provider configuration."`
- Circular reference (`role:X` inside a role definition) → rejected during `RoleConfig` validation
- Empty model list in role → rejected during `RoleConfig` validation

**Edge Cases:**

- Preset passthrough: `role:fast@ro` applies `@ro` to resolved model, unless the resolved model already has its own preset (model's preset wins)
- Aliases inside roles: model entries like `opus` are valid — full alias resolution happens after role resolution via recursive `parse()`
- Config cascade: project `.ace/llm/config.yml` roles override user `~/.ace/llm/config.yml` roles (standard nearest-wins)
- CLI providers without API keys (codex, claude CLI wrappers): considered available if provider config exists and no `api_key.required` is set

## Success Criteria

1. `role:<name>` syntax resolves to first available model in any model string field
2. Roles participate in config cascade (project overrides user overrides gem defaults)
3. Existing model identifiers (`claude:opus:high@yolo`) continue working unchanged — zero regression
4. Preset passthrough works (`role:fast@ro` applies `@ro` to resolved model)
5. Clear, actionable error messages for unknown roles and no-available-models conditions
6. Circular `role:` references inside role definitions are rejected at config validation time

## Validation Questions

- ~All resolved in the plan discussion~ — no open questions remain

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
- `RoleResolver.resolve` returns first available model, skips unavailable providers
- `RoleResolver.resolve` handles preset passthrough correctly

### Integration/E2E Validation

- `ProviderModelParser.parse("role:reviewer")` returns valid `ParseResult` with resolved provider/model
- `ProviderModelParser.parse("role:fast@ro")` applies preset to resolved model
- `ProviderModelParser.parse("role:unknown")` returns invalid result with clear error
- Full `QueryInterface.query("role:fast", prompt)` works end-to-end (if provider available)

### Failure/Invalid Path Validation

- `parse("role:")` → error (empty role name)
- `parse("role:x")` where role `x` has all unavailable providers → actionable error
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
