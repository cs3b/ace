---
id: v.0.3.0+task.59
status: done
priority: medium
estimate: 2h
dependencies: []
---

# Rename Review Synthesizer for Consistency

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/handbook/workflow-instructions | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/handbook/workflow-instructions/
    ├── review-synthesizer.wf.md
    └── other workflow files...
```

## Objective

Rename `.ace/handbook/workflow-instructions/review-synthesizer.wf.md` to `.ace/handbook/workflow-instructions/synthesize-reviews.wf.md` to follow the verb-first naming convention and ensure consistency with other workflow files.

## Scope of Work

* Rename workflow file from review-synthesizer.wf.md to synthesize-reviews.wf.md
* Update any internal references within the file to reflect new naming
* Verify no external references to the old filename exist
* Ensure file content remains functionally identical
* Follow established naming patterns (`<verb>-<context>.wf.md`)

### Deliverables

#### Create

* .ace/handbook/workflow-instructions/synthesize-reviews.wf.md

#### Delete

* .ace/handbook/workflow-instructions/review-synthesizer.wf.md

## Phases

1. Audit current file and check for external references
2. Rename file following verb-first convention
3. Update internal references if needed
4. Validate functionality remains intact

## Implementation Plan

### Planning Steps

* [x] Check for any external references to review-synthesizer.wf.md
  > TEST: External Reference Check
  > Type: Pre-condition Check
  > Assert: Any external references to the old filename are identified
  > Command: grep -r "review-synthesizer" .ace/handbook/ .ace/taskflow/ --include="*.md" --exclude="review-synthesizer.wf.md"

* [x] Verify current file structure and content
  > TEST: Current File Analysis
  > Type: Pre-condition Check
  > Assert: Current file structure is documented for comparison
  > Command: wc -l .ace/handbook/workflow-instructions/review-synthesizer.wf.md && head -20 .ace/handbook/workflow-instructions/review-synthesizer.wf.md

### Execution Steps

* [x] Create new file with verb-first naming (synthesize-reviews.wf.md)
  > TEST: New File Creation
  > Type: Action Validation
  > Assert: New file created with identical content to original
  > Command: test -f .ace/handbook/workflow-instructions/synthesize-reviews.wf.md

* [x] Copy content from review-synthesizer.wf.md to synthesize-reviews.wf.md
  > TEST: Content Copy Verification
  > Type: Action Validation
  > Assert: Content is identical between old and new files
  > Command: diff .ace/handbook/workflow-instructions/review-synthesizer.wf.md .ace/handbook/workflow-instructions/synthesize-reviews.wf.md

* [x] Update title in new file to match new filename
  > TEST: Title Update
  > Type: Action Validation
  > Assert: File title reflects new verb-first naming
  > Command: grep -A 1 "^# " .ace/handbook/workflow-instructions/synthesize-reviews.wf.md

* [x] Remove old review-synthesizer.wf.md file
  > TEST: Old File Removal
  > Type: Action Validation
  > Assert: Old file no longer exists
  > Command: test ! -f .ace/handbook/workflow-instructions/review-synthesizer.wf.md

* [x] Update any external references found during audit
  > TEST: Reference Updates
  > Type: Action Validation
  > Assert: All external references updated to new filename
  > Command: grep -r "synthesize-reviews" .ace/handbook/ .ace/taskflow/ --include="*.md" | grep -v "synthesize-reviews.wf.md:"

## Acceptance Criteria

* [x] AC 1: File renamed from review-synthesizer.wf.md to synthesize-reviews.wf.md
* [x] AC 2: File content remains functionally identical
* [x] AC 3: File title updated to reflect verb-first naming
* [x] AC 4: Old file (review-synthesizer.wf.md) is removed
* [x] AC 5: Any external references to old filename are updated
* [x] AC 6: New filename follows verb-first convention (`<verb>-<context>.wf.md`)
* [x] AC 7: All automated checks in the Implementation Plan pass

## Out of Scope

* ❌ Modifying workflow functionality or content structure
* ❌ Updating other workflow files unless they reference the old name
* ❌ Changing any embedded templates or examples
* ❌ Modifying workflow execution logic or process steps

## References

* .ace/handbook/workflow-instructions/review-synthesizer.wf.md (current file)
* .ace/handbook/.meta/gds/workflow-instructions-definition.g.md (naming conventions)
