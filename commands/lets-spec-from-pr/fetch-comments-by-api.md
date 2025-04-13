# Fetch PR Comments by API Command

This command uses command-line tools to fetch pull request comments and reviews.

## Process Steps

1. **Initialize and Fetch Data**:
   - Accept PR URL as input and parse owner/repo/number
   - Use the existing release path if one was provided or previously created
   - If no release path exists yet:
     - Determine current project version from appropriate files (e.g., `package.json`, `VERSION`, `lib/version.rb`)
     - Create new version bump based on current version (use next patch version using semver)
     - Create release path: `docs-dev/project/current/v{version}-feedback-to-pr-{number}/`
     - Example: `docs-dev/project/current/v1.0.1-feedback-to-pr-21/`
   - Call data fetching tool:
     ```bash
     ruby docs-dev/tools/get-github-pr-data.rb \
       --owner {owner} \
       --repo {repo} \
       --pr {number} \
       --dir docs-dev/project/current/v1.0.1-feedback-to-pr-21/
     ```
   - Tool will create timestamped directory with JSON files:
     ```
     docs/
     └── pr-21-20240410-071231/
         ├── pr.json       # PR details
         ├── reviews.json  # Reviews with their comments
         └── comments.json # PR comments
     ```
     - You can find the exact directory path created by the tool using:
       ```bash
       tree docs-dev/project/current/v1.0.1-feedback-to-pr-21/docs -I raw
       ```
       
       This will show the directory structure similar to:
       ```
       docs-dev/project/current/v1.0.1-feedback-to-pr-21/docs
       └── pr-21-20250413-183459
           ├── comments
           │   ├── comment-2025-04-10-0712-2036663266.json
           │   ├── comment-2025-04-10-0715-2036668671.json
           │   ├── comment-2025-04-10-0717-2036670764.json
           │   └── ... (more comment files)
           ├── pr
           │   └── pr-2025-04-01-0134-2430243692.json
           └── reviews
               └── review-2025-04-10-0824-2755584987.json
       ```

   - Before proceeding with analysis, use the tree command to verify the exact location of PR data:
     ```bash
     tree docs-dev/project/current/v1.0.1-feedback-to-pr-21/docs -I raw
     ```

2. **Process Individual Files**:
   - The tool has already prepared JSON files in separate directories:
   ```
   docs-dev/project/current/v1.0.1-feedback-to-pr-21/docs/pr-21-20250413-183459/
   ├── comments/                                      # Individual PR comments
   │   ├── comment-2025-04-10-0712-2036663266.json   # Each comment in separate file
   │   └── ...                                        
   ├── reviews/                                       # PR review comments
   │   ├── review-2025-04-10-0824-2755584987.json    # Each review in separate file
   │   └── ...                                        
   └── pr/                                            # PR metadata
       └── pr-2025-04-01-0134-2430243692.json        # Basic PR information
   ```
   - Each comment/review file contains:
     - Original timestamp
     - Author information
     - Comment/review content
     - Context (file, line numbers if applicable)

## Success Criteria

- PR URL correctly parsed into owner, repo, and number
- Tool successfully executed and data fetched
- Directory structure created as expected
- All PR comments, reviews and metadata properly stored in JSON files

## Usage Example

```bash
# Fetch PR comments with:
fetch-pr-comments-by-api https://github.com/org/repo/pull/123

# Tool creates:
docs-dev/project/current/v1.0.1-feedback-to-pr-21/docs/pr-21-20250413-183459/
├── comments/                                      # Individual PR comments
│   ├── comment-2025-04-10-0712-2036663266.json   # Tool name feedback
│   ├── comment-2025-04-10-0715-2036668671.json   # Version bump request
│   └── comment-2025-04-10-0719-2036678438.json   # Pagination feedback
├── reviews/                                       # PR review comments
│   └── review-2025-04-10-0824-2755584987.json    # Main review feedback
├── pr/                                            # PR metadata
│   └── pr-2025-04-01-0134-2430243692.json        # Basic PR information
└── raw/                                           # Raw JSON data
    ├── comments.json
    ├── reviews.json
    └── pr.json
```