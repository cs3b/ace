# AI Agent Task: Comprehensive Diff-Based Documentation Review

You are an expert technical documentation analyst and software architect. Your task is to review the provided code diff and create a comprehensive plan to update ALL related documentation, ensuring perfect consistency between implementation and documentation.

## Context: Project Information

This project follows:

- **ATOM architecture** pattern (Atoms, Molecules, Organisms, Ecosystems)
- **Test-driven development** with RSpec
- **CLI-first design** for both humans and AI agents
- **Documentation-driven development** approach
- **Semantic versioning** with clear changelog practices

## Input Data

### 1. Code Diff to Review

```diff
[INSERT YOUR DIFF CONTENT HERE]
```

### 2. Current Documentation State

#### Key Documentation Context

Essential documentation files included for review context:
[INSERT KEY DOCUMENTATION CONTENT HERE]

## Your Comprehensive Analysis Task

### Phase 1: Deep Diff Analysis

Analyze the diff and categorize every change:

**1. New Features Added**

- What new functionality was introduced?
- What new APIs or interfaces were created?
- What new configuration options were added?

**2. Existing Features Modified**

- What existing functionality changed behavior?
- What APIs had signature changes?
- What configuration options were modified?

**3. Architecture & Design Changes**

- What structural patterns were introduced or modified?
- What design decisions were made?
- What trade-offs were considered?

**4. Breaking Changes**

- What changes might break existing user workflows?
- What deprecated functionality was removed?
- What API changes are not backward compatible?

**5. Dependencies & Infrastructure**

- What external dependencies were added/removed/updated?
- What build or deployment configuration changed?
- What environment variables or settings changed?

**6. Internal Refactoring**

- What code organization changes occurred?
- What performance optimizations were made?
- What technical debt was addressed?

### Phase 2: Architectural Decision Documentation

For each significant change identified, determine:

**New ADRs Needed:**

- What architectural decisions were made during implementation?
- What alternatives were considered and rejected?
- What constraints or requirements drove these decisions?
- What are the long-term implications?

**Existing ADRs to Update:**

- What previously documented decisions need revision?
- What assumptions are no longer valid?
- What decisions need additional context or clarification?

### Phase 3: Documentation Impact Assessment

Systematically assess each documentation category:

#### Architecture Decision Records (`docs/decisions/`)

- [ ] **New ADR Required**: [Topic] - [Reason for documentation]
- [ ] **Update Existing ADR**: [File] - [Specific changes needed]

#### Project Documentation (`dev-taskflow/*.md`)

- [ ] **architecture.md**: [Specific sections needing updates]
- [ ] **blueprint.md**: [Specific sections needing updates]
- [ ] **what-do-we-build.md**: [Specific sections needing updates]

#### Root Documentation (`*.md`)

- [ ] **README.md**: [Specific sections needing updates]
- [ ] **CHANGELOG.md**: [Version entry and changes to document]
- [ ] **Other files**: [Specify files and required changes]

#### Technical Documentation (`docs/**/*.md`)

- [ ] **SETUP.md**: [Installation/setup changes needed]
- [ ] **DEVELOPMENT.md**: [Development workflow changes needed]
- [ ] **Other guides**: [Specify files and required changes]

### Phase 4: Comprehensive Update Requirements

Consider and document all additional updates needed:

**Code Examples & Snippets**

- Do existing code examples in documentation still work?
- Do new features need usage examples?
- Are there outdated API usage patterns?

**CLI Documentation**

- Do command-line help texts need updates?
- Are there new CLI flags or options to document?
- Do existing CLI examples still work?

**Configuration Documentation**

- Do environment variable examples need updates?
- Are there new configuration options to document?
- Do configuration file templates need updates?

**Integration Guides**

- Do third-party integration instructions need updates?
- Are there new integration possibilities to document?
- Do existing integration examples still work?

**Migration Guides**

- Do breaking changes need migration documentation?
- Are there upgrade paths to document?
- Do users need specific migration steps?

### Phase 5: Create Prioritized Action Plan

Organize all identified updates by priority:

## 🔴 CRITICAL UPDATES (Must be done immediately)

*These affect user safety, security, or basic functionality*

- [ ] [Specific update with file path and detailed rationale]

## 🟡 HIGH PRIORITY UPDATES (Should be done soon)

*These affect user experience or developer onboarding*

- [ ] [Specific update with file path and detailed rationale]

## 🟢 MEDIUM PRIORITY UPDATES (Should be done eventually)

*These improve clarity, completeness, or maintainability*

- [ ] [Specific update with file path and detailed rationale]

## 🔵 LOW PRIORITY UPDATES (Nice to have)

*These address minor inconsistencies or optimizations*

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

- [ ] All diff changes have corresponding documentation updates
- [ ] All new features have usage examples
- [ ] All breaking changes are clearly documented
- [ ] All deprecated functionality is marked with migration paths

**Accuracy**

- [ ] All code examples are syntactically correct
- [ ] All CLI examples use correct syntax
- [ ] All links and references are functional
- [ ] All version numbers and dates are correct

**Consistency**

- [ ] Documentation style matches project guidelines
- [ ] Terminology is consistent across all documents
- [ ] Cross-references between documents are updated
- [ ] Formatting follows established patterns

**User Experience**

- [ ] Changes are explained from user perspective
- [ ] Migration paths are clear and actionable
- [ ] Examples are practical and realistic
- [ ] Documentation remains accessible to target audience

## Expected Output Format

Structure your comprehensive response as:

```markdown
# Comprehensive Documentation Review Analysis

## Executive Summary
[2-3 sentence overview of changes and their documentation impact]

## Detailed Diff Analysis
### New Features
[Detailed list with implications]

### Modified Features
[Detailed list with implications]

### Architecture Changes
[Detailed list with implications]

### Breaking Changes
[Detailed list with user impact]

### Dependencies & Infrastructure
[Detailed list with setup implications]

## Architecture Decision Records Required
### New ADRs Needed
[List with detailed rationale for each]

### Existing ADRs to Update
[List with specific changes needed]

## Comprehensive Documentation Update Plan
[Use the 4-tier priority system from Phase 5]

## Detailed Implementation Specifications
[Use the format from Phase 6 for each identified update]

## Cross-Reference Update Map
[List all internal links and references that need updating]

## Quality Assurance Validation
[Completed checklist from Phase 7]

## Risk Assessment
[Potential issues if documentation updates are not completed]

## Implementation Timeline Recommendation
[Suggested order and timing for implementing updates]

## Additional Recommendations
[Any other considerations, tools, or processes that would help]
```

## Critical Success Factors

Your analysis must be:

1. **Exhaustive**: Miss nothing that could affect users or developers
2. **Specific**: Provide exact file paths, section names, and change descriptions
3. **Prioritized**: Clear ranking of importance and urgency
4. **Actionable**: Every recommendation should be implementable
5. **User-focused**: Consider impact on actual users and their workflows

Begin your comprehensive analysis now.
