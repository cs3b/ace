# Fetch PR Comments by MCP Command

This command uses GitHub MCP server to fetch pull request comments and reviews.

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

## Success Criteria

- All PR comments successfully fetched and stored
- All PR reviews successfully fetched and stored
- Files correctly named according to convention
- Directory structure properly created

## Usage Example

```bash
# Fetch PR comments with:
fetch-pr-comments-by-mcp https://github.com/org/repo/pull/123

# Creates directory structure:
docs-dev/project/current/v1.0.1-feedback-to-pr-21/
├── docs/
│   ├── comments/
│   │   ├── comment-2025-04-10-0712-2036663266.json    # Tool name feedback
│   │   ├── comment-2025-04-10-0715-2036668671.json    # Version bump request
│   │   └── comment-2025-04-10-0719-2036678438.json    # Pagination feedback
│   └── reviews/
│       └── review-2025-04-10-0824-2755584987.json     # Main review feedback
└── README.md                                           # Empty release overview
```