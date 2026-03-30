---
id: 8qs.t.j24.1
status: done
priority: high
created_at: "2026-03-29 12:42:28"
estimate: TBD
dependencies: []
tags: [ace-support-core, bootstrap, scaffold, dx]
parent: 8qs.t.j24
bundle:
  presets: [project]
  files: [ace-support-core/lib/ace/core/organisms/config_initializer.rb, ace-support-core/lib/ace/core/models/config_templates.rb, .ace/bundle/presets/project.md, .ace/bundle/presets/project-base.md, .ace/README.md, ace-support-core/docs/config.md]
  commands: []
needs_review: false
---

# Make ace-framework init generate valid generic project bootstrap files

## Objective

After a fresh install, `ace-framework init` should produce valid, runnable, non-monorepo-specific project bootstrap files for a normal project. A user should not need to repair generated presets or manually remove ACE-monorepo copy before the system works.

## Behavioral Specification

### User Experience

- **Input:** A user runs `ace-framework init` in a fresh project that is not the ACE monorepo.
- **Process:** ACE copies the default project config into `.ace/` using current schemas and generic project-facing content.
- **Output:** The generated config works immediately with `ace-bundle project`; preset structure is valid, command references are current, and placeholder text is obviously generic rather than ACE-specific.

### Expected Behavior

1. `ace-framework init` remains a non-interactive initializer.
2. Generated bundle presets use a structure accepted by current `ace-bundle` behavior.
3. Generated command references use current ACE CLIs such as `ace-task`, not retired `ace-taskflow` commands.
4. Generated project-facing prose uses neutral placeholders or TODO markers rather than ACE-monorepo descriptions.
5. Generated config remains understandable for first-time users.

### Interface Contract

```bash
ace-framework init
ace-bundle project
```

```yaml
bundle:
  sections:
    overview:
      title: Project Overview
      files:
        - docs/vision.md
```

### Error Handling

- If generated config cannot be loaded by `ace-bundle`, the task is incomplete.
- If generated text still claims the user is in the ACE monorepo, the task is incomplete.

### Edge Cases

- Empty project without any ACE-specific docs yet
- Existing `.ace/` config overwritten intentionally with `--force`
- Users who only know the public CLI and not internal package history

## Success Criteria

1. In a fresh project, `ace-framework init` followed by `ace-bundle project` succeeds.
2. Generated presets use valid current bundle structure.
3. Generated commands do not mention `ace-taskflow`.
4. Generated copy does not mention “Coding Agent Workflow Toolkit (Meta)”.
5. Placeholder values are clearly placeholders, not misleading defaults.

## Validation Questions

- No blocking questions remain.
- Non-interactive generic placeholders are the intended contract, not init prompts.

## Vertical Slice Decomposition (Task/Subtask Model)

**Single standalone task**

- **Slice:** config initializer output, generated bundle preset validity, generic scaffold language
- **Advisory size:** Small-Medium
- **Context dependencies:** config initializer, default templates, bundle preset contract

## Verification Plan

### Unit/Component Validation

- Generated project preset shape is accepted by current bundle schema.
- Generated command references are current.

### Integration/E2E Validation

- Fresh project bootstrap reaches a working `ace-bundle project` baseline.
- The generated project preset reads as generic project scaffolding.

### Failure/Invalid Path Validation

- Invalid generated frontmatter is treated as failure.
- Monorepo-specific prose in generated defaults is treated as failure.

### Verification Commands

- `ace-framework init`
- `ace-bundle project`

## Scope of Work

### Included

- Config initializer output contract
- Bundle preset validity
- Generic project-facing scaffold text

### Out of Scope

- Introducing interactive project setup prompts
- Reworking unrelated config namespaces

## Deliverables

### Behavioral Specifications

- Valid generated preset contract
- Generic scaffold content contract

### Validation Artifacts

- Fresh-project init scenario
- Bundle-load success scenario

## References

- Usage doc: `.ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/1-make-ace-framework-init-generate/ux-usage.md`
- Parent task: `.ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/8qs.t.j24-new-project-onboarding-hardening-rollout.s.md`
