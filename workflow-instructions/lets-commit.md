# Let's Commit Workflow Instruction

## Goal
Guide the developer through creating a well-structured, atomic Git commit following project conventions.

## Prerequisites
- Code changes have been implemented and tested.
- Files related to a single logical change are ready to be staged.
- Familiarity with the project's version control guidelines.
# Let's Commit Workflow Instruction

Follow these steps to create well-structured commits. For detailed conventions and practical examples, first read [Version Control Guide](docs-dev/guides/version-control.md)

## Process Steps

1.  **Review and Prepare Changes:**
    *   Review modified files (`git status`, `git diff`).
    *   Ensure new code has corresponding tests.
    *   Verify tests pass (e.g., `bundle exec rspec`, adjust command as needed).
    *   Check test coverage if applicable (e.g., `COVERAGE=true bundle exec rspec`).
    *   Group related changes logically (e.g., feature implementation + tests + docs).

2.  **Create Commit:**
    *   Stage *only* the related changes for this commit (`git add <files...>`).
    *   Review staged changes (`git diff --staged`).
    *   **Review AI Changes:** If changes were generated or assisted by AI, review them rigorously against requirements and coding standards before proceeding. Check for correctness, edge cases, and adherence to patterns.
    *   Write a clear conventional commit message (follow format in guide). Use `git commit`.
    *   Verify commit scope and content.

3.  **Follow Up:**
    *   Push changes when ready (`git push`).
    *   Update relevant project tracking (e.g., mark task as done in its `.md` file if applicable).

## Output / Success Criteria
- [x] Related changes are staged (`git add`).
- [x] AI-generated changes (if any) are reviewed.
- [x] A single, atomic commit is created (`git commit`).
- [x] The commit message follows the conventional commit format outlined in the Version Control Guide.
- [x] Project tracking (e.g., task `.md` status) is updated if the commit completes a task.
## Reference Guides
- [Version Control Guide](docs-dev/guides/version-control.md)
- [Documentation Guide](docs-dev/guides/documentation.md)
- [Project Management Guide](docs-dev/guides/project-management.md) (Task status updates)
