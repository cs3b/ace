---
id: 8qp.t.r6b.2
status: draft
priority: medium
created_at: "2026-03-26 22:33:02"
estimate: TBD
dependencies: ["8qp.t.r6b.1"]
tags: [ace-demo, asciinema, backend-selection, integration]
parent: 8qp.t.r6b
bundle:
  presets: ["project"]
  files:
    - ace-demo/lib/ace/demo/organisms/demo_recorder.rb
    - ace-demo/lib/ace/demo/atoms/demo_yaml_parser.rb
    - ace-demo/lib/ace/demo/molecules/demo_sandbox_builder.rb
    - ace-demo/lib/ace/demo/cli.rb
    - ace-demo/.ace-defaults/demo/config.yml
    - ace-demo/test/organisms/demo_recorder_test.rb
  commands: []
---

# Integrate Asciinema as Default Recording Backend

## Objective

Wire asciinema into the DemoRecorder pipeline as the default backend, replacing VHS. The recording flow becomes: tape.yml → asciinema → `.cast` → agg → gif/webm. VHS remains available via explicit opt-in. The tape.yml schema gains a `backend` setting, and the CLI gains a `--backend` override flag.

## Behavioral Specification

### User Experience

- **Input**: `ace-demo record <tape>` with optional `--backend` flag
- **Process**: DemoRecorder selects backend (asciinema default), records, converts via agg
- **Output**: `.cast` file + gif/webm visual artifact

### Expected Behavior

**Default recording (asciinema)**:
1. User runs `ace-demo record my-tape` (no flags)
2. DemoRecorder parses tape.yml, sees no `backend` setting or `backend: asciinema`
3. Builds sandbox via DemoSandboxBuilder (unchanged)
4. Compiles tape to bash script via AsciinemaTapeCompiler
5. Records via AsciinemaExecutor → produces `.cast` file
6. Converts `.cast` via AggExecutor → produces gif/webm
7. Applies playback_speed retiming if configured (on the gif/webm, not the `.cast`)
8. Runs teardown (unchanged)
9. Returns paths to both `.cast` and visual output

**VHS fallback**:
1. User runs `ace-demo record my-tape --backend vhs` or tape has `backend: vhs`
2. DemoRecorder follows existing VHS pipeline (unchanged behavior)

**Backend resolution order**:
1. CLI `--backend` flag (highest priority)
2. tape.yml `settings.backend` key
3. Config default: `asciinema`

### Interface Contract

```bash
# Default: asciinema (no flag needed)
ace-demo record my-tape
# => .ace-local/demo/my-tape.cast
# => .ace-local/demo/my-tape.gif

# Explicit asciinema
ace-demo record my-tape --backend asciinema

# Legacy VHS
ace-demo record my-tape --backend vhs
# => .ace-local/demo/my-tape.gif (VHS direct)

# tape.yml schema addition
settings:
  backend: asciinema   # or "vhs"; default "asciinema" when omitted
  format: gif          # agg output: gif, webm
  font_size: 16
  width: 960
  height: 480
```

Error Handling:
- Unknown backend value → clear error: `Unknown backend 'foo'. Valid: asciinema, vhs`
- asciinema not installed → `AsciinemaNotFoundError` with install instructions
- agg not installed → `AggNotFoundError` with install instructions (for format conversion)

Edge Cases:
- Existing tapes without `backend` key → asciinema (new default)
- Raw `.tape` files (non-YAML) → VHS only (no change to raw tape behavior)
- `--backend vhs` with playback_speed → existing MediaRetimer behavior (unchanged)
- `--backend asciinema` with playback_speed → retime the agg-produced gif/webm

### Success Criteria

- [ ] `ace-demo record` uses asciinema by default for YAML tapes
- [ ] `--backend` CLI flag overrides tape.yml and config defaults
- [ ] tape.yml `settings.backend` key accepted and validated by DemoYamlParser
- [ ] DemoRecorder dispatches to correct backend based on resolution order
- [ ] asciinema pipeline: compile → record → convert → retime (if needed)
- [ ] VHS pipeline unchanged when selected explicitly
- [ ] Raw `.tape` files continue to use VHS (no regression)
- [ ] Both `.cast` and visual artifact paths returned/reported to user

## Vertical Slice Decomposition

Single subtask — backend integration is one cohesive change to DemoRecorder + CLI + schema.

- **Slice**: Backend dispatch + asciinema default in recording pipeline
- **Advisory size**: Medium
- **Context**: Depends on atoms/molecules from .1

## Verification Plan

### Unit/Component Validation
- [ ] DemoYamlParser accepts `settings.backend` key (asciinema, vhs)
- [ ] DemoYamlParser rejects unknown backend values
- [ ] DemoRecorder routes to asciinema when backend is asciinema or nil
- [ ] DemoRecorder routes to VHS when backend is vhs
- [ ] CLI `--backend` flag parsed and forwarded correctly

### Integration Validation
- [ ] Full asciinema recording: tape.yml → .cast → gif via agg
- [ ] Full VHS recording with `--backend vhs` (regression check)
- [ ] Playback speed retiming works with asciinema pipeline

### Failure Path Validation
- [ ] Unknown backend value produces actionable error
- [ ] Missing asciinema binary produces clear install instructions
- [ ] Missing agg binary produces clear install instructions

### Verification Commands
- [ ] `ace-demo record sample-tape` → produces .cast + .gif
- [ ] `ace-demo record sample-tape --backend vhs` → produces .gif (VHS)
- [ ] `ace-test` in ace-demo passes all existing + new tests
