# First-use release workflows and agent setup - Draft Usage

## API Surface

- [ ] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)
- [x] Documentation surface (quick-start / harness docs)

## Usage Scenarios

### Scenario 1: Resolve release baseline in a plain install

**Goal**: An agent or human loads the local release preparation workflow from installed gems without project-local release overlays.

```bash
bundle exec ace-bundle wfi://release/local
```

#### Expected Output

- Workflow resolves to a path under an installed ACE gem handbook tree (or equivalent gem WFI source).
- Content describes local preparation, distinguishes publication, and defaults to non-publishing behavior.
- Guidance explains how to override via project workflow sources.

### Scenario 2: Missing release URI still fails clearly

**Goal**: An intentionally absent release workflow URI does not silently succeed.

```bash
bundle exec ace-bundle wfi://release/does-not-exist
```

#### Expected Output

- Non-zero failure / clear unresolved workflow error.
- No implication that release skills are ready for that URI.

### Scenario 3: Default quick-start path seeds AGENTS.md and .agents/skills

**Goal**: A developer following quick-start alone ends with agents-first guidance and skills.

```bash
bundle exec ace-config sync ace-support-core
bundle exec ace-handbook sync
```

#### Expected Output

- Root `AGENTS.md` (and `docs/tools.md`) exist as the primary agent instruction surface.
- Skills are projected under `.agents/skills/`.
- Quick-start does not require reading `docs/agent-harnesses.md` to finish default setup.

### Scenario 4: Optional harness projection is documented separately

**Goal**: A developer who needs a Codex/Claude-native skill tree finds the optional path without polluting the default quick-start.

```bash
# Documented in docs/agent-harnesses.md (linked once from quick-start)
bundle exec ace-handbook sync --provider codex
```

#### Expected Output

- Harness-native tree is generated only when explicitly requested.
- Default quick-start remains focused on `.agents/` + `AGENTS.md`.

## Notes for Implementer

- Full usage documentation to be completed during work-on-task using `wfi://docs/update-usage` if package usage docs change.
- Parent GitHub issue: https://github.com/cs3b/ace/issues/310
