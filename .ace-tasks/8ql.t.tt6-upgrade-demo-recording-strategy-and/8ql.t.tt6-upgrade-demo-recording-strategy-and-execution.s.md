---
id: 8ql.t.tt6
status: pending
priority: medium
created_at: "2026-03-22 19:52:26"
estimate: TBD
dependencies: []
tags: [ace-demo, demo, yaml, vhs, sandbox]
bundle:
  presets: [project]
  files: [ace-demo/lib/ace/demo/organisms/demo_recorder.rb, ace-demo/lib/ace/demo/atoms/tape_content_generator.rb, ace-demo/lib/ace/demo/atoms/tape_metadata_parser.rb, ace-demo/lib/ace/demo/molecules/tape_resolver.rb, ace-demo/lib/ace/demo/molecules/vhs_executor.rb, ace-demo/lib/ace/demo/molecules/tape_scanner.rb, ace-demo/lib/ace/demo/organisms/tape_creator.rb, ace-demo/lib/ace/demo/cli/commands/record.rb, ace-demo/lib/ace/demo/cli/commands/create.rb, ace-demo/lib/ace/demo/cli/commands/list.rb, ace-demo/lib/ace/demo/cli/commands/show.rb, ace-demo/.ace-defaults/demo/config.yml]
  commands: []
needs_review: false
---

# Upgrade Demo Recording Strategy and Execution

## Objective

Current demo tapes are raw VHS `.tape` files — flat, imperative, fragile. They run against whatever environment they happen to be in (hardcoded task IDs, no controlled data). There is no sandbox isolation, no setup/teardown, and no structured scenes.

This task introduces a **YAML authoring format** (`.tape.yml`) with structured scenes, setup/teardown directives, and settings. The VHS `.tape` becomes a **generated artifact** — compiled from YAML into `.ace-local/` for recording only. This separates authoring (YAML, committed) from execution (VHS tape, ephemeral), enabling controlled sandbox environments with realistic seed data that produce compelling, reproducible demos.

Carries forward idea 8qlonb's framing: transition from generic command execution to high-impact visual storytelling with reproducible, sandboxed recordings.

## Behavioral Specification

### User Experience

- **Input**: Demo authors write `.tape.yml` files with structured settings, setup/teardown directives, and organized scenes containing literal commands
- **Process**: `ace-demo record my-demo.tape.yml` parses the YAML, creates an isolated sandbox, runs setup commands (seed data, git-init, copy fixtures), compiles scenes into a VHS tape, records, then tears down the sandbox
- **Output**: A clean GIF/video showing realistic, controlled demo data — committed alongside the `.tape.yml` source. The intermediate VHS tape is ephemeral in `.ace-local/`

### Expected Behavior

1. **YAML format**: `.tape.yml` files define `settings`, `setup`, `scenes`, and `teardown` sections
2. **Compilation**: YAML scenes compile to VHS tape syntax (Type/Enter/Sleep directives with scene comments)
3. **Sandbox isolation**: Each recording runs in a fresh sandbox directory (`.ace-local/demo/sandbox/{id}/`) with git-init, fixture copying, and setup commands
4. **Teardown**: Sandbox is cleaned up after recording completes (success or failure)
5. **Backward compat**: Old `.tape` files still work — passed through directly to VHS with no compilation step
6. **Pipeline**: `.tape.yml` → parse → sandbox → compile VHS tape → record → teardown → output media

### Interface Contract

```yaml
# docs/demo/ace-task-getting-started.tape.yml (authored, committed)
description: Showcase ace-task filtering and management
tags: [ace-task, docs, getting-started]

settings:
  font_size: 16
  width: 960
  height: 540
  format: gif

setup:
  - sandbox
  - git-init
  - copy-fixtures
  - run: "git add -A && git commit -qm 'seed'"
  - run: "ace-task create 'Deploy API v2' --status done --tags ops"

scenes:
  - name: List and filter tasks
    commands:
      - type: "ace-task list"
        sleep: 3s
      - type: "ace-task list --status pending"
        sleep: 3s

teardown:
  - cleanup
```

```bash
# Record from YAML (new pipeline)
ace-demo record ace-task-getting-started.tape.yml
# → sandbox created → VHS tape compiled → recorded → sandbox cleaned → GIF output

# Record from .tape (backward compat — passthrough)
ace-demo record hello.tape
# → direct VHS execution, no sandbox

# Create new demo (generates .tape.yml)
ace-demo create my-new-demo
# → creates docs/demo/my-new-demo-getting-started.tape.yml

# List demos (shows both formats during migration)
ace-demo list
# → lists .tape and .tape.yml files
```

Error Handling:
- Missing `.tape.yml` file: `TapeNotFoundError` with search paths (same cascade as `.tape`)
- YAML parse failure: clear error with line number
- Setup command failure: abort recording, run teardown, report which setup command failed
- VHS execution failure: run teardown, report VHS error

### Success Criteria

- [ ] All 23 package demos record successfully from `.tape.yml` with controlled sandbox data
- [ ] GIFs show realistic, curated data (not random live environment data)
- [ ] Old `.tape` files continue to work via passthrough (backward compat during migration)
- [ ] Sandbox is always cleaned up, even on recording failure
- [ ] `ace-demo create` generates `.tape.yml` instead of `.tape`
- [ ] `ace-demo list` and `ace-demo show` work with both formats
- [ ] No raw `.tape` files remain committed after migration (subtask 3)
- [ ] `ace-test ace-demo` passes with full coverage of new components

## Vertical Slice Decomposition (Task/Subtask Model)

| Subtask | Slice | Advisory Size | Verification |
|---|---|---|---|
| 8ql.t.tt6.0 | Spike: Validate YAML format end-to-end | medium | Record ace-task from YAML in sandbox. GIF shows realistic data. Sandbox cleaned up. Old tape still works. |
| 8ql.t.tt6.1 | Full YAML demo engine implementation | medium | `ace-test ace-demo` passes. Unit tests for parser, compiler, sandbox, teardown. Both formats resolve. |
| 8ql.t.tt6.2 | Migrate all 23 package tapes to YAML | large | All packages record from `.tape.yml`. Visual review of GIFs. Old `.tape` files removed. |
| 8ql.t.tt6.3 | Remove non-CLI demos and cleanup | small | `ace-test/docs/demo/` removed. No dangling README refs. `ace-demo list` clean. |

## Concept Inventory (Orchestrator)

| Concept | Introduced by | Removed by | Status |
|---|---|---|---|
| YAML demo format (`.tape.yml`) | Spike (tt6.0) | — | NEW |
| YAML-to-VHS compiler | Spike (tt6.0) | — | NEW |
| Sandbox lifecycle (setup/teardown) | Spike (tt6.0) | — | NEW |
| Package-level `docs/demo/fixtures/` | Migration (tt6.2) | — | NEW |
| `DemoYamlParser` atom | Engine (tt6.1) | — | NEW |
| `VhsTapeCompiler` atom | Engine (tt6.1) | — | NEW |
| `DemoSandboxBuilder` molecule | Engine (tt6.1) | — | NEW |
| `DemoTeardownExecutor` molecule | Engine (tt6.1) | — | NEW |
| `TapeResolver` | — | — | MODIFIED (resolve `.tape.yml` too) |
| `DemoRecorder` | — | — | MODIFIED (compile → sandbox → record → teardown) |
| `TapeContentGenerator` | — | — | KEPT (used by InlineRecorder for inline `--` commands) |
| `InlineRecorder` | — | — | KEPT (inline recording path unchanged) |
| `VhsExecutor` | — | — | KEPT (receives generated tape path) |
| `TapeMetadataParser` | — | Engine (tt6.1) | REPLACED by DemoYamlParser for `.tape.yml`; kept for `.tape` backward compat |

## Verification Plan

### Unit/Component Validation

- [ ] `DemoYamlParser` correctly parses valid `.tape.yml` files and rejects invalid ones
- [ ] `VhsTapeCompiler` produces correct VHS syntax from parsed YAML scenes
- [ ] `DemoSandboxBuilder` creates isolated directory, initializes git, copies fixtures, runs setup commands
- [ ] `DemoTeardownExecutor` removes sandbox directory
- [ ] `TapeResolver` resolves both `.tape` and `.tape.yml` files via search cascade

### Integration/E2E Validation

- [ ] Full pipeline: `.tape.yml` → sandbox → compile → VHS record → teardown → GIF output
- [ ] Backward compat: `.tape` file records without sandbox or compilation
- [ ] `ace-demo record`, `list`, `show`, `create` all work with `.tape.yml` format

### Failure/Invalid Path Validation

- [ ] Missing `.tape.yml` produces `TapeNotFoundError` with search paths
- [ ] Invalid YAML produces clear parse error
- [ ] Setup command failure aborts recording and still runs teardown
- [ ] Sandbox is cleaned up on VHS execution failure

## API Surface Changes

- **File format**: New `.tape.yml` YAML authoring format (committed); `.tape` becomes generated artifact (ephemeral in `.ace-local/`)
- **CLI**: `ace-demo record` accepts both `.tape` (passthrough) and `.tape.yml` (compile → sandbox → record)
- **CLI**: `ace-demo create` generates `.tape.yml` instead of `.tape`
- **CLI**: `ace-demo list` / `show` work with both formats
- **Config**: New `sandbox_dir` key in `.ace-defaults/demo/config.yml`
- **Convention**: Each package's `docs/demo/` contains `.tape.yml` + optional `fixtures/` directory

## Design Decisions (Confirmed)

- **File extension**: `.tape.yml` (e.g., `ace-task-getting-started.tape.yml`)
- **Migration scope**: Single subtask covering all 23 packages (each tape is independent)
- **Dynamic references**: Not in first version — commands are literal strings; setup creates predictable data with known IDs
- **Spike-first**: Subtask 0 validates the core pipeline before remaining subtasks decompose further

## Out of Scope

- Dynamic template variables in commands (future enhancement)
- Multi-tape orchestration (recording multiple demos in sequence)
- Remote recording or CI-based recording
- Performance optimization of sandbox creation

## References

- Source idea: 8qlonb — "Upgrade Demo Recording Strategy and Execution"
- Usage docs: ux-usage.md (draft usage scenarios)
- Sandbox pattern inspiration: `ace-test-runner-e2e/lib/ace/test/end_to_end_runner/molecules/setup_executor.rb`
