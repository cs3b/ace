# Named Model Pools (Roles) - Draft Usage

## API Surface

- [x] Configuration (new `llm.roles` config key)
- [x] Developer API (new `RoleConfig` model, `RoleResolver` molecule)
- [ ] CLI (no new CLI commands)
- [ ] Agent API (no new workflows/protocols)

## Usage Scenarios

### Scenario 1: Define roles in project config

**Goal**: Set up provider-agnostic model pools for different use cases and enable centralized model/provider swaps

```yaml
# .ace/llm/config.yml
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

### Expected Output

Consumers reference stable role names. Changing the role definition later can redirect every consumer to different models/providers without editing each consumer file.

### Scenario 2: Reference a role in package config

**Goal**: Use a role instead of a hardcoded model identifier

```yaml
# .ace-defaults/task/config.yml
task:
  doctor_agent_model: "role:fast@yolo"
  plan:
    model: "role:orchestrator@ro"
```

### Expected Output

Transparent resolution — the package receives a fully resolved model as if a direct identifier was used. No change to downstream behavior.

This decouples each package config from the exact provider/model choice, so system-wide changes can be made in role config instead of per-package edits.

### Scenario 2b: Override role defaults at the call site

**Goal**: Reuse a role while forcing a different thinking level and preset

```yaml
task:
  review_model: "role:reviewer:low@ro"
```

### Expected Output

The selected role candidate still determines provider and base model, but caller-supplied suffixes win for thinking level and preset.

### Scenario 3: Programmatic role resolution

**Goal**: Parse a role reference in Ruby code

```ruby
parser = Ace::LLM::Molecules::ProviderModelParser.new
result = parser.parse("role:reviewer")

result.valid?     # => true
result.provider   # => "claude" (first available active/loadable provider)
result.model      # => "claude-sonnet-4-6"
result.preset     # => "yolo"
result.original_input # => "role:reviewer"
```

```ruby
result = parser.parse("role:reviewer:low@ro")

result.valid?     # => true
result.provider   # => "claude"
result.model      # => "claude-sonnet-4-6"
result.thinking_level # => "low"
result.preset     # => "ro"
result.original_input # => "role:reviewer:low@ro"
```

### Scenario 4: No available models for a role

**Goal**: Clear error when all providers in a role are unavailable

```ruby
result = parser.parse("role:reviewer")
# When every candidate is inactive, unloadable, or missing a required API key:
result.valid?  # => false
result.error   # => "No available models for role 'reviewer'. Tried: claude:sonnet:high@yolo, codex:gpt@ro. Check API keys and provider configuration."
```

### Scenario 5: Unknown role reference

**Goal**: Clear error for undefined role names

```ruby
result = parser.parse("role:nonexistent")
result.valid?  # => false
result.error   # => "Unknown role: 'nonexistent'. Defined roles: reviewer, orchestrator, fast"
```

## Notes for Implementer

- Full usage documentation to be completed during work-on-task step using `wfi://docs/update-usage`
- V1 availability is strict runtime availability: active provider, loadable provider config/client, and required API key present; future ranking metrics remain out of scope for this task
- Caller-supplied `:thinking` and `@preset` on a `role:` reference always override thinking/preset embedded in the resolved role entry
