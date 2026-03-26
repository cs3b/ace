---
id: 8qp.t.r6b.0
status: draft
priority: medium
created_at: "2026-03-26 22:32:56"
estimate: TBD
dependencies: []
tags: [ace-demo, asciinema, agg, spike]
parent: 8qp.t.r6b
bundle:
  presets: ["project"]
  files:
    - ace-demo/lib/ace/demo/organisms/demo_recorder.rb
    - ace-demo/lib/ace/demo/molecules/vhs_executor.rb
    - ace-demo/lib/ace/demo/atoms/vhs_tape_compiler.rb
    - ace-demo/lib/ace/demo/atoms/vhs_command_builder.rb
    - ace-demo/lib/ace/demo/molecules/demo_sandbox_builder.rb
    - ace-demo/lib/ace/demo/atoms/demo_yaml_parser.rb
    - ace-demo/.ace-defaults/demo/config.yml
    - ace-demo/docs/demo/fixtures/sample-project/demo.tape.yml
  commands: []
---

# Spike: Validate Asciinema and Agg Recording Pipeline

## Objective

Time-boxed spike to prove that asciinema can record a tape.yml scenario inside the existing ace-demo sandbox and that agg can convert the resulting `.cast` file to gif. Produces a concept inventory showing which existing VHS concepts survive, which get abstracted, and what the final multi-backend architecture looks like.

## Behavioral Specification

### User Experience

- **Input**: An existing `tape.yml` file from ace-demo fixtures
- **Process**: Manually drive asciinema recording of one scenario in a sandbox, convert with agg
- **Output**: A working `.cast` file, a gif converted via agg, and a concept inventory document

### Expected Behavior

1. Install/verify `asciinema` and `agg` are available on the system
2. Take an existing `tape.yml` fixture (e.g., `sample-project/demo.tape.yml`)
3. Build a sandbox via the existing `DemoSandboxBuilder`
4. Manually construct an asciinema recording command that captures the tape's commands
5. Execute asciinema in the sandbox, producing a `.cast` file
6. Run agg on the `.cast` file to produce a gif
7. Verify: the `.cast` file contains JSON event lines matching the executed commands
8. Document findings: what worked, what needed adaptation, concept inventory

### Interface Contract

No public interface changes in this spike. This is exploratory validation.

```bash
# Spike validation commands (manual, not production)
asciinema rec --command "bash script.sh" output.cast
agg output.cast output.gif
```

Key questions to answer:
- Does asciinema work in a sandboxed directory with custom env vars?
- Can we script asciinema to run commands non-interactively?
- Does agg produce acceptable gif quality from `.cast`?
- What asciinema flags map to tape.yml settings (width, height, font_size)?

### Success Criteria

- [ ] asciinema records a tape.yml scenario in sandbox, producing valid `.cast` file
- [ ] agg converts `.cast` to gif successfully
- [ ] `.cast` file contains parseable JSON with command/output event data
- [ ] Concept inventory documents: what survives from VHS pattern, what needs new abstraction
- [ ] Clear recommendation on asciinema invocation pattern for tape compilation

### Validation Questions

- Does asciinema support `--cols` and `--rows` to match tape.yml width/height settings?
- Can asciinema run a script file non-interactively (no TTY required)?
- Does agg support format selection (gif vs webm) or just gif?
- Are there sandbox permission/isolation concerns with asciinema?

## Vertical Slice Decomposition

Single standalone spike — no further decomposition needed.

- **Slice**: End-to-end asciinema + agg validation
- **Advisory size**: Small
- **Verification**: `.cast` file exists and is valid JSON; gif file exists and is viewable

## Verification Plan

### Unit/Component Validation
- [ ] `.cast` file is valid asciinema v2 format (JSON header + event lines)
- [ ] `.cast` events contain typed commands and their output

### Integration Validation
- [ ] asciinema works inside DemoSandboxBuilder-created sandbox
- [ ] agg produces gif from the `.cast` file without errors

### Failure Path Validation
- [ ] Document behavior when asciinema is not installed
- [ ] Document behavior when agg is not installed
- [ ] Document behavior with invalid/empty script input
