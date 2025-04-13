# PR Comments to Specification Command

This command processes GitHub pull request comments into organized specifications and tasks.

## Process Steps

1. **Initialize**:
   - Accept PR URL as input
   - Create new version bump based on current version for feedback implementation (use next patch version using semver), and pull request number (e.g.: v1.0.1-feedback-to-pr-21)
   - Create new version directory ine: `docs-dev/project/current/`
   - Set up release subdirectories (docs / tasks / README.md) e.g.:
     ```
     docs-dev/project/current/v1.0.1-feedback-to-pr-21/ 
     ├── docs/         # Raw feedback and analysis
     ├── tasks/        # Grouped implementation tasks
     └── README.md     # Release overview
     ```

2. **Gather Feedback**:
   - Use GitHub MCP server to fetch:
     - PR comments via `get_pull_request_comments`
     - PR reviews via `get_pull_request_reviews`
   - Store comments and reviews individually following naming convention:
     Comments: `docs/comments/comment-{created_at}-{id}.json`
     Reviews: `docs/reviews/review-{submitted_at}-{id}.json`
     
     Example for comment with:
     ```json
     {
       "id": 2036663266,
       "created_at": "2025-04-10T07:12:31Z"
     }
     ```
     Becomes: `docs/comments/comment-2025-04-10-0712-2036663266.json`
     
     Example for review with:
     ```json
     {
       "id": 2755584987,
       "submitted_at": "2025-04-10T08:24:37Z"
     }
     ```
     Becomes: `docs/reviews/review-2025-04-10-0824-2755584987.json`
   
   - Validate data structures for each file

3. **Process Feedback**:
   - Combine and analyze both:
     - Individual PR comments
     - Review comments and suggestions
     - Review status (approved, changes requested, etc)
   - Group feedback by related scope/topic
   - Create task files in `tasks/` directory following naming convention:
     `tasks/{scope}-{action}-{target}.md`
     
     Examples based on actual PR feedback:
     ```
     tasks/prompt-use-consistent-name-method.md
     # From: "I like the overridable prompt_name method, we can use it here..."
     
     tasks/examples-add-to-demo-files.md
     # From: "Could you add this example to examples/server_with_stdio_transport.rb..."
     
     tasks/image-fix-content-format.md
     # From: "The specification expects a constant value of base64-encoded-image-data..."
     
     tasks/server-add-pagination-support.md
     # From: "We need to handle pagination and adapt the tools..."
     ```
   - Format each task with:
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
