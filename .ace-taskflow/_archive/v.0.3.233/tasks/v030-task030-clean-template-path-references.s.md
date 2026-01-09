---
id: v.0.3.0+task.30
status: done
priority: medium
estimate: 3h
dependencies: []
---

# Clean Template Path References

## 0. Directory Audit ✅

_Command run:_

```bash
grep -l "path (" .ace/handbook/workflow-instructions/*.wf.md | head -5 | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/handbook/workflow-instructions/create-adr.wf.md
    .ace/handbook/workflow-instructions/create-api-docs.wf.md
    .ace/handbook/workflow-instructions/create-reflection-note.wf.md
    .ace/handbook/workflow-instructions/create-task.wf.md
    (and others...)
```

## Objective

Several workflow files correctly use the XML `<templates>` block but also contain obsolete inline `path (...)` references within their process steps. This creates confusion about the single source of truth for templates. All stray `path (...)` text must be removed, leaving only the XML template declarations.

## Scope of Work

* Remove all inline `path (...)` references from workflow bodies
* Ensure XML templates are the single source of truth
* Maintain readability while removing redundant information
* Verify no functional impact on workflows

### Deliverables

#### Create

* None - this is a cleanup task

#### Modify

* .ace/handbook/workflow-instructions/create-adr.wf.md
* .ace/handbook/workflow-instructions/create-api-docs.wf.md
* .ace/handbook/workflow-instructions/create-reflection-note.wf.md
* .ace/handbook/workflow-instructions/create-task.wf.md
* Any other workflow files with stray path references

#### Delete

* None

## Phases

1. Identify all affected files
2. Remove stray path references
3. Verify template integrity
4. Test workflow clarity

## Implementation Plan

### Planning Steps

* [x] Search for all workflow files containing "path (" pattern
  > TEST: All Files Identified
  > Type: Pre-condition Check
  > Assert: Complete list of affected files compiled
  > Command: bin/test --check-files-identified
* [x] Review each file to understand context of path references
* [x] Ensure XML templates exist for all removed references

### Execution Steps

* [x] Remove inline "path (...)" text from create-adr.wf.md
* [x] Remove inline "path (...)" text from create-api-docs.wf.md
* [x] Remove inline "path (...)" text from create-reflection-note.wf.md
* [x] Remove inline "path (...)" text from create-task.wf.md
  > TEST: No Stray Path References
  > Type: Content Search
  > Assert: No "path (" patterns remain in workflow bodies
  > Command: bin/test --check-no-path-references
* [x] Remove from any other identified workflow files
* [x] Verify each file still has proper XML template declarations
  > TEST: XML Templates Present
  > Type: Structure Check
  > Assert: All modified files have valid <templates> sections
  > Command: bin/test --check-xml-templates-exist

## Acceptance Criteria

* [x] No inline "path (...)" references remain in workflow instruction bodies
* [x] All templates are referenced only through XML `<templates>` blocks
* [x] Workflow readability maintained or improved
* [x] No functional changes to workflow execution
* [x] Single source of truth established for all templates

## Out of Scope

* ❌ Modifying the XML template blocks themselves
* ❌ Changing template content
* ❌ Adding new templates
* ❌ Altering workflow logic

## References

* template-embedding.g.md (single source of truth principle)
* Workflow review reports identifying the redundancy
* Affected workflow files list from grep search
