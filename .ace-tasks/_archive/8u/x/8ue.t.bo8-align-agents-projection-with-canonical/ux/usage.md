# Align agents projection with canonical inventory - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Project common workflows by default

**Goal**: Give agents access to every available common ACE workflow skill through the neutral default provider.

```bash
ace-handbook sync
```

### Expected Output

- The command reports a successful `agents` projection with a dynamic count matching the effective common-workflow policy.
- `.agents/skills/as-git-commit/SKILL.md` exists when `ace-git-commit` is installed and discovered.
- Representative skills from every available common-workflow source are present under `.agents/skills/`.

### Scenario 2: Verify that status describes the projection sync maintains

**Goal**: Detect missing, stale, extra, filtered, or incomplete skill projections accurately.

```bash
ace-handbook status
ace-handbook status --format json
```

### Expected Output

- The canonical inventory and the `agents` expected set are both visible.
- After a clean sync, the status reports zero missing, outdated, and extra entries, with in-sync equal to expected.
- If canonical total exceeds the expected set because of intentional provider targeting, the output identifies the curated policy, excluded count, and policy boundary instead of implying that every canonical skill is projected.

### Scenario 3: Keep explicit provider sync isolated

**Goal**: Allow a project to request a provider-native projection without changing the neutral default projection.

```bash
ace-handbook sync --provider codex
```

### Expected Output

- The command writes only the Codex projection under `.codex/skills/`.
- `.agents/skills/` is not updated by the explicit Codex invocation.
- Codex-specific targeting and frontmatter overrides remain scoped to the Codex output.

### Scenario 4: Report curated projection coverage

**Goal**: Make an intentional difference between canonical inventory and default projection visible to users and automation.

```text
ace-handbook status --format json
```

### Expected Output

- The provider entry reports the effective projection policy, excluded count, and policy boundary.
- The canonical total and expected count remain machine-readable so automation can distinguish file-level sync from inventory coverage.
- The status does not claim that a smaller curated projection is a complete canonical mirror.

## Notes for Implementer

- Use dynamic inventory and sentinel assertions rather than fixed global skill counts.
- Full usage documentation should be completed during work-on-task using `wfi://docs/update-usage`.
