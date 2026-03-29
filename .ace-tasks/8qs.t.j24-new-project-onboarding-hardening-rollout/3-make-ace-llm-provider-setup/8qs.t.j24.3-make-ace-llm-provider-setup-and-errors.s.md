---
id: 8qs.t.j24.3
status: draft
priority: medium
created_at: "2026-03-29 12:42:29"
estimate: TBD
dependencies: []
tags: [ace-llm, config, providers, dx]
parent: 8qs.t.j24
bundle:
  presets: [project]
  files:
    - ace-llm/docs/usage.md
    - ace-llm/lib/ace/llm/configuration.rb
    - ace-llm/lib/ace/llm/molecules/provider_model_parser.rb
    - ace-llm/lib/ace/llm/molecules/client_registry.rb
    - .ace/llm/config.yml
    - .ace/llm/providers/openrouter.yml
    - .ace/llm/providers/codexoai.yml
  commands: []
---

# Make ace-llm provider setup and errors actionable

## Objective

Provider misconfiguration should lead users toward resolution instead of a crash-driven debugging session. ACE already has a discovery surface in `ace-llm --list-providers`; this task makes errors and docs point to it clearly and tie supported providers to their required environment variables.

## Behavioral Specification

### User Experience

- **Input:** A user runs an ACE command that depends on provider config, with an unsupported provider name, an ignored active-provider entry, or missing credentials.
- **Process:** ACE reports the failure in actionable language, naming supported providers, required env keys, and the next discovery step.
- **Output:** The user can fix provider config by following the error message and docs without reading stack traces.

### Expected Behavior

1. Unknown provider errors list supported providers and a clear next step.
2. Ignored `llm.providers.active` entries explain that they were ignored and why.
3. Docs provide a discoverable provider/config reference with concrete environment variable guidance.
4. The canonical discovery surface is `ace-llm --list-providers`; this task does not invent a new subcommand.
5. Alias-driven inputs such as `glite` remain compatible with clear guidance when they fail through config issues.

### Interface Contract

```bash
ace-llm --list-providers
ace-llm glite "Say hello"
```

```text
Unknown provider: <name>. Supported providers: <list>. Run `ace-llm --list-providers` for available providers and configuration guidance.
```

```text
Unknown providers in llm.providers.active: <list> (ignored)
# plus explanation of what to change next
```

### Error Handling

- If a provider failure still requires a stacktrace to discover the supported set or env key, the task is incomplete.
- If docs and runtime messages disagree on the canonical provider-discovery command, the task is incomplete.

### Edge Cases

- Unsupported provider names in config
- Alias inputs that resolve through provider config
- Providers present in config but inactive in `llm.providers.active`
- Providers requiring different env keys

## Success Criteria

1. Unknown/ignored provider errors are actionable.
2. `ace-llm --list-providers` is the explicit discovery path across runtime help and docs.
3. Docs map supported providers to required env vars with examples.
4. The task improves onboarding without changing the primary CLI shape.

## Validation Questions

- No blocking questions remain.
- A new `ace-llm providers` subcommand is intentionally out of scope.

## Vertical Slice Decomposition (Task/Subtask Model)

**Single standalone task**

- **Slice:** runtime provider errors, provider setup docs, discovery-path clarification
- **Advisory size:** Small-Medium
- **Context dependencies:** provider parser, registry, config loading, usage docs

## Verification Plan

### Unit/Component Validation

- Unknown provider errors name supported providers.
- Ignored active-provider entries generate explanatory output.
- Docs include provider/env-key mapping examples.

### Integration/E2E Validation

- A user can move from failing provider config to a corrected config through runtime guidance and docs.
- `ace-llm --list-providers` is enough to discover the supported set.

### Failure/Invalid Path Validation

- Ambiguous provider crashes are failure.
- Introducing a new subcommand instead of using the existing discovery surface is out of scope.

### Verification Commands

- `ace-llm --list-providers`
- `ace-llm glite "Say hello"`

## Scope of Work

### Included

- Provider error guidance
- Provider setup docs
- Env-key discoverability

### Out of Scope

- New provider implementations
- A new top-level `providers` subcommand

## Deliverables

### Behavioral Specifications

- Provider error contract
- Provider docs/discovery contract

### Validation Artifacts

- Unknown-provider scenario
- Ignored-provider scenario

## References

- Usage doc: `.ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/3-make-ace-llm-provider-setup/ux-usage.md`
- Parent task: `.ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/8qs.t.j24-new-project-onboarding-hardening-rollout.s.md`
