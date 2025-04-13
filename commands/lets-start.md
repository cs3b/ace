# Let's Start Command

This command helps initialize your development session with proper context.

## Process Steps

1. Load Environment:
   - Run the [Load Environment](./load-env.md) command first to establish project context

2. Test-Driven Development Approach:
   - Create tests for each feature before implementation
   - Run `bin/rspec` to verify test failures initially
   - Add implementation to make tests pass

3. Sprint Focus:
- Review current sprint tasks in `docs-dev/project/current/`
   - Identify dependencies and blocked items
   - Plan implementation order
   - Set up development environment for current task

## Success Criteria

1. Environment Ready:
   - Load Environment command completed successfully
   - Development tools configured
   - Test framework available
   - Working directory clean

2. Development Plan:
   - Current task selected and understood
   - Dependencies identified and resolved
   - Test approach planned
   - Implementation strategy defined

/
├── lib/             # Main source code
├── spec/            # Test files
└── docs-dev/        # Development documentation
    ├── guides/      # Development standards and practices
    ├── project/     # Project management and planning
    │   ├── backlog/    # Future planned work
    │   ├── current/    # Current sprint/milestone tasks
    │   └── done/       # Completed work
    └── commands/    # AI interaction command patterns

## Key Files

- `lib/aira.rb`: Main entry point for the SDK
- `lib/aira/version.rb`: Current SDK version
- `spec/spec_helper.rb`: Test configuration
- `docs-dev/project/what-do-we-build.md`: Project objectives
- `docs-dev/project/architecture.md`: System architecture

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
