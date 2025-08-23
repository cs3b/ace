---
id: v.0.5.0+task.036
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Enhanced Reflection Note Creation with Automation and Tool Proposals

## Behavioral Specification

### User Experience
- **Input**: User completes any workflow and invokes `/create-reflection-note` command
- **Process**: Workflow guides user through structured reflection capturing insights, patterns, and improvement opportunities
- **Output**: Enhanced reflection note with automation insights, tool proposals, workflow proposals, and cookbook opportunities

### Expected Behavior
The system enhances the reflection note creation workflow to systematically capture improvement opportunities. When users complete workflows and create reflections, the system prompts for and structures insights about:
- Automation opportunities discovered during workflow execution
- Missing tools that would improve efficiency
- New workflows that could streamline processes
- Patterns suitable for cookbook documentation
- Reusable templates or code snippets identified

The enhanced workflow guides users through analyzing their just-completed work to extract maximum learning and improvement potential.

### Interface Contract
```bash
# Workflow Interface
/create-reflection-note
# Prompts for workflow context and generates reflection with sections:
# - Standard reflection content (what worked, challenges, etc.)
# - Automation Insights (opportunities for automation)
# - Tool Proposals (new dev-tools executables needed)
# - Workflow Proposals (new workflows to create)
# - Cookbook Opportunities (patterns worth documenting)
# - Pattern Identification (reusable elements)

# Output: Reflection note in dev-taskflow/current/[release]/reflections/
# Format: [timestamp]-[workflow-name].reflection.md
```

**Error Handling:**
- Missing workflow context: Prompt user for workflow details
- Invalid reflection location: Default to current release reflections directory
- Incomplete sections: Allow partial completion with clear markers

**Edge Cases:**
- Multiple workflows in single session: Support composite reflections
- No improvements identified: Still create reflection with learning captured

### Success Criteria
- [ ] **Automation Section Added**: Reflection notes include dedicated automation insights section
- [ ] **Tool Proposals Captured**: Missing tools systematically identified and documented
- [ ] **Workflow Proposals Included**: New workflow opportunities captured with clear descriptions
- [ ] **Cookbook Patterns Identified**: Reusable patterns flagged for cookbook creation
- [ ] **Structured Output Generated**: All sections properly formatted and stored

### Validation Questions
- [ ] **Section Prompts**: What specific questions best elicit actionable insights from users?
- [ ] **Tool Proposal Format**: How should tool proposals be structured for easy implementation?
- [ ] **Workflow Proposal Detail**: What level of detail needed for workflow proposals?
- [ ] **Integration with Synthesis**: How will enhanced sections integrate with synthesis workflow?

## Objective

Enhance the reflection note creation process to systematically capture improvement opportunities, making development workflows self-improving through structured insight collection.

## Scope of Work

- **User Experience Scope**: Enhanced prompting and guidance during reflection creation
- **System Behavior Scope**: Structured sections for automation, tools, workflows, and cookbooks
- **Interface Scope**: Extended workflow interface with new reflection sections

### Deliverables

#### Behavioral Specifications
- Enhanced reflection note template with new sections
- Structured prompts for improvement insights
- Integration points with synthesis workflow

#### Validation Artifacts
- Sample enhanced reflection notes
- Section completion criteria
- Quality metrics for insights


## Out of Scope

- ❌ **Implementation Details**: Specific file structures or code organization
- ❌ **Technology Decisions**: Tool selections or framework choices
- ❌ **Automation Implementation**: Actual automation of identified opportunities
- ❌ **Cookbook Creation**: Full cookbook generation (separate workflow)

## References

- Source idea: dev-taskflow/backlog/ideas/008-reflection-cookbook-automation.md
- Related workflow: dev-handbook/workflow-instructions/create-reflection-note.wf.md
- Integration target: dev-handbook/workflow-instructions/synthesize-reflection-notes.wf.md