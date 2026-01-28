# Question: State Persistence Model

## The Question

Where does workflow/session state live, and in what format?

## Context

Overseer needs to:
- Track current step in workflow
- Store step outcomes (success/failure)
- Persist across process restarts
- Support multiple concurrent sessions

## Options

### Option A: Single State File (Simplest)

```
.ace/overseer/state.json
```

One file, one session at a time.

**Pros:**
- Trivial to implement
- Easy to inspect/debug
- No session management needed

**Cons:**
- Only one workflow at a time
- No worktree isolation
- Conflicts if running multiple

### Option B: Session-Scoped State (In Worktree)

```
.ace/coworker/<session-id>/.ace/overseer/state.json
```

Each session has its own state in its worktree.

**Pros:**
- Natural isolation
- State travels with worktree
- Multiple concurrent sessions
- Git-friendly (can commit state)

**Cons:**
- Requires session/worktree management
- Finding "current" session needs convention

### Option C: Central Registry + Session State (Hybrid)

```
.ace/overseer/
├── index.json           # List of all sessions
└── sessions/
    └── <id>/state.json  # Per-session state
```

Central index with session-specific state.

**Pros:**
- Fast session listing
- No worktree dependency
- Clear structure

**Cons:**
- Sync issues (index vs reality)
- Doesn't travel with worktree
- Extra indirection

## Recommendation

**Phase 1: Option A** - Single state file. Get workflow execution working first.

**Phase 2: Option B** - Move to session-scoped when adding worktree support. State in worktree is natural and self-contained.

## Format: JSON vs YAML

JSON preferred for state:
- Faster parsing
- No edge cases (YAML multiline, etc.)
- Easy to read/write from any language
- State is data, not config

## Additional Considerations

- Concurrency: do we need file locking or a single-process guarantee?
- Schema versioning: how do we migrate `state.json` across releases?
- Resume mechanics: how does resume reconstruct in-memory state safely?

## Decision Status

- [x] Decided: **Hybrid approach** - `.cache/ace-overseer/{ace-timestamp}/state.json`. Each worktree (including main) has its own local cache. Session ID (ace-timestamp) allows multiple concurrent sessions per worktree. State is temporary/cache, not committed. JSON format.
