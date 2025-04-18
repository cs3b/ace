# Fetch PR Comments by API Workflow Instruction

## Goal
Fetch Pull Request details, comments, and reviews (including review comments) from GitHub using the API via the `docs-dev/tools/get-github-pr-data.rb` script, and store them in a structured format within a specified release path.

## Prerequisites
- Ruby environment installed to run the script.
- Required gems (`json`, `net/http`, `uri`, `dotenv`, `optparse`, `fileutils`, `time`) installed.
- A `.env` file in `docs-dev/tools/` containing a valid `GITHUB_TOKEN`.
- A target release directory path provided or determined.
- A valid GitHub Pull Request URL.

## Input
- GitHub Pull Request URL (e.g., `https://github.com/owner/repo/pull/123`).
- Target release directory path (e.g., `docs-project/current/v1.0.1-feedback-to-pr-123/`).
# Fetch PR Comments by API Workflow Instruction

This workflow instruction uses command-line tools to fetch pull request comments and reviews.

## Process Steps

1. **Initialize and Fetch Data**:
   - Accept PR URL as input and parse owner/repo/number
   - Use the existing release path if one was provided or previously created
   - If no release path exists yet - ask for it
   - Call data fetching tool:
     ```bash
     ruby docs-dev/tools/get-github-pr-data.rb \
       --owner {owner} \
       --repo {repo} \
       --pr {number} \
       --dir {release_path}
     ```
   - Tool will create timestamped directory with JSON files:
     ```
     docs/
     └── {pr_path}
         ├── pr.json       # PR details
         ├── reviews.json  # Reviews with their comments
         └── comments.json # PR comments
     ```
     - You can find the exact directory path created by the tool using:
       ```bash
       tree {release_path}/docs -I raw
       ```

       This will show the directory structure similar to:
       ```
       docs-dev-workflow-instruction/{release_path}/docs
       └── {pr_path}
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
     tree {release_path}/docs -I raw
     ```

2. **Process Individual Files**:
   - The tool has already prepared JSON files in separate directories:
   ```
   docs-dev/{release_path}/docs/{pr_path}/
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

## Output / Success Criteria

**Output:**
- A timestamped subdirectory created within `{release_path}/docs/` (e.g., `pr-123-YYYYMMDD-HHMMSS/`).
- Inside the timestamped directory:
    - `raw/` subdirectory containing `pr.json`, `reviews.json`, `comments.json`.
    - `pr/` subdirectory containing individual PR details JSON.
    - `reviews/` subdirectory containing individual review JSON files.
    - `comments/` subdirectory containing individual comment JSON files (from PR and reviews).

**Success Criteria:**

- PR URL correctly parsed into owner, repo, and number
- Tool successfully executed and data fetched
- Directory structure created as expected
- All PR comments, reviews and metadata properly stored in JSON files

## Usage Example

```bash
# Fetch PR comments with:
fetch-pr-comments-by-api https://github.com/org/repo/pull/123

# Tool creates:
docs-project/current/v1.2.1-feedback-to-pr-21/docs/pr-21-20250413-183459/
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
    ## Reference Documentation
    - [Writing Workflow Instructions Guide](../../../guides/writing-workflow-instructions.md)
    - [`get-github-pr-data.rb` script](../../../tools/get-github-pr-data.rb)
    - [GitHub REST API Documentation](https://docs.github.com/en/rest/pulls)
```
