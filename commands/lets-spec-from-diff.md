# Git Diff to Specification Command (lets-spec-from-diff)

This command processes a Git diff file (or direct Git command output) to generate structured analysis and actionable tasks. It follows an "Outside-In" approach, first analyzing high-level interfaces and designs before examining implementation details.

## Goal
Transform Git diff content into a comprehensive analysis with prioritized, actionable tasks that follow the unified task management system. This helps in understanding changes, identifying improvements, and creating a structured implementation plan.

## Process Steps

1. **Input Preparation**:
   - Accept git diff source (file path, git command, or commit range)
   - Determine target release directory:
     ```bash
     # Default: use active release in docs-project/current/
     # Option: specify target release
     lets-spec-from-diff changes.diff --release-path docs-project/current/v1.2.0-hotfix/
     ```
   - Create standard directory structure:
     ```
     {release_path}/
     ├── backlog/
     │   ├── high-level/      # Interface/design analysis
     │   └── technical/       # Implementation details analysis
     ├── tasks/               # Generated tasks
     └── README.md            # Release overview
     ```

2. **Diff Analysis**:
   - Parse changes by file and change type (additions, modifications, deletions)
   - Group related changes by component/module/feature
   - Apply "Outside-In" analysis approach:
     - First focus on interfaces, DSLs, examples, and high-level tests
     - Then examine implementation details and flows
   - Tag changes by type:
     - API/interface changes
     - Implementation details
     - Tests/documentation
     - Dependencies/configuration

3. **Generate Layered Feedback**:
   - **High-Level Analysis** (`backlog/high-level/{component}-analysis.md`):
     ```markdown
     # {Component} Interface Analysis

     ## Change Overview
     [Brief description of the changes]

     ## Interface/API Impacts
     - [API change 1]
     - [API change 2]

     ## Design Considerations
     - [Design pattern impact]
     - [Architecture concerns]

     ## Alternatives
     - [Alternative approach 1]
     - [Alternative approach 2]
     ```

   - **Technical Analysis** (`backlog/technical/{component}-details.md`):
     ```markdown
     # {Component} Technical Analysis

     ## Implementation Details

     ### [File path:line range]
     ```diff
     [Code snippet]
     ```

     **Observations:**
     - [Technical observation]
     - [Potential issue]

     **Call to Action:**
     - [What needs to be changed]
     - [How it should be implemented]
     - [Affected file paths with line numbers]

     **Improvement Options:**
     - [Option 1 with pros/cons]
     - [Option 2 with pros/cons]
     ```

4. **Task Generation**:
   - Group feedback by common intentions/challenges
   - For each logical group of changes/feedback:
     - Create structured task file in `tasks/` directory
     - Use naming convention: `{sequence}-{scope}-{action}-{target}.md`
     - Include standard frontmatter:
       ```yaml
       ---
       id: {sequence}
       status: pending
       priority: [high|medium|low]
       dependencies: []
       diff_files: ["file1.ext", "file2.ext"]
       ---
       ```
     - Structure task content:
       ```markdown
       # Task Title: [Clear action-oriented title]

       ## Description
       [Task objective based on diff analysis]

       ## Implementation Details / Notes
       - [Technical guidance from detailed feedback]
       - [Specific approaches to consider]
       - [Link to feedback documents]
       - [Specific file paths and line numbers to change]

       ## Acceptance Criteria / Test Strategy
       - [ ] [Specific verification step]
       - [ ] [Test to create or update]
       - [ ] [Quality check]
       ```
   - Order tasks logically, considering dependencies
   - Update release README.md with task summary

5. **Results Summary**:
   - Report analysis statistics:
     - Files analyzed
     - Changes processed
     - Feedback documents created
     - Tasks generated
   - Recommend next steps

## Success Criteria

- **Complete Coverage**: All significant changes in diff are analyzed
- **Outside-In Approach**: Interface and design analysis precedes implementation details
- **Clear Organization**: Changes grouped by logical components and intentions
- **Dual-Layer Analysis**: Both high-level and technical feedback provided
- **Actionable Tasks**: Concrete tasks created with clear acceptance criteria and specific file references
- **Multiple Solution Options**: Each technical feedback includes different approaches with trade-offs
- **Traceable References**: Tasks link back to specific feedback and diff sections
- **Integration**: Tasks follow the project's standard format and organization

## Usage Example

```bash
# Basic usage with diff file
lets-spec-from-diff changes.diff

# Direct git command
lets-spec-from-diff "git diff main feature/auth-refactor"

# Commit range
lets-spec-from-diff "git diff HEAD~3 HEAD"

# Agent produces:
docs-project/current/v1.2.0-hotfix/
├── backlog/
│   ├── high-level/
│   │   └── auth-service-analysis.md
│   └── technical/
│       └── auth-service-details.md
├── tasks/
│   ├── 01-auth-refactor-token-validation.md
│   ├── 02-auth-add-error-handling.md
│   └── 03-auth-update-tests.md
└── README.md  # Updated with task summary
```

## Implementation Notes

### Diff Parsing Strategy

For optimal diff analysis:

1. **First Pass - Component Identification**:
   - Group files by directory structure or naming patterns
   - Identify common prefixes/namespaces
   - Detect related changes across multiple files

2. **Second Pass - Functional Analysis**:
   - Analyze interface changes (method signatures, class definitions)
   - Extract test changes to understand intended behavior
   - Identify configuration/dependency changes

3. **Third Pass - Implementation Details**:
   - Examine internal logic changes
   - Look for patterns across similar changes
   - Detect potential issues (error handling, edge cases)

### Integration with Other Commands

This command complements:
- `lets-spec-from-pr-comments`: Similar structure but different input source
- `lets-spec-from-release-backlog`: Uses the same task generation format
- `self-reflect`: Can be used after analysis to capture additional insights

## Common Usage Patterns

1. **Reviewing Pull Requests**: Analyze changes before merging
2. **Examining Legacy Code**: Understand existing codebase structure
3. **Preparing Refactoring**: Identify patterns and pain points
4. **Pre-Implementation Planning**: Convert design changes to concrete tasks