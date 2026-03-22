---
id: 8ql.t.tt6.0
status: pending
priority: medium
created_at: "2026-03-22 19:52:30"
estimate: TBD
dependencies: []
tags: [ace-demo, spike, yaml, sandbox]
parent: 8ql.t.tt6
bundle:
  presets: [project]
  files: [ace-demo/lib/ace/demo/organisms/demo_recorder.rb, ace-demo/lib/ace/demo/atoms/tape_content_generator.rb, ace-demo/lib/ace/demo/atoms/tape_metadata_parser.rb, ace-demo/lib/ace/demo/molecules/tape_resolver.rb, ace-demo/lib/ace/demo/molecules/vhs_executor.rb, ace-demo/lib/ace/demo/molecules/tape_scanner.rb, ace-demo/lib/ace/demo/organisms/tape_creator.rb, ace-demo/.ace-defaults/demo/config.yml, ace-demo/docs/demo/ace-demo-getting-started.tape, ace-test-runner-e2e/lib/ace/test/end_to_end_runner/molecules/setup_executor.rb]
  commands: []
needs_review: false
---

# Spike: Validate YAML Demo Format End-to-End

## Objective

Validate that the YAML demo format can drive the full recording pipeline end-to-end before committing to the full engine implementation. This spike proves the core concept: `.tape.yml` → parse → sandbox → compile VHS tape → record → teardown → GIF with controlled data.

Using ace-task as the test subject, the spike should produce a GIF showing realistic seed data (multiple tasks with different statuses, filtering that shows different results) — demonstrating the value of sandbox isolation over recording against live environment data.

## Behavioral Specification

### User Experience

- **Input**: A single `.tape.yml` file for ace-task with settings, setup (sandbox + seed tasks), scenes (list, filter, create, show), and teardown
- **Process**: Minimal spike code parses the YAML, creates a sandbox directory, runs setup commands to seed data, compiles scenes to VHS tape syntax, records via VHS, and cleans up
- **Output**: A GIF demonstrating ace-task with controlled data. Concept inventory documenting what existing components survive, what changes, and what's new

### Expected Behavior

1. **YAML parsing**: Read `.tape.yml` file, extract settings, setup, scenes, teardown sections
2. **Sandbox creation**: Create temporary directory via `sandbox` directive
3. **Git init**: Initialize git repo in sandbox via `git-init` directive (separate from sandbox creation)
4. **Fixture copy**: Copy fixtures into sandbox via `copy-fixtures` directive
5. **Setup execution**: Run setup commands in sandbox (e.g., `ace-task create ...` to seed data)
6. **VHS compilation**: Convert scenes to VHS tape content (Output, Set, Type, Enter, Sleep directives)
7. **Recording**: Pass compiled tape to VhsExecutor (existing component, kept as-is)
8. **Teardown**: Remove sandbox directory after recording
9. **Backward compat**: Existing `.tape` files still record via current pipeline (no regression)

### Interface Contract

```yaml
# Spike test file: ace-task/docs/demo/ace-task-getting-started.tape.yml
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
  - run: "ace-task create 'Fix auth bug' --status pending --priority high"
  - run: "ace-task create 'Write onboarding guide' --status done --tags docs"

scenes:
  - name: List and filter tasks
    commands:
      - type: "ace-task list"
        sleep: 3s
      - type: "ace-task list --status pending"
        sleep: 3s

  - name: Create a task
    commands:
      - type: "ace-task create 'Add health check' --priority high --tags ops"
        sleep: 3s

  - name: Show task details
    commands:
      - type: "ace-task show 001"
        sleep: 3s

teardown:
  - cleanup
```

```bash
# Spike validation: record from YAML
ace-demo record ace-task-getting-started.tape.yml
# → Creates sandbox, seeds data, compiles VHS tape, records, cleans up

# Backward compat: old .tape still works
ace-demo record hello
# → Direct VHS execution, no sandbox (unchanged behavior)
```

Error Handling:
- YAML parse error: clear message with what's wrong
- Setup command fails: abort, run teardown, report failure
- VHS fails: run teardown, report VHS error

### Success Criteria

- [ ] ace-task `.tape.yml` records successfully in an isolated sandbox
- [ ] GIF shows realistic controlled data (seed tasks with different statuses, filtering shows different results)
- [ ] Sandbox directory is created during recording and cleaned up after
- [ ] Existing `.tape` files (e.g., `hello.tape`) still record without regression
- [ ] Concept inventory produced: what survives, what changes, what's new, what's removed

### Validation Questions

- None — design decisions confirmed in planning (file extension `.tape.yml`, literal commands, sandbox lifecycle)

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice**: Standalone subtask (spike) — validates core pipeline end-to-end
- **Outcome**: Working prototype proving YAML→sandbox→VHS→GIF pipeline; concept inventory for remaining subtasks
- **Advisory size**: medium
- **Context**: Needs ace-demo source (recorder, tape content generator, VHS executor), ace-test-runner-e2e setup_executor.rb for sandbox pattern inspiration

## Verification Plan

### Unit/Component Validation

- [ ] YAML file parses correctly into settings, setup, scenes, teardown structures
- [ ] VHS tape compilation produces valid Type/Enter/Sleep directives from scenes
- [ ] Sandbox directory is created at expected path and contains initialized git repo after setup

### Integration/E2E Validation

- [ ] Full pipeline: `.tape.yml` → sandbox → compile → record → teardown → GIF exists at output path
- [ ] GIF visual review: shows multiple tasks, filtering shows subset, create adds a task
- [ ] Backward compat: `ace-demo record hello` still works unchanged

### Failure/Invalid Path Validation

- [ ] Setup command failure triggers teardown (sandbox cleaned up even on error)
- [ ] Malformed YAML produces helpful error message

## Scope of Work

- **Included**: Minimal YAML parsing, sandbox creation/teardown, VHS compilation, one end-to-end recording
- **Excluded**: Full test suite, CLI integration, `create`/`list`/`show` command changes, fixture directory convention, multi-package migration

## Deliverables

### Behavioral Specifications
- Working YAML→sandbox→VHS→GIF pipeline for ace-task demo
- Concept inventory document (what survives, changes, is new, is removed)

### Validation Artifacts
- Recorded GIF from YAML source showing controlled seed data
- Verified backward compat with existing `.tape` files

## Out of Scope

- Full test coverage (deferred to subtask 1)
- CLI command changes (`create`, `list`, `show`) (deferred to subtask 1)
- Migration of other packages (deferred to subtask 2)
- Fixture directory convention (deferred to subtask 2)
