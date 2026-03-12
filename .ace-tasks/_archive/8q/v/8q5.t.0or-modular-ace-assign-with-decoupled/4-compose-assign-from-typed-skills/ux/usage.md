# Assign-Capable Skill Composition - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Inspect the assign-capable catalog

**Goal**: See phases derived from canonical workflow/orchestration skills instead of provider trees or phase YAML authority.

```bash
ace-assign catalog

# Expected output:
# Available phases reflect canonical workflow/orchestration skills with assign metadata.
```

### Scenario 2: Compose from the assign-capable subset

**Goal**: Build an assignment from canonical typed skills while excluding capability skills.

```bash
/as-assign-compose "plan task 123 and then start the assignment"

# Expected output:
# The proposed assignment uses workflow/orchestration skills
# Capability skills like as-b36ts do not appear in the phase list
```

### Scenario 3: Create assignment via canonical subset

**Goal**: Ensure public create UX still works while sourcing phases from canonical assign-capable skills.

```bash
/as-assign-create "work on task 123 and create a PR"

# Expected output:
# Assignment creates successfully through the same public command.
# Hidden spec remains deterministic input for `ace-assign create FILE`.
# Capability-only skills are excluded from phase selection.
```

### Scenario 4: Drive compatibility wrapper

**Goal**: Verify orchestration wrapper still delegates to canonical create/drive flow.

```bash
/as-assign-start "plan task 123 and then start the assignment" --run

# Expected output:
# Start delegates to assign/create then assign/drive.
# Runtime behavior remains deterministic (`ace-assign create FILE` boundary preserved).
```
