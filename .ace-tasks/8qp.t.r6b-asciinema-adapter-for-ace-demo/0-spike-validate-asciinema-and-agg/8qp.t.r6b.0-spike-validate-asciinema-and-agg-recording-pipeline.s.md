---
id: 8qp.t.r6b.0
status: pending
priority: medium
created_at: "2026-03-26 22:32:56"
estimate: TBD
dependencies: []
tags: [ace-demo, asciinema, agg, spike]
parent: 8qp.t.r6b
bundle:
  presets: [project]
  files: [ace-demo/lib/ace/demo/organisms/demo_recorder.rb, ace-demo/lib/ace/demo/molecules/vhs_executor.rb, ace-demo/lib/ace/demo/atoms/vhs_tape_compiler.rb, ace-demo/lib/ace/demo/atoms/vhs_command_builder.rb, ace-demo/lib/ace/demo/molecules/demo_sandbox_builder.rb, ace-demo/lib/ace/demo/atoms/demo_yaml_parser.rb, ace-demo/.ace-defaults/demo/config.yml, ace-demo/docs/demo/fixtures/sample-project/demo.tape.yml]
  commands: []
needs_review: false
---

# Spike: Validate Asciinema and Agg Recording Pipeline

## Objective

Time-boxed spike to prove that asciinema can record a tape.yml scenario inside the existing ace-demo sandbox and that agg can convert the resulting `.cast` file to GIF. Produces a concept inventory showing which existing VHS concepts survive, which get abstracted, what the final multi-backend architecture looks like, and which cast-format compatibility path keeps asciinema interoperable with agg.

## Behavioral Specification

### User Experience

- **Input**: An existing `tape.yml` file from ace-demo fixtures
- **Process**: Manually drive asciinema recording of one scenario in a sandbox, convert with agg
- **Output**: A working `.cast` file, a GIF converted via agg, and a concept inventory document that recommends the production invocation contract

### Expected Behavior

1. Install/verify `asciinema` and `agg` are available on the system
2. Take an existing `tape.yml` fixture (e.g., `sample-project/demo.tape.yml`)
3. Build a sandbox via the existing `DemoSandboxBuilder`
4. Manually construct an asciinema recording command that captures the tape's commands
5. Execute asciinema in the sandbox, producing a `.cast` file
6. Confirm whether the recorder emits asciicast v2 directly or requires a conversion step before agg can consume the cast
7. Run agg on the compatible `.cast` file to produce a GIF
8. Verify: the `.cast` file contains JSON event lines matching the executed commands
9. Document findings: what worked, what needed adaptation, final flag mapping, concept inventory, and the chosen v2-compatibility mechanism

### Interface Contract

No public interface changes in this spike. This is exploratory validation.

```bash
# Spike validation commands (manual, not production)
asciinema rec -c "bash script.sh" output.cast
agg output.cast output.gif
```

Key questions to answer:
- Does asciinema work in a sandboxed directory with custom env vars?
- Can we script asciinema to run commands non-interactively?
- Does agg produce acceptable gif quality from `.cast`?
- Which current asciinema flags map to tape.yml settings (window size, env, command)?
- Does the chosen asciinema version need a conversion step to hand agg a v2-compatible cast?

### Success Criteria

- [ ] asciinema records a tape.yml scenario in sandbox, producing valid `.cast` file
- [ ] agg converts `.cast` to gif successfully
- [ ] `.cast` file contains parseable JSON with command/output event data
- [ ] Concept inventory documents: what survives from VHS pattern, what needs new abstraction
- [ ] Clear recommendation on asciinema invocation pattern, cast compatibility strategy, and GIF-only renderer assumptions for production

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
- [ ] Document behavior when the recorder emits a cast format agg cannot consume directly
