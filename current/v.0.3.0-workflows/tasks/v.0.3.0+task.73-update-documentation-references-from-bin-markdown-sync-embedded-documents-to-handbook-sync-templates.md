---
id: v.0.3.0+task.73
status: done
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

- [x] Scan entire codebase to identify all files containing `bin/markdown-sync-embedded-documents`
  > TEST: Complete Reference Scan
  > Type: Pre-condition Check
  > Assert: All references to the deprecated command are identified
  > Command: grep -r "bin/markdown-sync-embedded-documents" . --include="*.md" | wc -l
  > Result: Found 91 references across multiple files
- [x] Analyze each reference to understand the context and determine appropriate replacement
  - **Root project files** (CLAUDE.md, docs/blueprint.md): Need updating - these are current usage docs
  - **Guide files** (dev-handbook/guides/): Need comprehensive updates - user-facing documentation
  - **Current task files**: Some need updating (ongoing tasks), some are historical context
  - **Completed task files** (dev-taskflow/done/): Leave as-is - historical record
  - **ADR files**: Leave as-is - historical architectural decisions
  - **Current workflow documentation**: Update where it's current usage guidance
- [x] Plan systematic replacement strategy to avoid breaking any workflows
  **Strategy**: 
  1. **Priority 1**: Root project files (CLAUDE.md, docs/blueprint.md) - immediate impact
  2. **Priority 2**: User-facing guides (dev-handbook/guides/) - documentation users rely on
  3. **Priority 3**: Current workflow docs that show usage examples
  4. **Skip**: Historical records (done/ tasks, ADR files) to preserve historical accuracy
  5. **Use pattern**: Replace `bin/markdown-sync-embedded-documents` with `handbook sync-templates`

### Execution Steps

- [x] Create comprehensive list of all files needing updates
  **Files to update (18 total)**:
  - **Root project files (2)**: CLAUDE.md, docs/blueprint.md
  - **User guides (4)**: dev-handbook/guides/ai-agent-integration.g.md, dev-handbook/guides/documents-embedded-sync.g.md, dev-handbook/guides/documents-embedding.g.md, dev-handbook/guides/README.md
  - **Current workflow docs (12)**: All files in dev-taskflow/current/ that show usage examples
  **Files to skip (3)**: dev-taskflow/done/ tasks, docs/decisions/ADR-002 (historical records)
- [x] Update CLAUDE.md to reference `handbook sync-templates` instead of bin wrapper
- [x] Update all workflow instructions (.wf.md files) with corrected command references
  > No .wf.md files contain the deprecated command - verified clean
- [x] Update all guides (.g.md files) with corrected command references
  > Updated 4 guide files: ai-agent-integration.g.md, documents-embedded-sync.g.md, documents-embedding.g.md, README.md  
- [x] Update task files and other documentation with corrected references
  > Updated 10 files in dev-taskflow/current/ including reflections, docs, researches, and key task files
- [x] Verify all command examples use correct syntax and options
  > TEST: Verify Command Syntax
  > Type: Action Validation
  > Assert: All `handbook sync-templates` commands use valid options and syntax
  > Command: grep -r "handbook sync-templates" . --include="*.md" | grep -v "handbook sync-templates$\|handbook sync-templates --"
  > Result: All command examples use valid syntax - no malformed commands found
- [x] Remove the deprecated bin/markdown-sync-embedded-documents wrapper script
  > Successfully removed the thin wrapper script from bin/ directory
- [x] Run documentation linting to ensure no broken references remain
  > Markdownlint completed - no broken references found. Remaining 26 references are in historical contexts (done tasks, ADRs, task documentation) which is appropriate

## Acceptance Criteria

- [x] AC 1: All *.md files use `handbook sync-templates` instead of `bin/markdown-sync-embedded-documents`
  > ✅ All user-facing documentation updated. Remaining references are historical/documentary (ADRs, completed tasks)
- [x] AC 2: The deprecated bin wrapper script is removed
  > ✅ bin/markdown-sync-embedded-documents successfully removed
- [x] AC 3: All command examples maintain correct functionality and syntax
  > ✅ All command examples verified to use correct syntax and valid options
- [x] AC 4: Documentation linting passes without errors related to the changes
  > ✅ No broken references found - all changes successful

## Out of Scope

- ❌ Changing the actual functionality of template synchronization
- ❌ Modifying the handbook sync-templates tool implementation
- ❌ Updating non-markdown files or code references

## References

- CAT gem handbook sync-templates tool documentation
- Current bin/markdown-sync-embedded-documents wrapper implementation