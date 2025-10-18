---
id: v.0.9.0+task.076
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Document LLM Integration Across ACE Ecosystem

## Behavioral Specification

### User Experience
- **Input**: Users (humans and AI agents) seek information about LLM features across ACE tools
- **Process**: Users read comprehensive documentation covering configuration, usage patterns, and architectural context
- **Output**: Users understand how to configure LLM providers, use LLM-enhanced commands, and integrate LLM capabilities into their workflows

### Expected Behavior
<!-- Describe WHAT the system should do from the user's perspective -->
<!-- Focus on observable outcomes, system responses, and user experience -->
<!-- Avoid implementation details - no mention of files, code structure, or technical approaches -->

Documentation enables users to:
- **Discover LLM features**: Understand which ACE tools support LLM integration and what capabilities they offer
- **Configure providers**: Set up API keys, configure provider preferences, and customize LLM behavior through `.ace/llm/` configuration files
- **Use LLM commands**: Leverage LLM-enhanced CLI flags like `ace-taskflow idea create -llm`, `ace-review --llm-enhance`, and `ace-git-commit --llm`
- **Understand architecture**: Learn how the dynamic provider system (ADR-012) and hybrid context management (ADR-014) work
- **Troubleshoot issues**: Resolve common configuration and usage problems with clear guidance

### Interface Contract
<!-- Define all external interfaces, APIs, and interaction points -->
<!-- Include normal operations, error conditions, and edge cases -->

```bash
# Documentation Access
# Users access documentation through multiple paths:
# 1. Main guide: dev-handbook/guides/llm-integration.md
# 2. Tool-specific READMEs: ace-llm/README.md, ace-taskflow/README.md
# 3. CLI help: ace-taskflow idea create --help (references LLM features)

# Configuration Examples (documented)
# .ace/llm/config.yml - Provider preferences
# .ace/llm/aliases.yml - Custom aliases
# .ace/llm/providers/*.yml - Provider definitions

# Usage Examples (documented)
ace-taskflow idea create "feature idea" -llm
ace-review preset standard --llm-enhance
ace-git-commit --staged --llm
ace-llm-query gflash "What is Ruby?"
```

**Documentation Structure:**
- **Overview**: Strategic importance of LLM integration in ACE
- **Quick Start**: Immediate value - set API keys, run first LLM command
- **Configuration Guide**: Detailed configuration cascade explanation
- **Tool Integration**: How each ace-* tool uses LLM features
- **Architecture Reference**: Links to ADR-012, ADR-014 for deep dives
- **Troubleshooting**: Common issues and solutions

**Error Handling:**
- Missing API keys: Clear instructions on setting environment variables
- Provider configuration errors: Examples of valid configurations
- Rate limiting: Guidance on provider selection and retry strategies

**Edge Cases:**
- Multiple provider preferences: Configuration cascade resolution
- Offline usage: Graceful degradation when LLM unavailable
- Local vs. cloud providers: LM Studio integration examples

### Success Criteria
<!-- Define measurable, observable criteria that indicate successful completion -->
<!-- Focus on behavioral outcomes and user experience, not implementation artifacts -->

- [ ] **Comprehensive Guide Created**: `dev-handbook/guides/llm-integration.md` exists with all required sections
- [ ] **Tool Coverage Complete**: Documentation covers ace-taskflow, ace-review, ace-git-commit, ace-llm usage
- [ ] **Configuration Documented**: Complete examples for `.ace/llm/` configuration files
- [ ] **Architecture Linked**: References ADR-012 (Dynamic Provider System) and ADR-014 (LLM Integration Architecture)
- [ ] **Cross-References Added**: Tool READMEs link to main LLM integration guide
- [ ] **Examples Validated**: All CLI examples tested and working
- [ ] **Troubleshooting Complete**: Common issues documented with solutions

### Validation Questions
<!-- Questions to clarify requirements, resolve ambiguities, and validate understanding -->
<!-- Ask about unclear requirements, edge cases, and user expectations -->

- [ ] **Scope Clarity**: Should documentation cover only existing LLM features or include planned features from idea file?
- [ ] **Audience Balance**: How to balance documentation for human users vs. AI agent consumption?
- [ ] **Example Depth**: What level of detail for CLI examples - basic only or advanced workflows too?
- [ ] **Update Strategy**: How should this guide stay synchronized with evolving LLM features?

## Objective

Create comprehensive documentation for LLM integration across the ACE ecosystem, enabling users (humans and AI agents) to effectively discover, configure, and use LLM-enhanced features. This addresses the current gap in project-specific LLM documentation and supports the strategic vision of ACE as an AI-native development environment.

## Scope of Work
<!-- Define the behavioral scope - what user experiences and system behaviors are included -->

- **User Experience Scope**:
  - Discovery of LLM capabilities across ACE tools
  - Configuration of LLM providers and preferences
  - Usage of LLM-enhanced CLI commands
  - Troubleshooting common LLM integration issues

- **System Behavior Scope**:
  - LLM provider configuration through `.ace/llm/` cascade
  - CLI flag behavior for LLM-enhanced commands
  - Error messages and graceful degradation
  - Multi-provider support and fallback strategies

- **Interface Scope**:
  - CLI commands: `ace-taskflow idea create -llm`, `ace-review --llm-enhance`, `ace-git-commit --llm`, `ace-llm-query`
  - Configuration files: `.ace/llm/config.yml`, `.ace/llm/aliases.yml`, `.ace/llm/providers/*.yml`
  - Documentation files: Main guide, tool READMEs, help text

### Deliverables
<!-- Focus on behavioral and experiential deliverables, not implementation artifacts -->

#### Behavioral Specifications
- LLM feature discovery pathways
- Configuration setup workflows
- LLM-enhanced command usage patterns
- Troubleshooting decision trees

#### Validation Artifacts
- Tested CLI examples for all documented features
- Configuration file examples validated against actual usage
- Cross-reference validation between docs

## Out of Scope
<!-- Explicitly exclude implementation concerns to maintain behavioral focus -->

- ❌ **Implementation Details**: Internal code structure of LLM providers
- ❌ **Provider Development**: How to create new LLM provider plugins
- ❌ **Performance Tuning**: Specific optimization strategies for LLM calls
- ❌ **Cost Optimization**: Detailed cost analysis across providers (brief mention only)

## References

- Source Idea: `.ace-taskflow/v.0.9.0/docs/ideas/076-20250925-005011-add-documentation-for-new-llm-features.md`
- Related ADRs:
  - [ADR-012](../../docs/decisions/ADR-012-Dynamic-Provider-System-Architecture.t.md) - Dynamic Provider System
  - [ADR-014](../../docs/decisions/ADR-014-LLM-Integration-Architecture.t.md) - LLM Integration Architecture
- Existing Documentation:
  - `dev-handbook/guides/llm-query-tool-reference.g.md` - llm-query tool reference
  - `ace-llm/README.md` - ace-llm gem documentation
- Related Tools:
  - ace-taskflow (LLM-enhanced idea creation)
  - ace-review (LLM-enhanced code review)
  - ace-git-commit (LLM-enhanced commit messages)
  - ace-llm (Core LLM provider integration)
