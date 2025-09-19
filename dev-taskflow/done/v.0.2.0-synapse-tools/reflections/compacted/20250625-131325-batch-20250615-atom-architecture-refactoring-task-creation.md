# Reflections Template

## Stop Doing

- Placing data structures in molecules/ when they don't compose atoms or perform meaningful operations
- Mixing architectural concerns by having pure data carriers in behavior-oriented namespaces
- Creating tasks without first understanding the full dependency chain and usage patterns

## Continue Doing

- Following ATOM architecture house rules consistently across the codebase
- Using code review feedback as input for structured task creation
- Performing thorough directory audits before making architectural changes
- Creating detailed implementation plans with embedded tests for verification
- Maintaining backward compatibility during refactoring by preserving public APIs

## Start Doing

- Proactively identifying other classes that might be misplaced according to ATOM principles
- Creating architectural decision records (ADRs) when making significant structural changes
- Adding more granular tests around class behavior to catch regressions during refactoring
- Documenting the rationale for architectural decisions in code comments for future maintainers