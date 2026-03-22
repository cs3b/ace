---
id: 8ql.t.tt6.3
status: pending
priority: medium
created_at: "2026-03-22 19:52:32"
estimate: TBD
dependencies: [8ql.t.tt6.2]
tags: [ace-demo, cleanup]
parent: 8ql.t.tt6
bundle:
  presets: [project]
  files: [ace-demo/lib/ace/demo/molecules/tape_scanner.rb]
  commands: []
needs_review: false
---

# Remove Demos for Non-CLI Packages and Cleanup

## Objective

Remove demo tapes for packages that don't have CLI binaries (no `exe/` directory) and clean up any orphaned references. This ensures `ace-demo list` reflects only packages that can actually produce meaningful terminal recordings.

## Behavioral Specification

### User Experience

- **Input**: Existing demo artifacts for packages without CLI binaries
- **Process**: Identify and remove demos for non-CLI packages, clean up dangling references in READMEs, verify `ace-demo list` is accurate
- **Output**: Clean demo inventory matching actual CLI packages

### Expected Behavior

1. **Remove ace-test demo**: `ace-test/docs/demo/ace-test-getting-started.tape` (or `.tape.yml` if already migrated in subtask 2) — ace-test has no `exe/` binary, so no terminal demo is possible
2. **Verify ace-nav**: Confirm ace-support-nav has no `docs/demo/` directory (already verified: it does not)
3. **Clean README references**: Remove or update any README sections that reference removed demo GIFs (broken image links)
4. **Verify inventory**: `ace-demo list` shows only demos for packages with actual CLI binaries
5. **Remove orphaned GIFs**: Delete any `.gif` files in `docs/demo/` for removed demos

### Interface Contract

```bash
# After cleanup, ace-demo list is clean
ace-demo list
# → No entries for ace-test or other non-CLI packages

# No broken image links in READMEs
# README.md files for affected packages updated to remove demo GIF references
```

Error Handling:
- If a README references a demo GIF that's being removed, update the README to remove the reference rather than leaving a broken link

### Success Criteria

- [ ] `ace-test/docs/demo/` directory removed entirely (tape + GIF)
- [ ] No other non-CLI packages have `docs/demo/` directories
- [ ] No README files reference removed demo GIFs (no broken image links)
- [ ] `ace-demo list` output is clean — only CLI packages with demos appear

### Validation Questions

- None — scope is straightforward removal and cleanup

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice**: Subtask of orchestrator — cleanup pass
- **Outcome**: Clean demo inventory with no orphaned artifacts
- **Advisory size**: small
- **Context**: Needs list of packages with `exe/` directories, current `ace-demo list` output

## Verification Plan

### Unit/Component Validation

- [ ] `ace-test/docs/demo/` directory does not exist after cleanup
- [ ] No other non-CLI package has a `docs/demo/` with tape files

### Integration/E2E Validation

- [ ] `ace-demo list` shows only valid CLI package demos
- [ ] All README.md files render without broken image references

### Failure/Invalid Path Validation

- [ ] Glob search for `.tape` and `.tape.yml` in non-CLI packages returns empty
- [ ] Grep for removed GIF filenames in README files returns no matches

## Scope of Work

- **Included**: Removing ace-test demo, cleaning README references, verifying ace-demo list
- **Excluded**: Any engine changes, any tape migrations (already done in subtask 2)

## Out of Scope

- Adding new demos for packages that don't have them
- Engine or compiler changes
- Re-recording any existing demos
