# Phase 2: Session Management (ace-coworker)

## Goal

Manage multiple sessions within a single directory (worktree or main repo), with clean isolation between them.

## Scope

**In scope:**
- Session creation with unique ID (ace-timestamp)
- Session listing and status
- Session-scoped state files
- Auto-resume when starting with same task
- Multiple concurrent sessions per directory

**Out of scope (future ace-overseer):**
- Worktree creation/management
- Multi-directory orchestration
- Spawning new coworker instances

## Session Model

Each session lives in `.cache/ace-coworker/{session-id}/`:

```
.cache/ace-coworker/
├── 8or5kx/              # Session for task 228
│   ├── job.json
│   ├── log.jsonl
│   └── reports/
├── 8or7ab/              # Session for task 229
│   ├── job.json
│   ├── log.jsonl
│   └── reports/
└── 8or9cd/              # Another session for task 228 (different workflow)
    ├── job.json
    ├── log.jsonl
    └── reports/
```

## Session ID

Uses ace-timestamp format (e.g., `8or5kx`) - compact, sortable, unique.

## CLI Commands

```bash
# Start new session (or resume existing for same task)
ace-coworker start --task 228 --workflow task-completion
# → Creates 8or5kx if no session exists for task 228
# → Resumes existing session if one exists

# List all sessions
ace-coworker list
# SESSION   TASK   WORKFLOW          STATUS    STEP      PROGRESS
# 8or5kx    228    task-completion   running   test      3/5
# 8or7ab    229    bug-fix           paused    review    2/4
# 8or9cd    228    release           complete  -         5/5

# Status of specific session
ace-coworker status --session 8or5kx

# Resume specific session
ace-coworker resume --session 8or5kx

# Status of current/latest session
ace-coworker status
```

## Auto-Resume Logic

When `ace-coworker start --task 228` is called:

1. Scan `.cache/ace-coworker/*/job.json`
2. Find sessions where `task == 228` and `status != completed`
3. If found: resume that session
4. If not found: create new session

This prevents accidental duplicate sessions for the same task.

## Session Lifecycle

```
[start] → CREATED → RUNNING → PAUSED → COMPLETED
                        ↓         ↑
                    FAILED ───────┘ (resume)
```

States:
- **CREATED**: Session initialized, workflow not started
- **RUNNING**: Workflow executing
- **PAUSED**: At human gate, waiting for input
- **FAILED**: Step failed, awaiting retry/resume
- **COMPLETED**: Workflow finished successfully

## Session Discovery

Sessions are discovered by scanning the filesystem:

```ruby
def list_sessions
  Dir.glob(".cache/ace-coworker/*/job.json").map do |path|
    JSON.parse(File.read(path))
  end
end
```

No central registry needed - the filesystem is the source of truth.

## Cleanup

Sessions live in `.cache/` which is:
- Gitignored (not committed)
- Deleted when worktree is removed
- Can be manually cleaned with `rm -rf .cache/ace-coworker/`

No automatic TTL for MVP. Sessions stay until manually removed or cache is cleared.

## Worktree Considerations

ace-coworker works in whatever directory it's run from:
- Main repo: `.cache/ace-coworker/` in repo root
- Worktree: `.cache/ace-coworker/` in worktree root

Each worktree has its own independent sessions.

**Creating worktrees is manual** (or future ace-overseer responsibility):

```bash
# Manual worktree creation
ace-git-worktree create --task 228

# Then start coworker in that worktree
cd .ace/worktrees/task-228
ace-coworker start --task 228 --workflow task-completion
```

## Success Criteria

- [ ] Can list all sessions in current directory
- [ ] Can start session with unique ID
- [ ] Auto-resumes existing session for same task
- [ ] Session state isolated per session
- [ ] Multiple concurrent sessions work correctly
- [ ] Cleanup happens with cache/worktree removal
