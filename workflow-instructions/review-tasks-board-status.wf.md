# Review Tasks Board Status Workflow Instruction

## Goal

Review current task statuses, dependencies, and priorities within the active release. This workflow helps to
ensure tasks are progressing as expected, identify potential blockers early, and maintain alignment with overall
project goals. It also involves clarifying triggers for when this review is most beneficial and ensuring
terminology aligns with the [Project Management Guide](dev-handbook/guides/project-management.g.md).

## Prerequisites

- Familiarity with the [Project Management Guide](dev-handbook/guides/project-management.g.md), particularly task
 statuses, dependencies, and priorities.
- Task files within the active release (e.g., `dev-taskflow/current/{release_dir}/tasks/`) follow the standard
  Markdown format, including `status:`, `priority:`, and `dependencies:` fields in their frontmatter.
- Access to the project repository to run CLI tools.

## Process Steps

This workflow is typically triggered:

- At the beginning of a work session.
- Before planning new work within the current release.
- When assessing progress towards a release milestone.

The following steps and tools help in reviewing task statuses:

1. **View Current Task Overview:**
    - Run `bin/tr` (Task Report) to get a summary of tasks in the current release, including their ID, title,
      status, priority, and last update. This helps quickly identify what's `pending`, `in-progress`, `blocked`,
      or `done`.
    - Filter by time if needed (e.g., `bin/tr --last 3.days`) to see recent activity.

2. **Identify Next Actionable Task & Dependencies:**
    - Run `bin/tn` (Task Next) to find the next task that is `pending` and has all its `dependencies` met.
    - This helps in prioritizing and understanding immediate workflow. Review the dependencies listed for this
      task and others to foresee potential bottlenecks.

3. **Assess Overall Progress and Priorities:**
    - Review the output from `bin/tr` to understand the distribution of task statuses.
    - Cross-reference with task priorities (from frontmatter, visible via `cat` or by enhancing `bin/tr` if
      needed) to ensure high-priority items are being addressed.
    - Manually inspect task files (`cat dev-taskflow/current/{release_dir}/tasks/NN-task-name.md`) for any
      specific notes or complexities if `bin/tr` output indicates issues.

4. **(Optional) Contextual Review - Recent Changes:**
    - Run `bin/gl` (Git Log) to see recent commits if understanding recent code changes might provide context to
      task statuses (e.g., a task unexpectedly blocked).

5. **Synthesize & Document:**
    - Based on the review, update task statuses in their respective `.md` files if they have changed (e.g., from
      `pending` to `in-progress`).
    - Note any identified blockers, dependency issues, or priority adjustments.
    - Determine if any tasks require reprioritization or further breakdown.

## Example Usage

- At the start of a work session: Use `bin/tr` and `bin/tn` to quickly understand current task statuses and
  identify the immediate next step.
- During release planning: Use `bin/tr` to assess overall progress, check for `blocked` tasks, and verify
  `dependencies` for upcoming work.
- When a task seems stuck: Review its details, check `dependencies` using `bin/tn` logic (or manually), and use
  `bin/gl` if recent changes might be relevant.

These tools, combined with direct inspection of task files when needed, provide a comprehensive way to review and
manage task statuses effectively.

## Input

- User request to review current task statuses, dependencies, and priorities.

## Output / Success Criteria

- Current statuses (`pending`, `in-progress`, `done`, `blocked`, etc.) of tasks in the active release are
  clearly understood.
- Dependencies between tasks are reviewed, and any critical path or potential bottlenecks are identified.
- Task priorities are confirmed or adjusted based on the current situation.
- Any blockers preventing task progression are identified.
- Action items for resolving blockers or adjusting plans are noted.
- Terminology used aligns with the [Project Management Guide](dev-handbook/guides/project-management.g.md).

## Reference Documentation

- [Project Management Guide](dev-handbook/guides/project-management.g.md) (Defines task statuses, priorities, and overall
  project structure)
- Standard Task `.md` file format (as defined in `task-definition.g.md`)
- CLI tool documentation (if available separately, e.g., `bin/tr --help`, `bin/tn --help`)

## Usage Example

Invoke this workflow instruction (as detailed in "Process Steps" triggers):

- To get a clear picture of current task statuses.
- To ensure priorities are aligned and dependencies are managed.
- To identify and address any impediments to task completion.

Example Invocation:
> "Run the `review-tasks-board-status` workflow instruction to check on our tasks."
