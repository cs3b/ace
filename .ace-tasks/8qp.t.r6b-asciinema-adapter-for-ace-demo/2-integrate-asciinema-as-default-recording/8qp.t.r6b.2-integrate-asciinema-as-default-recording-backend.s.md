---
id: 8qp.t.r6b.2
status: pending
priority: medium
created_at: "2026-03-26 22:33:02"
estimate: TBD
dependencies: [8qp.t.r6b.1]
tags: [ace-demo, asciinema, backend-selection, integration]
parent: 8qp.t.r6b
bundle:
  presets: [project]
  files: [ace-demo/lib/ace/demo/cli/commands/record.rb, ace-demo/lib/ace/demo/organisms/demo_recorder.rb, ace-demo/lib/ace/demo/atoms/demo_yaml_parser.rb, ace-demo/lib/ace/demo/molecules/demo_sandbox_builder.rb, ace-demo/lib/ace/demo/cli/commands/attach.rb, ace-demo/.ace-defaults/demo/config.yml, ace-demo/docs/usage.md, ace-demo/test/organisms/demo_recorder_test.rb, .ace-tasks/8qp.t.r6b-asciinema-adapter-for-ace-demo/2-integrate-asciinema-as-default-recording/ux-usage.md]
  commands: []
needs_review: false
---

# Integrate Asciinema as Default Recording Backend

## Objective

Wire asciinema into the DemoRecorder pipeline as the default backend for YAML tapes. The recording flow becomes: tape.yml → asciinema → `.cast` → agg → GIF. VHS remains available via explicit opt-in for compatibility output modes. The tape.yml schema gains a `backend` setting, the CLI gains a `--backend` override flag, and `DemoRecorder` moves from returning a single path to returning a structured recording result.

## Behavioral Specification

### User Experience

- **Input**: `ace-demo record <tape>` with optional `--backend` flag
- **Process**: DemoRecorder selects backend (asciinema default), records, converts via agg
- **Output**: `RecordingResult` with backend, visual artifact path, optional `.cast` path, and verification metadata

### Expected Behavior

**Default recording (asciinema)**:
1. User runs `ace-demo record my-tape` (no flags)
2. DemoRecorder parses tape.yml, sees no `backend` setting or `backend: asciinema`
3. Builds sandbox via DemoSandboxBuilder (unchanged)
4. Compiles tape to bash script via AsciinemaTapeCompiler
5. Records via AsciinemaExecutor → produces `.cast` file
6. Converts `.cast` via AggExecutor → produces GIF
7. Applies playback_speed retiming if configured (on the GIF, not the `.cast`)
8. Runs teardown (unchanged)
9. Returns `RecordingResult` with `backend: "asciinema"`, `cast_path`, `visual_path`, and verification placeholder/result slot for `.3`

**VHS fallback**:
1. User runs `ace-demo record my-tape --backend vhs` or tape has `backend: vhs`
2. DemoRecorder follows existing VHS pipeline (unchanged behavior)

**Backend resolution order**:
1. CLI `--backend` flag (highest priority)
2. tape.yml `settings.backend` key
3. Config default: `asciinema`

**Format resolution**:
1. `mp4` is rejected for all backends
2. `gif` is valid for both backends
3. `webm` requires `backend: vhs` or `--backend vhs`
4. YAML tapes resolving to asciinema reject non-GIF visual formats with an actionable error

### Interface Contract

```bash
# Default: asciinema (no flag needed)
ace-demo record my-tape
# => Recorded backend: asciinema
# => Cast: .ace-local/demo/my-tape.cast
# => Output: .ace-local/demo/my-tape.gif

# Explicit asciinema
ace-demo record my-tape --backend asciinema

# Legacy VHS
ace-demo record my-tape --backend vhs --format webm
# => Output: .ace-local/demo/my-tape.webm

# tape.yml schema addition
settings:
  backend: asciinema   # or "vhs"; default "asciinema" when omitted
  format: gif          # asciinema path supports gif only
  font_size: 16
  width: 960
  height: 480
```

```ruby
DemoRecorder.record(...)
# => RecordingResult(
#      backend: "asciinema" | "vhs",
#      visual_path: "/abs/path/demo.gif",
#      cast_path: "/abs/path/demo.cast" | nil,
#      verification: nil | VerificationResult
#    )
```

Error Handling:
- Unknown backend value → clear error: `Unknown backend 'foo'. Valid: asciinema, vhs`
- asciinema not installed → `AsciinemaNotFoundError` with install instructions
- agg not installed → `AggNotFoundError` with install instructions (for format conversion)
- `mp4` requested → actionable error describing that `mp4` is no longer supported
- `webm` requested with asciinema backend → actionable error directing the caller to `--backend vhs`

Edge Cases:
- Existing tapes without `backend` key → asciinema (new default)
- Raw `.tape` files (non-YAML) → VHS only (no change to raw tape behavior)
- `--backend vhs` with playback_speed → existing MediaRetimer behavior (unchanged)
- `--backend asciinema` with playback_speed → retime the agg-produced GIF
- `--format webm` without an explicit VHS backend on YAML input → reject, do not silently switch backends

### Success Criteria

- [ ] `ace-demo record` uses asciinema by default for YAML tapes
- [ ] `--backend` CLI flag overrides tape.yml and config defaults
- [ ] tape.yml `settings.backend` key accepted and validated by DemoYamlParser
- [ ] DemoRecorder dispatches to correct backend based on resolution order
- [ ] `DemoRecorder.record` returns a structured recording result exposing backend, visual path, optional cast path, and verification slot/details
- [ ] asciinema pipeline: compile → record → convert to GIF → retime (if needed)
- [ ] VHS pipeline unchanged when selected explicitly
- [ ] Raw `.tape` files continue to use VHS (no regression)
- [ ] `webm` remains available only via explicit VHS selection
- [ ] `mp4` is rejected with an actionable error
- [ ] Both `.cast` and visual artifact paths are reported to the user when asciinema is used

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
- [ ] DemoRecorder rejects `mp4` regardless of backend
- [ ] DemoRecorder rejects `webm` when backend resolves to asciinema
- [ ] CLI `--backend` flag parsed and forwarded correctly

### Integration Validation
- [ ] Full asciinema recording: tape.yml → .cast → gif via agg
- [ ] Full VHS recording with `--backend vhs` (regression check)
- [ ] Playback speed retiming works with asciinema pipeline
- [ ] `ace-demo record sample-tape --backend vhs --format webm` remains supported

### Failure Path Validation
- [ ] Unknown backend value produces actionable error
- [ ] Missing asciinema binary produces clear install instructions
- [ ] Missing agg binary produces clear install instructions
- [ ] `webm` requested on asciinema path produces an actionable error
- [ ] `mp4` requested produces an actionable error

### Verification Commands
- [ ] `ace-demo record sample-tape` → produces .cast + .gif
- [ ] `ace-demo record sample-tape --backend vhs --format webm` → produces .webm (VHS)
- [ ] `ace-demo record sample-tape --format mp4` → fails with unsupported-format guidance
- [ ] `ace-test` in ace-demo passes all existing + new tests
