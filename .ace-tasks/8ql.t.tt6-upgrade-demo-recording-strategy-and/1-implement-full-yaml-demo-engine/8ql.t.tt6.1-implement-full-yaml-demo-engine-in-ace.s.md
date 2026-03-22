---
id: 8ql.t.tt6.1
status: pending
priority: medium
created_at: "2026-03-22 19:52:31"
estimate: TBD
dependencies: [8ql.t.tt6.0]
tags: [ace-demo, yaml, vhs, compiler, sandbox]
parent: 8ql.t.tt6
bundle:
  presets: [project]
  files: [ace-demo/lib/ace/demo/organisms/demo_recorder.rb, ace-demo/lib/ace/demo/atoms/tape_content_generator.rb, ace-demo/lib/ace/demo/atoms/tape_metadata_parser.rb, ace-demo/lib/ace/demo/molecules/tape_resolver.rb, ace-demo/lib/ace/demo/molecules/vhs_executor.rb, ace-demo/lib/ace/demo/molecules/tape_scanner.rb, ace-demo/lib/ace/demo/molecules/tape_writer.rb, ace-demo/lib/ace/demo/organisms/tape_creator.rb, ace-demo/lib/ace/demo/cli/commands/record.rb, ace-demo/lib/ace/demo/cli/commands/create.rb, ace-demo/lib/ace/demo/cli/commands/list.rb, ace-demo/lib/ace/demo/cli/commands/show.rb, ace-demo/.ace-defaults/demo/config.yml, ace-demo/lib/ace/demo/molecules/inline_recorder.rb]
  commands: []
needs_review: false
---

# Implement Full YAML Demo Engine in ace-demo

## Objective

Building on the spike's validated pipeline, implement the full YAML demo engine as production-quality components in ace-demo. This means proper atoms/molecules/organisms following the ATOM pattern, full test coverage, CLI integration for all commands, and backward compatibility with existing `.tape` files.

## Behavioral Specification

### User Experience

- **Input**: Users author `.tape.yml` files with structured settings, setup/teardown directives, and organized scenes. They use `ace-demo record`, `create`, `list`, and `show` commands with both `.tape` and `.tape.yml` files.
- **Process**: The recording pipeline detects format, and for `.tape.yml`: parses YAML → builds sandbox → compiles VHS tape → records → tears down. For `.tape`: passes through directly to VHS (no change).
- **Output**: High-quality GIFs/videos from controlled sandbox environments. CLI commands work seamlessly with both formats.

### Expected Behavior

**New components:**

1. **`DemoYamlParser` (atom)**: Parse and validate `.tape.yml` YAML format. Returns structured data: settings hash, setup directive list, scenes array (each with name and commands), teardown directive list. Validates `scenes` section is required (at least one scene); `settings`, `setup`, and `teardown` sections are optional (default to empty). Rejects unknown top-level keys.

2. **`VhsTapeCompiler` (atom)**: Compile parsed YAML scenes into VHS tape content string. Generates `Output`, `Set` (font size, width, height), `Type`/`Enter`/`Sleep` per command, with `# Scene: <name>` comments between scenes.

3. **`DemoSandboxBuilder` (molecule)**: Create sandbox in `.ace-local/demo/sandbox/{id}/`. Executes setup directives in order:
   - `sandbox` — create the isolated directory
   - `git-init` — initialize git repo with demo user config
   - `copy-fixtures` — copy `fixtures/` tree relative to the `.tape.yml` file's directory into sandbox (e.g., `ace-task/docs/demo/fixtures/` for a tape at `ace-task/docs/demo/ace-task-getting-started.tape.yml`). If tape was resolved from project-level `.ace/demo/tapes/`, `copy-fixtures` is a no-op with warning. If fixtures directory doesn't exist, skip with warning (not error)
   - `run: <cmd>` — execute arbitrary bash command in sandbox (working directory set to sandbox)

4. **`DemoTeardownExecutor` (molecule)**: Execute teardown directives after recording:
   - `cleanup` — remove the sandbox directory
   - `run: <cmd>` — execute arbitrary cleanup command
   - Always runs, even if recording failed (ensure-style)

**Modified components:**

5. **`DemoRecorder` (organism)**: New pipeline branch for `.tape.yml`:
   - Detect format (`.tape.yml` vs `.tape`) via file extension
   - `.tape.yml` path: parse → sandbox → compile → write temp tape to `.ace-local/` → record via VhsExecutor → teardown
   - `.tape` path: existing behavior unchanged (direct VhsExecutor call)

6. **`TapeResolver` (molecule)**: Resolve `.tape.yml` files in addition to `.tape`. Same cascade: direct path → `.ace/demo/tapes/` → `~/.ace/demo/tapes/` → `.ace-defaults/`. When name given without extension, check `.tape.yml` first, then `.tape`.

7. **`TapeScanner` (molecule)**: Discover both `.tape` and `.tape.yml` files across search paths.

8. **CLI `record` command**: Accept `.tape.yml` references. No flag changes — format detected automatically.

9. **CLI `create` command**: Generate `.tape.yml` template instead of `.tape`. Include skeleton settings, setup (sandbox, copy-fixtures), one example scene, and teardown (cleanup).

10. **CLI `list` command**: Show both `.tape` and `.tape.yml` files. Display format indicator.

11. **CLI `show` command**: Display `.tape.yml` metadata from YAML frontmatter (description, tags, settings) instead of `# Key: Value` header parsing.

**Unchanged components (kept as-is):**

12. **`InlineRecorder` (molecule)**: Inline recording path (`ace-demo record name -- cmd1 cmd2`) remains unchanged. Continues using `TapeContentGenerator` for VHS tape generation from CLI arguments.

13. **`TapeContentGenerator` (atom)**: Kept for `InlineRecorder` and `TapeCreator` backward compatibility. Not used by the new YAML pipeline (which uses `VhsTapeCompiler` instead).

**Setup directive vocabulary:**
- `sandbox` — create isolated directory at `.ace-local/demo/sandbox/{unique-id}/`
- `git-init` — initialize git repo with `Demo User <demo@example.com>` committer
- `copy-fixtures` — copy `fixtures/` relative to `.tape.yml` location into sandbox (see DemoSandboxBuilder above for resolution rules)
- `run: <cmd>` — execute bash command in sandbox working directory

**Teardown directive vocabulary:**
- `cleanup` — remove sandbox directory (rm -rf)
- `run: <cmd>` — execute arbitrary cleanup command

### Interface Contract

```bash
# Record from YAML (auto-detected by extension)
ace-demo record ace-task-getting-started.tape.yml
# → parse → sandbox → compile → VHS → teardown → GIF

# Record from .tape (backward compat, auto-detected)
ace-demo record hello.tape
# → direct VHS execution

# Record by name (no extension — tries .tape.yml first, then .tape)
ace-demo record ace-task-getting-started
# → resolves to .tape.yml if exists, falls back to .tape

# Create new demo (generates .tape.yml)
ace-demo create my-feature
# → creates docs/demo/my-feature-getting-started.tape.yml with template

# List all demos (both formats)
ace-demo list
# → shows .tape and .tape.yml files with format column

# Show demo details (works with both formats)
ace-demo show ace-task-getting-started.tape.yml
# → displays YAML metadata: description, tags, settings, scene names
```

```yaml
# Generated .tape.yml template from ace-demo create
description: ""
tags: []

settings:
  font_size: 14
  width: 800
  height: 400
  format: gif

setup:
  - sandbox
  - copy-fixtures
  - run: "git add -A && git commit -qm 'seed'"

scenes:
  - name: Example scene
    commands:
      - type: "echo 'Hello from my-feature'"
        sleep: 2s

teardown:
  - cleanup
```

Configuration:
- New `sandbox_dir` key in `.ace-defaults/demo/config.yml` — default: `.ace-local/demo/sandbox`
- Sandbox instances created at `{sandbox_dir}/{unique-id}/` (using `Ace::B36ts.now` for ID)

Error Handling:
- Invalid YAML structure: `DemoYamlParseError` with specific validation message
- Unknown setup directive: error listing valid directives
- Unknown teardown directive: error listing valid directives
- Missing fixtures directory when `copy-fixtures` specified: warning (not error), skip copy
- Sandbox creation failure: error with path and reason

### Success Criteria

- [ ] `DemoYamlParser` parses valid `.tape.yml` and rejects invalid structures with clear errors
- [ ] `VhsTapeCompiler` produces correct VHS tape syntax from parsed YAML
- [ ] `DemoSandboxBuilder` creates sandbox, runs all setup directives in order
- [ ] `DemoTeardownExecutor` cleans up sandbox even after recording failure
- [ ] `DemoRecorder` routes `.tape.yml` through new pipeline, `.tape` through existing
- [ ] `TapeResolver` resolves both formats with `.tape.yml` priority for extensionless names
- [ ] `ace-demo create` generates `.tape.yml` template
- [ ] `ace-demo list` shows both formats
- [ ] `ace-demo show` displays YAML metadata for `.tape.yml` files
- [ ] `ace-test ace-demo` passes with all new and existing tests
- [ ] `TapeMetadataParser` replaced by `DemoYamlParser` for `.tape.yml` files (kept for `.tape` backward compat)

### Validation Questions

- None — spike will have validated core design; this subtask implements production-quality version

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice**: Subtask of orchestrator — full engine implementation
- **Outcome**: Production-ready YAML demo engine with tests, CLI integration, backward compat
- **Advisory size**: medium
- **Context**: Needs all ace-demo source files, spike learnings (concept inventory)

## Verification Plan

### Unit/Component Validation

- [ ] `DemoYamlParser`: valid YAML → correct structured output; missing sections → error; unknown keys → error
- [ ] `VhsTapeCompiler`: scenes with commands → correct VHS syntax with Output/Set/Type/Enter/Sleep; empty scenes → minimal tape
- [ ] `DemoSandboxBuilder`: `sandbox` → directory exists; `git-init` → `.git/` present; `copy-fixtures` → files copied; `run:` → command executed in sandbox cwd
- [ ] `DemoTeardownExecutor`: `cleanup` → directory removed; `run:` → command executed
- [ ] `TapeResolver`: resolves `.tape.yml` by name; resolves `.tape` by name; `.tape.yml` takes priority for extensionless lookup

### Integration/E2E Validation

- [ ] Full pipeline: `.tape.yml` → recorded GIF at expected output path
- [ ] Backward compat: `.tape` → recorded GIF (no regression from current behavior)
- [ ] CLI `create` → generates valid `.tape.yml` that can be recorded
- [ ] CLI `list` → includes both `.tape` and `.tape.yml` files

### Failure/Invalid Path Validation

- [ ] Malformed YAML → `DemoYamlParseError` with specific message
- [ ] Unknown setup directive → error listing valid directives
- [ ] Setup command failure → teardown still runs, sandbox cleaned up
- [ ] VHS failure → teardown still runs, error reported

## Scope of Work

- **Included**: All new atoms/molecules/organisms, CLI changes, test coverage, backward compat
- **Excluded**: Migrating existing `.tape` files (subtask 2), removing non-CLI demos (subtask 3)

## Out of Scope

- Migration of existing tapes (subtask 2)
- Fixture creation for packages (subtask 2)
- Removal of non-CLI demos (subtask 3)
- Dynamic template variables in commands
