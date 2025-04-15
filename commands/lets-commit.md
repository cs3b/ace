# Let's Commit Command

Follow these steps to create well-structured commits. For detailed conventions and practical examples, first read [Version Control Guide](../guides/version-control.md).

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
    *   Write a clear conventional commit message (follow format in guide). Use `git commit`.
    *   Verify commit scope and content.

3.  **Follow Up:**
    *   Push changes when ready (`git push`).
    *   Update relevant project tracking (e.g., mark task as done in its `.md` file if applicable).

## Reference Guides
- [Version Control Guide](../guides/version-control.md)
- [Documentation Guide](../guides/documentation.md)
- [Project Management Guide](../guides/project-management.md) (Task status updates)
