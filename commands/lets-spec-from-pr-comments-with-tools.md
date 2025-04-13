# PR Comments to Specification Command (Tool-Assisted)

This command processes GitHub pull request comments into organized specifications and tasks, using command-line tools for data fetching.

## Process Steps

1. **Initialize and Fetch Data**:
   - Accept PR URL as input and parse owner/repo/number
   - Create new version bump (e.g.: v1.0.1-feedback-to-pr-21)
   - Create new version directory: `docs-dev/project/current/v1.0.1-feedback-to-pr-21/`
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

2. **Process Raw Data Files**:
   - Tool has prepared JSON files in timestamped directory
   - Process these files to create individual feedback files in structured directories:
   ```
   docs/
   ├── comments/                                      # Individual PR comments
   │   ├── comment-{created_at}-{id}.json            # Each comment in separate file
   │   └── ...                                       # Naming format: comment-YYYY-MM-DD-HHMM-{id}.json
   ├── reviews/                                      # PR review comments
   │   ├── review-{submitted_at}-{id}.json          # Each review in separate file
   │   └── ...                                      # Naming format: review-YYYY-MM-DD-HHMM-{id}.json
   └── pr/                                          # PR metadata
       └── pr.json                                  # Basic PR information
   ```
   - Each comment/review file contains:
     - Original timestamp
     - Author information
     - Comment/review content
     - Context (file, line numbers if applicable)

3. **Process Feedback**:
   - Combine and analyze both:
     - Individual PR comments from `docs/comments/`
     - Review comments and suggestions from `docs/reviews/`
     - Review status (approved, changes requested, etc) from `docs/pr/pr.json`
   - Group feedback by related scope/topic
   - Create task files in `tasks/` directory following naming convention:
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

5. **Order Tasks by Dependencies**:
   - Analyze each task's dependencies
   - Create dependency graph to determine execution order
   - Update task filenames to include sequence prefix: `tasks/{sequence}-{scope}-{action}-{target}.md`

   Example dependency order from PR feedback:
   ```
   tasks/01-prompt-use-consistent-name-method.md # Must be done first as other tasks depend on prompt_name
   tasks/02-image-fix-content-format.md          # Independent but simpler change
   tasks/03-examples-add-to-demo-files.md        # Depends on prompt_name changes
   tasks/04-server-add-pagination-support.md     # Larger change that should come last
   ```

   Each task file should include dependency metadata in frontmatter:
   ```md
   ---
   sequence: 01
   depends_on: []
   required_for:
     - 03-examples-add-to-demo-files
   ---
   # Use Consistent Prompt Name Method
   ...
   ```

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
lets-spec-from-pr-comments-with-tools https://github.com/org/repo/pull/123

# Creates complete directory structure:
docs-dev/project/current/v1.0.1-feedback-to-pr-21/
├── docs/
│   ├── comments/                                          # Individual PR comments
│   │   ├── comment-2025-04-10-0712-2036663266.json       # Tool name feedback
│   │   ├── comment-2025-04-10-0715-2036668671.json       # Version bump request
│   │   └── comment-2025-04-10-0719-2036678438.json       # Pagination feedback
│   ├── reviews/                                           # PR review comments
│   │   └── review-2025-04-10-0824-2755584987.json        # Main review feedback
│   └── pr/                                                # PR metadata
│       └── pr.json                                        # Basic PR information
├── tasks/                                                 # Generated task files
│   ├── 01-prompt-use-consistent-name-method.md           # Core change affecting other tasks
│   ├── 02-image-fix-content-format.md                    # Independent formatting fix
│   ├── 03-examples-add-to-demo-files.md                  # Depends on prompt_name implementation
│   └── 04-server-add-pagination-support.md               # Complex change to come last
└── README.md                                              # Implementation overview
```
