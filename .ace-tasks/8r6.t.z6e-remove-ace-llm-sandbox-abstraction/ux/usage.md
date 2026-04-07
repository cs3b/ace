# ace-llm sandbox cleanup - Draft Usage

## API Surface

- [ ] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Run a provider from an E2E sandbox

**Goal**: Execute the provider from a prepared sandbox without giving `ace-llm` ownership of sandbox policy.

```ruby
Ace::LLM::QueryInterface.query(
  "role:e2e-runner",
  prompt,
  working_dir: "/tmp/e2e-sandbox",
  subprocess_env: {
    "PROJECT_ROOT_PATH" => "/tmp/e2e-sandbox",
    "ACE_E2E_SOURCE_ROOT" => "/repo"
  }
)
```

### Expected Output

The provider runs with cwd `/tmp/e2e-sandbox`, receives the supplied environment, and derives any execution policy from its preset configuration.

### Scenario 2: Request provider policy through presets instead of sandbox input

**Goal**: Express read-only or similar provider behavior through preset/config, not a generic sandbox argument.

```ruby
Ace::LLM::QueryInterface.query(
  "codex:gpt@ro",
  prompt,
  working_dir: "/workspace"
)
```

### Expected Output

`ace-llm` applies the provider-specific preset-defined CLI flags for `ro` and does not require or interpret a separate sandbox abstraction.

## Notes for Implementer

Full usage documentation should be completed during work-on-task using `wfi://docs/update-usage`.
