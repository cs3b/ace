# Named Model Pools (Roles) - Draft Usage

## API Surface

- [x] Configuration (new `llm.roles` config key)
- [x] Developer API (new `RoleConfig` model, `RoleResolver` molecule)
- [ ] CLI (no new CLI commands)
- [ ] Agent API (no new workflows/protocols)

## Usage Scenarios

### Scenario 1: Define roles in project config

**Goal**: Set up provider-agnostic model pools for different use cases

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

### Scenario 3: Programmatic role resolution

**Goal**: Parse a role reference in Ruby code

```ruby
parser = Ace::LLM::Molecules::ProviderModelParser.new
result = parser.parse("role:reviewer")

result.valid?     # => true
result.provider   # => "anthropic" (first available)
result.model      # => "claude-sonnet-4-5"
result.preset     # => "yolo"
result.original_input # => "role:reviewer"
```

### Scenario 4: No available models for a role

**Goal**: Clear error when all providers in a role are unavailable

```ruby
result = parser.parse("role:reviewer")
# When no API keys are configured for any provider in the role:
result.valid?  # => false
result.error   # => "No available models for role 'reviewer'. Tried: claude:sonnet:high@yolo, codex:gpt@ro. Check API keys and provider configuration."
```

### Scenario 5: Unknown role reference

**Goal**: Clear error for undefined role names

```ruby
result = parser.parse("role:nonexistent")
result.valid?  # => false
result.error   # => "Unknown role: 'nonexistent'. Defined roles: reviewer, fast"
```

## Notes for Implementer

- Full usage documentation to be completed during work-on-task step using `wfi://docs/update-usage`
