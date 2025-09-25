# Idea

---
title: Implement Task Dependency Management in ace-taskflow
filename_suggestion: feat-taskflow-task-dependencies
enhanced_at: 2025-09-25 00:48:14
location: active
llm_model: gflash
---

## Problem
Currently, `ace-taskflow` manages individual tasks, but there's no explicit mechanism to define relationships or dependencies between them. This limitation makes it challenging to manage complex projects where tasks have prerequisites, leading to potential out-of-order execution, blocked progress, and a lack of clear critical paths for both human developers and autonomous AI agents. Without dependency tracking, agents must infer task order, which can be error-prone and inefficient.

## Solution
Implement a robust task dependency management system within the `ace-taskflow` gem. This system will allow users and AI agents to define 'depends-on' relationships between tasks. `ace-taskflow` will then leverage this information to:
1.  Prevent tasks from transitioning to 'in progress' or 'done' status if their dependencies are not yet met.
2.  Provide clear, deterministic output indicating why a task is blocked and by which dependencies.
3.  Offer topological sorting of task lists to suggest the next actionable tasks.
4.  Enhance `ace-taskflow task show <id>` output to include a task's dependencies and their current statuses.

## Implementation Approach
This feature will be developed within the `ace-taskflow` gem, adhering to the ATOM architecture pattern:
-   **Models:** The `Task` model (likely `ace-taskflow/lib/ace/taskflow/models/task.rb`) will be extended to include attributes for `dependencies` (e.g., an array of `task_id`s) and `blocked_by` (an array of `task_id`s).
-   **Atoms/Molecules:**
    -   `DependencyValidator`: An atom/molecule to check for circular dependencies and ensure that all referenced task IDs are valid and exist.
    -   `DependencyResolver`: A molecule responsible for determining a task's readiness based on the statuses of its dependencies.
    -   `TaskGraphGenerator`: A molecule to construct and traverse the task dependency graph.
-   **Organisms:**
    -   An `Ace::Taskflow::Organisms::TaskManager` (or similar) will orchestrate the dependency checks during task status updates and queries.
    -   New CLI commands will be introduced to manage dependencies:
        -   `ace-taskflow task add-dependency <task_id> --depends-on <other_task_id>`
        -   `ace-taskflow task remove-dependency <task_id> --depends-on <other_task_id>`
        -   `ace-taskflow task show <task_id> --dependencies` to display the full dependency tree/status.
        -   `ace-taskflow tasks --ready` to list all tasks whose dependencies are met and are therefore actionable.
-   **Deterministic Output:** All CLI commands interacting with dependencies will provide structured, parseable output (e.g., JSON) to facilitate autonomous agent interaction.

## Considerations
-   **Integration:** Ensure seamless integration with existing `ace-taskflow` commands (`task create`, `task update`, `task show`, `tasks`).
-   **Circular Dependencies:** The system must robustly detect and prevent circular dependencies, providing clear error messages to the user/agent.
-   **Status Propagation:** Define how dependency statuses (e.g., 'pending', 'in progress', 'done', 'failed') affect the status of dependent tasks (e.g., 'blocked', 'ready').
-   **CLI Interface Design:** Design an intuitive CLI for human users while prioritizing machine-readability for AI agents.
-   **Configuration Cascade:** Explore if any dependency-related behaviors or default settings could be managed via the `.ace/` configuration cascade.
-   **Workflow Updates:** Update relevant `ace-taskflow` workflow instructions (`.wf.md` files) to guide AI agents on how to leverage and manage task dependencies effectively.

## Benefits
-   **Enhanced AI Autonomy:** AI agents can reliably determine the next actionable task, avoiding premature execution of dependent tasks and improving decision-making for complex workflows.
-   **Improved Project Visibility:** Provides a clearer understanding of project progress, critical paths, and bottlenecks for both human developers and AI.
-   **Reduced Errors:** Minimizes the risk of out-of-order task execution, leading to more stable and predictable development cycles.
-   **Streamlined Workflows:** Enables the definition and execution of more complex and robust workflows directly within `ace-taskflow`, aligning with the ACE vision of packaging development capabilities as modular gems.
-   **Deterministic Scheduling:** Offers a deterministic mechanism for agents to schedule and prioritize tasks based on their readiness and interdependencies.

---

## Original Idea

```
Add support for task dependencies in ace-taskflow
```

---
Captured: 2025-09-25 00:47:59