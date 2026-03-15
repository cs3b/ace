# 8qb.t.q3r.0 OptionParser Concept Inventory

Date: 2026-03-13
Decision: **GO** - proceed with OptionParser foundation for `ace-support-cli`.

## Capability Matrix

| Capability | dry-cli state in repo | OptionParser spike result | Outcome |
| --- | --- | --- | --- |
| Integer coercion | Manual `convert_types` needed | Native `Integer` conversion in parser callback | KEPT (simpler) |
| Float coercion | Manual `convert_types` needed | Native `Float` conversion in parser callback | KEPT (simpler) |
| Boolean toggles | Works via dry-cli option typing | Native `--[no-]flag` support | KEPT |
| String options | Works | Works | KEPT |
| Array accumulation | Requires `ArgvCoalescer` preprocessing | Repeated `--tag` accumulated directly in callback | KEPT (workaround removed) |
| Hash parsing | Rare usage; custom handling required | `key:value` split + validation works | KEPT (explicit parser branch) |
| Positional arguments | Works | Works with required/optional mapping | KEPT |
| End-of-options (`--`) | Works | Works | KEPT |
| Mixed positional + options | Works | Works (`arg1 --timeout 30 arg2`) | KEPT |
| Parse errors | Present, but often framework-specific text | Clear parse errors observed for invalid/missing values | KEPT |

## What Survives from dry-cli

- Declarative command metadata model (`option`, `argument`, `desc`, `example`) remains viable.
- Runner flow (`ARGV -> parse -> command call`) remains viable.
- Required/optional positional semantics remain viable.

## What Changes

- Remove per-command manual coercion helpers (`convert_types` usage).
- Remove ARGV preprocessing for repeated array flags (`ArgvCoalescer`) by using parser callback accumulation.
- Centralize hash option parsing/validation in the new parser.

## What Is Removed

- `ArgvCoalescer` workaround requirement for repeated array flags in executables.
- Stringly-typed option values that require command-level conversion.

## Kill Criteria Evaluation

Kill criterion from task: pivot if OptionParser cannot handle mixed positional+keyword args or array accumulation natively.

Observed result:
- Mixed positional+keyword: **passes**
- Array accumulation (without ARGV preprocessing): **passes**

Decision: **No pivot required**. Continue with OptionParser-based implementation in `8qb.t.q3r.1`.

## Risks to Carry Forward

- Help text formatting parity with dry-cli is not covered in this spike (scheduled for `8qb.t.q3r.2`).
- This spike validates behavior with informal runs, not full test suite coverage (formalized in `8qb.t.q3r.1`).
- Unknown-flag suggestion quality (Levenshtein/prefix hints) remains implementation work in core parser task.

## Downstream Guidance for 8qb.t.q3r.1

- Design parser around typed callbacks first, not post-parse coercion.
- Support repeated array flags as first-class behavior.
- Keep explicit parse error wrappers (`ParseError`) with flag-oriented messages.
- Preserve positional parsing contract (`required` + optional order) and end-of-options behavior.
