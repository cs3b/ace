---
id: v.0.6.0+task.016
status: draft
priority: high
estimate: TBD
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
dev-handbook/workflow-instructions/README.md
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

## References

- Current issue: dev-handbook/workflow-instructions/README.md incorrectly mentions meta workflows in the Session Management category
- Context: Meta workflows and guides/templates/integrations are different species and should be clearly separated