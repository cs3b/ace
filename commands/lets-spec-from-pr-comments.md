<!-- Read the project management guide first: docs-dev/project/README.md -->
# PR Comments to Specification Command

This command processes GitHub pull request comments into organized specifications and tasks, using command-line tools for data fetching.

## Process Steps

1. **Establish Current Version and Release Path**:
   - Check the project's current version by examining:
     - Project configuration files in root directory (e.g., `package.json`, `Gemfile`, etc.)
     - Dedicated version files (e.g., `VERSION`, `lib/version.rb`)
     - Git tags or release notes
   - Use the existing release path created by the fetch command, following this pattern:
     `docs-dev/project/current/v{version}-feedback-to-pr-{number}/`
   - If the release path doesn't exist yet, create it following the same convention:
     - Use current version + next patch version (e.g., v1.0.0 → v1.0.1)
     - Append `-feedback-to-pr-{number}` where number is the PR number
     - Example: `docs-dev/project/current/v1.0.1-feedback-to-pr-21/`
   - This release path will be used for all further operations in this and subsequent commands

2. **Prepare Environment**:
- First READ the files at `docs-dev/commands/lets-spec-from-pr/fetch-comments-by-api.md` and run the instructions from one of these files, before proceeding further
   - Ensure PR data is downloaded in the expected location:
     ```
     {release_path}/
     └── docs/
         └── {pr_path}/
             ├── comments/
             ├── reviews/
             └── pr/
     ```

3. **Create Tasks**:
- Scan all files (except raw directory) in the timestamped folder created by the tool:
  - Individual PR comments from `docs/{pr_path}/comments/*.json`
  - Review comments and suggestions from `docs/{pr_path}/reviews/*.json`
  - Review status (approved, changes requested, etc) from `docs/{pr_path}/pr/*.json`
- Group feedback by related scope/topic
- Create task files in `{release_path}/tasks/` directory following naming convention:
  `tasks/{scope}-{action}-{target}.md` where:
       - `{scope}` indicates the component or feature area (prompt, image, server)
       - `{action}` is the change type (add, fix, update, remove)
       - `{target}` describes what's being modified

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
   - Include references to PR comment IDs for traceability

5. **Order Tasks by Dependencies**:
   - Analyze each task's dependencies
   - Create dependency graph to determine execution order
   - Update task filenames to include sequence prefix: `{release_path}/tasks/{sequence}-{scope}-{action}-{target}.md`

   Example dependency order from PR feedback:
   ```
   tasks/01-prompt-use-consistent-name-method.md # Must be done first as other tasks depend on prompt_name
   tasks/02-image-fix-content-format.md          # Independent but simpler change
   tasks/03-examples-add-to-demo-files.md        # Depends on prompt_name changes
   tasks/04-server-add-pagination-support.md     # Larger change that should come last
   ```

   Each task file should include dependency metadata and comment references in frontmatter:
   ```md
   ---
   sequence: 01
   depends_on: []
   required_for:
     - 03-examples-add-to-demo-files
   comment_ids:
     - 1234567890  # ID of the GitHub comment that prompted this task
     - 1234567891  # Additional comment ID if multiple comments address the same issue
   ---
   # Use Consistent Prompt Name Method
   ...
   ```
   6. **Communicate Results**:
   - After processing is complete, inform the user about:
     - Total number of comments processed
     - Number of tasks created
     - Location of generated files
     - Next steps for implementation
     - Use tree command to show the final directory structure:
       ```bash
       tree {release_path} -L 2
       ```
       Example output:
       ```
       {release_path}/
       ├── docs
       │   └── {pr_path}
       ├── tasks
       │   ├── 01-prompt-use-consistent-name-method.md
       │   ├── 02-image-fix-content-format.md
       │   ├── 03-examples-add-to-demo-files.md
       │   └── 04-server-add-pagination-support.md
       └── README.md
       ```

## Success Criteria

- All feedback processed:
  - PR comments fully captured from data provided by the fetch command
  - PR reviews and their comments included in analysis
  - Review status considered when prioritizing tasks
  - Each task includes references to originating comment IDs for traceability
- Feedback grouped logically by topic
- Tasks properly scoped and prioritized
- Clear implementation plan created with README.md
- Dependencies identified and task sequence determined
- Review concerns addressed in task descriptions
- Complete directory structure created as specified

## Prerequisites

Before running this command:

1. Read the project management guide: `docs-dev/project/README.md`
2. Read one of the PR comment fetching guides: `docs-dev/commands/lets-spec-from-pr/fetch-comments-by-api.md` or `docs-dev/commands/lets-spec-from-pr/fetch-comments-by-mcp.md`
3. Understand the current project structure and workflows
4. Determine the current project version from appropriate files
5. Ensure you have appropriate GitHub permissions for API-based fetching
## Usage Example

```bash
# First, read the project management guide
cat docs-dev/project/README.md

# Check current version from appropriate files
cat VERSION # or
cat lib/version.rb # or
grep -A 3 "version" package.json

# Read the fetch command documentation first (choose one method)
cat docs-dev/commands/lets-spec-from-pr/fetch-comments-by-api.md
# or
cat docs-dev/commands/lets-spec-from-pr/fetch-comments-by-mcp.md

# Then fetch PR comments using your preferred method
fetch-comments-by-api https://github.com/org/repo/pull/123
# or
fetch-comments-by-mcp https://github.com/org/repo/pull/123

# Then process PR comments with:
lets-spec-from-pr-comments {release_path}/

# Agent creates:
docs-dev/project/current/v1.2.1-feedback-to-pr-21/  # Example path
├── docs/                                              # Data from fetch command
│   └── {pr_path}/
│       ├── comments/
│       ├── reviews/
│       └── pr/
├── tasks/                                             # Generated task files
│   ├── 01-prompt-use-consistent-name-method.md       # Core change affecting other tasks
│   ├── 02-image-fix-content-format.md                # Independent formatting fix
│   ├── 03-examples-add-to-demo-files.md              # Depends on prompt_name implementation
│   └── 04-server-add-pagination-support.md           # Complex change to come last
└── README.md                                          # Implementation overview
```
