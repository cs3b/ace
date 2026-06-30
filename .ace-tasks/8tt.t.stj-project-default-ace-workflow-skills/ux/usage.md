# Default agents projection for ACE workflow skills

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Sync common workflows into the default agents provider

**Goal**: Give agents access to installed common ACE workflow skills after the modern default sync.

```bash
ace-handbook sync
```

### Expected Output

- The command writes the default provider projection under `.agents/skills/`.
- `.agents/skills/as-git-commit/SKILL.md` exists when `ace-git-commit` is installed.
- The projected `as-git-commit` skill keeps its workflow body and does not include the canonical `integration:` block.
- The project does not need `.codex/skills/` or local overrides for this workflow to be available.

### Scenario 2: Report a clean default projection in status

**Goal**: Show status that matches what default sync will actually maintain.

```bash
ace-handbook status
```

### Expected Output

- The `agents` row uses the same expected skill set as default sync.
- Common installed workflow skills such as `as-git-commit` are not reported as extras merely because their canonical metadata came from the legacy provider target set.
- A clean sync followed by status reports no missing, outdated, or extra entries for the expected default projection.

### Scenario 3: Preserve explicit provider sync

**Goal**: Keep provider-native projection behavior available for projects that request it.

```bash
ace-handbook sync --provider codex
```

### Expected Output

- The command writes only the Codex provider projection under `.codex/skills/`.
- It does not write or update `.agents/skills/` as a side effect of the explicit provider request.
- Provider-specific frontmatter behavior remains unchanged for the requested provider.

### Scenario 4: Keep intentionally narrow targets narrow

**Goal**: Avoid widening genuinely provider-specific skills into the neutral default provider.

```text
canonical skill with integration.targets: [codex]
```

### Expected Output

- The skill is not projected into `.agents/skills/` unless it explicitly adds `agents`.
- Status and sync agree that the skill is not expected for the default `agents` provider.
- Unknown-provider and disabled-provider errors remain unchanged.

## Notes for Implementer

- Full usage documentation should be completed during work-on-task using `wfi://docs/update-usage`.
- Use sentinel assertions rather than exact global skill counts because the canonical inventory changes across releases.
