# ace-handbook sync and project extension - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [x] Configuration (project handbook layout)

## Usage Scenarios

### Scenario 1: Sync after full install
**Goal**: Project canonical skills after the full ACE stack is installed.

```bash
ace-handbook sync
```

#### Expected Output

Sync output explains what was projected and whether the current inventory reflects the installed stack or a partial install state.

### Scenario 2: Add a project-specific workflow
**Goal**: Add project handbook content outside the ACE monorepo and have it discovered correctly.

```bash
ace-nav resolve wfi://handbook/manage-guides
```

#### Expected Output

Docs tell the user where project-specific workflow, guide, template, and skill files belong and how protocol URLs resolve in a normal project.

## Notes for Implementer

Full usage documentation to be completed during work-on-task using `wfi://docs/update-usage`.
