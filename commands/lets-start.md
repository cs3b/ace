# Let's Start Command

This command helps initialize your development session with proper context.

## Process Steps

1. Load Environment:
   - Run the [Load Environment](./load-env.md) command first to establish project context, including the current release directory in `docs-dev/project/current/`.

2. Identify and Select Task:
   - List tasks in the current release directory: `ls -la docs-dev/project/current/*/tasks/`
   - Review the task `.md` files (e.g., `cat docs-dev/project/current/*/tasks/02-*.md`). Pay attention to `status`, `priority`, and `dependencies`.
   - Choose the next task to work on (typically `pending` status, with met `dependencies`).

3. Understand Task Details:
   - Read the selected task's `.md` file carefully:
     - `# Task Title`
     - `## Description`
     - `## Implementation Details / Notes`
     - `## Acceptance Criteria / Test Strategy`
   - Ensure the goal, steps, and verification methods are clear.

4. Prepare Environment:
   - Set up your local development environment for the specific task.
   - Identify relevant code files based on the task description.

5. Plan Implementation (TDD Approach):
   - Outline the tests needed based on `Acceptance Criteria`.
   - Plan the implementation steps, considering `Implementation Details / Notes`.
   - Identify potential challenges or areas needing research.

## Success Criteria

1. Environment Ready:
   - Load Environment command completed successfully
   - Development tools configured
   - Test framework available
   - Working directory clean

2. Task Selected & Understood:
   - A specific task `.md` file from `docs-dev/project/current/*/tasks/` is chosen.
   - The task's description, implementation notes, and acceptance criteria are clear.
   - Dependencies (from frontmatter) are confirmed to be met.
   - A plan for testing and implementation is formulated.

/
├── lib/             # Main source code
├── spec/            # Test files
└── docs-dev/        # Development documentation
    ├── guides/      # Development standards and practices
    ├── project/     # Project Management (backlog/current/done release dirs)
    │   ├── backlog/
    │   ├── current/  # Active release directory is here
    │   └── done/
    ├── commands/    # AI interaction command patterns
    ├── decisions/   # Architecture Decision Records (ADRs)

## Key Files

- `spec/spec_helper.rb`: Test configuration
- `docs-dev/project/what-do-we-build.md`: Project objectives
- `docs-dev/project/architecture.md`: System architecture
- `lib/aira.rb`: Main entry point for the SDK
- `lib/aira/version.rb`: Current SDK version

## Success Criteria

1. Context Loaded:
   - Project objectives clear
   - Development philosophy understood
   - Current work identified

2. Environment Ready:
   - Code structure mapped and understood
   - Development tools configured
   - Test framework available
   - Working directory clean

3. Task Identified:
   - Current milestone clear
   - Current task selected
   - Dependencies understood
   - Implementation approach planned
