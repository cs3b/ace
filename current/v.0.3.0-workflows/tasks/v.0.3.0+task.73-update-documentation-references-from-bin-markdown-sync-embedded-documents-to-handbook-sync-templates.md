---
id: v.0.3.0+task.73
status: pending
priority: high
estimate: 2h
dependencies: []
---

# Update Documentation References from bin/markdown-sync-embedded-documents to handbook sync-templates

## 0. Directory Audit ✅

_Command run:_

```bash
find . -name "*.md" -exec grep -l "bin/markdown-sync-embedded-documents" {} \; | head -10
```

_Result excerpt:_

```
Multiple documentation files reference the deprecated bin wrapper instead of the modern CAT gem command
```

## Objective

Update all *.md files across the project to use `handbook sync-templates` instead of `bin/markdown-sync-embedded-documents` and remove the unnecessary bin wrapper script. This modernizes the documentation to use the CAT gem tool that has replaced the old shell wrapper.

## Scope of Work

- Find all *.md files containing references to `bin/markdown-sync-embedded-documents`
- Replace references with the equivalent `handbook sync-templates` command
- Update command examples and usage instructions
- Remove the deprecated bin wrapper script after all references are updated
- Verify all documentation is consistent with the new command

### Deliverables

#### Modify

- All *.md files containing `bin/markdown-sync-embedded-documents` references
- CLAUDE.md (update template synchronization section)
- Various workflow instructions and guides
- README files and documentation

#### Delete

- bin/markdown-sync-embedded-documents (after all references updated)

## Implementation Plan

### Planning Steps

- [ ] Scan entire codebase to identify all files containing `bin/markdown-sync-embedded-documents`
  > TEST: Complete Reference Scan
  > Type: Pre-condition Check
  > Assert: All references to the deprecated command are identified
  > Command: grep -r "bin/markdown-sync-embedded-documents" . --include="*.md" | wc -l
- [ ] Analyze each reference to understand the context and determine appropriate replacement
- [ ] Plan systematic replacement strategy to avoid breaking any workflows

### Execution Steps

- [ ] Create comprehensive list of all files needing updates
- [ ] Update CLAUDE.md to reference `handbook sync-templates` instead of bin wrapper
- [ ] Update all workflow instructions (.wf.md files) with corrected command references
- [ ] Update all guides (.g.md files) with corrected command references  
- [ ] Update task files and other documentation with corrected references
- [ ] Verify all command examples use correct syntax and options
  > TEST: Verify Command Syntax
  > Type: Action Validation
  > Assert: All `handbook sync-templates` commands use valid options and syntax
  > Command: grep -r "handbook sync-templates" . --include="*.md" | grep -v "handbook sync-templates$\|handbook sync-templates --"
- [ ] Remove the deprecated bin/markdown-sync-embedded-documents wrapper script
- [ ] Run documentation linting to ensure no broken references remain

## Acceptance Criteria

- [ ] AC 1: All *.md files use `handbook sync-templates` instead of `bin/markdown-sync-embedded-documents`
- [ ] AC 2: The deprecated bin wrapper script is removed
- [ ] AC 3: All command examples maintain correct functionality and syntax
- [ ] AC 4: Documentation linting passes without errors related to the changes

## Out of Scope

- ❌ Changing the actual functionality of template synchronization
- ❌ Modifying the handbook sync-templates tool implementation
- ❌ Updating non-markdown files or code references

## References

- CAT gem handbook sync-templates tool documentation
- Current bin/markdown-sync-embedded-documents wrapper implementation