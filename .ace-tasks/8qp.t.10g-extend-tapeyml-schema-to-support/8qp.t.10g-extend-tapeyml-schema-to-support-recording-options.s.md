---
id: 8qp.t.10g
status: draft
priority: medium
created_at: "2026-03-26 00:40:31"
estimate: TBD
dependencies: []
tags: [ace-demo, dx, tape-format]
bundle:
  presets: ["project"]
  files:
    - ace-demo/lib/ace/demo/atoms/demo_yaml_parser.rb
    - ace-demo/lib/ace/demo/atoms/playback_speed_parser.rb
    - ace-demo/lib/ace/demo/organisms/demo_recorder.rb
    - ace-demo/lib/ace/demo/cli/commands/record.rb
    - ace-demo/lib/ace/demo/molecules/media_retimer.rb
    - ace-demo/docs/demo/ace-demo-getting-started.tape.yml
  commands: []
---

# Extend tape.yml Schema to Support Recording Options

## Objective

Eliminate repetitive CLI flags for `ace-demo record` by allowing per-tape configuration of `playback_speed`, `output` path, and a retime-only output mode directly in tape.yml. Tapes that know where their output belongs should be self-contained — one `ace-demo record tape.tape.yml` invocation should produce the correct artifact at the correct location without extra flags.

Origin: idea 8qmrn1.

## Behavioral Specification

### User Experience

- **Input**: Users add `playback_speed` and/or `output` to the `settings` section of their tape.yml files
- **Process**: `ace-demo record tape.tape.yml` reads these settings from the parsed tape spec and applies them, same as if the equivalent CLI flags had been passed
- **Output**: Recording artifact at the correct path with the correct speed, without needing `--playback-speed` or `--output` flags

### Expected Behavior

When a tape.yml includes the new settings keys, `ace-demo record` honors them as defaults that CLI flags can override:

1. **`playback_speed` only** (no `output`): Raw recording goes to `.ace-local/demo/<name>.<fmt>`, retimed copy to `.ace-local/demo/<name>-<speed>.<fmt>`. Identical to current `--playback-speed` behavior.

2. **`output` only** (no `playback_speed`): Raw recording goes directly to the specified output path. Identical to current `--output` behavior.

3. **Both `playback_speed` + `output`** (retime-only output mode): Raw recording stays in `.ace-local/demo/<name>.<fmt>`. Retimed output goes to the specified `output` path (exact path, no speed suffix appended). The original recording is preserved as a source artifact; only the retimed file appears at the final destination.

CLI flags always override tape.yml values: `--playback-speed 2x` beats `settings.playback_speed: 4x`, `--output other.gif` beats `settings.output: docs/demo/tape.gif`.

### Interface Contract

```yaml
# tape.yml — extended settings keys
settings:
  font_size: 16
  width: 1100
  height: 600
  format: gif
  playback_speed: 4x            # NEW: 1x|2x|4x|8x (same values as --playback-speed)
  output: docs/demo/tape.gif    # NEW: output file path (same as --output)
```

```bash
# Before: verbose CLI flags every invocation
ace-demo record tape.tape.yml --playback-speed 4x --output docs/demo/tape.gif

# After: tape is self-contained
ace-demo record tape.tape.yml
# → Raw: .ace-local/demo/tape.gif
# → Retimed: docs/demo/tape.gif

# CLI override still works
ace-demo record tape.tape.yml --playback-speed 2x --output other.gif
# → Raw: .ace-local/demo/tape.gif
# → Retimed: other.gif (at 2x, not 4x)
```

Error Handling:
- Invalid `playback_speed` value (e.g., `3x`) → `DemoYamlParseError` with message listing valid values
- Invalid `output` value (non-string) → `DemoYamlParseError`

Edge Cases:
- `output` with relative path → resolved from cwd (consistent with `--output`)
- `output` path with missing parent directories → created automatically (consistent with current `--output` behavior)
- Inline recording mode (`--`) → tape.yml settings do not apply (no tape file to read)
- Dry-run mode → previews tape-defined speed and output in `[dry-run]` messages

### Success Criteria

1. `settings.playback_speed` in tape.yml produces identical retimed output as `--playback-speed` CLI flag
2. `settings.output` in tape.yml produces identical output placement as `--output` CLI flag
3. Combined retime-only mode: raw stays in `.ace-local/demo/`, retimed file placed exactly at `output` path (no `-4x` suffix)
4. CLI flags override tape.yml values for both `playback_speed` and `output`
5. Existing tapes without new keys continue working with zero behavioral change
6. Parser rejects invalid `playback_speed` values with clear error message
7. Dry-run mode correctly previews tape-sourced settings

### Validation Questions

- Resolved: `output` supports relative paths resolved from cwd (same as `--output`)
- Resolved: When both are set, retimed file uses `output` path exactly as written (no speed suffix)

## Vertical Slice Decomposition (Task/Subtask Model)

**Slice type**: Standalone task (single capability slice)
**Advisory size**: Medium — parser extension + wiring through recorder/CLI + tests
**Slice outcome**: `ace-demo record` honors `playback_speed` and `output` from tape.yml with retime-only output mode

**Context dependencies**: ace-demo package (parser, recorder, CLI command, retimer)

## Verification Plan

### Unit / Component Validation

- `DemoYamlParser` accepts `playback_speed` and `output` in settings without error
- `DemoYamlParser` normalizes `playback_speed` via `PlaybackSpeedParser` and rejects invalid values
- `DemoYamlParser` normalizes `output` as string
- `DemoYamlParser` continues to reject truly unknown settings keys
- Existing tape.yml files without new keys parse identically

### Integration / E2E Validation

- `ace-demo record tape.tape.yml` with `playback_speed: 4x` in settings retimes output
- `ace-demo record tape.tape.yml` with `output: path/file.gif` in settings writes to specified path
- Combined mode: raw stays in `.ace-local/`, retimed at output path
- CLI `--playback-speed` overrides tape `settings.playback_speed`
- CLI `--output` overrides tape `settings.output`
- Dry-run shows tape-sourced settings in preview

### Failure / Invalid Path Validation

- `settings.playback_speed: 3x` → `DemoYamlParseError`
- `settings.playback_speed: true` → `DemoYamlParseError`
- `settings.output: 123` → normalized to string (consistent with format handling)
- Tape without scenes + new settings → still fails on missing scenes (no regression)

### Verification Commands

- `cd ace-demo && ace-test atoms` → parser tests pass
- `cd ace-demo && ace-test` → full suite passes
- `ace-test-suite` → monorepo green

## Scope of Work

- **User experience scope**: `ace-demo record` tape-based recording mode only (not inline mode)
- **System behavior scope**: YAML parsing, recording orchestration, retime-output routing
- **Interface scope**: tape.yml schema (new settings keys), CLI override precedence

## Deliverables

### Behavioral Specifications
- Extended tape.yml schema with `playback_speed` and `output` settings
- Retime-only output mode when both are combined
- CLI-override precedence contract

### Validation Artifacts
- Unit tests for parser extension
- Integration tests for retime-only output routing
- CLI override precedence tests

## Out of Scope

- Implementation details: file structures, code organization, technical architecture
- Inline recording mode changes (no tape file to read settings from)
- New playback speed values beyond 1x/2x/4x/8x
- Config cascade integration (these are per-tape settings, not user/project config)
- Changes to `ace-demo create` tape template generation

## References

- Source idea: `.ace-ideas/archive/8qmrn1-extend-tapeyml-schema-to-support/` (after archival)
- Current parser: `ace-demo/lib/ace/demo/atoms/demo_yaml_parser.rb`
- Current CLI: `ace-demo/lib/ace/demo/cli/commands/record.rb`
- Current recorder: `ace-demo/lib/ace/demo/organisms/demo_recorder.rb`
