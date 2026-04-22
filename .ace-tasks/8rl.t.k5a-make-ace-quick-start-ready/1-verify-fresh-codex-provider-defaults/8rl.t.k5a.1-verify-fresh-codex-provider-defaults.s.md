---
id: 8rl.t.k5a.1
status: done
priority: medium
estimate: TBD
dependencies: []
bundle:
  presets: [project]
  files: [ace-llm/.ace-defaults/llm/config.yml, ace-llm-providers-cli/.ace-defaults/llm/providers/codex.yml, ace-llm-providers-cli/lib/ace/llm/providers/cli/codex_client.rb, ace-llm/test/fast/organisms/configuration_test.rb, ace-llm-providers-cli/test/fast/molecules/codex_client_test.rb]
  commands: [ace-task show 8rl.t.k5a.1]
tags: []
parent: 8rl.t.k5a
created_at: "2026-04-22 13:26:01"
needs_review: false
---

# Verify fresh Codex provider defaults

## Behavioral Specification

### User Experience

- Input: A developer runs `ace-config init` in a fresh repo and then uses `ace-llm --list-providers` or a role that falls back to `codex:mini`.
- Process: Generated Codex config exposes current Codex model IDs and aliases.
- Output: `codex:mini` resolves to a currently supported Codex CLI model and does not point at `gpt-5-mini`.

### Expected Behavior

Fresh generated defaults should list current Codex models and aliases. The `commit` role may include `codex:mini` as a fallback only if that alias resolves to a current supported model. Users should never receive stale default config that directs Codex CLI to a rejected `gpt-5-mini` model.

### Interface Contract

```bash
ace-config init
ace-llm --list-providers
ace-llm codex:mini "Return exactly: OK"
```

Expected model catalog includes:

- `gpt-5.4`
- `gpt-5.4-mini`
- `gpt-5.3-codex`
- `gpt-5.3-codex-spark`

Error Handling:

- If a configured Codex alias resolves to an unsupported model, setup diagnostics report the alias and resolved model.
- If the local Codex CLI account rejects a model, the user receives account/model-specific setup guidance instead of a generic provider failure.

Edge Cases:

- Existing projects with custom `.ace/llm/providers/codex.yml` can still override defaults.
- Provider discovery remains useful even when Codex CLI is unavailable locally.

## Success Criteria

- Fresh default Codex provider config contains current model IDs and aliases.
- Tests assert `mini` resolves to `gpt-5.4-mini`.
- Tests assert no fresh default references `gpt-5-mini`.
- The `commit` role fallback chain remains compatible with the fresh Codex alias.

## Validation Questions

- None.

## Vertical Slice Decomposition: Task/Subtask Model

- Slice type: subtask.
- Slice outcome: generated Codex defaults are safe for first-use fallback chains.
- Advisory size: small.
- Context dependencies: ace-llm defaults, ace-llm-providers-cli Codex defaults, provider discovery tests.

## Verification Plan

### Unit/Component Validation

- Codex provider default tests assert current model list and alias mappings.
- LLM configuration tests assert the `commit` role resolves through current aliases.

### Integration/E2E Validation

- Provider discovery output includes current Codex model names when CLI provider package is installed.

### Failure/Invalid Path Validation

- A stale alias such as `codex:gpt-5-mini` is reported as invalid by readiness diagnostics.

### Verification Commands

- `ace-test ace-llm`
- `ace-test ace-llm-providers-cli`

## Objective

Prevent fresh ACE setup from generating stale Codex defaults that break first-use commit generation.

## Scope of Work

- Codex provider defaults and validation coverage.
- Do not redesign provider selection or fallback semantics.

## Deliverables

### Behavioral Specifications

- Current Codex default and alias behavior is specified as a user-visible contract.

### Validation Artifacts

- Regression tests for stale alias prevention.

## Out of Scope

- Live account-level model availability beyond readiness diagnostics.

## References

- GitHub issue: https://github.com/cs3b/ace/issues/298
