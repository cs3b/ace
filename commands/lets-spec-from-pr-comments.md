# PR Comments to Specification Command

This command processes GitHub pull request comments into organized specifications and tasks.

## Process Steps

1. **Initialize**:
   - Accept PR URL as input
   - Create new release directory: `feedback-to-<PR-number>/`
   - Set up release subdirectories:
     ```
     feedback-to-<PR-number>-<sequence>/
     ├── docs/         # Raw feedback and analysis
     ├── tasks/        # Grouped implementation tasks
     └── README.md     # Release overview

Example:
     feedback-to-123-001/    # First feedback task for PR 123
     feedback-to-123-002/    # Second feedback task for PR 123
     ```

2. **Gather Feedback**:
   - Use GitHub MCP server to fetch PR comments
   - Store raw response in `docs/pr-comments.json`
   - Validate comment data structure

3. **Process Comments**:
   - Group comments by related scope/topic
   - Create task files in `tasks/` directory
   - Format tasks with:
     - Clear title and description
     - Implementation notes
     - Acceptance criteria
     - Related files/references

4. **Generate Release Document**:
   - Create overview in README.md
   - Summarize changes needed
   - Group tasks by priority/impact
   - Document dependencies

## Success Criteria

- All PR comments processed
- Comments grouped logically
- Tasks properly scoped
- Clear implementation plan
- Dependencies identified

## Usage Example

```bash
# Process PR comments with:
lets-spec-from-pr-comments https://github.com/org/repo/pull/123

# Creates new release:
feedback-to-123/
├── docs/
│   └── pr-comments.json    # Raw GitHub API response
├── tasks/
│   ├── task-001.md        # Grouped feedback tasks
│   └── task-002.md
└── README.md              # Implementation overview
```