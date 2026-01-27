# Phase 2: Session Management

## Goal

Manage isolated work sessions with worktrees, allowing multiple concurrent workflows.

## Dependency

Requires Phase 1 (Workflow Executor) to be functional.

## Scope

**In scope:**
- Session = worktree + state + workflow
- Create/list/destroy sessions
- Session naming and identification
- Worktree lifecycle (leverage `ace-git-worktree`)
- Session-scoped state files

**Out of scope (Phase 3):**
- Agent dispatch
- Worker interface standardization
- TUI dashboard
- Separate coworker component (optional future layer)

## Interface

```bash
# Create new session for a task
ace-overseer start --task 228 --workflow task-completion
# Creates: .ace/coworker/228-abc123/

# List active sessions
ace-overseer list
# ID          TASK   WORKFLOW          STEP      STATUS
# 228-abc123  228    task-completion   test      running
# 215-def456  215    bug-fix           review    waiting

# Switch to session (cd to worktree)
ace-overseer attach 228-abc123

# Destroy session (cleanup worktree)
ace-overseer destroy 228-abc123

# Resume workflow in current session
ace-overseer resume
```

## Session Directory Structure

```
.ace/coworker/
└── 228-abc123/                    # Session directory (worktree root)
    ├── .ace/
    │   └── overseer/
    │       ├── session.json       # Session metadata
    │       └── state.json         # Workflow state (from Phase 1)
    └── ... (worktree contents)
```

### session.json

```json
{
  "id": "228-abc123",
  "task": "228",
  "workflow": "task-completion",
  "created_at": "2026-01-27T20:00:00Z",
  "worktree_path": ".ace/coworker/228-abc123",
  "base_branch": "main",
  "work_branch": "task/228-implement-feature"
}
```

## Integration with ace-git-worktree

Leverage existing worktree management:

```ruby
# In ace-overseer
def create_session(task:, workflow:)
  # Use ace-git-worktree under the hood
  worktree = AceGitWorktree.create(
    path: ".ace/coworker/#{session_id}",
    branch: "task/#{task}-#{slug}",
    base: "main"
  )

  # Initialize session state
  initialize_session(worktree.path, task, workflow)
end
```

## Session Lifecycle

```
[start] → CREATED → RUNNING → PAUSED → COMPLETED
                        ↓         ↑
                    FAILED ───────┘ (resume)
                        ↓
                   ABANDONED
```

States:
- **CREATED**: Worktree exists, workflow not started
- **RUNNING**: Workflow executing
- **PAUSED**: At human gate, waiting for input
- **FAILED**: Step failed, awaiting retry/resume
- **COMPLETED**: Workflow finished successfully
- **ABANDONED**: Manually destroyed before completion

## Key Decisions Needed

- [ ] Session ID format (`task-random` vs `timestamp` vs `uuid`)
- [ ] Where to store session registry (`.ace/coworker/index.json`?)
- [ ] Cleanup policy for completed sessions
- [ ] How to handle orphaned worktrees (from crashed sessions)

## Implementation Notes

### Building on ace-git-worktree

Check what's already available:

```bash
ace-git-worktree --help
```

May need to add:
- List worktrees with metadata
- Worktree-to-session mapping

### Session Registry

Option A: Directory scan (implicit)
- List directories in `.ace/coworker/`
- Read `session.json` from each

Option B: Central index (explicit)
- `.ace/coworker/index.json` with all sessions
- Faster listing, but sync issues possible

Recommendation: **Option A** - simpler, self-healing

## Observability

Session listing should be derived from the filesystem and each session's `.ace/overseer/state.json` so status is
inspectable and recoverable after crashes.

## Success Criteria

- [ ] Can create session with worktree isolation
- [ ] Can list all active sessions
- [ ] Can attach to session (cd to worktree)
- [ ] Can destroy session (cleanup worktree)
- [ ] Session state persists in worktree
- [ ] Multiple concurrent sessions work correctly
