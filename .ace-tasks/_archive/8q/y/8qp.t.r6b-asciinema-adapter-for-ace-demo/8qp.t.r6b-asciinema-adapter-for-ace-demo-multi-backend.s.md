---
id: 8qp.t.r6b
status: done
priority: medium
created_at: "2026-03-26 18:07:01"
estimate: TBD
dependencies: []
tags: [ace-demo, recording, asciinema, adapter, verification]
bundle:
  presets: [project]
  files: [ace-demo/lib/ace/demo/cli/commands/record.rb, ace-demo/lib/ace/demo/cli/commands/attach.rb, ace-demo/lib/ace/demo/organisms/demo_recorder.rb, ace-demo/lib/ace/demo/organisms/demo_attacher.rb, ace-demo/lib/ace/demo/atoms/vhs_tape_compiler.rb, ace-demo/lib/ace/demo/atoms/vhs_command_builder.rb, ace-demo/lib/ace/demo/molecules/vhs_executor.rb, ace-demo/lib/ace/demo/atoms/demo_yaml_parser.rb, ace-demo/docs/usage.md, ace-demo/.ace-defaults/demo/config.yml, .ace-tasks/8qp.t.r6b-asciinema-adapter-for-ace-demo/2-integrate-asciinema-as-default-recording/ux-usage.md]
  commands: []
needs_review: false
worktree:
  branch: r6b-asciinema-adapter-for-ace-demo-multi-backend-recording
  path: ../ace-t.r6b
  created_at: "2026-03-27 10:57:47"
  updated_at: "2026-03-27 10:57:47"
  target_branch: main
---

# Asciinema Adapter for ace-demo Multi-Backend Recording

## Objective

Replace VHS as the default recording backend for YAML tapes with asciinema, enabling text-based `.cast` recordings that can be programmatically verified and converted to GIF visual artifacts via `agg`. This gives us a unified tape definition (`tape.yml`) where asciinema captures the verifiable source-of-truth and agg produces the PR/documentation artifact. VHS remains available as an explicit compatibility backend for GIF and WebM output.

Originated from idea `8qpnt9`: the core motivation is that `.cast` JSON files are searchable, lightweight, and CI-verifiable — unlike binary GIFs.

## Behavioral Specification

### User Experience

- **Input**: Existing `tape.yml` files with optional `settings.backend` key (default: `asciinema`) and optional `--backend` CLI override
- **Process**: `ace-demo record` dispatches to asciinema by default for YAML tapes, produces a `.cast`, converts it to a GIF via `agg`, and runs non-blocking command-presence verification against the cast. Raw `.tape` files continue to use VHS.
- **Output**: Structured recording result containing backend, visual artifact path, optional `.cast` path, and verification status/details

### Expected Behavior

When a developer runs `ace-demo record my-tape`, the system:
1. Parses `tape.yml` and selects the recording backend (asciinema by default)
2. Sets up sandbox, compiles tape to backend-specific format
3. Records via asciinema, producing a persisted `.cast` artifact that is compatible with the downstream `agg` pipeline
4. Converts the `.cast` to GIF via agg
5. Verifies the `.cast` by confirming expected commands were recorded; verification emits details but does not fail the recording command
6. Returns a structured result exposing backend, `visual_path`, optional `cast_path`, and verification metadata

VHS remains available as `--backend vhs` or `settings.backend: vhs` for backward compatibility. VHS remains the only path for WebM output. `mp4` support is removed from this feature line.

### Interface Contract

```bash
# Default recording (asciinema)
ace-demo record my-tape
# => Records .cast, converts to gif via agg, verifies command presence

# Explicit backend override
ace-demo record my-tape --backend vhs
# => Uses VHS compatibility path

# tape.yml settings
settings:
  backend: asciinema  # default, can be omitted
  format: gif         # asciinema path supports gif only
```

```ruby
DemoRecorder.record(...)
# => RecordingResult(
#      backend: "asciinema" | "vhs",
#      visual_path: "/abs/path/demo.gif",
#      cast_path: "/abs/path/demo.cast" | nil,
#      verification: VerificationResult | nil
#    )
```

### Success Criteria

- [ ] asciinema is the default recording backend for all new recordings
- [ ] `.cast` files produced from tape.yml specs via asciinema and retained as the primary machine-readable artifact
- [ ] agg converts `.cast` to GIF for visual output and PR attachment
- [ ] Verification confirms expected commands were recorded in the `.cast` and reports actionable warning details without failing the record command
- [ ] VHS remains functional as opt-in backend (`--backend vhs`)
- [ ] Existing tape.yml files work without modification (asciinema default is non-breaking)
- [ ] WebM remains available only through the explicit VHS backend
- [ ] `mp4` is no longer accepted by `ace-demo record`
- [ ] PR attachment workflow supports asciinema-first flow (.cast → agg → gif → attach)

## Vertical Slice Decomposition (Task/Subtask Model)

| Subtask | Slice | Advisory Size |
|---------|-------|---------------|
| 8qp.t.r6b.0 | Spike: validate asciinema + agg pipeline end-to-end | Small |
| 8qp.t.r6b.1 | Asciinema and agg atoms/molecules (ATOM pattern) | Medium |
| 8qp.t.r6b.2 | Backend selection in DemoRecorder, asciinema as default | Medium |
| 8qp.t.r6b.3 | Cast verification logic + PR attachment integration | Medium |

## Concept Inventory

| Concept | Introduced by | Removed by | Status |
|---------|--------------|------------|--------|
| AsciinemaCommandBuilder | .1 | — | NEW |
| AsciinemaTapeCompiler | .1 | — | NEW |
| AsciinemaExecutor | .1 | — | NEW |
| AggCommandBuilder | .1 | — | NEW |
| AggExecutor | .1 | — | NEW |
| settings.backend key | .2 | — | NEW |
| CastFileParser | .3 | — | NEW |
| CastVerifier | .3 | — | NEW |
| VhsCommandBuilder | existing | — | KEPT |
| VhsTapeCompiler | existing | — | KEPT |
| VhsExecutor | existing | — | KEPT |
| DemoRecorder | existing | — | MODIFIED |

## Out of Scope

- Removing VHS support entirely
- Streaming/live recording capabilities
- Interactive terminal session recording
- Custom asciinema themes or player embedding
- Semantic output assertions beyond command-presence verification
- Uploading `.cast` files directly to PR comments or releases

## References

- Source idea: `8qpnt9` — asciinema adapter for ace-demo multi-backend recording
- Latest asciinema CLI defaults to asciicast v3; this task must persist a cast artifact that remains compatible with `agg`
- agg is treated as the GIF renderer in this task line
