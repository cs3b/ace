# AI Agent Task: Comprehensive Diff-Based Handbook Review

You are an expert workflow architect and development guide specialist. Your task is to review the provided dev-handbook diff and create a comprehensive plan to update ALL related guides and workflows, ensuring perfect consistency between workflow instructions and development patterns.

## Context: Project Information

This project creates:

- **AI-assisted development workflows** with structured guide patterns
- **Workflow-instructions** for autonomous AI agents
- **Development guides** covering patterns, templates, and best practices
- **Template-driven approach** for consistent development workflows
- **Guide-first development** with comprehensive workflow documentation

## Input Data

### 1. Handbook Diff to Review

```diff
[INSERT YOUR DIFF CONTENT HERE]
```

### 2. Current Handbook State

#### Key Handbook Context

Essential guide and workflow files included for review context:

- `dev-handbook/guides/.meta/workflow-instructions-embeding-tests.g.md`
- `dev-handbook/guides/.meta/guides-definition.g.md`
- `dev-handbook/guides/.meta/workflow-instructions-definition.g.md`

[INSERT KEY HANDBOOK CONTENT HERE]

## Your Comprehensive Analysis Task

### Phase 1: Deep Diff Analysis

Analyze the diff and categorize every change:

**1. New Workflows Added**

- What new development workflows were introduced?
- What new workflow-instructions were created?
- What new guide patterns were added?

**2. Existing Workflows Modified**

- What existing workflows changed their process?
- What workflow-instructions had step changes?
- What guide structures were modified?

**3. Guide & Pattern Changes**

- What structural patterns were introduced or modified?
- What workflow design decisions were made?
- What template trade-offs were considered?

**4. Breaking Workflow Changes**

- What changes might break existing AI agent workflows?
- What deprecated workflow patterns were removed?
- What workflow-instructions are not backward compatible?

**5. Dependencies & Tool Changes**

- What development tools were added/removed/updated?
- What workflow configuration changed?
- What template variables or settings changed?

**6. Internal Guide Refactoring**

- What guide organization changes occurred?
- What workflow optimizations were made?
- What template debt was addressed?

### Phase 2: Workflow Decision Documentation

For each significant change identified, determine:

**New Workflow ADRs Needed:**

- What workflow design decisions were made during implementation?
- What alternative workflow patterns were considered and rejected?
- What constraints or requirements drove these workflow decisions?
- What are the long-term implications for AI agents?

**Existing Workflow ADRs to Update:**

- What previously documented workflow decisions need revision?
- What workflow assumptions are no longer valid?
- What workflow decisions need additional context or clarification?

### Phase 3: Handbook Impact Assessment

Systematically assess each handbook category:

#### Workflow Instructions (`workflow-instructions/**/*.md`)

- [ ] **AI agent workflows**: [Workflow instruction changes needed]
- [ ] **Development patterns**: [Pattern guide changes needed]
- [ ] **Template workflows**: [Template usage changes needed]

#### Development Guides (`guides/**/*.md`)

- [ ] **Process guides**: [Process changes needed]
- [ ] **Pattern guides**: [Pattern documentation changes needed]
- [ ] **Template guides**: [Template usage changes needed]

### Phase 4: Comprehensive Update Requirements

Consider and document all additional updates needed:

**Workflow Examples & Templates**

- Do existing workflow examples in guides still work?
- Do new workflow patterns need usage examples?
- Are there outdated workflow instruction patterns?

**AI Agent Instructions**

- Do workflow-instructions need updates for AI agents?
- Are there new workflow steps to document?
- Do existing AI workflow examples still work?

**Template Documentation**

- Do template variable examples need updates?
- Are there new template patterns to document?
- Do template file structures need updates?

**Integration Workflows**

- Do workflow integration instructions need updates?
- Are there new workflow integration possibilities to document?
- Do existing workflow integration examples still work?

**Migration Workflows**

- Do breaking workflow changes need migration documentation?
- Are there workflow upgrade paths to document?
- Do AI agents need specific workflow migration steps?

### Phase 5: Create Prioritized Action Plan

Organize all identified updates by priority:

## 🔴 CRITICAL UPDATES (Must be done immediately)

*These affect workflow safety, AI agent functionality, or basic workflow execution*

- [ ] [Specific update with file path and detailed rationale]

## 🟡 HIGH PRIORITY UPDATES (Should be done soon)

*These affect workflow effectiveness or developer onboarding*

- [ ] [Specific update with file path and detailed rationale]

## 🟢 MEDIUM PRIORITY UPDATES (Should be done eventually)

*These improve workflow clarity, completeness, or maintainability*

- [ ] [Specific update with file path and detailed rationale]

## 🔵 LOW PRIORITY UPDATES (Nice to have)

*These address minor workflow inconsistencies or optimizations*

- [ ] [Specific update with file path and detailed rationale]

### Phase 6: Detailed Implementation Specifications

For each update identified, provide:

#### [File Path/Name]

- **Section to Update**: [Specific section heading or line numbers]
- **Current Content**: [Quote relevant current content if significant changes]
- **Required Changes**: [Exactly what needs to be changed]
- **New Content Suggestions**: [Proposed new text or examples]
- **Rationale**: [Why this change is needed based on the diff]
- **Dependencies**: [What other updates this depends on]
- **Cross-references**: [What other documents reference this content]

### Phase 7: Quality Assurance Checklist

Ensure your recommendations address:

**Completeness**

- [ ] All diff changes have corresponding handbook updates
- [ ] All new workflows have usage examples
- [ ] All breaking workflow changes are clearly documented
- [ ] All deprecated workflows are marked with migration paths

**Accuracy**

- [ ] All workflow examples are practically correct
- [ ] All template examples use correct syntax
- [ ] All links and references are functional
- [ ] All workflow steps and dates are correct

**Consistency**

- [ ] Handbook style matches project guidelines
- [ ] Terminology is consistent across all guides
- [ ] Cross-references between guides are updated
- [ ] Formatting follows established patterns

**AI Agent Experience**

- [ ] Changes are explained from AI agent perspective
- [ ] Migration paths are clear and actionable
- [ ] Examples are practical and executable
- [ ] Handbook remains accessible to target AI agents

## Expected Output Format

Structure your comprehensive response as:

```markdown
# Comprehensive Handbook Review Analysis

## Executive Summary
[2-3 sentence overview of changes and their handbook impact]

## Detailed Diff Analysis
### New Workflows
[Detailed list with implications]

### Modified Workflows
[Detailed list with implications]

### Guide & Pattern Changes
[Detailed list with implications]

### Breaking Workflow Changes
[Detailed list with AI agent impact]

### Dependencies & Tool Changes
[Detailed list with workflow implications]

## Workflow Decision Records Required
### New Workflow ADRs Needed
[List with detailed rationale for each]

### Existing Workflow ADRs to Update
[List with specific changes needed]

## Comprehensive Handbook Update Plan
[Use the 4-tier priority system from Phase 5]

## Detailed Implementation Specifications
[Use the format from Phase 6 for each identified update]

## Cross-Reference Update Map
[List all internal links and references that need updating]

## Quality Assurance Validation
[Completed checklist from Phase 7]

## Risk Assessment
[Potential issues if handbook updates are not completed]

## Implementation Timeline Recommendation
[Suggested order and timing for implementing updates]

## Additional Recommendations
[Any other considerations, tools, or processes that would help]

## Suggested Workflows & Guides for Software Engineering
[Consider adding these workflow patterns and guides that would benefit AI-assisted development]

```

## Critical Success Factors

Your analysis must be:

1. **Exhaustive**: Miss nothing that could affect AI agents or workflow effectiveness
2. **Specific**: Provide exact file paths, section names, and change descriptions
3. **Prioritized**: Clear ranking of importance and urgency
4. **Actionable**: Every recommendation should be implementable
5. **AI-agent-focused**: Consider impact on actual AI agents and their workflow execution

Begin your comprehensive analysis now.
