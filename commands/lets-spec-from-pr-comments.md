# PR Comments to Specification Command

This command processes GitHub pull request comments into organized specifications and tasks.

## Process Steps

1. **Initialize**:
   - Accept PR URL as input
   - Create new version bump based on current version for feedback implementation (use next patch version using semver)
   - Create new release directory in: `docs-dev/project/current/v1.0.1-feedback-to-pr-21/`
   - Set up release subdirectories:
     ```
     docs-dev/project/current/v1.0.1-feedback-to-pr-21/    # First feedback patch
     docs-dev/project/current/v1.0.2-feedback-to-pr-21/    # Second feedback patch
     ├── docs/         # Raw feedback and analysis
     ├── tasks/        # Grouped implementation tasks
     └── README.md     # Release overview
     ```

2. **Gather Feedback**:
   - Use GitHub MCP server to fetch:
     - PR comments via `get_pull_request_comments`
     - PR reviews via `get_pull_request_reviews`
   - Store comments and reviews individually in:
     - `docs/comments/comment-2025-04-10-0712-2036663266.json`
     - `docs/comments/comment-2025-04-10-0715-2036668671.json`
     - `docs/reviews/review-2025-04-10-0824-2755584987.json`
   - Validate data structures for each file

3. **Process Feedback**:
   - Combine and analyze both:
     - Individual PR comments
     - Review comments and suggestions
     - Review status (approved, changes requested, etc)
   - Group feedback by related scope/topic
   - Create task files in `tasks/` directory
   - Format tasks with:
     - Clear title and description
     - Implementation notes
     - Acceptance criteria
     - Related files/references
     - Review status context

4. **Generate Release Document**:
   - Create overview in README.md
   - Summarize changes needed
   - Group tasks by priority/impact
   - Document dependencies

## Success Criteria

- All feedback processed:
  - PR comments fully captured
  - PR reviews and their comments included
  - Review status considered
- Feedback grouped logically by topic
- Tasks properly scoped and prioritized
- Clear implementation plan created
- Dependencies identified
- Review concerns addressed

## Usage Example

```bash
# Process PR comments with:
lets-spec-from-pr-comments https://github.com/org/repo/pull/123

# Creates new release directory:
docs-dev/project/current/v1.0.1-feedback-to-pr-21/
├── docs/
│   ├── comments/
│   │   ├── comment-2025-04-10-0712-2036663266.json    # Tool name feedback
│   │   ├── comment-2025-04-10-0715-2036668671.json    # Version bump request
│   │   └── comment-2025-04-10-0719-2036678438.json    # Pagination feedback
│   └── reviews/
│       └── review-2025-04-10-0824-2755584987.json     # Main review feedback
├── tasks/
│   ├── use-prompt-name-method.md      # Use consistent prompt_name method
│   ├── add-prompt-examples.md         # Add prompt examples to demo files
│   ├── fix-image-content-format.md    # Update image content mime type
│   └── add-pagination-support.md      # Add pagination to prompts listing
└── README.md                          # Implementation overview
```
