---
id: 8qr.t.uon
status: pending
priority: medium
created_at: "2026-03-28 20:27:23"
estimate: TBD
dependencies: []
tags: [ace-assign, fork, configuration]
bundle:
  presets: [project]
  files: [ace-assign/lib/ace/assign/models/step.rb, ace-assign/lib/ace/assign/atoms/step_file_parser.rb, ace-assign/lib/ace/assign/molecules/queue_scanner.rb, ace-assign/lib/ace/assign/molecules/step_writer.rb, ace-assign/lib/ace/assign/molecules/fork_session_launcher.rb, ace-assign/lib/ace/assign/cli/commands/fork_run.rb, ace-assign/lib/ace/assign/cli/commands/status.rb, ace-assign/lib/ace/assign/organisms/assignment_executor.rb, ace-assign/.ace-defaults/assign/config.yml, ace-assign/docs/usage.md, ace-assign/handbook/guides/fork-context.g.md]
  commands: [cd ace-assign && ace-test]
needs_review: false
---

# Per-Step Fork Provider Override

## Objective

All forked steps currently share a single global model (`execution.provider` in config). When different fork steps need different models (e.g., research with sonnet, implementation with opus), the only override is the CLI `--provider` flag at fork-run time. This task adds per-step model configuration via a `fork:` frontmatter key so catalog and job definitions can declare the right model per step.

## Behavioral Specification

### User Experience

- **Input:** Set `fork: { provider: "..." }` in step frontmatter alongside `context: fork`, or `context.fork.provider` in catalog step definitions
- **Process:** When `ace-assign fork-run` executes for a fork root, it resolves the provider from that root step's `fork.provider` before falling back to global config
- **Output:** The forked agent runs with the step-specified model for that subtree launch; `ace-assign status` shows which provider a fork step will use in both table and JSON output

### Expected Behavior

Assignment authors can control which LLM model each fork step uses independently. A research step can run with `claude:sonnet@yolo` while an implementation step runs with `claude:opus:high@yolo`, all within the same assignment — without needing CLI overrides.

Steps without `fork:` behave exactly as today. The `context: fork` string field is unchanged.

This override is resolved once per `ace-assign fork-run` invocation from the fork root being launched. It does not switch providers mid-run between child steps inside the same forked subtree, because subtree execution already runs under a single scoped provider process.

### Interface Contract

Step file frontmatter:
```yaml
---
name: research
status: pending
context: fork
fork:
  provider: "claude:sonnet@yolo"
---
```

Catalog step definition:
```yaml
name: research
context:
  default: fork
  reason: "Research benefits from focused exploration"
  fork:
    provider: "claude:sonnet@yolo"
```

Status output:
```bash
$ ace-assign status
Current Step: 020 - research
Context: fork
Fork Provider: claude:sonnet@yolo

# fork-run resolves step provider
$ ace-assign fork-run --root 020
Provider: claude:sonnet@yolo    # from step fork.provider

# CLI --provider still overrides everything
$ ace-assign fork-run --root 020 --provider claude:haiku
Provider: claude:haiku           # CLI wins
```

Provider priority chain (first non-nil wins):
```
CLI --provider  >  step fork.provider  >  config execution.provider  >  DEFAULT_PROVIDER
```

Status JSON contract:
```json
{
  "steps": [
    {
      "number": "020",
      "name": "research",
      "status": "pending",
      "context": "fork",
      "fork_provider": "claude:sonnet@yolo"
    }
  ],
  "current_step": {
    "number": "020",
    "name": "research",
    "status": "pending",
    "context": "fork",
    "fork_provider": "claude:sonnet@yolo"
  }
}
```

Error Handling:
- Invalid provider string in `fork.provider` — handled downstream by `QueryInterface`, no step-level validation needed
- `fork:` key without `context: fork` — ignored (fork options only apply to fork steps)

Edge Cases:
- `fork: {}` (empty hash) — no provider override, behaves as today
- `fork: { provider: nil }` — same as absent, falls through to config

### Success Criteria

1. Steps with `fork.provider` in frontmatter launch fork sessions with that provider
2. CLI `--provider` flag overrides step-level `fork.provider`
3. Steps without `fork:` key behave exactly as today (zero regression)
4. `ace-assign status` displays the per-step fork provider when set
5. `ace-assign status --format json` includes `fork_provider` on both `steps[*]` and `current_step` when set
6. Catalog `context.fork.provider` flows through composition into step file `fork.provider`
7. `fork:` serializes to/from step file frontmatter via `to_frontmatter` round-trip
8. Usage and fork-context docs describe the new field and precedence chain

### Validation Questions

- None remaining — design confirmed with user (Option B: separate `fork:` top-level key). Status JSON should expose `fork_provider`, and docs updates are included in this task.

## Vertical Slice Decomposition (Task/Subtask Model)

Single flat task — **small**. Straightforward field addition threading through an existing chain:
Step model -> parser -> scanner -> step writer round-trip -> fork_run -> launcher -> status display/json, plus catalog composition and docs.

## Verification Plan

### Unit / Component Validation

- Step model: `fork_options` hash stored, `fork_provider` accessor returns `fork.provider`
- Step model: `to_frontmatter` serializes `fork:` hash, omits when nil/empty
- StepFileParser: `extract_fields` extracts `fork:` hash from frontmatter YAML
- QueueScanner: passes `fork_options` through to `Step.new`
- StepWriter/frontmatter updates preserve `fork:` content during state transitions

### Integration Validation

- ForkRun: uses `step.fork_provider` when no CLI `--provider` override
- ForkRun: CLI `--provider` overrides `step.fork_provider`
- ForkRun: provider display line shows resolved provider from step
- Status: displays "Fork Provider:" when `fork_provider` is set
- Status JSON: includes `fork_provider` on serialized step objects
- Catalog composition: `context.fork.provider` persists onto generated step frontmatter
- Docs: usage and fork-context guide include `fork.provider` examples and precedence

### Failure / Invalid Path Validation

- Step without `fork:` — provider resolves to config default (no change)
- `fork: {}` — provider resolves to config default
- Child steps inside one forked subtree do not change provider mid-run; only the fork root for that `fork-run` invocation controls the launched provider unless CLI override is supplied
- Invalid provider string — error raised by downstream `QueryInterface`, not step layer

### Verification Commands

- `cd ace-assign && ace-test test/models/step_test.rb` — step model tests
- `cd ace-assign && ace-test test/atoms/step_file_parser_test.rb` — parser tests
- `cd ace-assign && ace-test test/commands/fork_run_command_test.rb` — fork-run tests
- `cd ace-assign && ace-test test/commands/status_command_test.rb` — status display tests
- `cd ace-assign && ace-test test/organisms/assignment_executor_test.rb` — catalog composition coverage if needed
- `cd ace-assign && ace-test` — full package suite

## Scope of Work

- **Included:** `fork:` frontmatter key on steps, `fork_provider` accessor, threading through fork-run and status, status JSON exposure, catalog composition, and docs updates
- **Excluded:** No new CLI flags, no provider format changes, no catalog step file updates (can be done separately)

## Deliverables

### Behavioral Specifications
- `fork:` hash field on Step model with `fork_provider` convenience accessor
- StepFileParser extraction and round-trip serialization
- ForkRun provider resolution incorporating step-level override
- Status display and JSON serialization of per-step fork provider
- Usage and fork-context documentation updates for `fork.provider`

### Validation Artifacts
- Unit tests for Step model fork_options/fork_provider
- Unit tests for StepFileParser fork extraction
- Integration tests for ForkRun provider resolution priority
- Status display/JSON tests showing fork provider
- Catalog composition tests showing `context.fork.provider` materialization

## Out of Scope

- Updating existing catalog step definitions with fork.provider values
- Adding other fork options (timeout, cli_args per step) — future extension point
- Provider format shorthand (e.g., `@opus` without provider prefix)
- Changes to `context:` field semantics

## References

- `ace-assign/.ace-defaults/assign/config.yml` — current global `execution.provider`
- `ace-assign/lib/ace/assign/molecules/fork_session_launcher.rb` — current provider resolution
- `ace-assign/handbook/guides/fork-context.g.md` — fork context guide
