# Let's Commit Workflow Instruction

## Goal

Guide the developer through creating a well-structured, atomic Git commit following project conventions.

## Prerequisites

- Code changes have been implemented and tested.
- Files related to a single logical change are ready to be staged.
- Familiarity with the project's version control guidelines.

Follow these steps to create well-structured commits.
For detailed conventions and practical examples, first read [Version Control Guide](docs-dev/guides/version-control.md)

## Process Steps

1. **Review and Prepare Changes:**
    - Review modified files (`git status`, `git diff`).
    - Ensure new code has corresponding tests.
    - Verify tests pass (using your project's standard test command, e.g., `your_test_runner_command`. See
      `docs-dev/guides/testing/<your_lang>.md` or `docs-dev/guides/task-cycle/<your_lang>.md` for details).
    - Check test coverage if applicable (using your project's standard coverage command,
      e.g., `your_coverage_command`. See testing guides for details).
    - Group related changes logically (e.g., feature implementation + tests + docs).

2. **Create Commit:**
    - Stage *only* the related changes for this commit (`git add <files...>`).
    - Review staged changes (`git diff --staged`).
    - **Review AI Changes:** If changes were generated or assisted by AI, review them rigorously against
      requirements and coding standards before proceeding. Check for correctness, edge cases, and adherence
      to patterns.
    - Write a clear conventional commit message (follow format in guide). Use `git commit`.
    - Verify commit scope and content.

3. **Follow Up:**
    - Push changes when ready (`git push`).
    - Update relevant project tracking (e.g., mark task as done in its `.md` file if applicable).

## Output / Success Criteria

- Related changes are staged (`git add`).
- AI-generated changes (if any) are reviewed.
- A single, atomic commit is created (`git commit`).
- The commit message follows the conventional commit format outlined in the Version Control
  Guide.
- Project tracking (e.g., task `.md` status) is updated if the commit completes a task.

## Reference Guides

- [Version Control Guide](docs-dev/guides/version-control.md)
- [Documentation Guide](docs-dev/guides/documentation.md)
- [Project Management Guide](docs-dev/guides/project-management.md) (Task status updates)
- [Testing Guides](docs-dev/guides/testing)
