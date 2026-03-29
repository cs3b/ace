# Handbook cookbooks - Draft Usage

## API Surface

- [ ] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Discover available handbook cookbooks
**Goal**: Find canonical cookbook examples and load one by protocol.

```bash
ace-nav list 'cookbook://*'
ace-nav resolve cookbook://setup-starting-an-astro-project-with-ace
```

#### Expected Output

`ace-nav list` shows handbook-owned cookbook items, and `ace-nav resolve` returns the canonical Astro cookbook path without involving `ace-docs`.

### Scenario 2: Load cookbook authoring workflow
**Goal**: Start cookbook authoring from the handbook-owned workflow and not the retired `ace-docs` path.

```bash
ace-bundle wfi://handbook/manage-cookbooks
ace-bundle wfi://handbook/review-cookbooks
```

#### Expected Output

Both workflow bundles load successfully and describe cookbook authoring and review as `ace-handbook` responsibilities.

## Notes for Implementer

Full usage documentation to be completed during work-on-task using `wfi://docs/update-usage`.
