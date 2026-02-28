---
id: v.0.9.0+task.298
status: done
priority: medium
estimate: TBD
dependencies: []
worktree:
  branch: 298-add-multi-file-input-support-to-ace-sim-via-ace-bundle-integration
  path: "../ace-task.298"
  created_at: '2026-02-28 15:36:43'
  updated_at: '2026-02-28 15:36:43'
  target_branch: main
---

# Add Multi-File Input Support to ace-sim via ace-bundle Integration

## Behavioral Specification

### User Experience
- **Input**: Users pass `--source` with a single path, comma-separated paths, or a glob pattern. No new CLI flags.
- **Process**: ace-bundle merges all matched files into `<run-dir>/input.bundle.md`. The simulation pipeline reads this bundle as its step-1 input — uniform regardless of file count.
- **Output**: Simulations run identically whether given one file or many. The run directory contains `input.bundle.md` as the canonical source artifact.

### Expected Behavior

Every `--source` value — single file, comma list, or glob — is passed to `ace-bundle` to produce `input.bundle.md` in the run directory. There is no special-casing for single files; all paths converge through ace-bundle.

When `--source` contains commas, the value is split into individual paths (empty segments from trailing/leading commas are stripped). When `--source` contains glob characters (`*`, `?`, `**`), it is expanded to matching files. In all cases, the resolved file list is passed to ace-bundle via `-f` flags which produces a single merged markdown file with frontmatter stripped.

The resulting `input.bundle.md` becomes the step-1 input for every chain in the simulation. From that point forward, the chain pipeline is unchanged — each step reads its `input.md` as before.

**Synthesis step adaptation**: The final synthesis step currently copies `session.source` as `source.original.md`. Since `session.source` is no longer a single file path, synthesis must instead copy `input.bundle.md` (the bundled input that the simulation actually processed) as `source.original.md`. This is a minimal adaptation, not a redesign — the synthesis pipeline structure is unchanged.

**Writeback constraint**: `--writeback` is incompatible with multi-file `--source`. When writeback is enabled and `--source` resolves to more than one file, exit with a clear error before any LLM call. Writeback targets a single source file; multi-file has no unambiguous target.

### Interface Contract

```bash
# Single file (now also routed through ace-bundle)
ace-sim run --preset validate-task --source path/to/task.md

# Comma-separated files
ace-sim run --preset validate-task --source "path/to/parent.md,path/to/subtask.md"

# Glob pattern
ace-sim run --preset validate-task --source "tasks/291/**/*.md"
```

**Error Handling:**
- Glob matches zero files: Non-zero exit with clear error message before any LLM call
- Listed file does not exist: Non-zero exit with clear error message before any LLM call
- Empty `--source` value: Same error as today ("--source is required")
- `--writeback` with multi-file `--source`: Non-zero exit with error "writeback requires a single source file"
- Degenerate comma input (`"file.md,"`, `","`): Empty segments stripped; if no valid paths remain, error as empty source

**Edge Cases:**
- Single file path: Goes through ace-bundle like multi-file — `input.bundle.md` is always the step-1 input
- Glob that matches one file: Treated identically to explicit single file — still bundled
- Paths with spaces or special characters: Handled by ace-bundle's existing path resolution
- Trailing/leading commas: Empty segments silently stripped

### Success Criteria

- [ ] `--source "tasks/291/**/*.md"` bundles all matching files into `input.bundle.md` and runs as one simulation
- [ ] `--source "parent.md,subtask.md"` bundles both files into `input.bundle.md` and runs as one simulation
- [ ] `--source single.md` also goes through ace-bundle — `input.bundle.md` is always the step-1 input
- [ ] Empty glob or missing file exits with non-zero status and clear error before LLM call
- [ ] Frontmatter is stripped by ace-bundle; simulation chain receives clean markdown
- [ ] `--writeback` with multi-file `--source` exits with clear error before LLM call
- [ ] Synthesis `source.original.md` contains the bundled input (not the raw `--source` string)

### Validation Questions

- [x] ~~How should `--source` distinguish commas from globs?~~ Resolved: commas split into paths, glob characters trigger expansion — mutually detectable
- [x] ~~Should single files bypass ace-bundle for performance?~~ Resolved: No, uniform path through ace-bundle for all inputs
- [x] ~~What happens to synthesis `copy_source` with multi-file?~~ Resolved: copy `input.bundle.md` as `source.original.md` (the actual simulation input)
- [x] ~~What is writeback behavior with multi-file?~~ Resolved: error — writeback requires single source file
- [x] ~~How to handle degenerate comma inputs?~~ Resolved: strip empty segments after split

## Objective

Enable `ace-sim` to accept multiple files or glob patterns via the existing `--source` flag. When multiple files are detected, `ace-bundle` is invoked to merge them into a single `input.bundle.md` — the rest of the simulation pipeline runs unchanged. No new flags or variadic args: just extend `--source` to handle commas and globs.

Carried forward from idea `8pr2vt-taskflow-add`.

## Scope of Work

- **User Experience Scope**: `--source` flag accepts single path, comma-separated paths, or glob patterns. No new flags introduced.
- **System Behavior Scope**: SourceResolver detects multi-file input, expands globs, invokes `ace-bundle -f <file1> -f <file2> ... --output input.bundle.md` to produce bundled input. SimulationRunner uses `input.bundle.md` as uniform step-1 input. Synthesis `copy_source` adapted to use bundled input.
- **Interface Scope**: Only the `--source` flag behavior changes. All other CLI flags, presets, steps, and synthesis structure remain unchanged.

### Deliverables

#### Behavioral Specifications
- Multi-file detection logic in SourceResolver (comma-split and glob expansion)
- ace-bundle invocation via `-f` flags to produce `input.bundle.md`
- Uniform step-1 input contract (`input.bundle.md` always exists in run directory)
- Synthesis adaptation: `source.original.md` copies bundled input
- Writeback guard: error when multi-file + writeback

#### Validation Artifacts
- Success criteria verification for each input pattern (single, comma, glob)
- Error path verification (missing files, empty globs, writeback + multi-file)
- Existing single-file simulations continue working unchanged

## Out of Scope

- New CLI flags or variadic arguments
- Changes to step bundle templates or preset configurations
- Synthesis pipeline redesign (only minimal `copy_source` adaptation in scope)
- Performance optimization of ace-bundle invocation
- Interactive file selection or prompting
- Multi-file writeback (explicitly unsupported — error on attempt)

## References

- Usage documentation: `ux/usage.md` (draft usage scenarios)
- Source idea: `.ace-taskflow/v.0.9.0/ideas/done/8pr2vt-taskflow-add/idea.idea.s.md`
- ace-sim source resolver: `ace-sim/lib/ace/sim/molecules/source_resolver.rb`
- ace-sim stage executor: `ace-sim/lib/ace/sim/molecules/stage_executor.rb`
- ace-sim simulation runner: `ace-sim/lib/ace/sim/organisms/simulation_runner.rb`
- ace-sim final synthesis executor: `ace-sim/lib/ace/sim/molecules/final_synthesis_executor.rb`
- ace-bundle CLI (multi-file via `-f` flags): `ace-bundle/lib/ace/bundle/cli/commands/load.rb`