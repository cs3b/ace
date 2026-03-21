---
doc-type: guide
title: General Coding Standards
purpose: Documentation for ace-handbook/handbook/guides/coding-standards.g.md
ace-docs:
  last-updated: 2026-01-08
  last-checked: 2026-03-21
---

# General Coding Standards

## Goal

This guide outlines the fundamental principles and standards for writing clean, readable, maintainable,
and consistent code within this project. Adhering to these standards facilitates collaboration
(human-human and human-AI) and long-term project health.

This document outlines general coding standards applicable across the project. Project-specific
conventions or language-specific rules beyond these general principles may be documented
in the relevant `dev-taskflow/` directory or linked from the `docs/blueprint.md`.

## General Principles

- **Clarity & Readability:** Write code that is easy for others (and your future self) to understand. Use
  meaningful variable names, keep functions/methods short and focused, and add comments where logic is
  complex or non-obvious.
- **Consistency:** Follow established patterns and conventions within the project. If using a style guide tool
  (like StandardRB, RuboCop), adhere to its rules.
- **Simplicity (KISS):** Avoid unnecessary complexity. Prefer straightforward solutions unless a more complex
  approach offers significant, justifiable benefits (e.g., performance).
- **Don\'t Repeat Yourself (DRY):** Abstract common logic into reusable functions, methods, or classes.
- **Modularity:** Design components with clear responsibilities and well-defined interfaces. Aim for loose
  coupling and high cohesion.
- **Testability:** Write code that is easy to test. Use dependency injection and avoid tight coupling to

## Language-Specific Coding Standards

Language-specific idioms, conventions, and tool recommendations have been moved to dedicated sub-guides.
Please refer to the relevant guide for your language:

- [Ruby Coding Standards](./coding-standards/ruby.md)
- [TypeScript Coding Standards](./coding-standards/typescript.md)

## Formatting & Style

- **Indentation:** Use consistent indentation (e.g., 2 spaces for Ruby).
- **Line Length:** Adhere to a reasonable line length limit (e.g., 100-120 characters) to improve
  readability.
- **Whitespace:** Use whitespace effectively to separate logical blocks of code.
- **Tooling:** Utilize automated formatters and linters (e.g., StandardRB, Prettier) to enforce
  consistency. Configure these tools via project configuration files (e.g., `.standard.yml`, `.prettierrc`).

## Error Handling

- Use specific, informative error classes. Define a base error class for the project/library.
- Provide context with errors (e.g., relevant data, operation being performed).
- Handle errors appropriately (log, retry, raise, return error values) based on the context.
- See [Error Handling Guide](./error-handling.g.md) for more details.

## Testing

- Write tests for new code (unit, integration, E2E as appropriate).
- Ensure tests cover primary functionality, edge cases, and error conditions.
- Keep tests independent and fast.
- See [Testing Guidelines](guide://testing) for more details.

## Documentation

- Document public APIs (classes, methods, modules) using standard documentation tools (e.g., YARD for Ruby).
- Add comments to explain complex logic or non-obvious decisions within method bodies.
- Keep documentation up-to-date with code changes.
- See [Documentation Standards](guide://documentation) for more details.

## File Organization

- Follow a logical directory structure (e.g., separating library code, tests, configuration, documentation).
- Use clear and consistent file naming conventions.
Refer to the project's `docs/blueprint.md` for the specific structure.

## AI-Assisted Development Collaboration

When working with AI coding agents (like Cursor, Claude, etc.), treat them as collaborative partners, often akin
to a junior developer needing clear guidance.

- **Plan Before Prompting:** Thoroughly plan the task, including outlining steps, defining requirements, and
  identifying relevant context *before* asking the AI to generate or modify code. This aligns with the
  "Slow Vibe Coding" principle mentioned in Project Management.
- **Provide Context:** Give the AI sufficient context, including relevant code snippets, project structure
  (`docs/blueprint.md`), architecture (`docs/architecture.md`), existing patterns, and the
  specific task definition (`.md` file within `dev-taskflow`).
- **Use Specific, Concise Instructions:** Avoid vague requests. Break down complex tasks into smaller,
  well-defined steps. Use clear action verbs and specify the desired outcome. Consider using "prompt hygiene"
  like "ONLY IMPLEMENT EXACTLY THIS STEP" for focused changes.
- **Structured Prompts:** Structure prompts clearly, defining the AI\'s role, the objective, step-by-step instructions,
  and the desired output format (XML is often preferred by models like GPT-4.1). Include examples (few-shot learning)
  where appropriate.
- **Review Rigorously:** Review AI-generated code with the same scrutiny as human-written code. Check for
  correctness, adherence to standards, edge cases, security, and performance implications. Do not blindly
  trust AI output.
- **Iterate and Refine:** Expect to iterate. Provide constructive feedback on the AI\'s output to guide it
  towards the desired solution. Ask for explanations of its logic to learn and verify understanding.
- **Leverage Strengths:** Use AI for tasks it excels at (e.g., boilerplate code, implementing well-defined
  algorithms, refactoring based on clear rules) but rely on human oversight for complex design decisions
  and architectural planning.
- **Avoid "Hacky" Prompts:** Modern models respond better to clear instructions than tricks like excessive
  capitalization or emotional appeals.

Refer to the [Project Management Guide](guide://project-management) for how AI collaboration fits
into the task workflow.

(Example structure - adjust based on project)

```text
project-root/
├── lib/          # Core library code
│   └── my_module/
├── spec/         # Tests
│   ├── unit/
│   ├── integration/
│   └── support/
├── config/       # Configuration files
├── docs/         # User-facing documentation
├── ace-handbook/     # Development handbook (internal docs)
├── bin/          # Executable scripts
└── Rakefile / Makefile / etc. # Build/task runner configuration
```

## Related Documentation

- [Error Handling Guide](./error-handling.g.md)
- [Testing Guidelines](guide://testing)
- [Documentation Standards](guide://documentation)
- [Temporary File Management Guidelines](./temporary-file-management.g.md)
- [Project Management Guide](guide://project-management) (AI Collaboration context)
