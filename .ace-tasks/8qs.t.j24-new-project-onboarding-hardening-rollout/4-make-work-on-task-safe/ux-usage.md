# work-on-task assignment safety - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [x] Configuration (registered `wfi://` sources)

## Usage Scenarios

### Scenario 1: Create assignment in a plain project
**Goal**: Create the default work-on-task assignment without hand-patching hidden release workflows.

```bash
ace-assign create --preset work-on-task --task 123
```

#### Expected Output

Assignment creation succeeds and any release-related steps resolve through shipped/default workflow behavior.

### Scenario 2: Project-level release workflow override
**Goal**: Use a project-registered `wfi://release/publish` source.

```bash
ace-bundle wfi://release/publish
```

#### Expected Output

The same project-level registration model is honored by both `ace-bundle` and `ace-assign`.

## Notes for Implementer

Full usage documentation to be completed during work-on-task using `wfi://docs/update-usage`.
