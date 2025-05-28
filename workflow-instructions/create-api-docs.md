# Create API Documentation Workflow Instruction

## Goal

Generate or update API documentation for public interfaces (classes, modules, methods) using standard
documentation tools (e.g., YARD for Ruby) and adhering to project documentation standards.

## Prerequisites

- Code with public interfaces that need documentation.
- Project configured with a documentation generation tool (e.g., YARD setup).

## Process Steps

1. **Identify Target Code:** Determine which classes, modules, or methods require documentation updates
   (e.g., newly added, recently modified).
2. **Analyze Code:** Review the code to understand its purpose, parameters, return values, potential
   exceptions, usage patterns, and any performance or thread-safety considerations.
3. **Write Doc Comments:** Add or update documentation comments directly in the source code using the
   standard tool syntax (e.g., YARD tags like `@param`, `@return`, `@raise`, `@example`, `@note`, `@see`).
    - Follow guidelines in `docs-dev/guides/documentation.md` for content and style.
    - Include clear descriptions, parameter details, return value explanations, usage examples, and notes
      on constraints or important behaviors.
4. **Generate Documentation:** Run the documentation generation tool (e.g., `bundle exec yard doc` from
   project root) to produce the static documentation files.
5. **Review Generated Docs:** Check the output for completeness, accuracy, formatting errors, and broken
   links. Ensure examples are correct and helpful.
6. **Commit Changes:** Commit the updated source code comments and any generated documentation files (if tracked in git).

## Input

- Target code files or modules needing documentation.
- Understanding of the code's functionality.

## Output / Success Criteria

- [x] Source code contains updated, accurate documentation comments for the target interfaces.
- [x] Documentation comments follow project standards (`docs-dev/guides/documentation.md`).
- [x] Generated API documentation (e.g., HTML files) is up-to-date and reflects the code comments.
- [x] Documentation covers key aspects: purpose, params, returns, examples, exceptions, notes.

## Reference Documentation

- [Documentation Standards Guide](docs-dev/guides/documentation.md) (Provides specific examples and tag usage)
- [Coding Standards Guide](docs-dev/guides/coding-standards.md)
