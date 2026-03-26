---
id: 8qp.t.r6b
status: draft
priority: medium
created_at: "2026-03-26 18:07:01"
estimate: TBD
dependencies: []
tags: [ace-demo, recording, asciinema, adapter, verification]
bundle:
  presets: ["project"]
  files:
    - ace-demo/lib/ace/demo/organisms/demo_recorder.rb
    - ace-demo/lib/ace/demo/atoms/vhs_tape_compiler.rb
    - ace-demo/lib/ace/demo/atoms/vhs_command_builder.rb
    - ace-demo/lib/ace/demo/molecules/vhs_executor.rb
    - ace-demo/lib/ace/demo/atoms/demo_yaml_parser.rb
    - ace-demo/.ace-defaults/demo/config.yml
  commands: []
---

# Asciinema Adapter for ace-demo Multi-Backend Recording

## Objective

Replace VHS as the default recording backend with asciinema, enabling text-based `.cast` recordings that can be programmatically verified and converted to visual formats (gif/webm) via `agg`. This gives us a unified tape definition (`tape.yml`) where asciinema captures the verifiable source-of-truth and agg produces visual artifacts for PR attachment and documentation.

Originated from idea `8qpnt9`: the core motivation is that `.cast` JSON files are searchable, lightweight, and CI-verifiable — unlike binary GIFs.

## Behavioral Specification

### User Experience

- **Input**: Existing `tape.yml` files with optional `settings.backend` key (default: `asciinema`)
- **Process**: `ace-demo record` dispatches to asciinema by default, producing `.cast` files. agg converts `.cast` to gif/webm for visual output. Verification confirms commands ran and output is valid.
- **Output**: `.cast` file (primary artifact) + gif/webm (visual artifact via agg) + verification result

### Expected Behavior

When a developer runs `ace-demo record my-tape`, the system:
1. Parses `tape.yml` and selects the recording backend (asciinema by default)
2. Sets up sandbox, compiles tape to backend-specific format
3. Records via asciinema, producing a `.cast` file
4. Converts `.cast` to gif/webm via agg
5. Verifies the `.cast` — confirms all commands executed and output is valid
6. Returns paths to both `.cast` and visual artifacts

VHS remains available as `--backend vhs` or `settings.backend: vhs` for backward compatibility.

### Interface Contract

```bash
# Default recording (asciinema)
ace-demo record my-tape
# => Records .cast, converts to gif via agg, verifies

# Explicit backend override
ace-demo record my-tape --backend vhs
# => Uses VHS (legacy behavior)

# tape.yml settings
settings:
  backend: asciinema  # default, can be omitted
  format: gif         # agg output format: gif, webm
```

### Success Criteria

- [ ] asciinema is the default recording backend for all new recordings
- [ ] `.cast` files produced from tape.yml specs via asciinema
- [ ] agg converts `.cast` to gif/webm for visual output and PR attachment
- [ ] Verification confirms commands ran AND output is valid from `.cast`
- [ ] VHS remains functional as opt-in backend (`--backend vhs`)
- [ ] Existing tape.yml files work without modification (asciinema default is non-breaking)
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

## References

- Source idea: `8qpnt9` — asciinema adapter for ace-demo multi-backend recording
- asciinema v2 cast format: header JSON line + event JSON lines
- agg: asciinema gif/webm generator
