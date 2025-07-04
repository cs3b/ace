# Code Review Process

## Goal

This guide establishes the principles and high-level process for conducting comprehensive code reviews that cover code quality, testing, and documentation. It defines the systematic approach for ensuring code changes meet project standards and maintain consistency across all aspects of the codebase.

## Overview

Effective code review ensures that changes meet quality standards across multiple dimensions: code quality, test coverage, and documentation accuracy. This guide provides a systematic approach to:

- Conduct comprehensive multi-focus reviews (code, tests, docs)
- Maintain consistency between implementation and documentation
- Apply consistent quality standards across all changes
- Generate actionable feedback with clear priorities

## Core Principles

1. **Multi-Dimensional Review**: Every change should be evaluated for code quality, test impact, and documentation consistency
2. **Systematic Analysis**: Follow a structured process to ensure comprehensive coverage
3. **Priority-Based Action**: Not all issues are equally urgent - focus on critical items first
4. **Evidence-Based Decisions**: Reviews should provide specific, actionable feedback with clear rationale

## The Code Review Process

### Review Focus Areas

Code reviews should systematically evaluate three key dimensions:

**Code Quality Review**

- Architecture and design patterns
- Security and performance considerations  
- Ruby/language best practices
- Code organization and maintainability

**Testing Review**

- Test coverage for new and modified functionality
- Test quality and maintainability
- Integration with existing test suite
- Performance test considerations

**Documentation Review**

- Impact on user-facing documentation
- Architecture decision records (ADRs)
- Code examples and API documentation
- Cross-reference integrity

### Review Methodology

**Structured Analysis**

- Categorize changes by type (new features, modifications, breaking changes)
- Assess impact across all three focus areas
- Identify dependencies and cross-cutting concerns
- Document architectural decisions and trade-offs

**Multi-Model Approach**

- Leverage multiple AI models for comprehensive analysis
- Compare findings to identify consensus vs. unique insights
- Synthesize results into unified recommendations
- Validate findings against project standards

### Priority Framework

Organize review findings by impact and urgency:

**🔴 Critical** (Must be done immediately)

- Security vulnerabilities or unsafe patterns
- Breaking changes affecting user workflows  
- Logic errors or incorrect implementations

**🟡 High Priority** (Should be done soon)

- Significant architectural concerns
- Missing test coverage for critical paths
- User-facing documentation gaps

**🟢 Medium Priority** (Should be done eventually)

- Code quality improvements
- Test maintainability enhancements
- Documentation clarity improvements

**🔵 Low Priority** (Nice to have)

- Style and consistency improvements
- Performance optimizations
- Minor documentation updates

### Implementation Approach

Effective code review produces actionable outcomes:

1. **Specific Feedback**: Clear identification of issues with exact locations
2. **Rationale**: Explanation of why changes are needed
3. **Recommendations**: Concrete suggestions for improvement
4. **Priority Guidance**: Clear indication of what to address first
5. **Validation Criteria**: How to verify that issues are resolved

## Review Tools and Automation

### Unified Review Workflow

The project uses a structured review system that supports:

- **Multi-focus reviews**: Code, tests, and documentation in a single workflow
- **Flexible targets**: Git ranges, file patterns, or specific files
- **Contextual analysis**: Automatic project context loading
- **Multi-model execution**: Comparative analysis across different AI models
- **Structured output**: Organized session directories with synthesis capabilities

### Review Execution

Reviews are executed through standardized commands that create organized sessions with input files, prompts, model reports, and synthesis results. The system handles both general code reviews and specialized handbook reviews with appropriate templates and context.

## Integration with Development Workflow

### Development Phases

**Pre-Development**

- Consider review scope and potential impact areas
- Plan for documentation and testing requirements
- Identify architectural decisions that will need documentation

**During Implementation**

- Make incremental commits that are easy to review
- Document design decisions as they are made
- Keep test coverage aligned with code changes

**Post-Implementation**

- Execute comprehensive reviews across all focus areas
- Address critical and high-priority findings
- Validate that all aspects meet project standards

### Release Integration

**Pre-Release**

- Comprehensive review of all changes since last release
- Validation of documentation accuracy and completeness
- Synthesis of findings across multiple reviews

**Release Process**

- Final validation of critical issues resolution
- Documentation of breaking changes and migration paths
- Quality assurance checklist completion

## Best Practices

### Effective Review Execution

- **Scope appropriately**: Focus reviews on meaningful change sets
- **Provide context**: Include rationale for changes, not just implementation details
- **Be systematic**: Follow consistent process across all review types
- **Synthesize findings**: Combine multiple perspectives for comprehensive analysis
- **Act on results**: Prioritize and address findings systematically

### Review Quality

- **Consistency**: Apply same standards across all changes
- **Completeness**: Cover all relevant aspects (code, tests, docs)
- **Actionability**: Provide specific, implementable recommendations
- **Validation**: Verify that addressed issues are actually resolved

### Process Improvement

- **Learn from reviews**: Identify patterns in issues found
- **Refine standards**: Update review criteria based on experience
- **Automate where possible**: Leverage tools to improve efficiency
- **Track metrics**: Monitor review effectiveness and process health

## Quality Standards

### Review Completeness

- All critical and high-priority findings addressed
- Code changes align with architectural standards
- Test coverage adequate for risk level
- Documentation accurately reflects implementation

### Code Quality

- Follows established patterns and conventions
- Security considerations appropriately addressed
- Performance implications considered
- Maintainability and readability optimized

### Testing Standards

- Appropriate test coverage for change scope
- Tests are maintainable and reliable
- Integration with existing test suite verified
- Edge cases and error conditions covered

### Documentation Standards

- User-facing changes properly documented
- Technical decisions recorded in ADRs
- Cross-references and examples updated
- Migration paths provided for breaking changes

## Related Resources

### Implementation Workflows

- [Review Code Workflow](../workflow-instructions/review-code.wf.md) - Detailed review execution process
- [Synthesize Reviews Workflow](../workflow-instructions/synthesize-reviews.wf.md) - Multi-report analysis

### Standards and Guidelines  

- [Documentation Guide](./documentation.g.md) - Documentation standards and practices
- [Quality Assurance Guide](./quality-assurance.g.md) - Overall quality standards
- [Version Control System Guide](./version-control-system.g.md) - Git workflow integration

---

*Effective code review is a cornerstone of software quality, ensuring that changes meet standards across code, tests, and documentation while maintaining long-term maintainability.*
