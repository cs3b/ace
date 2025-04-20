# Generate Code Review Checklist Workflow Instruction

## Goal
Generate a context-specific code review checklist based on the nature of the changes being reviewed (e.g., new feature, bug fix, refactoring) and project standards.

## Prerequisites
- Code changes ready for review (e.g., in a Pull Request or commit range).
- Access to project quality guidelines (`guides/quality-assurance.md`).

## Process Steps

1.  **Analyze Changes:** Review the code diff or Pull Request description to understand:
    *   The purpose and scope of the changes.
    *   Affected components or modules.
    *   Potential impacts (breaking changes, dependencies, performance, security).
2.  **Select Base Checklist:** Start with the standard review checklist template found in `docs-dev/guides/quality-assurance.md` (under "Review Checklist").
3.  **Tailor Checklist:** Adapt the base checklist based on the specific changes:
    *   Add checks relevant to the modified areas (e.g., "Verify new API endpoint follows REST principles").
    *   Remove checks that are not applicable.
    *   Emphasize areas of higher risk (e.g., "Pay close attention to security aspects of authentication changes").
4.  **Generate Checklist:** Present the tailored checklist (e.g., as Markdown). This checklist can be added as a comment to a PR or used directly by the reviewer.

## Input
- Code changes (diff, PR link, commit range).
- Context about the purpose of the changes.

## Output / Success Criteria
- [x] A code review checklist tailored to the specific changes is generated.
- [x] The checklist is based on the project's standard checklist (`docs-dev/guides/quality-assurance.md`).
- [x] The checklist highlights relevant areas for review based on the changes' scope and potential impact.

## Reference Documentation
- [Writing Workflow Instructions Guide](docs-dev/guides/writing-workflow-instructions.md)
- [Quality Assurance Guide](docs-dev/guides/quality-assurance.md) (Contains base checklist and PR template)
- [Coding Standards Guide](docs-dev/guides/coding-standards.md)
