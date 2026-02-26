---
id: v.0.9.0+task.284
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Rethink ace-assign phase lifecycle CLI (start/finish + piped reports)

## Behavioral Specification

### User Experience
- **Input**: Operators run explicit lifecycle commands (`ace-assign start`, `ace-assign finish`) with optional phase targeting (`STEP` or `ASSIGNMENT@STEP`), and provide report content by `--report <file>` or stdin pipe.
- **Process**: The CLI validates phase state and hierarchy, applies deterministic transitions, and prints clear progression/error output without requiring manual phase file edits.
- **Output**: Queue state advances through command-driven transitions, report artifacts are written for finished phases, and users can complete work without creating temporary report files.

### Expected Behavior
`ace-assign` must provide explicit phase lifecycle control through CLI commands rather than direct cache file mutation.

The workflow must support:
- Starting the next workable pending phase, or starting a specific targeted phase.
- Finishing the current/targeted in-progress phase with required report content.
- Reading report content from either `--report` file input or piped stdin.
- Advancing queue state with existing hierarchy and auto-completion semantics preserved.

The workflow must prevent ambiguous transitions:
- `start` fails when another phase is already in progress (strict mode).
- `finish` fails when the target phase is not in progress.
- `finish` fails when no report content source is provided.

### Interface Contract

```bash
# Phase start
ace-assign start
ace-assign start 010
ace-assign start 8pp0t6@020.01

# Phase finish with file input
ace-assign finish --report /tmp/onboard-report.md
ace-assign finish 020.01 --report ./report.md
ace-assign finish 8pp0t6@020.01 --report ./report.md

# Phase finish with piped stdin
cat ./report.md | ace-assign finish
printf "Done: onboard complete\n" | ace-assign finish 8pp0t6@020.01
```

**Error Handling:**
- Active conflict on start: return non-zero with message indicating an in-progress phase already exists and must be finished/failed first.
- Missing phase target: return non-zero when targeted step/assignment cannot be resolved.
- Missing report input: return non-zero when `finish` has neither `--report` nor piped stdin.
- Invalid finish state: return non-zero when target is not `in_progress`.

**Edge Cases:**
- Hierarchical parent phases with incomplete children remain non-finishable according to current hierarchy rules.
- Targeted assignment operations (`ASSIGNMENT@STEP`) must mutate only the specified assignment.

### Success Criteria

- [ ] **Lifecycle Control**: Users can transition phases using `start` and `finish` only, without editing `.cache/ace-assign/*` files manually.
- [ ] **Report Input UX**: Users can complete `finish` with either `--report <file>` or stdin pipe, eliminating mandatory temp-file creation.
- [ ] **Behavioral Consistency**: Existing hierarchy semantics (workable phase selection, parent auto-complete, subtree behavior) remain intact after command redesign.
- [ ] **Command Surface Clarity**: `ace-assign report` is removed and docs/help consistently instruct users to use `finish`.

### Validation Questions

- [ ] **Target Parsing Scope**: Should `STEP` positional targeting be accepted for active assignment only, while `ASSIGNMENT@STEP` is required for cross-assignment targeting?
- [ ] **Create Behavior Coupling**: Should assignment creation continue auto-starting first phase, or should that behavior move to explicit `start` in a follow-up task?
- [ ] **Error Compatibility**: Which existing error strings/exit codes must remain stable for downstream automation?
- [ ] **Fork Lifecycle UX**: Should `finish` expose additional messaging for fork-root subtree completion parity with current `report` output?

## Objective

Provide a command-line lifecycle model for `ace-assign` where phase state transitions are explicit, scriptable, and user-safe. The objective is to remove reliance on manual state editing and reduce operational friction by allowing direct stdin/file report submission while preserving queue integrity.

## Scope of Work

- **User Experience Scope**: Replace implicit/manual phase progression with explicit `start` and `finish` commands and predictable transition feedback.
- **System Behavior Scope**: Define and enforce state transition rules for pending/in-progress/done phases with required report input for completion.
- **Interface Scope**: Update ace-assign command surface, command help output, and lifecycle docs/examples to the new contracts.

### Deliverables

#### Behavioral Specifications
- CLI lifecycle behavior for `start` and `finish` (target resolution, transition preconditions, output expectations).
- Report input behavior contract (`--report` and stdin) with deterministic precedence.
- Removal policy for `report` command and updated user guidance.

#### Validation Artifacts
- Behavioral test scenarios for start/finish transitions, targeting, and report input modes.
- Error-case scenarios for active conflicts, missing targets, and missing report content.
- Documentation acceptance checks confirming no `report`-based instructions remain.

## Out of Scope

- ❌ **Implementation Details**: Internal class/method refactors, file-level architecture, and parser internals.
- ❌ **Technology Decisions**: New framework/library adoption beyond existing CLI/tool stack.
- ❌ **Performance Optimization**: Runtime profiling or optimization work unrelated to lifecycle behavior.
- ❌ **Broader Workflow Renames**: Assignment-creation command redesign (`create` naming/semantics) beyond this lifecycle command scope.

## References

- Planning conversation for ace-assign lifecycle redesign (Feb 26, 2026)
- Existing `ace-assign` command contracts and lifecycle behavior docs
