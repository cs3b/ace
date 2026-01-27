# Question: State Persistence Strategy

## The Problem
If the Overseer process crashes, the computer restarts, or the process pauses for human review, the state of the workflow must be preserved. We cannot rely on in-memory variables.

## Proposed Solution: `state.json`

Every active session maintains a `state.json` in its root (or `.ace-overseer/`).

### Schema Draft
```json
{
  "session_id": "task-123-abc",
  "task_id": "123",
  "current_phase": "EXECUTION",
  "status": "in_progress",
  "iteration": 2,
  "max_iterations": 5,
  "artifacts": {
    "spec": "path/to/spec.md",
    "plan": "path/to/plan.md"
  },
  "history": [
    {
      "timestamp": "2026-01-27T10:00:00Z",
      "phase": "PLANNING",
      "event": "started"
    },
    {
      "timestamp": "2026-01-27T10:05:00Z",
      "phase": "PLANNING",
      "event": "completed",
      "output": "spec.md generated"
    }
  ]
}
```

## Questions to Answer
1.  **Concurrency**: What if multiple processes try to write to state? (Likely not an issue if 1 Overseer per Worktree).
2.  **Recovery**: How does `ace-overseer resume` reconstruct the Ruby object graph from this JSON?
