---
title: Implement Event-Driven Job Queue for Asynchronous Workflows
filename_suggestion: feat-scheduler-event-queue
enhanced_at: 2026-02-04 14:48:02.000000000 +00:00
llm_model: gflash
source: taskflow:v.0.9.0
id: 8p3m78
status: pending
tags: []
created_at: '2026-02-04 14:48:01'
---

# Implement Event-Driven Job Queue for Asynchronous Workflows

## Problem
ACE currently executes complex, multi-step workflows synchronously, blocking the developer's CLI session. For processes triggered by events—such as task completion, PR merging, or release initiation—this leads to slow command execution and increased risk of interruption, especially when involving long-running LLM operations (e.g., generating release notes via `ace-llm` or updating documentation via `ace-docs`). We lack a robust, inspectable mechanism to defer and manage these asynchronous jobs.

## Solution
Introduce a lightweight, file-based job queue and event architecture, likely implemented within the foundation of the planned `ace-scheduler` component (Task #255). This system will allow ACE tools (like `ace-taskflow` or `ace-git`) to emit structured events. Configured handlers will translate these events into queued jobs (CLI commands) that can be processed asynchronously via a dedicated CLI runner (`ace-scheduler run`).

This adheres to the **Transparent & Inspectable** principle by ensuring the job queue state is persistent, traceable, and manageable via CLI commands (`ace-scheduler status`, `ace-scheduler logs`).

## Implementation Approach
1. **Component:** Establish `ace-scheduler` (or integrate core logic into `ace-support-core` and `ace-taskflow`).
2. **Persistence:** Use a file-based queue (e.g., YAML or JSON files stored in `.ace/queue/`) to ensure persistence across sessions, aligning with the CLI-first, non-daemonized environment of ACE.
3. **ATOM Architecture:**
    * **Atoms:** `EventSerializer`, `JobQueueWriter` (handles atomic file writes).
    * **Molecules:** `QueueManager` (handles job lifecycle: enqueue, dequeue, mark complete/fail).
    * **Organisms:** `EventDispatcher` (in `ace-taskflow`) and `SchedulerRunner` (the main processing loop).
4. **Configuration Cascade (ADR-022):** Define event-to-job mappings in `.ace-defaults/scheduler/events.yml`, allowing project and user overrides. This configuration specifies which CLI commands are triggered by which events (e.g., `taskflow:task:approved` triggers `ace-docs update_release_notes`).
5. **CLI Interface:** Provide deterministic CLI tools for managing the queue:
    * `ace-scheduler run [--once]`
    * `ace-scheduler status`
    * `ace-scheduler logs <job_id>`

## Considerations
- **Concurrency Safety:** Since the environment is often single-user, initial implementation should focus on robust file locking to prevent race conditions if multiple `ace-scheduler run` instances are accidentally started.
- **Error Handling:** Jobs must capture command output and exit codes, supporting configurable retry policies before marking a job as failed.
- **Integration:** Ensure `ace-taskflow` is refactored to emit events upon state changes (e.g., task completion, task approval) rather than executing synchronous cleanup scripts.

## Benefits
- **Improved Responsiveness:** Developers experience instant feedback from task management commands, as heavy processing is deferred.
- **Reliability:** Long-running, resource-intensive tasks (especially LLM calls) are executed reliably in the background, isolated from the main CLI session.
- **Customizable Workflows:** The event-to-job mapping allows developers and projects to easily customize post-processing steps without modifying core gem code (Principle 4).
- **Agent Autonomy:** Agents can trigger complex, multi-step workflows via a single event emission, enhancing their ability to manage releases and documentation.

---

## Original Idea

```
ques and event based architecture - some jobs happens (are added to the que after events) - e.g.: we finish work on taksk, and work is approved - we run release and add few tasks to the reelase jobs to)
```