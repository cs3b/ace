# Create User Documentation Workflow Instruction

## Goal

Create or update user-facing documentation (e.g., README additions, tutorials, usage examples) for a new feature
or significant change.

## Prerequisites

- Feature/change is implemented or well-defined.
- Understanding of the target audience and their needs.
- Access to relevant code, examples, and task descriptions.

## Process Steps

1. **Identify Scope & Audience:** Determine what needs to be documented and who the documentation is for
   (e.g., end-users, other developers integrating the feature).
2. **Analyze Feature:** Review the feature\'s functionality, configuration, use cases, API (if applicable), and
   potential integration points. Refer to task files, code, and examples.
3. **Outline Documentation:** Plan the structure of the documentation. Consider sections like:
    - Quick Start / Basic Usage Example
    - Key Concepts / How it Works
    - Detailed Usage / Configuration Options
    - Advanced Patterns / Use Cases
    - Troubleshooting / Common Issues
    - API Reference (if applicable, link to generated API docs)
    - Integration Examples
    - Migration Guide (if applicable)
    - *(Refer to `docs-dev/guides/draft-release/v.x.x.x/docs/_template.md` for a template)*
4. **Draft Content:** Write the documentation content, focusing on clarity, accuracy, and practical examples.
    - Include code snippets for examples.
    - Explain the "why" as well as the "how".
    - Use formatting (headings, lists, code blocks) effectively.
5. **Review & Refine:** Check the draft for clarity, completeness, technical accuracy, grammar, and
   spelling. Ensure examples work.
6. **Save/Commit:** Save the documentation in the appropriate location (e.g., `docs/`, `examples/`,
   `README.md` at project root, or within a release directory
   `docs-project/current/{release_dir}/user-experience/` or `docs-project/current/{release_dir}/docs/`).
   Commit the changes.

## Input

- Description of the feature/change to be documented.
- Target audience information.
- Relevant code, examples, task files.

## Output / Success Criteria

- User documentation for the specified feature/change is created or updated.
- Documentation is clear, accurate, and appropriate for the target audience.
- Key aspects (usage, configuration, examples) are covered.
- Documentation follows project standards (`docs-dev/guides/documentation.md`).
- Documentation is saved in the correct location.

## Reference Documentation

- [Documentation Standards Guide](docs-dev/guides/documentation.md)
- [User Docs Template](docs-dev/guides/draft-release/v.x.x.x/docs/_template.md)
- [User Experience Template](docs-dev/guides/draft-release/v.x.x.x/user-experience/_template.md)
