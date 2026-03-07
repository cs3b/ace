# Hidden Spec Handoff - Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Smart create renders a hidden spec

**Goal**: Create an assignment without manually writing `job.yaml`.

```bash
/as-assign-create work-on-task --taskref 123

# Expected output:
# Assignment: work-on-task-123 (<id>)
# Created: .ace-local/assign/<id>/
# Created from hidden spec: .ace-local/assign/jobs/<timestamp>-work-on-task-123.yml
# Phase 010: ...
```

**Behavior contract:**
- Hidden spec is rendered under `.ace-local/assign/jobs/`.
- Runtime handoff remains deterministic through `ace-assign create FILE`.
- Assignment metadata retains hidden spec provenance path.

### Scenario 2: Creation failure stays deterministic

**Goal**: Preserve current CLI failure behavior if the rendered spec is invalid.

```bash
/as-assign-create work-on-task --taskref broken

# Expected output:
# Hidden-spec rendering or ace-assign create reports a concrete error
# No partial assignment is left active
```
