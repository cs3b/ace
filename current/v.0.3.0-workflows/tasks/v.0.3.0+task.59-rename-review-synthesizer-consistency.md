---
id: v.0.3.0+task.59
status: pending
priority: medium
estimate: 2h
dependencies: []
---

# Rename Review Synthesizer for Consistency

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/workflow-instructions | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-handbook/workflow-instructions/
    ├── review-synthesizer.wf.md
    └── other workflow files...
```

## Objective

Rename `dev-handbook/workflow-instructions/review-synthesizer.wf.md` to `dev-handbook/workflow-instructions/synthesize-reviews.wf.md` to follow the verb-first naming convention and ensure consistency with other workflow files.

## Scope of Work

* Rename workflow file from review-synthesizer.wf.md to synthesize-reviews.wf.md
* Update any internal references within the file to reflect new naming
* Verify no external references to the old filename exist
* Ensure file content remains functionally identical
* Follow established naming patterns (`<verb>-<context>.wf.md`)

### Deliverables

#### Create

* dev-handbook/workflow-instructions/synthesize-reviews.wf.md

#### Delete

* dev-handbook/workflow-instructions/review-synthesizer.wf.md

## Phases

1. Audit current file and check for external references
2. Rename file following verb-first convention
3. Update internal references if needed
4. Validate functionality remains intact

## Implementation Plan

### Planning Steps

* [ ] Check for any external references to review-synthesizer.wf.md
  > TEST: External Reference Check
  > Type: Pre-condition Check
  > Assert: Any external references to the old filename are identified
  > Command: grep -r "review-synthesizer" dev-handbook/ dev-taskflow/ --include="*.md" --exclude="review-synthesizer.wf.md"

* [ ] Verify current file structure and content
  > TEST: Current File Analysis
  > Type: Pre-condition Check
  > Assert: Current file structure is documented for comparison
  > Command: wc -l dev-handbook/workflow-instructions/review-synthesizer.wf.md && head -20 dev-handbook/workflow-instructions/review-synthesizer.wf.md

### Execution Steps

* [ ] Create new file with verb-first naming (synthesize-reviews.wf.md)
  > TEST: New File Creation
  > Type: Action Validation
  > Assert: New file created with identical content to original
  > Command: test -f dev-handbook/workflow-instructions/synthesize-reviews.wf.md

* [ ] Copy content from review-synthesizer.wf.md to synthesize-reviews.wf.md
  > TEST: Content Copy Verification
  > Type: Action Validation
  > Assert: Content is identical between old and new files
  > Command: diff dev-handbook/workflow-instructions/review-synthesizer.wf.md dev-handbook/workflow-instructions/synthesize-reviews.wf.md

* [ ] Update title in new file to match new filename
  > TEST: Title Update
  > Type: Action Validation
  > Assert: File title reflects new verb-first naming
  > Command: grep -A 1 "^# " dev-handbook/workflow-instructions/synthesize-reviews.wf.md

* [ ] Remove old review-synthesizer.wf.md file
  > TEST: Old File Removal
  > Type: Action Validation
  > Assert: Old file no longer exists
  > Command: test ! -f dev-handbook/workflow-instructions/review-synthesizer.wf.md

* [ ] Update any external references found during audit
  > TEST: Reference Updates
  > Type: Action Validation
  > Assert: All external references updated to new filename
  > Command: grep -r "synthesize-reviews" dev-handbook/ dev-taskflow/ --include="*.md" | grep -v "synthesize-reviews.wf.md:"

## Acceptance Criteria

* [ ] AC 1: File renamed from review-synthesizer.wf.md to synthesize-reviews.wf.md
* [ ] AC 2: File content remains functionally identical
* [ ] AC 3: File title updated to reflect verb-first naming
* [ ] AC 4: Old file (review-synthesizer.wf.md) is removed
* [ ] AC 5: Any external references to old filename are updated
* [ ] AC 6: New filename follows verb-first convention (`<verb>-<context>.wf.md`)
* [ ] AC 7: All automated checks in the Implementation Plan pass

## Out of Scope

* ❌ Modifying workflow functionality or content structure
* ❌ Updating other workflow files unless they reference the old name
* ❌ Changing any embedded templates or examples
* ❌ Modifying workflow execution logic or process steps

## References

* dev-handbook/workflow-instructions/review-synthesizer.wf.md (current file)
* dev-handbook/.meta/gds/workflow-instructions-definition.g.md (naming conventions)
