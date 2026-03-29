# ace-framework init bootstrap - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [x] Configuration (generated `.ace/` files)

## Usage Scenarios

### Scenario 1: Fresh project bootstrap
**Goal**: Initialize ACE config in a non-monorepo project and immediately load project context.

```bash
ace-framework init
ace-bundle project
```

#### Expected Output

`ace-framework init` copies valid generic config, and `ace-bundle project` succeeds without requiring manual preset repair.

### Scenario 2: Generated project preset is generic
**Goal**: Confirm the generated scaffold does not assume the ACE monorepo.

```bash
ace-framework init --force
```

#### Expected Output

Generated files contain generic project placeholders/TODOs and current CLI references such as `ace-task`, not monorepo-specific copy or retired `ace-taskflow` commands.

## Notes for Implementer

Full usage documentation to be completed during work-on-task using `wfi://docs/update-usage`.
