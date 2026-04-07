# Assignment Skill-First Migration - Draft Usage

## API Surface

- [ ] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Compose a skill-backed assignment step

**Goal**: An agent or maintainer composes an assignment by discovering canonical skills instead of duplicated YAML step definitions.

`/as-assign-compose "work on task 123 and create a PR"`

#### Expected Output

The composed assignment resolves `work-on-task` and `create-pr` from canonical skill metadata, applies recipe/rule policy from `ace-assign`, and leaves runtime subtree expansion to the bound workflows.

### Scenario 2: Execute a workflow-bound assignment step

**Goal**: `ace-assign` binds a discovered skill to its workflow and expands runtime sub-steps from workflow frontmatter.

`ace-assign create .ace-local/assign/jobs/example.yml`

#### Expected Output

When a step references `source: skill://as-task-work`, `ace-assign` resolves execution through `skill.execution.workflow`, reads runtime `assign.sub-steps` from the workflow, and materializes the expected subtree deterministically.

### Scenario 3: Execute a fallback-only direct capability skill with no workflow binding

**Goal**: `ace-assign` can compose and execute a capability skill directly when it has no workflow binding and no `assign:` metadata, using only fallback name/description matching instead of explicit skill-side composition metadata.

`ace-assign create .ace-local/assign/jobs/direct-skill.yml`

#### Expected Output

When a step references `source: skill://external-review`, `ace-assign` renders the skill body directly when `skill.kind: capability`, without requiring a duplicated workflow reference or workflow-level `assign:` frontmatter.

### Scenario 4: Internal helper or explicit workflow step (`wfi://` is internal-only)

**Goal**: A non-user-invocable helper step such as `task-load`, or an explicitly authored `wfi://...` step, remains executable without turning workflows into a second public discovery surface.

`/as-assign-compose "work on task 123"`

#### Expected Output

The resulting assignment can include helper behavior via internal skills/workflows, or explicit `wfi://...` references, without requiring a duplicated public step YAML definition or workflow discovery inventory.

## Notes for Implementer

Full usage documentation to be completed during work-on-task using `wfi://docs/update-usage`.
