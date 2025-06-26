# Code Review: Diff-Based Documentation Updates

## Goal

This guide explains how to systematically review code diffs and update all related documentation to maintain consistency between implementation and documentation. It provides a structured approach for both human developers and AI agents to ensure comprehensive documentation coverage when code changes.

## Overview

When code changes are made, documentation often falls behind, creating inconsistencies that confuse users and developers. This guide provides a systematic approach to:

- Analyze code diffs for documentation impact
- Identify all affected documentation areas
- Create prioritized update plans
- Ensure comprehensive documentation coverage

## Core Principles

1. **Comprehensive Coverage**: Every code change should be evaluated for documentation impact
2. **Systematic Analysis**: Follow a structured process to avoid missing documentation areas
3. **Priority-Based Updates**: Not all documentation updates are equally urgent
4. **Cross-Reference Awareness**: Consider how changes affect links between documents

## The Documentation Review Process

### Phase 1: Diff Analysis

When reviewing a code diff, categorize every change:

**New Features Added**
- What new functionality was introduced?
- What new APIs or interfaces were created?
- What new configuration options were added?

**Existing Features Modified**
- What existing functionality changed behavior?
- What APIs had signature changes?
- What configuration options were modified?

**Architecture & Design Changes**
- What structural patterns were introduced or modified?
- What design decisions were made?
- What trade-offs were considered?

**Breaking Changes**
- What changes might break existing user workflows?
- What deprecated functionality was removed?
- What API changes are not backward compatible?

**Dependencies & Infrastructure**
- What external dependencies were added/removed/updated?
- What build or deployment configuration changed?
- What environment variables or settings changed?

### Phase 2: Documentation Impact Assessment

Systematically assess each documentation category for required updates:

**Architecture Decision Records (ADRs)**
- New ADRs needed for architectural decisions made during implementation
- Updates to existing ADRs when assumptions change
- Documentation of alternatives considered and rejected

**Project Documentation**
- Updates to architecture overviews
- Changes to project blueprints
- Modifications to project scope or goals

**Root Documentation**
- README.md updates for new features or changed setup
- CHANGELOG.md entries for version tracking
- Installation or quick-start guide changes

**Technical Documentation**
- Setup and development workflow changes
- Integration guide updates
- Configuration documentation changes

**Code Examples & Snippets**
- Validation that existing examples still work
- New usage examples for added features
- Updates to API usage patterns

### Phase 3: Priority Classification

Organize documentation updates by priority:

**🔴 Critical Updates** (Must be done immediately)
- Security-related documentation changes
- Breaking changes that affect user workflows
- Incorrect information that could cause system failures

**🟡 High Priority Updates** (Should be done soon)  
- New feature documentation for user-facing changes
- Developer onboarding documentation updates
- API reference updates

**🟢 Medium Priority Updates** (Should be done eventually)
- Improved clarity or completeness
- Updated code examples
- Cross-reference corrections

**🔵 Low Priority Updates** (Nice to have)
- Minor inconsistencies
- Style improvements
- Optimization documentation

### Phase 4: Implementation Planning

For each identified update:

1. **Specify exact locations**: File paths and section headings
2. **Detail required changes**: What specifically needs to be modified
3. **Provide content suggestions**: Draft new text or examples
4. **Identify dependencies**: What other updates this change depends on
5. **Note cross-references**: What other documents link to this content

## Tools and Automation

### Generate Documentation Review Prompts

Use the provided tool to create comprehensive AI agent prompts:

```bash
# Generate from a diff file
bin/cr-docs -d your-changes.diff

# Specify output location
bin/cr-docs -d changes.diff -o review-prompt.md

# Include full documentation content (for detailed analysis)
bin/cr-docs -d changes.diff --include-content
```

### AI Agent Prompt Template

The comprehensive AI agent prompt template is available at:
[dev-handbook/guides/code-review/_documentation-update-from-diff.md](dev-handbook/guides/code-review/_documentation-update-from-diff.md)

This template provides structured instructions for AI agents to:
- Perform systematic diff analysis
- Assess documentation impact across all categories  
- Create prioritized action plans
- Provide detailed implementation specifications

## Integration with Workflow

### During Development

- **Before major changes**: Review what documentation will be affected
- **During implementation**: Keep notes on decisions that need documentation
- **After implementation**: Generate and execute documentation review

### During Code Review

- **Include documentation impact**: Assess documentation changes in PR reviews
- **Validate examples**: Ensure code examples in documentation still work
- **Check cross-references**: Verify links and references remain accurate

### During Release Process

- **Release preparation**: Run comprehensive documentation review for all changes
- **Release notes**: Ensure all user-facing changes are properly documented
- **Migration guides**: Create upgrade documentation for breaking changes

## Best Practices

### For Effective Reviews

- **Provide clean diffs**: Avoid noise from formatting-only changes
- **Include context**: Document why changes were made, not just what changed
- **Specify audience**: Consider who will be reading the updated documentation
- **Test examples**: Validate all code examples after updates

### For Maintenance

- **Regular audits**: Periodically review documentation for accuracy
- **Update processes**: Improve the review process based on what gets missed
- **Track debt**: Monitor accumulating documentation gaps
- **Validate links**: Regularly check that cross-references remain functional

## Quality Assurance Checklist

Before considering documentation updates complete:

**Completeness**
- All diff changes have corresponding documentation updates
- All new features have usage examples
- All breaking changes are clearly documented
- All deprecated functionality includes migration paths

**Accuracy**
- Code examples are syntactically correct
- CLI examples use correct syntax
- Links and references are functional
- Version numbers and dates are current

**Consistency**
- Documentation style matches project guidelines
- Terminology is consistent across documents
- Cross-references between documents are updated
- Formatting follows established patterns

**User Experience**
- Changes are explained from user perspective
- Migration paths are clear and actionable
- Examples are practical and realistic
- Documentation remains accessible to target audience

## Related Documentation

- [Documentation Guide](dev-handbook/guides/documentation.g.md) - General documentation standards
- [Version Control System Guide](dev-handbook/guides/version-control-system.g.md) - Working with diffs and changes
- [Quality Assurance Guide](dev-handbook/guides/quality-assurance.g.md) - Review processes and standards

---

*Maintaining documentation consistency requires systematic attention, but the investment pays dividends in user experience and developer productivity.*