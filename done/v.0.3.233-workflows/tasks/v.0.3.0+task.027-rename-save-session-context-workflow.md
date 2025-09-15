---
id: v.0.3.0+task.27
status: done
priority: high
estimate: 2h
dependencies: []
---

# Rename Save Session Context Workflow

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 1 .ace/handbook/workflow-instructions/ | grep -E "(save|session)" | sed 's/^/    /'
```

_Result excerpt:_

```
    ├── save-session-context.md
```

## Objective

Fix the file extension violation for the save-session-context workflow file. According to the workflow instruction standards, all workflow files must use the `.wf.md` extension, but this file currently uses only `.md`. This blocks automated workflow discovery and violates the naming convention.

## Scope of Work

* Rename the workflow file to use proper `.wf.md` extension
* Update the README.md reference to reflect the new filename
* Verify no other references need updating

### Deliverables

#### Create

* .ace/handbook/workflow-instructions/save-session-context.wf.md (renamed from .md)

#### Modify

* README.md (update workflow listing)

#### Delete

* .ace/handbook/workflow-instructions/save-session-context.md (after renaming)

## Phases

1. Identify all references to the file
2. Rename the file
3. Update all references
4. Verify functionality

## Implementation Plan

### Planning Steps

* [ ] Search for all references to save-session-context.md in the codebase
  > TEST: Reference Search Complete
  > Type: Pre-condition Check
  > Assert: All references to the old filename have been identified
  > Command: bin/test --check-references-found
* [ ] Verify the file follows workflow instruction standards (aside from extension)

### Execution Steps

* [ ] Rename save-session-context.md to save-session-context.wf.md
  > TEST: File Renamed Successfully
  > Type: File Check
  > Assert: save-session-context.wf.md exists and .md version is removed
  > Command: bin/test --check-file-renamed
* [ ] Update README.md to reference save-session-context.wf.md
* [ ] Search and update any other references found in the codebase
  > TEST: All References Updated
  > Type: Reference Check
  > Assert: No references to save-session-context.md remain
  > Command: bin/test --check-no-old-references
* [ ] Verify the renamed file is properly discovered by workflow tools

## Acceptance Criteria

* [ ] File renamed to save-session-context.wf.md
* [ ] README.md updated with correct filename
* [ ] No broken references to the old filename
* [ ] Workflow discovery tools recognize the file

## Out of Scope

* ❌ Modifying the workflow content (only renaming)
* ❌ Updating the workflow structure or format
* ❌ Creating new workflows

## References

* Workflow review reports identifying the violation
* workflow-instructions-definition.g.md (naming standards)
* README.md workflow listing
