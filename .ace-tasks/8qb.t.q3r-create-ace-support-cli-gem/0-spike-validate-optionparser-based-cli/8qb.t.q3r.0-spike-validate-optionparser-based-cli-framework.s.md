---
id: 8qb.t.q3r.0
status: done
priority: high
created_at: "2026-03-12 17:25:42"
estimate: Small
dependencies: []
tags: [cli, spike, optionparser]
parent: 8qb.t.q3r
bundle:
  presets: [project]
  files: [ace-support-core/lib/ace/core/cli/dry_cli/base.rb, ace-support-core/lib/ace/core/cli/dry_cli/argv_coalescer.rb]
  commands: []
needs_review: false
---

# Spike: Validate OptionParser-based CLI framework end-to-end

## Behavioral Specification

### User Experience
- **Input**: A time-boxed proof-of-concept command using Ruby's stdlib `OptionParser` that exercises all option types used across the monorepo.
- **Process**: The spike validates that OptionParser can replicate dry-cli's parsing behavior with automatic type coercion, without monkey-patches or workarounds.
- **Output**: A working proof-of-concept command demonstrating each option type, plus a concept inventory documenting what survives from dry-cli vs what's new.

### Expected Behavior

This spike proves viability before committing to a full gem implementation. It must validate:
1. **Integer coercion**: `--timeout 30` arrives as `Integer` in `call()`, not `String`. Invalid values like `--timeout abc` produce a clear parse error.
2. **Float coercion**: `--rate 1.5` arrives as `Float`. Invalid values produce a clear parse error.
3. **Boolean flags**: `--verbose` / `--[no-]verbose` toggle `true`/`false`.
4. **String options**: `--name foo` arrives as `String` (baseline, should work trivially).
5. **Array accumulation**: `--tag a --tag b` accumulates to `["a", "b"]` without ARGV preprocessing.
6. **Positional arguments**: `command arg1 arg2` parses positional args in declared order.
7. **End-of-options**: `--` terminates option parsing; remaining tokens are positional.
8. **Mixed positional + keyword**: `mycommand arg1 --timeout 30 arg2` handles interleaved args and options.
9. **Default values**: Defaults respect declared types (integer default is `Integer`, not `String`).
10. **DSL compatibility**: The proof-of-concept uses `option` and `argument` declarations similar to dry-cli.

### Interface Contract

```ruby
# Proof-of-concept command
class SpikeCommand
  option :timeout, type: :integer, default: 30, desc: "Timeout in seconds"
  option :rate,    type: :float,   default: 1.0, desc: "Rate limit"
  option :verbose, type: :boolean, default: false, desc: "Verbose output"
  option :tags,    type: :array,   desc: "Tags to apply"
  option :format,  type: :string,  default: "json", desc: "Output format"

  argument :input,  required: true,  desc: "Input file"
  argument :output, required: false, desc: "Output file"

  def call(input:, output: nil, timeout:, rate:, verbose:, tags:, format:, **)
    timeout.is_a?(Integer)  # => true
    rate.is_a?(Float)       # => true
    verbose.is_a?(TrueClass) || verbose.is_a?(FalseClass)  # => true
    tags.is_a?(Array)       # => true
    input.is_a?(String)     # => true
  end
end
```

```bash
# Test invocations
spike input.txt --timeout 30 --rate 1.5 --verbose --tag a --tag b
spike input.txt output.txt --timeout 60
spike input.txt -- --not-a-flag
spike input.txt --timeout abc  # => ParseError
```

**Error Handling:**
- `--timeout abc` raises a parse error mentioning the invalid integer value.
- `--rate not-a-number` raises a parse error mentioning the invalid float value.
- Missing required positional argument raises a parse error listing the argument name.

**Edge Cases:**
- `--timeout=30` (equals-sign form) works identically to `--timeout 30`.
- `--no-verbose` sets verbose to `false` even if default is `true`.
- Empty `--tag` (no value) is rejected rather than silently producing `nil`.
- Hash option `--header key:value` parses to `{"key" => "value"}` (1 usage in monorepo).

### Success Criteria

- [x] **Integer coercion proven**: `--timeout 30` yields `Integer` value `30`.
- [x] **Float coercion proven**: `--rate 1.5` yields `Float` value `1.5`.
- [x] **Boolean toggle proven**: `--verbose` / `--no-verbose` yields `true` / `false`.
- [x] **Array accumulation proven**: repeated `--tag` flags accumulate into a single array.
- [x] **Positional parsing proven**: positional args parse in declared order with required/optional distinction.
- [x] **End-of-options proven**: `--` stops option parsing.
- [x] **Mixed args+options proven**: interleaved positional args and options parse correctly.
- [x] **Parse errors are clear**: invalid types produce user-friendly messages.
- [x] **Kill criteria evaluated**: document whether OptionParser handles all cases or if a pivot is needed.

### Validation Questions

- [x] **Should the spike be time-boxed?** -> Yes, this is a validation exercise not a production implementation.
- [x] **What triggers the kill criteria?** -> If OptionParser cannot handle mixed positional+keyword args or array accumulation natively, pivot to wrapping dry-cli parser with a coercion post-processor.
- [x] **Does the spike need tests?** -> Informal validation is sufficient; formal tests come in subtask 1.

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Subtask (spike)
- **Slice Outcome**: Validated that OptionParser can serve as the foundation for ace-support-cli, with documented concept inventory of what survives from dry-cli vs what's new.
- **Advisory Size**: small
- **Context Dependencies**: dry-cli DSL surface, OptionParser stdlib capabilities, current option type distribution (boolean:420, string:187, integer:33, array:27, hash:1, float:1)

### Verification Plan

#### Unit / Component Validation
- [x] Proof-of-concept command exercises all 6 option types (string, integer, float, boolean, array, hash).
- [x] Proof-of-concept command exercises required and optional positional arguments.

#### Integration / E2E Validation
- [x] End-to-end invocation from ARGV through parsing to typed `call()` arguments.

#### Failure / Invalid-Path Validation
- [x] Invalid integer, float values produce clear parse errors.
- [x] Missing required arguments produce clear parse errors.

#### Verification Commands
- [x] Run the proof-of-concept with representative invocations and verify types.

### Implementation Notes

- Spike command implementation: `ace-support-core/dev/spikes/option_parser_cli_spike.rb`
- Runner used for command validation: `ace-support-core/dev/spikes/run_option_parser_cli_spike.rb`
- Validation transcript: `.ace-tasks/8qb.t.q3r-create-ace-support-cli-gem/0-spike-validate-optionparser-based-cli/artifacts/8qb.t.q3r.0-validation-log.md`
- Concept inventory + kill criteria decision: `.ace-tasks/8qb.t.q3r-create-ace-support-cli-gem/0-spike-validate-optionparser-based-cli/artifacts/8qb.t.q3r.0-optionparser-concept-inventory.md`

## Objective

Prove that Ruby's stdlib OptionParser can replicate dry-cli's command parsing with automatic type coercion, justifying the investment in a full gem before committing the ecosystem.

## Scope of Work

- **User Experience Scope**: A single proof-of-concept command exercising all option types.
- **System Behavior Scope**: OptionParser-based parsing with type coercion, array accumulation, positional args, end-of-options.
- **Interface Scope**: Command DSL shape compatible with dry-cli's `option` and `argument` declarations.

### Deliverables

#### Behavioral Specifications
- Proof-of-concept command with all option types
- Concept inventory: what survives from dry-cli, what's new, what's removed

#### Validation Artifacts
- Test invocations proving each option type
- Kill criteria evaluation document

### Consumer Packages

- None (spike only — informs subtask 1)

## Out of Scope

- ❌ Production-quality code or gem structure
- ❌ Help formatting
- ❌ Registry or multi-command routing
- ❌ Migration of any existing commands

## References

- Parent: 8qb.t.q3r — Create ace-support-cli gem to replace dry-cli
- `ace-support-core/lib/ace/core/cli/dry_cli/base.rb` (current DSL surface)
- `ace-support-core/lib/ace/core/cli/dry_cli/argv_coalescer.rb` (array workaround to eliminate)
