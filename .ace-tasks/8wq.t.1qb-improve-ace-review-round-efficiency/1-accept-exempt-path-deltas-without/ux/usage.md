# Exempt-path scopes - Draft Usage

## API Surface

- [ ] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars): new `exempt_paths` review config key

## Usage Scenarios

### Scenario 1: Docs-only delta accepted without a model call

**Goal**: A PR round whose delta touches only declared-exempt paths completes free.

```yaml
# project review config
exempt_paths:
  - "CHANGELOG.md"
  - "**/*.golden"
```

```bash
ace-review --pr 172 --delta   # delta touches only CHANGELOG.md
```

**Expected output**: A recorded no-op session: "delta is review-exempt (CHANGELOG.md
matched `CHANGELOG.md`)", verdict issued, zero model calls in usage records.

### Scenario 2: Overly broad exemption is refused

**Goal**: Config that would exempt everything fails loudly at load.

```yaml
exempt_paths:
  - "**"
```

**Expected output**: Config load refusal naming the offending pattern; no session
created.

## Behavioral Acceptance Contract

- Fully-exempt delta rounds record zero model calls and enumerate exempt paths.
- Mixed deltas review only the non-exempt part and list what was skipped.
- Exemption decisions (path → matching pattern) are visible in the session report.

## Notes for Implementer

- Full usage documentation to be completed during work-on-task step using
  `wfi://docs/update-usage`.
