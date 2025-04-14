# ADR-001: Unified Task Management System

## Status
Proposed
Date: YYYY-MM-DD

## Context
The current `docs-dev` setup primarily uses a simple Kanban-style system (`docs-dev/project/{backlog,current,done}`). An experimental system (`docs-dev/project/task-manager`), inspired by Claude Task Master, was explored, containing scripts, rules, and feedback processing ideas. Valuable research (`task-master-ai-hlo.md`, `windsurf-tips.md`) was also conducted.

The goal is to avoid the confusion of multiple systems by formally establishing the simple Kanban structure as the primary one, while integrating the most valuable concepts learned from the experiment and research (like structured task files and direct PR feedback integration) into this unified system.

## Decision
We will adopt a single, unified task management system based on the `docs-dev/project/{backlog,current,done}` structure. Key enhancements will be integrated from the `task-manager` concepts:

1.  **Primary Structure:** `docs-dev/project/backlog/`, `docs-dev/project/current/`, `docs-dev/project/done/` will be the sole task state directories. The term "current" will be used consistently.
2.  **Structured Task Files:** Tasks within these directories (especially in `current/`) will be represented by Markdown files following a standardized template (similar to the `task-manager` format but simplified), including ID, title, status, description, dependencies, implementation details, and test strategy.
3.  **PR Feedback Integration:** The `lets-spec-from-pr-comments` command will be updated to directly parse fetched feedback (from `docs/{pr_path}/`) and create/update structured task files within the `docs-dev/project/current/` directory structure, including links back to the originating comment IDs.
4.  **Removal:** The experimental `docs-dev/project/task-manager` directory and its contents will be removed. Key concepts identified in research files (`task-master-ai-hlo.md`, `windsurf-tips.md`) will be integrated into the guides and task format where appropriate.
5.  **Command Alignment:** All relevant commands (`lets-start`, `_review-kanban-board`, `self-reflect`, etc.) will be updated to work exclusively with this unified system.

## Consequences

### Positive
- **Clarity:** Single source of truth for tasks, reducing confusion for human developers and AI agents.
- **Simplicity:** Easier to understand and manage workflow. Reduced maintenance overhead.
- **Consistency:** All commands and processes interact with the same task system.
- **Integration:** PR feedback processing is directly integrated into the main task flow.
- **Focus:** Leverages the simplicity of the directory-based Kanban while incorporating useful structure from Task Master.

### Negative
- **Loss of Advanced Features:** Some specific automation or analysis features from `task-manager` scripts (like `analyze-complexity`) might be lost unless explicitly reimplemented or adapted.
- **Migration Effort:** Existing tasks or data within `task-manager` might need manual migration if considered valuable.

### Neutral
- Shifts complexity from managing separate systems to potentially more complex task file structures within the unified system (mitigated by simplification).

## Alternatives Considered
- **Keep Both Systems:** Maintain both systems, defining specific use cases for each. Rejected due to high complexity and confusion.
- **Fully Adopt Task Master:** Replace the directory Kanban entirely with the `task-manager` system. Rejected as potentially overly complex for the project's core needs and deviates from the established simpler structure.
- **Develop Custom Tooling:** Build entirely new tooling. Rejected due to effort required.

## Related Decisions
- Relates to the overall goal of Release v0.2.0 to streamline the workflow.

## References
- Claude Task Master: https://github.com/eyaltoledano/claude-task-master
- Existing `docs-dev/project/` structure.
- Existing `docs-dev/project/task-manager/` structure.