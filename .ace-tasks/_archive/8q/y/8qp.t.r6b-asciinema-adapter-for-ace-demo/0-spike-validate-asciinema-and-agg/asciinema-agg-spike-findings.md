# 8qp.t.r6b.0 Spike Findings: Asciinema + Agg Pipeline

## Scope
Validate whether `asciinema` can record a `tape.yml` scenario in the existing sandbox model and whether `agg` can convert resulting `.cast` artifacts to GIF.

## Environment and Versions
- `asciinema`: `asciinema 3.2.0`
- `agg`: `agg 1.7.0`
- Runtime architecture: `aarch64`

## Evidence Artifacts
- Main cast: `.ace-local/demo/spikes/8qp.t.r6b.0/recording.cast`
- Main gif: `.ace-local/demo/spikes/8qp.t.r6b.0/recording.gif`
- Metadata: `.ace-local/demo/spikes/8qp.t.r6b.0/metadata.json`
- Empty-script cast: `.ace-local/demo/spikes/8qp.t.r6b.0/empty.cast`
- Invalid-script cast: `.ace-local/demo/spikes/8qp.t.r6b.0/invalid.cast`
- Incompatible-format cast: `.ace-local/demo/spikes/8qp.t.r6b.0/incompatible.cast`

## Execution Results
- `DemoSandboxBuilder` flow validated: sandbox was created at `.ace-local/demo/sandbox/8qqgnu` using tape setup directives.
- Asciinema recording succeeded in headless mode and generated a parseable cast.
- Cast header produced by `asciinema 3.2.0` is v3 (`"version": 3`).
- Cast event line contains recorded command output (`echo 'Hello from tape with recording options!'`).
- Agg conversion from cast to GIF succeeded with explicit font selection:
  - Working command: `agg --font-family "Hack Nerd Font Mono" recording.cast recording.gif`

## Failure-Path Observations
- Missing tool behavior before install:
  - `asciinema --version` -> `command not found`
  - `agg --version` -> `command not found`
- Empty script behavior:
  - `asciinema` still writes a valid cast header (`empty.cast`).
  - `agg` fails to render GIF with: `Found no usable frames to encode`.
- Invalid script behavior:
  - `asciinema` exits successfully but records shell error output in cast events.
  - Error text appears in cast event payload: `command not found`.
- Incompatible cast format behavior:
  - Forcing cast header to version 4 causes `agg` to fail with:
    `not a v1, v2, v3 asciicast file`.

## Flag and Concept Mapping

### Mapping from Current VHS-Oriented Concepts
- `settings.width` / `settings.height` -> still relevant; map to terminal geometry or cast metadata expectations.
- `settings.env` -> still relevant; use env exports for recording command execution.
- Scene command list -> still relevant; compile to executable shell script consumed by `asciinema rec --command`.
- Sandbox setup/teardown -> survives unchanged as orchestration concern.

### Concepts Needing New Abstractions
- Recorder command builder:
  - VHS: direct `vhs <tape> --output <gif/webm>`
  - New: `asciinema rec ... <cast>` plus separate agg conversion command.
- Output model:
  - VHS path returns one visual artifact.
  - New model should preserve both `.cast` (source-of-truth) and GIF (visual artifact).
- Compatibility validation:
  - Need explicit cast-version guard for agg-compatible versions (v1-v3).
- Rendering prerequisites:
  - agg may require explicit font configuration in some environments.

## Compatibility Decision
- **Chosen strategy**: accept asciinema-generated v3 casts directly (no normalization step required for this version), then convert with agg.
- **Guardrail**: add explicit compatibility validation with actionable error if cast version is unsupported by agg.

## Recommended Production Invocation Contract
1. Record in sandbox:
   - `asciinema rec --overwrite --command "bash <compiled-script>" <output.cast>`
2. Convert visual artifact:
   - `agg [--font-family <configured-font>] <output.cast> <output.gif>`
3. Keep `.cast` as primary machine-readable artifact and GIF as derived output.
4. Add config keys for binaries and optional agg font override:
   - `asciinema_bin`, `agg_bin`, `agg_font_family`.

## Answered Spike Questions
- Does asciinema work in sandbox with custom context? **Yes**.
- Can it run non-interactively? **Yes** (`--command` headless mode works).
- Can agg convert resulting cast to GIF? **Yes**, with explicit font choice in this environment.
- Does cast need conversion before agg? **No** for asciinema v3 output; agg consumed v3 directly.
- What compatibility path should we use? **Direct cast consumption + version guard**, no v3->v2 converter required.
