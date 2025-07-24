---
id: v.0.3.0+task.74
status: pending
priority: medium
estimate: 1h
dependencies: []
---

# Replace bin/handbook-review-folder with code-review Command

## 0. Directory Audit ✅

_Command run:_

```bash
ls -la bin/handbook-review-folder && dev-tools/exe/code-review --help | head -10
```

_Result excerpt:_

```
bin/handbook-review-folder exists as a Ruby script for creating timestamped review folders
CAT gem code-review command supports focus and folder options for modern review workflows
```

## Objective

Replace the deprecated `bin/handbook-review-folder` script with the modern CAT gem `code-review` command that now supports focus areas and folder-based reviews. The new approach provides better integration with the CAT architecture and more flexible review capabilities.

## Scope of Work

- Update all references to `bin/handbook-review-folder` to use `code-review` with appropriate options
- Document the new workflow using `code-review docs handbook/**/*.md` with focus and folder options
- Remove the deprecated bin script after all references are updated
- Update any related documentation or guides that reference the old script

### Deliverables

#### Modify

- All documentation files referencing `bin/handbook-review-folder`
- CLAUDE.md (if applicable)
- Workflow instructions mentioning handbook review process
- Blueprint or other architectural documentation

#### Delete

- bin/handbook-review-folder (after all references updated)

## Implementation Plan

### Planning Steps

- [ ] Identify all references to `bin/handbook-review-folder` in the codebase
  > TEST: Complete Reference Scan
  > Type: Pre-condition Check  
  > Assert: All references to the deprecated script are identified
  > Command: grep -r "handbook-review-folder" . --include="*.md" | wc -l
- [ ] Understand the equivalent functionality in the CAT code-review command
- [ ] Plan appropriate `code-review` command replacements with proper focus and folder options

### Execution Steps

- [ ] Find all files referencing `bin/handbook-review-folder`
- [ ] Replace references with equivalent `code-review docs handbook/**/*.md` commands
- [ ] Update command examples to use proper focus options (e.g., --focus docs, --focus handbook)
- [ ] Update any workflow instructions that describe the handbook review process
- [ ] Verify the new commands provide equivalent functionality
  > TEST: Verify Command Functionality
  > Type: Action Validation
  > Assert: New code-review commands provide equivalent review capabilities
  > Command: code-review docs handbook/**/*.md --help
- [ ] Remove the deprecated bin/handbook-review-folder script
- [ ] Update blueprint.md or other architectural docs that reference the old script

## Acceptance Criteria

- [ ] AC 1: All references to `bin/handbook-review-folder` are replaced with `code-review` commands
- [ ] AC 2: New commands use appropriate focus and folder options for handbook reviews  
- [ ] AC 3: The deprecated bin script is removed
- [ ] AC 4: Documentation accurately reflects the new review workflow

## Out of Scope

- ❌ Modifying the CAT code-review tool functionality
- ❌ Changing the underlying review process beyond command updates
- ❌ Creating new review workflows beyond the replacement

## References

- CAT gem code-review command documentation
- Current bin/handbook-review-folder implementation
- Blueprint documentation for bin script references