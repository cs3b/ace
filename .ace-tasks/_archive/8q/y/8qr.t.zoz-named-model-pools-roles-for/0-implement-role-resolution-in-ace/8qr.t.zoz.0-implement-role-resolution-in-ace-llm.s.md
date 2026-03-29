---
id: 8qr.t.zoz.0
status: done
priority: medium
created_at: "2026-03-29 00:19:49"
estimate: TBD
dependencies: []
tags: [ace-llm, config, model-resolution]
parent: 8qr.t.zoz
bundle:
  presets: [project]
  files: [.ace/llm/config.yml, .ace/llm/providers/claude.yml, .ace/llm/providers/codex.yml, .ace/llm/providers/gemini.yml, ace-llm/lib/ace/llm/molecules/provider_model_parser.rb, ace-llm/lib/ace/llm/molecules/client_registry.rb, ace-llm/lib/ace/llm/molecules/llm_alias_resolver.rb, ace-llm/lib/ace/llm/models/fallback_config.rb, ace-llm/lib/ace/llm/configuration.rb, ace-llm/lib/ace/llm/molecules/config_loader.rb, ace-llm/lib/ace/llm.rb, ace-llm/.ace-defaults/llm/config.yml, ace-llm/test/molecules/provider_model_parser_test.rb, ace-llm/test/models/fallback_config_test.rb]
  commands: []
---

# Implement role resolution in ace-llm

## Objective

Add named model roles to `ace-llm` so any consumer that already accepts a model/provider selector can use `role:<name>` instead of hardcoding provider/model strings. Roles must support centralized model swaps and preserve caller overrides for thinking level and preset.

## Behavioral Specification

### User Experience

- **Input:** Users define roles in config (`llm.roles` in `.ace/llm/config.yml` or `~/.ace/llm/config.yml`); consumers reference them as `role:<name>` anywhere a model identifier is accepted
- **Process:** Candidates are evaluated in order until one is available under the strict runtime rule: provider is active, registry-loadable, and has a present API key when that provider requires one. The winning model is parsed through the normal alias/provider/thinking/preset flow. Caller-supplied thinking and preset suffixes on the `role:` reference are applied last and override any thinking or preset embedded in the resolved role entry
- **Output:** The resolved model is used transparently; if no models are available, an actionable error reports the tried candidates. Updating one role definition can redirect many consumer configs without editing those consumer files

### Expected Behavior

1. `ProviderModelParser.parse()` detects `role:` before normal parsing begins
2. Resolution delegates to a role-aware component that loads role definitions from config cascade
3. Roles are resolved using strict runtime availability: active-provider filtering, loadable provider config/gem/class, and required API key presence
4. The selected candidate is re-parsed through normal alias, provider, thinking, and preset handling
5. Caller overrides on the original `role:` reference win for thinking and preset
6. `ParseResult.original_input` preserves the original `role:` reference

### Interface Contract

```yaml
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

```yaml
model: role:reviewer
model: role:fast@ro
model: role:reviewer:low@ro
```

```ruby
parser = ProviderModelParser.new
parser.parse("role:reviewer")
parser.parse("role:reviewer:low@ro")
```

### Error Handling

- Unknown role -> clear error listing defined roles
- No available models -> clear error listing tried candidates
- Empty role list -> validation error
- Nested `role:` entries inside a role definition -> validation error

### Edge Cases

- Caller `@preset` overrides resolved-role preset
- Caller `:thinking` overrides resolved-role thinking level
- Combined `:thinking@preset` overrides both
- Aliases inside role entries are valid and resolve through normal parsing
- Providers without required API keys remain eligible when loadable

## Success Criteria

1. `role:<name>` resolves in every field that currently accepts a model/provider selector through `ace-llm`
2. Caller overrides work for preset, thinking, and combined suffixes
3. Strict runtime availability is enforced
4. Existing non-role inputs keep working unchanged
5. Roles provide central indirection so one role edit can redirect many consumers

## Validation Questions

- No blocking questions remain
- Future ranking metrics stay out of scope for this task

## Vertical Slice Decomposition (Task/Subtask Model)

**Single standalone task**

- **Slice:** role config model, role resolution, parser integration, defaults, tests
- **Advisory size:** Small-Medium
- **Context dependencies:** parser, config loader, client registry, fallback config model pattern

## Verification Plan

### Unit/Component Validation

- role config parsing accepts string/symbol YAML keys
- validation rejects empty role lists and nested `role:` references
- role resolution skips inactive, unloadable, and required-key-missing candidates
- role resolution preserves caller thinking/preset overrides

### Integration/E2E Validation

- `ProviderModelParser.parse("role:reviewer")` returns resolved provider/model
- `ProviderModelParser.parse("role:fast@ro")` overrides any resolved preset
- `ProviderModelParser.parse("role:reviewer:low")` overrides resolved thinking level
- `ProviderModelParser.parse("role:reviewer:low@ro")` overrides both
- `QueryInterface.query("role:fast", prompt)` works end-to-end when a candidate is available

### Failure/Invalid Path Validation

- `parse("role:")` errors
- unknown role errors
- no-available-models errors
- role config containing `role:other` as a candidate fails validation

### Verification Commands

- `cd ace-llm && ace-test test/models/role_config_test.rb`
- `cd ace-llm && ace-test test/molecules/role_resolver_test.rb`
- `cd ace-llm && ace-test test/molecules/provider_model_parser_test.rb`
- `cd ace-llm && ace-test`

## Scope of Work

### Included

- role config model
- role resolver
- parser integration
- defaults and tests

### Out of Scope

- consumer config migration across ACE
- runtime fallback redesign
- role inheritance or composition
- CLI subcommand for listing roles

## Deliverables

### Behavioral Specifications

- role config model contract
- role resolution behavior
- parser integration behavior

### Validation Artifacts

- model tests
- resolver tests
- parser integration tests

## References

- Usage doc: `.ace-tasks/8qr.t.zoz-named-model-pools-roles-for/0-implement-role-resolution-in-ace/ux-usage.md`
- Parent rollout task: `.ace-tasks/8qr.t.zoz-named-model-pools-roles-for/8qr.t.zoz-named-model-pools-roles-for-ace-llm.s.md`
