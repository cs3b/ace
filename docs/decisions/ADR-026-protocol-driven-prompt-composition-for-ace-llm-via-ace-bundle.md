# ADR-026: Protocol-Driven Prompt Composition for ace-llm via ace-bundle

## Status

Accepted
Date: 2026-03-04

## Context

Recent work in this repository moved planning system prompt composition away from inline hardcoded strings and into reusable template and workflow resources. The implementation now composes prompts with `ace-bundle` using protocol-addressable inputs such as:

- `tmpl://agent/plan-mode`
- `wfi://task/plan`
- preset composition (`presets: [project]`)

This surfaced a broader architecture concern: if prompt logic is embedded as ad-hoc strings in tool code, users cannot reliably override behavior without patching Ruby sources. That increases maintenance risk, duplicates prompt logic across gems, and prevents prompt contracts from being reviewed as first-class resources.

At the same time, the repository already has mature protocol and bundle infrastructure (`tmpl://`, `prompt://`, `wfi://`, `guide://`, `ace-bundle` section composition). We need an explicit decision that standardizes how ace-llm-consuming tools compose prompts and where customization lives.

## Decision

We will standardize prompt composition for ace-llm consumers around protocol resources and `ace-bundle` configuration instead of hardcoded prompt strings.

Key aspects of this decision:

- Prompt assembly must use resource references (for example `tmpl://`, `prompt://`, `wfi://`, or file paths) as composition inputs.
- System and user prompt assembly should be performed via `ace-bundle` configuration primitives (`base`, `sections`, `presets`) when composing multi-source prompts.
- User/project customization must happen by overriding resources and bundle configuration, not by editing embedded prompt literals in code.
- Existing branch pattern is the canonical example:
  - `base: tmpl://agent/plan-mode`
  - `sections.workflow.files: [wfi://task/plan]`
  - `sections.project_context.presets: [project]`
  - repeated guard/reminder section using `tmpl://agent/plan-mode`

## Consequences

### Positive

- Prompt behavior is overrideable through config and protocol sources without code edits.
- Prompt composition becomes auditable and testable as explicit resources.
- Cross-gem consistency improves because prompt assembly uses one common mechanism (`ace-bundle`).
- Reuse improves: templates/workflows can be shared across tools instead of copied into implementation code.

### Negative

- Prompt assembly now depends on protocol registration and source discovery being correct.
- Debugging requires tracing composed sources instead of reading one local string literal.
- Documentation quality becomes a hard requirement because composition is configuration-driven.

### Neutral

- There is one additional indirection layer (bundle config + protocol resolution) between caller and final prompt text.
- Some single-purpose cases may still use direct strings, but multi-source prompt composition follows this ADR.

## Alternatives Considered

### Alternative 1: Hardcoded Prompt Strings in Code

- **Description**: Keep composing prompts directly inside Ruby classes with multiline strings.
- **Pros**: Simple local implementation, fewer moving parts.
- **Cons**: Hard to override, duplicates logic, weak separation between architecture and content.
- **Why not chosen**: It blocks user override patterns and does not scale across gems.

### Alternative 2: Dedicated Prompt Files Without ace-bundle Composition

- **Description**: Use static files only, but avoid section/preset composition.
- **Pros**: Better than inline strings; prompt text is externalized.
- **Cons**: Weak for multi-source composition, limited reuse, no standardized merging contract.
- **Why not chosen**: It does not leverage existing composition mechanisms and leads to ad-hoc assembly rules.

### Alternative 3: Per-Tool Custom Composition Pipelines

- **Description**: Let each tool define independent logic for building prompts.
- **Pros**: Tool-level flexibility.
- **Cons**: Inconsistent behavior, repeated implementation complexity, harder onboarding.
- **Why not chosen**: We need a shared architecture contract across ace-llm-consuming tools.

## Related Decisions

- [ADR-014: LLM Integration Architecture](ADR-014-LLM-Integration-Architecture.md)
- [ADR-022: Configuration Default and Override Pattern](ADR-022-configuration-default-and-override-pattern.md)
- [ADR-023: dry-cli Framework](ADR-023-dry-cli-framework.md)

## References

- `ace-task/lib/ace/task/molecules/task_plan_prompt_builder.rb`
- `ace-llm/handbook/templates/agent/plan-mode.template.md`
- `ace-bundle/docs/configuration.md`
- `ace-bundle/docs/usage.md`
