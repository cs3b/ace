---
id: v.0.6.0+task.016
status: done
priority: high
estimate: 1h
dependencies: []
---

# Clean up meta workflows reference in workflow instructions README

## Behavioral Specification

### User Experience
- **Input**: Developer or AI agent reviewing the workflow instructions README.md file
- **Process**: User reads the README to understand available workflows and how to use them
- **Output**: Clear, accurate documentation that correctly distinguishes between regular workflows and meta workflows

### Expected Behavior
The workflow instructions README should present accurate information about available workflows without confusing references to meta workflows in the wrong context. Meta workflows are for maintaining the handbook itself and should be clearly separated from the main workflow listings that are intended for regular development work. Users should be able to quickly understand which workflows are applicable to their development tasks without encountering inappropriate meta workflow references.

### Interface Contract
```bash
# No CLI interface - this is a documentation update task

# Expected file structure after update:
.ace/handbook/workflow-instructions/README.md
- Individual Workflow Reference section listing regular workflows
- Meta Workflows section (if kept) clearly separated and explained
- No mixing of meta workflows with regular workflow categories
```

**Error Handling:**
- N/A - This is a documentation cleanup task

**Edge Cases:**
- If meta workflows section is retained, it must be clearly labeled and separated
- Cross-references to meta workflows must be accurate and contextually appropriate

### Success Criteria
- [ ] **Documentation Clarity**: Meta workflows reference removed from section 7 (Session Management) in the main workflow listing
- [ ] **Organizational Accuracy**: All workflows are correctly categorized without meta workflows mixed into regular categories
- [ ] **User Understanding**: Developers can easily distinguish between workflows for their projects vs. workflows for maintaining the handbook

### Validation Questions
- [ ] **Scope Clarity**: Should the meta workflows section be removed entirely or just cleaned up and properly separated?
- [ ] **Reference Accuracy**: Are there other places in the README that incorrectly reference meta workflows?
- [ ] **Section Organization**: Should meta workflows have their own dedicated section at the end if they're kept?

## Objective

Clean up the workflow instructions README to remove inappropriate references to meta workflows from the main workflow categories. Meta workflows are specific to handbook maintenance and should not be presented alongside regular development workflows, as this creates confusion about their purpose and applicability.

## Scope of Work

- **Documentation Scope**: Update the workflow instructions README.md file
- **Content Scope**: Remove or relocate meta workflow references that are incorrectly placed
- **Organization Scope**: Ensure clear separation between regular workflows and meta workflows

### Deliverables

#### Behavioral Specifications
- Cleaned up README with proper workflow categorization
- Clear distinction between development workflows and meta workflows
- Improved documentation organization

#### Validation Artifacts
- Verification that meta workflows are not mixed with regular workflows
- Confirmation that all workflow references are contextually appropriate
- Documentation that passes review for clarity and accuracy

## Out of Scope

- ❌ **Implementation Details**: No changes to actual workflow files
- ❌ **Technology Decisions**: No changes to documentation tooling
- ❌ **Performance Optimization**: Not applicable to documentation
- ❌ **Future Enhancements**: No new workflow creation or major restructuring

## Technical Approach

### Architecture Pattern
- Documentation structure cleanup
- Clear separation of concerns between development workflows and handbook maintenance workflows
- Maintain existing navigation patterns while improving clarity

### Technology Stack
- Markdown documentation
- No additional tools or libraries needed
- Git for version control

### Implementation Strategy
- Identify and remove the misplaced Meta Workflows section from Individual Workflow Reference
- Optionally create a clearly separated section for meta workflows if they should be documented
- Ensure all cross-references are accurate and contextually appropriate
- Maintain documentation consistency

## File Modifications

### Modify
- .ace/handbook/workflow-instructions/README.md
  - Changes: Remove Meta Workflows subsection (lines 773-777) from Individual Workflow Reference section
  - Impact: Clearer distinction between regular workflows and meta workflows
  - Integration points: No impact on actual workflow functionality

## Risk Assessment

### Technical Risks
- **Risk:** Removing useful reference information
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** The meta workflow can still be accessed through .meta/wfi directory
  - **Rollback:** Simple git revert if needed

### Integration Risks
- **Risk:** Breaking existing documentation links
  - **Probability:** Low  
  - **Impact:** Medium
  - **Mitigation:** Search for any references to the meta workflows section before removal
  - **Monitoring:** Check for 404s or broken links after update

## Implementation Plan

### Planning Steps

* [x] Analyze the current documentation structure to understand the full scope
  > TEST: Documentation Analysis
  > Type: Pre-condition Check
  > Assert: All meta workflow references identified and their context understood
  > Command: grep -n "meta workflow" README.md | wc -l

* [x] Search for any other references to meta workflows in the README
  > TEST: Reference Search
  > Type: Pre-condition Check  
  > Assert: No other inappropriate meta workflow references found
  > Command: grep -i "meta workflow" README.md

* [x] Determine if meta workflows should have their own dedicated section

### Execution Steps

- [x] Remove the Meta Workflows subsection (lines 773-777) from the Individual Workflow Reference section
  > TEST: Section Removal Verification
  > Type: Action Validation
  > Assert: Meta Workflows section no longer appears in Individual Workflow Reference
  > Command: grep -A 5 "### Meta Workflows" README.md || echo "Section removed successfully"

- [x] Verify that Session Management section in the main workflow listing (lines 57-60) does not contain meta workflow references
  > TEST: Session Management Verification  
  > Type: Action Validation
  > Assert: Session Management section contains only regular workflows
  > Command: grep -A 5 "### 7. Session Management" README.md

- [x] Update the closing statement if needed to reflect the removal
  > TEST: Document Consistency
  > Type: Action Validation
  > Assert: Document maintains consistent structure and messaging
  > Command: tail -5 README.md

- [x] Review the entire document for consistency and completeness
  > TEST: Final Document Review
  > Type: Action Validation
  > Assert: No broken references or inconsistencies
  > Command: grep -c "\[.*\](\.\..*meta.*wfi.*\.md)" README.md

## Acceptance Criteria

- [x] Meta workflows reference removed from Individual Workflow Reference section
- [x] All workflows are correctly categorized without meta workflows mixed into regular categories  
- [x] Document structure remains clear and navigation is intuitive
- [x] No broken links or references

## Out of Scope

- ❌ **Implementation Details**: No changes to actual workflow files
- ❌ **Technology Decisions**: No changes to documentation tooling
- ❌ **Performance Optimization**: Not applicable to documentation
- ❌ **Future Enhancements**: No new workflow creation or major restructuring

## References

- Current issue: .ace/handbook/workflow-instructions/README.md incorrectly mentions meta workflows in the Individual Workflow Reference section (lines 773-777)
- Context: Meta workflows are for handbook maintenance and live in .meta/wfi/ directory
- Meta workflows should be clearly separated from regular development workflows