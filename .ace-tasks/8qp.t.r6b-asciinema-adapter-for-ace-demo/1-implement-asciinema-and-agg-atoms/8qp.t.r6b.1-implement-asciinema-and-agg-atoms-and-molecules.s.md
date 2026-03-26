---
id: 8qp.t.r6b.1
status: draft
priority: medium
created_at: "2026-03-26 22:32:59"
estimate: TBD
dependencies: ["8qp.t.r6b.0"]
tags: [ace-demo, asciinema, agg, atoms, molecules]
parent: 8qp.t.r6b
bundle:
  presets: ["project"]
  files:
    - ace-demo/lib/ace/demo/atoms/vhs_command_builder.rb
    - ace-demo/lib/ace/demo/atoms/vhs_tape_compiler.rb
    - ace-demo/lib/ace/demo/molecules/vhs_executor.rb
    - ace-demo/lib/ace/demo/models/execution_result.rb
    - ace-demo/lib/ace/demo/atoms/demo_yaml_parser.rb
    - ace-demo/.ace-defaults/demo/config.yml
    - ace-demo/test/atoms/vhs_command_builder_test.rb
    - ace-demo/test/atoms/vhs_tape_compiler_test.rb
    - ace-demo/test/molecules/vhs_executor_test.rb
  commands: []
---

# Implement Asciinema and Agg Atoms and Molecules

## Objective

Build the asciinema and agg components following the established ATOM pattern, mirroring the existing VHS atoms/molecules. These components are the building blocks that subtask .2 will wire into the DemoRecorder pipeline.

## Behavioral Specification

### User Experience

- **Input**: Parsed tape.yml spec (from DemoYamlParser) and configuration
- **Process**: Components build commands, compile tape specs to asciinema scripts, execute recordings, and convert output
- **Output**: `.cast` files from asciinema; gif/webm files from agg

### Expected Behavior

**AsciinemaCommandBuilder** (atom):
- Builds the shell command array for asciinema invocation
- Accepts: output path, script path, optional cols/rows/env settings
- Returns: command array `[asciinema_bin, "rec", "--command", script, "--cols", w, "--rows", h, output_path]`
- Configurable binary path via `Demo.config["asciinema_bin"]`

**AsciinemaTapeCompiler** (atom):
- Converts parsed tape.yml spec into a bash script that asciinema will execute
- Generates: sequential shell commands with sleep intervals between them
- Handles: scene grouping, command types, sleep directives
- Output: bash script content (string) to write to sandbox as `.compiled.sh`
- Mirrors VhsTapeCompiler but produces bash instead of VHS syntax

**AsciinemaExecutor** (molecule):
- Executes asciinema binary, validates availability
- Uses `Open3.capture3` like VhsExecutor
- Returns `ExecutionResult` model (stdout, stderr, exit_code, success)
- Raises `AsciinemaNotFoundError` when binary missing
- Raises `AsciinemaExecutionError` on failure with stderr details

**AggCommandBuilder** (atom):
- Builds command array for agg invocation (`.cast` → gif/webm)
- Accepts: input `.cast` path, output path, optional theme/font-size
- Returns: command array `[agg_bin, input_cast, output_path]`
- Configurable binary path via `Demo.config["agg_bin"]`

**AggExecutor** (molecule):
- Executes agg binary for `.cast` → gif/webm conversion
- Returns `ExecutionResult` model
- Raises `AggNotFoundError` / `AggExecutionError`

### Interface Contract

```ruby
# AsciinemaCommandBuilder (atom)
AsciinemaCommandBuilder.build(output_path:, script_path:, cols: 80, rows: 24, env: {})
# => ["asciinema", "rec", "--command", "bash script.sh", "--cols", "80", "--rows", "24", "output.cast"]

# AsciinemaTapeCompiler (atom)
AsciinemaTapeCompiler.compile(spec, sandbox_path:)
# => "/path/to/sandbox/.compiled.sh"  (writes script, returns path)

# AsciinemaExecutor (molecule)
executor = AsciinemaExecutor.new
executor.run(command, chdir: sandbox_path)
# => ExecutionResult(stdout:, stderr:, exit_code:, success:)

# AggCommandBuilder (atom)
AggCommandBuilder.build(input_path:, output_path:, font_size: 16)
# => ["agg", "input.cast", "output.gif"]

# AggExecutor (molecule)
executor = AggExecutor.new
executor.run(command)
# => ExecutionResult(stdout:, stderr:, exit_code:, success:)
```

Error Handling:
- `AsciinemaNotFoundError` — asciinema binary not found, includes install instructions
- `AsciinemaExecutionError` — recording failed, includes stderr
- `AggNotFoundError` — agg binary not found, includes install instructions
- `AggExecutionError` — conversion failed, includes stderr

Edge Cases:
- Empty scenes list — raise `DemoYamlParseError` (existing validation)
- Commands with special characters — bash script escaping in compiler
- Missing env vars in settings — pass empty env hash (no error)

### Success Criteria

- [ ] AsciinemaCommandBuilder produces correct command arrays for all tape.yml settings
- [ ] AsciinemaTapeCompiler converts tape.yml scenes to valid bash scripts with sleep intervals
- [ ] AsciinemaExecutor records `.cast` files that are valid asciinema v2 JSON
- [ ] AggCommandBuilder produces correct command arrays for gif/webm conversion
- [ ] AggExecutor converts `.cast` to gif/webm successfully
- [ ] All components return `ExecutionResult` model consistently
- [ ] Error classes follow existing pattern (inherit from `Ace::Demo::Error`)
- [ ] Config keys `asciinema_bin` and `agg_bin` added to `.ace-defaults/demo/config.yml`

## Vertical Slice Decomposition

Single subtask — all atoms/molecules are tightly coupled and tested together.

- **Slice**: Complete asciinema + agg component layer
- **Advisory size**: Medium
- **Context**: Depends on spike (.0) findings for asciinema invocation patterns

## Verification Plan

### Unit/Component Validation
- [ ] AsciinemaCommandBuilder: correct args for various settings combinations
- [ ] AsciinemaTapeCompiler: bash script output matches expected for multi-scene tape
- [ ] AsciinemaTapeCompiler: special characters in commands are properly escaped
- [ ] AggCommandBuilder: correct args for gif and webm formats
- [ ] AsciinemaExecutor: returns ExecutionResult with correct fields
- [ ] AggExecutor: returns ExecutionResult with correct fields

### Integration Validation
- [ ] Full pipeline: compile → record → convert produces valid gif from tape.yml

### Failure Path Validation
- [ ] AsciinemaExecutor raises AsciinemaNotFoundError when binary missing
- [ ] AsciinemaExecutor raises AsciinemaExecutionError on recording failure
- [ ] AggExecutor raises AggNotFoundError when binary missing
- [ ] AggExecutor raises AggExecutionError on conversion failure
