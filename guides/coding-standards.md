# General Coding Standards

This document outlines general coding standards. Project-specific conventions or overrides should be documented in `docs-dev/project/coding-standards.md` (if it exists).

## General Principles

- **Clarity & Readability:** Write code that is easy for others (and your future self) to understand. Use meaningful variable names, keep functions/methods short and focused, and add comments where logic is complex or non-obvious.
- **Consistency:** Follow established patterns and conventions within the project. If using a style guide tool (like StandardRB, RuboCop), adhere to its rules.
- **Simplicity (KISS):** Avoid unnecessary complexity. Prefer straightforward solutions unless a more complex approach offers significant, justifiable benefits (e.g., performance).
- **Don't Repeat Yourself (DRY):** Abstract common logic into reusable functions, methods, or classes.
- **Modularity:** Design components with clear responsibilities and well-defined interfaces. Aim for loose coupling and high cohesion.
- **Testability:** Write code that is easy to test. Use dependency injection and avoid tight coupling to facilitate unit testing.

## Language-Specific Idioms (Example: Ruby)

- Follow community conventions (e.g., Ruby Style Guide).
- Use blocks and `yield` for configuration and iteration where appropriate.
- Leverage metaprogramming judiciously; prioritize clarity over cleverness.
- Use standard library features where applicable.

## Formatting & Style

- **Indentation:** Use consistent indentation (e.g., 2 spaces for Ruby).
- **Line Length:** Adhere to a reasonable line length limit (e.g., 100-120 characters) to improve readability.
- **Whitespace:** Use whitespace effectively to separate logical blocks of code.
- **Tooling:** Utilize automated formatters and linters (e.g., StandardRB, Prettier) to enforce consistency. Configure these tools via project configuration files (e.g., `.standard.yml`, `.prettierrc`).

## Error Handling

- Use specific, informative error classes. Define a base error class for the project/library.
- Provide context with errors (e.g., relevant data, operation being performed).
- Handle errors appropriately (log, retry, raise, return error values) based on the context.
- See [Error Handling Guide](error-handling.md) for more details.

## Testing

- Write tests for new code (unit, integration, E2E as appropriate).
- Ensure tests cover primary functionality, edge cases, and error conditions.
- Keep tests independent and fast.
- See [Testing Guidelines](testing.md) for more details.

## Documentation

- Document public APIs (classes, methods, modules) using standard documentation tools (e.g., YARD for Ruby).
- Add comments to explain complex logic or non-obvious decisions within method bodies.
- Keep documentation up-to-date with code changes.
- See [Documentation Standards](documentation.md) for more details.

## File Organization

- Follow a logical directory structure (e.g., separating library code, tests, configuration, documentation).
- Use clear and consistent file naming conventions.
- Refer to the project's `docs-dev/project/blueprint.md` for the specific structure.

*(Example structure - adjust based on project)*
```
project-root/
├── lib/          # Core library code
│   └── my_module/
├── spec/         # Tests
│   ├── unit/
│   ├── integration/
│   └── support/
├── config/       # Configuration files
├── docs/         # User-facing documentation
├── docs-dev/     # Internal development documentation
├── bin/          # Executable scripts
└── Rakefile / Makefile / etc. # Build/task runner configuration
```