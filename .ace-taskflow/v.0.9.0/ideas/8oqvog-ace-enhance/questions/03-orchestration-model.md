# Question: Orchestration Model

## The Question

Does overseer push work to agents, or do agents pull their next task?

## Context

Two paradigms for orchestration:

1. **Push (Dispatcher)**: Overseer invokes workers, waits for result
2. **Pull (Work Queue)**: Workers ask "what's next?", overseer responds

## Options

### Option A: Push Model (Dispatcher)

```
Overseer                     Worker
    |                           |
    |--- invoke(step, ctx) ---->|
    |                           | (work)
    |<--- result(outcome) ------|
    |                           |
```

Overseer controls execution. Workers are passive.

**Pros:**
- Simple mental model
- Overseer has full control
- Easy to implement with `system()` calls
- Works with CLI tools naturally

**Cons:**
- Long-running workers block overseer
- Hard to handle worker crashes gracefully
- Agent context resets between invocations

### Option B: Pull Model (Work Queue)

```
Worker                       Overseer
    |                           |
    |--- get_next_step() ------>|
    |<--- step(action, ctx) ----|
    | (work)                    |
    |--- report(outcome) ------>|
    |                           |
```

Workers are active. Overseer is reactive.

**Pros:**
- Workers control their lifecycle
- Agents can maintain context
- Resilient to worker restarts
- Natural for "continue session" pattern

**Cons:**
- More complex protocol
- Overseer needs to be running (or workers need to persist reports)
- Two-way communication needed

### Option C: Hybrid (Push for CLI, Pull for Agents)

```
# CLI tools: pushed
- action: ace-test  # Overseer invokes directly

# Agents: pulled
- worker: claude-code  # Agent reads state, executes, reports
  prompt: "Fix failing tests"
```

**Pros:**
- Best of both worlds
- CLI tools stay simple
- Agents get context continuity
- Matches natural behavior

**Cons:**
- Two execution paths to implement
- Worker type determines behavior

## Recommendation

**Option C: Hybrid**

For `action:` steps → Push (direct invocation)
For `worker:` steps → Pull (agent reads state, reports back)

This matches reality:
- `ace-test` is a stateless CLI tool → invoke it
- Claude Code maintains session context → let it pull work

## Implementation Sketch

```ruby
case step.type
when :action
  # Push: invoke directly
  result = system(step.action)
  record_outcome(result)

when :worker
  # Pull: set pending step, wait for report
  set_pending_step(step)
  wait_for_report(timeout: step.timeout)
end
```

## Decision Status

- [x] Decided: **Option A (Push)** - Simpler for now. Overseer acts as a state machine that:
  - Has preconditions/checklist before each step
  - Can spawn parallel sub-agents when planned (e.g., tests)
  - Supports conditional repeats/loops
  - Uses hard validations (must pass) and soft validations (warnings)
  - Controls all flow; workers are passive executors
  - Some workers (Claude Code) can run async, but parallelism must be explicitly planned in workflow
