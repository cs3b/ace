---
id: v.0.5.0+task.039
status: pending
priority: medium
estimate: 4h
dependencies: []
---

# Standardize and Consolidate Git Commit Workflow

## Behavioral Specification

### User Experience
- **Input**: User indicates they want to commit changes with optional strategy (all files, specific files, or with review)
- **Process**: System automatically determines optimal commit strategy based on context, analyzes changes, generates appropriate commit message, and executes commit
- **Output**: Clean commit with well-formed message following conventional commit format, confirmation of what was committed

### Expected Behavior
<!-- Describe WHAT the system should do from the user's perspective -->
<!-- Focus on observable outcomes, system responses, and user experience -->
<!-- Avoid implementation details - no mention of files, code structure, or technical approaches -->

Users should experience a unified git commit workflow where:
- A single entry point handles all commit scenarios (all files, specific files, review-first)
- The system intelligently selects the appropriate commit strategy based on user input and context
- All commits follow consistent conventional commit message format
- Users receive clear feedback about what was committed and the current repository status
- The workflow provides guardrails to prevent common commit mistakes
- Error conditions are handled gracefully with helpful guidance

### Interface Contract
<!-- Define all external interfaces, APIs, and interaction points -->
<!-- Include normal operations, error conditions, and edge cases -->

```bash
# Unified Workflow Interface
/commit                          # Auto-detect best commit strategy based on context
/commit --strategy all           # Force commit all changes
/commit --strategy files         # Prompt for specific files
/commit --strategy review        # Review changes before committing
/commit --intention "description" # Provide commit intention

# Agent Interface (unified git-commit agent)
git-commit --strategy all|files|review [--intention "text"] [file1 file2 ...]

# Expected outputs for all strategies:
- Commit hash and message
- Files committed summary  
- Current branch and status
- Next steps guidance

# Workflow Interface (single workflow instruction)
commit.wf.md - Self-contained workflow covering all commit scenarios
```

**Error Handling:**
- No changes to commit: "No changes detected. Check git-status for current repository state."
- Specific files not found: "Files not found: [list]. Available changed files: [list]"
- Commit message validation failure: "Commit message doesn't follow conventional format. Expected: type(scope): description"
- Pre-commit hook failure: "Pre-commit hooks failed. Fix issues and retry commit."

**Edge Cases:**
- Multiple repository changes: Automatically handle submodule commits
- Conflicting strategies: Default to safest option (review) with explanation
- Empty intention provided: Auto-generate appropriate commit message

### Success Criteria
<!-- Define measurable, observable criteria that indicate successful completion -->
<!-- Focus on behavioral outcomes and user experience, not implementation artifacts -->

- [ ] **Unified Entry Point**: Single /commit command handles all commit scenarios automatically
- [ ] **Strategy Auto-Detection**: System correctly determines optimal commit strategy based on context
- [ ] **Consistent Message Format**: All commits follow conventional commit format regardless of strategy
- [ ] **Clear User Feedback**: Users always receive confirmation of what was committed and repository status
- [ ] **Error Recovery Guidance**: Failed commits provide actionable next steps
- [ ] **Workflow Self-Containment**: Single workflow instruction covers all commit scenarios completely

### Validation Questions
<!-- Questions to clarify requirements, resolve ambiguities, and validate understanding -->
<!-- Ask about unclear requirements, edge cases, and user expectations -->

- [ ] **Strategy Selection Logic**: How should the system decide between commit strategies when context is ambiguous?
- [ ] **Message Auto-Generation**: What level of detail should auto-generated commit messages include?
- [ ] **Multi-Repository Handling**: Should commits in multiple submodules be atomic or separate?
- [ ] **Workflow Integration**: How should this integrate with existing task-based workflows?
- [ ] **Backward Compatibility**: Should existing git-*-commit agents remain for direct invocation?

## Objective

Consolidate and standardize the git commit workflow by creating a single source of truth that eliminates duplication between agents, workflow instructions, and commands while maintaining all existing functionality and improving user experience through intelligent strategy detection.

## Scope of Work

- **Workflow Consolidation**: Create unified commit.wf.md workflow instruction
- **Agent Unification**: Merge three git commit agents into one with strategy parameters  
- **Command Simplification**: Update /commit command to use unified approach
- **Logic Extraction**: Move git-specific logic from Claude files to reusable components

### Deliverables

#### Create

- dev-handbook/workflow-instructions/commit.wf.md
- .claude/agents/git-commit.ag.md (unified agent, replaces 3 existing agents)

#### Modify

- .claude/commands/commit.md (update to use git-commit agent)

#### Delete

- .claude/agents/git-all-commit.ag.md (after verification phase)
- .claude/agents/git-files-commit.ag.md (after verification phase)
- .claude/agents/git-review-commit.ag.md (after verification phase)
- .claude/agents/git-commit-unified.ag.md (cleanup - not needed)

## Technical Approach

### Architecture Pattern
- **Strategy Pattern**: Implement commit strategies (all, files, review) as parameters to unified agent
- **Template Method Pattern**: Use common workflow structure with strategy-specific variations
- **ATOM Architecture Alignment**: Extract reusable git logic following project ATOM principles
- **Workflow Self-Containment**: Single workflow instruction contains all necessary templates and context

### Technology Stack
- **Workflow Language**: Markdown with embedded XML templates (following ADR-002)
- **Agent Framework**: Claude Code agent format with YAML frontmatter
- **Command Interface**: Existing Claude commands structure
- **Git Integration**: Leverage existing git-commit wrapper commands

### Implementation Strategy
- **Direct Replacement**: Create unified components and remove old ones (no public release yet)
- **Clean Migration**: No backward compatibility needed since not shipped publicly
- **Template Consolidation**: Merge logic from three agents into parameterized single agent
- **Workflow Extraction**: Move git-specific logic from agent to self-contained workflow

## Tool Selection

| Criteria | Current Agents | Unified Agent | Unified Workflow | Selected |
|----------|----------------|---------------|------------------|----------|
| Maintainability | Poor (3 files) | Good (1 file) | Excellent (reusable) | Unified Workflow |
| User Experience | Confusing | Clear | Intuitive | Unified Workflow |
| Consistency | Variable | Consistent | Standardized | Unified Workflow |
| Reusability | Limited | Better | Maximum | Unified Workflow |
| Complexity | High | Medium | Low | Unified Workflow |

**Selection Rationale:** Unified workflow approach provides maximum reusability while maintaining all functionality. Single workflow instruction can be used by agents, commands, and directly by users.

### Dependencies
- **Existing**: git-commit wrapper command (already available)
- **Existing**: git-status wrapper command (already available)
- **No new dependencies**: Implementation uses existing project infrastructure

## File Modifications

### Create
- dev-handbook/workflow-instructions/commit.wf.md
  - Purpose: Self-contained workflow instruction covering all commit scenarios
  - Key components: Strategy detection logic, conventional commit templates, error handling
  - Dependencies: Embeds content from existing agents and commit workflow ideas

- .claude/agents/git-commit.ag.md
  - Purpose: Single agent that can handle all commit strategies via parameters
  - Key components: Strategy parameter validation, workflow delegation, response formatting
  - Dependencies: References commit.wf.md workflow instruction

### Modify
- .claude/commands/commit.md
  - Changes: Update to use unified git-commit agent instead of strategy selection
  - Impact: Simplified command logic, consistent user experience
  - Integration points: Direct invocation of unified agent

### Delete (Phase 3)
- .claude/agents/git-all-commit.ag.md
- .claude/agents/git-files-commit.ag.md
- .claude/agents/git-review-commit.ag.md
  - Reason: Replaced by unified git-commit.ag.md agent
  - Dependencies: Ensure all references updated to new agent
  - Migration: Direct removal after verification phase

## Implementation Plan

### Planning Steps

* [ ] **Current System Analysis**: Audit existing git commit agents to extract common patterns and unique logic
  - Analyze git-all-commit.ag.md for "commit everything" patterns
  - Analyze git-files-commit.ag.md for "specific files" patterns  
  - Analyze git-review-commit.ag.md for "review first" patterns
  - Identify shared response formats and error handling
  - Document strategy selection criteria used across agents

* [ ] **Workflow Design**: Design unified workflow instruction structure
  - Plan strategy parameter handling (all|files|review)
  - Design auto-detection logic for determining optimal strategy
  - Plan conventional commit message generation approach
  - Design error handling and recovery patterns
  - Plan template embedding for all commit scenarios

* [ ] **Agent Architecture**: Design unified agent structure with strategy parameters
  - Plan parameter validation and strategy selection
  - Design workflow delegation mechanism
  - Plan response formatting for different strategies
  - Design backward compatibility approach

### Execution Steps

#### Phase 1: Create Unified Components

- [ ] **Create Unified Workflow**: Implement dev-handbook/workflow-instructions/commit.wf.md
  - Extract and consolidate logic from three existing agents
  - Implement strategy auto-detection based on context analysis
  - Add conventional commit message templates for all scenarios
  - Include comprehensive error handling and recovery guidance
  - Embed all necessary templates following ADR-002 XML format
  > TEST: Workflow Completeness Check
  > Type: Content Validation
  > Assert: Workflow covers all commit scenarios from existing agents
  > Command: grep -E "(all changes|specific files|review)" dev-handbook/workflow-instructions/commit.wf.md

- [ ] **Create Unified Agent**: Implement .claude/agents/git-commit.ag.md
  - Create agent with strategy parameters (all|files|review)
  - Implement parameter validation and strategy selection logic
  - Add workflow delegation to commit.wf.md
  - Include response formatting matching existing agent patterns
  - Add comprehensive examples and usage documentation
  > TEST: Agent Parameter Validation
  > Type: Interface Validation
  > Assert: Agent accepts and validates strategy parameters correctly
  > Command: grep -A 5 "expected_params" .claude/agents/git-commit.ag.md

- [ ] **Update Command Interface**: Modify .claude/commands/commit.md
  - Replace strategy selection logic with unified agent invocation
  - Update usage examples to demonstrate new interface
  - Simplify command logic by delegating strategy handling to agent
  - Add documentation for new unified approach
  > TEST: Command Integration Check
  > Type: Integration Validation
  > Assert: Command properly invokes unified agent with context
  > Command: grep "git-commit" .claude/commands/commit.md

#### Phase 2: Verification and Testing

- [ ] **Integration Testing**: Validate unified workflow across all scenarios
  - Test workflow with strategy auto-detection
  - Test explicit strategy selection (all, files, review)
  - Test error conditions and recovery paths
  - Verify conventional commit message generation
  - Test multi-repository handling
  > TEST: End-to-End Workflow Validation
  > Type: Functional Integration
  > Assert: All commit scenarios work through unified workflow
  > Command: # Test unified workflow with sample repository changes

- [ ] **Feature Parity Verification**: Ensure no functionality lost
  - Verify all features from git-all-commit work
  - Verify all features from git-files-commit work
  - Verify all features from git-review-commit work
  - Document any differences or improvements
  > TEST: Feature Coverage Check
  > Type: Functionality Validation
  > Assert: All original agent capabilities preserved
  > Command: # Manual verification of each strategy

#### Phase 3: Cleanup and Finalization

- [ ] **Remove Legacy Agents**: Delete old agent files
  - Delete .claude/agents/git-all-commit.ag.md
  - Delete .claude/agents/git-files-commit.ag.md
  - Delete .claude/agents/git-review-commit.ag.md
  - Verify no remaining references to old agents
  > TEST: Reference Cleanup Check
  > Type: Reference Validation
  > Assert: No references to deleted agents remain
  > Command: grep -r "git-all-commit\|git-files-commit\|git-review-commit" .claude/ dev-handbook/

- [ ] **Update Documentation**: Ensure all docs reflect new structure
  - Update any workflow instructions that reference old agents
  - Update command documentation if needed
  - Add migration notes to project changelog
  > TEST: Documentation Consistency
  > Type: Documentation Validation
  > Assert: All documentation uses new git-commit agent
  > Command: grep -r "git-commit" dev-handbook/workflow-instructions/ .claude/commands/

## Risk Assessment

### Technical Risks
- **Risk:** Breaking existing workflows that depend on specific agent names
  - **Probability:** Low (not shipped publicly yet)
  - **Impact:** Low (internal use only)
  - **Mitigation:** Full verification before deletion, update all references
  - **Rollback:** Git history allows restoration if needed

- **Risk:** Strategy auto-detection logic makes incorrect choices
  - **Probability:** Medium
  - **Impact:** Low
  - **Mitigation:** Provide explicit strategy override parameters, conservative defaults
  - **Rollback:** Disable auto-detection, require explicit strategy selection

### Integration Risks
- **Risk:** Unified workflow too complex for self-containment principle
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Careful template embedding, thorough workflow testing
  - **Monitoring:** Validate workflow independence from external dependencies

- **Risk:** Loss of specialized functionality from individual agents
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Comprehensive feature audit, preserve all existing capabilities
  - **Monitoring:** User feedback on missing functionality

### Performance Risks
- **Risk:** Unified workflow slower than specialized agents
  - **Mitigation:** Optimize strategy detection, minimal performance overhead
  - **Monitoring:** Measure workflow execution time
  - **Thresholds:** No more than 200ms additional overhead

## Acceptance Criteria

### Behavioral Requirement Fulfillment
- [ ] **Unified Entry Point**: Single /commit command handles all scenarios with strategy auto-detection
- [ ] **Strategy Support**: All three strategies (all, files, review) work through unified interface
- [ ] **Message Consistency**: All commits follow conventional commit format regardless of strategy
- [ ] **Error Handling**: Comprehensive error recovery guidance for all failure modes
- [ ] **User Feedback**: Clear confirmation and status reporting for all commit operations

### Implementation Quality Assurance
- [ ] **Workflow Self-Containment**: commit.wf.md contains all necessary templates and logic
- [ ] **Clean Migration**: All old agents removed after verification
- [ ] **Code Quality**: All files follow project standards (markdownlint, agent format validation)
- [ ] **Documentation**: Comprehensive usage examples for new unified approach

### Integration Verification
- [ ] **Command Integration**: /commit command works seamlessly with unified agent
- [ ] **Multi-Repository Support**: Handles submodule commits correctly
- [ ] **Template Embedding**: All templates embedded following ADR-002 XML format
- [ ] **ATOM Alignment**: Implementation follows project architecture principles

## Out of Scope

- ❌ **Git Enhancement**: Adding new git functionality beyond existing wrapper commands
- ❌ **Agent Platform Changes**: Modifications to Claude Code agent framework
- ❌ **Command Syntax Changes**: Breaking changes to existing /commit command interface
- ❌ **Performance Optimization**: Improving underlying git command performance

## References

- Existing git-all-commit agent: .claude/agents/git-all-commit.ag.md
- Existing git-files-commit agent: .claude/agents/git-files-commit.ag.md
- Existing git-review-commit agent: .claude/agents/git-review-commit.ag.md
- Current /commit command: .claude/commands/commit.md
- Commit workflow ideas: dev-taskflow/backlog/ideas/commit.wf.md
- ADR-002 XML Template Embedding: docs/decisions/ADR-002-xml-template-embedding-architecture.md
- Workflow Self-Containment Principle: docs/decisions/ADR-001-workflow-self-containment-principle.md

```