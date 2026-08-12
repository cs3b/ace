# Safe application lifecycle recommendations and delivery defaults - Draft Usage

## API Surface

- [x] CLI (doctor recommendation flags)
- [ ] Developer API
- [x] Agent API (task-work skills, assignment presets, workflow receipts)
- [x] Configuration (profile and acknowledgement policy)

## Usage Scenarios

### Scenario 1: Inspect application lifecycle drift

**Goal**: Receive deterministic application findings without changing project files.

```bash
ace-config doctor --recommendations --profile application --json
```

#### Expected Output

- Versioned findings include stable ID, severity, profile, evidence, source, current and recommended values, rationale, next action, and package/recommendation version.
- The command is read-only and exits with the existing doctor semantics unless `--strict` is added.

### Scenario 2: Use low-noise defaults in an unconfigured project

**Goal**: Run recommendations without installing the full application stack.

```bash
ace-config doctor --recommendations
```

#### Expected Output

- The `minimal` profile is selected.
- Missing optional application or ACE-development packages do not produce findings.
- No network request is made.

### Scenario 3: Drive the default merge-approval outcome

**Goal**: Implement and deliver one task while retaining explicit merge approval.

```text
/as-task-work 8vb.t.example
```

#### Expected Output

- Public task work selects `work-on-task`, creates and drives its assignment, and stops merge-ready with branch/worktree intact.
- Review, feedback, verification, rebase, task completion, PR update, release receipt, and final exact-head review are evidenced against the current head.

### Scenario 4: Auto-merge authorization downgrades safely

**Goal**: Authorize guarded merge in advance without allowing uncertain delivery.

```text
/as-task-work 8vb.t.example --preset work-on-task-auto-merge
```

#### Expected Output

- Clean, current evidence may apply the reconstructed digest-bound merge plan.
- Scope expansion, deferred findings, skipped/failed/flaky gates, stale evidence, or uncertainty stops at ordinary merge approval.

### Scenario 5: Acknowledgement expires

**Goal**: Record an intentional exception without silencing it forever.

```yaml
recommendations:
  acknowledgements:
    workflow.review.executed:
      rationale: "External review gate is approved temporarily"
      expires_at: "2026-10-01"
```

#### Expected Output

- The finding is acknowledged only until its expiry or `recheck_after` boundary.
- Expired acknowledgements reappear with their original stable finding ID.

## Notes for Implementer

- Complete public usage docs during task work with `wfi://docs/update-usage`.
- Parent GitHub issue: https://github.com/cs3b/ace/issues/311
