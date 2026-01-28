# Question: Scope and Boundaries

## The Question

Do we need three separate components (coworker/overseer/worker), or is this over-engineering?

## Context

The original spec proposes:
- `ace-coworker`: Session/environment manager
- `ace-overseer`: State machine/orchestrator
- `ace-worker`: Execution roles

But the field notes show agents already struggle with complexity. More components = more concepts to manage.

## Options

### Option A: Three Components (Original Proposal)

```
ace-coworker (TUI) → ace-overseer (state machine) → workers
```

**Pros:**
- Clean separation of concerns
- Each component is simple
- Matches "Brain/Hands/Office" metaphor

**Cons:**
- Three gems to maintain
- Complex interaction model
- Over-engineering for initial use case

### Option B: Single Component (ace-overseer does all)

```
ace-overseer (workflow + session + dispatch)
```

**Pros:**
- Simpler mental model
- One gem to install
- Faster to implement

**Cons:**
- May grow too large
- Harder to test in isolation
- Mixing concerns

### Option C: Two Components (Recommended)

```
ace-overseer (workflow + session) → workers (existing tools + agents)
```

**Pros:**
- Session and workflow are tightly coupled anyway
- Workers are already external (ace-test, claude, humans)
- No need for separate `ace-coworker` initially

**Cons:**
- May need to split later
- TUI becomes part of overseer (or separate optional package)

## Recommendation

**Start with Option C.**

`ace-overseer` handles both workflow execution and session management. Workers are external by nature - they're existing CLI tools and agents.

If TUI becomes important, extract `ace-coworker` later. YAGNI applies here.

## Decision Status

- [x] Decided: **Option C** - Two components. `ace-overseer` handles workflow + session. Workers are external. Create `ace-coworker` as backlog task for future TUI/multi-session needs.
