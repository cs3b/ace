---
id: v.0.5.0+task.030
status: pending
priority: high
estimate: 6-8h
dependencies: v.0.5.0+task.028, v.0.5.0+task.029
---

# Simplify code-review command to single-command workflow

## Behavioral Context

**User Experience**:
- Input: Review parameters via CLI options (presets, context, subject, model, etc)
- Process: Single command execution that internally handles context generation, prompt composition, and review execution
- Output: Direct code review report or saved session files for debugging

**Expected Behavior**:
Users execute complete code review with a single command, eliminating the current 5+ step process. The system accepts context and subject configuration via YAML strings or simple options, composes prompts from modular components, generates and enhances prompts with context internally, and executes review immediately or saves session for later.

**Interface Contract**:
```bash
# Simple usage
code-review --preset pr --auto-execute

# Full parameters  
code-review \
  --preset ruby-atom-modular \
  --context 'presets: [project, dev-tools, dev-handbook]' \
  --subject 'commands: ["git diff HEAD~1"]' \
  --model "google:gemini-2.0-flash-exp" \
  --auto-execute

# With session saving
code-review --preset pr --save-session --session-dir path/to/session --auto-execute
```

**Success Criteria**:
- Single command executes complete review without intermediate files
- Context and subject generation happens in-memory
- YAML string arguments compatible with context tool format
- Optional session saving for debugging purposes
- Auto-execution completes without user intervention
- Context actually appends to system prompt (fixes empty context bug)

**Validation Questions**:
- Should --auto-execute be default behavior or require explicit flag?
- How to handle large context that might exceed LLM limits?
- Should config-file support multiple file inputs?
- What's the priority: backwards compatibility vs cleaner interface?

## Objective

Simplify the code review workflow from multiple manual steps to a single atomic command, improving developer experience and reducing friction in the review process.

## Scope of Work

- Fix context appending bug in prompt_enhancer.rb
- Add new CLI options for single-command workflow
- Implement in-memory processing by default
- Add config file support with embedded YAML
- Create direct LLM execution capability
- Update workflow documentation to promote single-command usage
- Maintain backwards compatibility

### Deliverables

#### Create

- Enhanced CLI interface with new options for single-command workflow
- In-memory processing capability for context and subject generation
- Config file support for embedded YAML configuration

#### Modify

- dev-tools/bin/code-review: Add new CLI options and single-command workflow
- dev-tools/lib/prompt_enhancer.rb: Fix context appending bug
- Existing command handlers to support in-memory processing

#### Delete

- No files to be deleted (maintaining backwards compatibility)

## Phases

1. Audit
2. Extract …
3. Refactor …

## Technical Approach

### Architecture Pattern
- [x] **Pipeline Architecture**: In-memory processing pipeline with optional persistence
- [x] **Integration**: Extends existing review.rb command without breaking changes
- [x] **Impact**: Reduces I/O operations, improves performance, maintains compatibility

### Technology Stack
- [x] **Ruby**: Existing codebase language (no new dependencies)
- [x] **YAML**: Configuration parsing (stdlib, already used)
- [x] **Tempfile**: Temporary file handling for LLM execution (stdlib)
- [x] **Open3**: Command execution (stdlib, already in use)

### Implementation Strategy
- [x] **Phase 1**: Fix critical context appending bug
- [x] **Phase 2**: Add new CLI options for single-command
- [x] **Phase 3**: Implement in-memory processing
- [x] **Phase 4**: Add config file support
- [x] **Rollback**: Feature flag for new behavior if needed
- [x] **Testing**: Unit tests for each component, integration tests for workflow

## Tool Selection

| Criteria | Tempfile (stdlib) | External Cache | Database | Selected |
|----------|----------|----------|----------|----------|
| Performance | Fast | Medium | Slow | Tempfile |
| Integration | Built-in | New dep | New dep | Tempfile |
| Maintenance | None | Medium | High | Tempfile |
| Security | OS-managed | Custom | Custom | Tempfile |
| Learning Curve | None | Low | Medium | Tempfile |

**Selection Rationale:** Using Ruby stdlib Tempfile for temporary LLM execution files provides best performance with zero new dependencies.

### Dependencies
- [x] **No new dependencies required** - all functionality uses Ruby stdlib
- [x] **Compatibility**: Works with existing Ruby 3.0+ requirement

## File Modifications

### Create
- `dev-tools/lib/coding_agent_tools/molecules/code/config_extractor.rb`
  - Purpose: Extract YAML configuration from markdown files
  - Key components: YAML parser, markdown scanner, config merger
  - Dependencies: yaml (stdlib), existing molecules

- `dev-tools/lib/coding_agent_tools/molecules/code/llm_executor.rb`
  - Purpose: Direct LLM query execution without intermediate files
  - Key components: Tempfile management, command execution, result handling
  - Dependencies: tempfile, open3, command_executor

### Modify
- `dev-tools/lib/coding_agent_tools/cli/commands/code/review.rb`
  - Changes: Add new CLI options, implement in-memory workflow, add auto_execute
  - Impact: Enables single-command workflow while maintaining compatibility
  - Integration points: Uses existing molecules, adds new execution path

- `dev-tools/lib/coding_agent_tools/molecules/code/prompt_enhancer.rb`
  - Changes: Fix enhance_prompt method to actually append context content
  - Impact: Resolves empty context bug, enables proper prompt enhancement
  - Integration points: Called by review command during prompt preparation

- `dev-tools/lib/coding_agent_tools/molecules/code/context_integrator.rb`
  - Changes: Add support for merging context_add, improve YAML string parsing
  - Impact: More flexible context configuration options
  - Integration points: Used by review command for context generation

- `dev-handbook/workflow-instructions/review-code.wf.md`
  - Changes: Add new single-command workflow section, update examples to show simplified approach
  - Impact: Encourages adoption of streamlined workflow, reduces friction for users
  - Integration points: Documentation for AI agents and developers using the tool

### Delete
- No files to delete (maintaining backwards compatibility)

## Implementation Plan

<!-- This section details the specific steps required to implement the behavioral requirements -->
<!-- Clear distinction between planning/analysis activities and concrete implementation work -->

### Planning Steps
<!-- Research, analysis, and design activities that clarify the technical approach -->

- [x] **System Analysis**: Analyzed review.rb, prompt_enhancer.rb, context_integrator.rb
  > TEST: Understanding Check
  > Type: Pre-condition Check  
  > Assert: Identified bug in enhance_prompt, understood execution flow
  > Command: grep -r "enhance_prompt" dev-tools/lib
- [x] **Architecture Design**: Pipeline architecture with optional persistence selected
  > TEST: Design Validation
  > Type: Design Review
  > Assert: In-memory processing reduces I/O, maintains compatibility
  > Command: Reviewed existing command patterns
- [x] **Implementation Strategy**: Four-phase approach defined (bug fix → CLI → memory → config)
- [x] **Dependency Analysis**: No new dependencies needed, all stdlib
- [x] **Risk Assessment**: Main risk is backwards compatibility (mitigated by keeping old flow)

### Execution Steps  
<!-- Concrete implementation actions that modify code, create files, or change system state -->

- [ ] **Fix Context Bug**: Fix enhance_prompt in prompt_enhancer.rb to append context
  > TEST: Context Appending
  > Type: Unit Test
  > Assert: Context content appears in enhanced prompt
  > Command: rspec spec/molecules/code/prompt_enhancer_spec.rb
- [ ] **Add CLI Options**: Add auto_execute, save_session, session_dir, context, subject options
  > TEST: CLI Option Parsing
  > Type: Integration Test
  > Assert: New options parsed and available in execute method
  > Command: code-review --help | grep auto_execute
- [ ] **In-Memory Processing**: Modify execute_review to keep data in memory by default
  > TEST: Memory-Only Execution
  > Type: Integration Test
  > Assert: No files created when save_session=false
  > Command: code-review --preset pr --dry-run
- [ ] **Create ConfigExtractor**: Implement YAML extraction from markdown files
  > TEST: Config Extraction
  > Type: Unit Test
  > Assert: YAML blocks correctly extracted from markdown
  > Command: rspec spec/molecules/code/config_extractor_spec.rb
- [ ] **Create LLMExecutor**: Implement direct LLM execution with tempfiles
  > TEST: Direct Execution
  > Type: Integration Test
  > Assert: LLM query executes without permanent files
  > Command: code-review --preset pr --auto-execute --dry-run
- [ ] **Integration Testing**: Full single-command workflow test
  > TEST: End-to-End Single Command
  > Type: System Test
  > Assert: Complete review executes with one command
  > Command: code-review --preset pr --context 'presets: [project]' --subject 'commands: ["git diff HEAD~1"]' --auto-execute
- [ ] **Update Documentation**: Add single-command examples to review-code.wf.md
  > TEST: Documentation Coverage
  > Type: Manual Review
  > Assert: Workflow instructions show new simplified approach prominently
  > Command: grep -A5 "Single-Command" dev-handbook/workflow-instructions/review-code.wf.md

## Risk Assessment

### Technical Risks
- **Risk:** Breaking backwards compatibility with existing workflow
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Keep all existing options functional, new features are additive
  - **Rollback:** Feature flag to disable new behavior if needed

### Integration Risks
- **Risk:** Context appending fix affects other commands
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Thorough testing of all commands using prompt_enhancer
  - **Monitoring:** Check other commands still work after fix

### Performance Risks
- **Risk:** Large contexts exceed memory limits
  - **Mitigation:** Implement streaming or chunking for very large contexts
  - **Monitoring:** Memory usage during context generation
  - **Thresholds:** Warn if context > 1MB, error if > 10MB

## Acceptance Criteria

<!-- Define conditions that signify successful implementation of behavioral requirements -->
<!-- These should directly map to success criteria from the behavioral specification -->
<!-- Focus on verifying that behavioral requirements are met, not just implementation completed -->

### Behavioral Requirement Fulfillment
- [ ] **User Experience Delivery**: All user experience requirements from behavioral spec are implemented and working
- [ ] **Interface Contract Compliance**: All interface contracts function exactly as specified in behavioral requirements  
- [ ] **System Behavior Validation**: System demonstrates all expected behaviors defined in behavioral specification

### Implementation Quality Assurance  
- [ ] **Code Quality**: All code meets project standards and passes quality checks
- [ ] **Test Coverage**: All embedded tests in Implementation Plan pass successfully
- [ ] **Integration Verification**: Implementation integrates properly with existing system components
- [ ] **Performance Requirements**: System meets any performance criteria specified in behavioral requirements

### Documentation and Validation
- [ ] **Behavioral Validation**: Success criteria from behavioral specification are demonstrably met
- [ ] **Error Handling**: All error conditions and edge cases handle as specified
- [ ] **Documentation Updates**: Any necessary documentation reflects the implemented behavior

## Out of Scope

- ❌ Changing the underlying review logic
- ❌ Modifying prompt composition system
- ❌ Changing context tool behavior
- ❌ Performance optimizations beyond in-memory processing

## References

- Testing session reflection: dev-taskflow/current/v.0.5.0-insights/reflections/20250821-222014-composable-prompt-testing-session.md
- Test report: dev-taskflow/current/v.0.5.0-insights/code-review/composable-system-review/test-report.md
- Related tasks: v.0.5.0+task.028 and v.0.5.0+task.029

```