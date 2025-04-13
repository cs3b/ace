<!-- Read the project management guide first: docs-dev/project/README.md -->
# PR Comments to Specification Command

This command processes GitHub pull request comments into organized specifications and tasks, using command-line tools for data fetching.

## Process Steps

1. **Prepare Environment**:
   - First use either `fetch-pr-comments-by-mcp` or `fetch-pr-comments-by-api` to fetch PR data
   - Ensure PR data is downloaded in the expected location:
     ```
     docs-dev/project/current/v1.0.1-feedback-to-pr-21/
     └── docs/
         └── pr-21-20250413-183459/
             ├── comments/
             ├── reviews/
             └── pr/
     ```

2. **Create Tasks**:
   - Scan all files (except raw directory) in the timestamped folder created by the tool:
     - Individual PR comments from `docs/pr-XX-YYYYMMDD-HHMMSS/comments/*.json`
     - Review comments and suggestions from `docs/pr-XX-YYYYMMDD-HHMMSS/reviews/*.json`
     - Review status (approved, changes requested, etc) from `docs/pr-XX-YYYYMMDD-HHMMSS/pr/*.json`
   - Group feedback by related scope/topic
   - Create task files in `docs-dev/project/current/v1.0.1-feedback-to-pr-21/tasks/` directory following naming convention:
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

3. **Generate Release Document**:
   - Create overview in README.md
   - Summarize changes needed
   - Group tasks by priority/impact
   - Document dependencies
   - Include references to PR comment IDs for traceability

4. **Order Tasks by Dependencies**:
   - Analyze each task's dependencies
   - Create dependency graph to determine execution order
   - Update task filenames to include sequence prefix: `docs-dev/project/current/v1.0.1-feedback-to-pr-21/tasks/{sequence}-{scope}-{action}-{target}.md`

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
5. **Communicate Results**:
   - After processing is complete, inform the user about:
     - Total number of comments processed
     - Number of tasks created
     - Location of generated files
     - Next steps for implementation
     - Use tree command to show the final directory structure:
       ```bash
       tree docs-dev/project/current/v1.0.1-feedback-to-pr-21/ -L 2
       ```
       Example output:
       ```
       docs-dev/project/current/v1.0.1-feedback-to-pr-21/
       ├── docs
       │   └── pr-21-20250413-183459
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
2. Understand the current project structure and workflows
3. Ensure you have appropriate GitHub permissions if using API-based fetching
## Usage Example

```bash
# First, read the project management guide
cat docs-dev/project/README.md

# Then fetch PR comments with either:
fetch-pr-comments-by-api https://github.com/org/repo/pull/123
# OR
fetch-pr-comments-by-mcp https://github.com/org/repo/pull/123

# Then process PR comments with:
lets-spec-from-pr-comments docs-dev/project/current/v1.0.1-feedback-to-pr-21/

# Agent creates:
docs-dev/project/current/v1.0.1-feedback-to-pr-21/
├── docs/                                              # Data from fetch command
│   └── pr-21-20250413-183459/
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
