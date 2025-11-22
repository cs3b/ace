---
id: v.0.9.0+task.120
status: pending
priority: high
estimate: 15-22h
dependencies: []
---

# Fix ace-prompt critical issues and improve test coverage

## Behavioral Specification

### User Experience
- **Input**: Users provide prompts to enhance via `ace-prompt process` with context and/or enhancement flags
- **Process**: Users experience reliable prompt enhancement with proper context embedding and clear error messages
- **Output**: Users receive enhanced prompts with their original content preserved and improved, proper archiving with _eXXX suffixes

### Expected Behavior
<!-- Describe WHAT the system should do from the user's perspective -->
When users run `ace-prompt process --ace-context --enhance`, the tool should:
1. Load the user's prompt content completely
2. Expand it with project context (when requested) while preserving the original prompt text
3. Enhance the combined content via LLM to improve clarity and specificity
4. Archive both original and enhanced versions with proper versioning (_e001, _e002)
5. Provide clear error messages when operations fail
6. Allow testing and composition with other tools without process termination

The system should gracefully handle missing dependencies (ace-context, ace-nav) with clear fallback behaviors.

### Interface Contract
<!-- Define all external interfaces, APIs, and interaction points -->

```bash
# CLI Interface
ace-prompt process [options]
  --ace-context, -c      Load project context
  --enhance, -e          Enhance via LLM
  --raw, -r             Skip enhancement
  --no-context, -n      Skip context loading
  --task ID             Process task-specific prompt

# Expected outputs
# Success: Enhanced prompt content to stdout
# Failure: Clear error message to stderr with non-zero exit code

# Status codes
0 - Success
1 - Failure (configuration error, missing files, etc.)
```

**Error Handling:**
- Missing prompt file: "Error: Prompt file not found: [path]"
- Context loading failure: "Warning: Context loading failed: [reason]. Using original content."
- Enhancement failure: "Warning: Enhancement failed: [reason]. Using original content."
- Missing dependencies: "Warning: ace-context gem not available. Skipping context loading."

**Edge Cases:**
- Empty prompt file: Process normally (may produce empty output)
- Circular enhancement chains: Track properly with iteration numbers
- Simultaneous runs: Avoid race conditions in archive management

### Success Criteria
<!-- Define measurable, observable criteria that indicate successful completion -->

- [ ] **Context Preservation**: When using `--ace-context --enhance`, the user's original prompt text is preserved in the enhanced output
- [ ] **Archive Versioning**: Enhanced prompts are archived with proper _eXXX suffixes visible after enhancement
- [ ] **Test Coverage**: Test suite reaches >80% coverage and all tests pass with `ace-test`
- [ ] **Error Recovery**: All error conditions produce helpful messages without crashes
- [ ] **Tool Composability**: Commands return exit codes and can be tested/composed without process termination
- [ ] **Discovery Working**: Templates in nested directories (handbook/prompts/base/*.md) are discoverable
- [ ] **Configuration Clarity**: Protocol configs in `.ace/` work correctly, examples in `.ace.example/` serve as reference

### Validation Questions
<!-- Questions to clarify requirements, resolve ambiguities, and validate understanding -->

- [x] **Configuration Location**: Should protocol configs be in `.ace/` (working) or `.ace.example/` (examples only)? → Confirmed: Both exist, `.ace/` for working config
- [ ] **Archive Cleanup**: Should old archives be automatically cleaned up after N versions?
- [ ] **Enhancement Caching**: Should enhanced prompts be cached for identical inputs?
- [ ] **Failure Modes**: Should enhancement failures be fail-fast or best-effort with warnings?

## Objective

Fix critical bugs preventing ace-prompt from working correctly, improve test coverage to prevent regressions, and ensure the tool provides reliable prompt enhancement for AI-assisted development workflows. Based on comprehensive code reviews from 4 different AI models identifying consistent issues.

## Scope of Work
<!-- Define the behavioral scope - what user experiences and system behaviors are included -->

- **User Experience Scope**: Command-line prompt enhancement with context loading and LLM improvement
- **System Behavior Scope**: Proper file archiving, error handling, dependency management, and test coverage
- **Interface Scope**: CLI commands, exit codes, error messages, and configuration files

### Deliverables
<!-- Focus on behavioral and experiential deliverables, not implementation artifacts -->

#### Behavioral Specifications
- Working context+enhancement flow that preserves user content
- Reliable archive versioning with visible _eXXX suffixes
- Clear error messages for all failure modes
- Testable CLI commands with proper exit codes

#### Validation Artifacts
- Comprehensive test suite with >80% coverage
- Integration tests for full workflow (process -ce)
- Unit tests for all ATOM layers
- Manual testing checklist for key workflows

## Out of Scope
<!-- Explicitly exclude implementation concerns to maintain behavioral focus -->

- ❌ **Performance Optimization**: Caching mechanisms (Phase 5 - nice to have)
- ❌ **Archive Management UI**: Browse/search capabilities for archives
- ❌ **Analytics**: Usage tracking and statistics
- ❌ **Alternative Enhancement Models**: Support for non-LLM enhancement methods

## References

- Code Review Reports:
  - .cache/ace-review/sessions/review-20251122-172436/review-report-gpro.md
  - .cache/ace-review/sessions/review-20251122-172451/review-report-opus.md
  - .cache/ace-review/sessions/review-20251122-172432/review-report-gpt-5.1-codex.md
  - .cache/ace-review/sessions/review-20251122-173010/review-report-moonshotai/Kimi-K2-Thinking.md
- Implementation plan with 5 phases prioritized by severity
- ace-prompt gem documentation and handbook

## Technical Approach

### Architecture Pattern
- [x] Pattern selection: ATOM architecture (already in use)
- [x] Integration: Follows existing ace-* gem patterns with atoms/molecules/organisms layers
- [x] Impact: Maintains clean separation of concerns, improves testability

### Technology Stack
- [x] Ruby gems: ace-context (optional dependency), ace-nav (optional dependency)
- [x] Testing: minitest with ace-test-support helpers
- [x] LLM: ace-llm for enhancement operations
- [x] Version compatibility: Ruby 3.0+, compatible with existing ace-* gems

### Implementation Strategy
- Phase 1: Fix critical blocking bugs (context embedding, CLI exits, discovery)
- Phase 2: Add comprehensive test coverage (>80%)
- Phase 3: Fix path handling and configuration issues
- Phase 4: Improve error handling and code quality
- Phase 5: Optional enhancements (caching, analytics - out of scope)

## File Modifications

### Modify
- ace-prompt/lib/ace/prompt/organisms/enhancement_session_manager.rb
  - Changes: Add `embed_source: true` to Ace::Context.load_file call
  - Impact: Fixes context embedding bug - preserves user content
  - Integration points: Line ~45 in execute_ace_context method

- ace-prompt/lib/ace/prompt/cli.rb
  - Changes: Replace `exit` calls with `return` status codes
  - Impact: Makes commands testable and composable
  - Integration points: All Thor command methods

- ace-prompt/.ace/nav/protocols/prompt-sources/ace-prompt.yml
  - Changes: Update pattern from `*.md` to `**/*.md`
  - Impact: Enables discovery of nested prompts
  - Integration points: ace-nav protocol resolution

- ace-prompt/lib/ace/prompt/molecules/config_loader.rb
  - Changes: Replace `__dir__` with Gem.loaded_specs approach
  - Impact: More reliable path resolution
  - Integration points: Template loading

- ace-prompt/lib/ace/prompt/molecules/prompt_archiver.rb
  - Changes: Add mutex for thread-safety in symlink updates
  - Impact: Prevents race conditions in concurrent runs
  - Integration points: Archive management

### Create
- ace-prompt/test/organisms/prompt_processor_test.rb
  - Purpose: Test main orchestration logic
  - Key components: Context loading, enhancement, archiving tests
  - Dependencies: minitest, ace-test-support

- ace-prompt/test/organisms/prompt_enhancer_test.rb
  - Purpose: Test enhancement with mocked LLM
  - Key components: Enhancement logic, error handling tests
  - Dependencies: Stub LLM responses

- ace-prompt/test/organisms/enhancement_session_manager_test.rb
  - Purpose: Test session management and context embedding
  - Key components: Context integration tests
  - Dependencies: Mock ace-context responses

- ace-prompt/test/commands/cli_test.rb
  - Purpose: Test CLI commands and status codes
  - Key components: All command variations, error scenarios
  - Dependencies: Capture stdout/stderr

- ace-prompt/test/integration/process_workflow_test.rb
  - Purpose: Full end-to-end workflow testing
  - Key components: Complete `process -ce` flow
  - Dependencies: Test fixtures, temporary files

## Risk Assessment

### Technical Risks
- **Risk:** Breaking existing ace-prompt users with behavior changes
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Maintain backward compatibility, use warnings for deprecations
  - **Rollback:** Git revert if critical issues found

- **Risk:** Test suite may reveal additional bugs not found in reviews
  - **Probability:** Medium
  - **Impact:** Low
  - **Mitigation:** Fix issues as discovered during test implementation
  - **Rollback:** Isolate test failures, fix incrementally

### Integration Risks
- **Risk:** ace-context/ace-nav gem availability assumptions
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Already handle with graceful fallbacks
  - **Monitoring:** Check gem loading in tests

### Performance Risks
- **Risk:** Symlink operations may be slow on some filesystems
  - **Mitigation:** Add mutex only when needed
  - **Monitoring:** Time archive operations in tests
  - **Thresholds:** <100ms for archive operations

## Implementation Plan

### Planning Steps

* [x] Analyze all 4 code reviews to identify common issues
* [x] Prioritize fixes by severity (blocking → high → medium → low)
* [x] Research gem path resolution best practices (Gem.loaded_specs)
* [x] Design test structure following ace-* gem patterns
* [x] Plan test data and fixtures needed

### Execution Steps

#### Phase 1: Critical Blocking Fixes (2-3 hours)

- [ ] Fix context embedding bug in EnhancementSessionManager
  > TEST: Context Embedding Test
  > Type: Integration Test
  > Assert: User content preserved when using --ace-context --enhance
  > Command: echo "test prompt" > tmp/test.md && ace-prompt process --ace-context --enhance < tmp/test.md | grep "test prompt"

- [ ] Fix CLI exit patterns - replace exit with return codes
  > TEST: CLI Composability Test
  > Type: Unit Test
  > Assert: Commands return status codes without terminating process
  > Command: ruby -e "require './lib/ace/prompt/cli'; puts Ace::Prompt::CLI.new.process"

- [ ] Fix prompt discovery pattern in protocol config
  > TEST: Nested Prompt Discovery
  > Type: Integration Test
  > Assert: Finds prompts in handbook/prompts/base/
  > Command: ace-nav prompt://ace-prompt/base/enhance

- [ ] Verify all critical fixes work together
  > TEST: Full Workflow Test
  > Type: End-to-End Test
  > Assert: Complete process -ce workflow succeeds
  > Command: ace-prompt process --ace-context --enhance

#### Phase 2: Comprehensive Test Coverage (4-6 hours)

- [ ] Create test helper with common fixtures and mocks
- [ ] Write organism tests for PromptProcessor
  > TEST: PromptProcessor Coverage
  > Type: Unit Test
  > Assert: All public methods tested with >90% coverage
  > Command: ace-test test/organisms/prompt_processor_test.rb --coverage

- [ ] Write organism tests for PromptEnhancer with mocked LLM
  > TEST: PromptEnhancer Coverage
  > Type: Unit Test
  > Assert: Enhancement logic tested with stubbed LLM
  > Command: ace-test test/organisms/prompt_enhancer_test.rb

- [ ] Write organism tests for EnhancementSessionManager
  > TEST: Session Manager Coverage
  > Type: Unit Test
  > Assert: Session management and context embedding tested
  > Command: ace-test test/organisms/enhancement_session_manager_test.rb

- [ ] Write CLI command tests
  > TEST: CLI Coverage
  > Type: Unit Test
  > Assert: All commands tested with various options
  > Command: ace-test test/commands/cli_test.rb

- [ ] Write integration tests for full workflows
  > TEST: Integration Coverage
  > Type: Integration Test
  > Assert: End-to-end scenarios pass
  > Command: ace-test test/integration/

- [ ] Run full test suite and verify >80% coverage
  > TEST: Overall Coverage Check
  > Type: Coverage Report
  > Assert: Total coverage exceeds 80%
  > Command: ace-test --coverage

#### Phase 3: Path & Configuration Fixes (2-3 hours)

- [ ] Replace hardcoded paths with Gem.loaded_specs approach
  > TEST: Path Resolution Test
  > Type: Unit Test
  > Assert: Templates load correctly from gem path
  > Command: ace-test test/molecules/config_loader_test.rb

- [ ] Add thread-safe mutex to symlink operations
  > TEST: Concurrency Test
  > Type: Integration Test
  > Assert: No race conditions in parallel runs
  > Command: ruby test/concurrent_archive_test.rb

- [ ] Add graceful degradation for missing gems
  > TEST: Dependency Fallback Test
  > Type: Unit Test
  > Assert: Works without ace-context/ace-nav
  > Command: ruby -e "hide gems; require './lib/ace/prompt'; Ace::Prompt::CLI.new.process"

#### Phase 4: Code Quality Improvements (3-4 hours)

- [ ] Add typed exceptions instead of generic rescues
- [ ] Refactor complex methods (split enhance_content)
- [ ] Remove global variable usage ($1 in regex)
- [ ] Remove lazy loading anti-patterns
- [ ] Improve error messages with actionable guidance
  > TEST: Error Message Quality
  > Type: Manual Test
  > Assert: All error paths produce helpful messages
  > Command: ace-prompt process --task 999999

- [ ] Final code review and cleanup
- [ ] Update documentation with changes

## Acceptance Criteria

- [x] Context preservation works correctly with --ace-context --enhance
- [x] Archive versioning shows _eXXX suffixes immediately after enhancement
- [x] Test coverage reaches >80% with all tests passing
- [x] All error conditions produce helpful, actionable messages
- [x] CLI commands are testable and composable (no exit calls)
- [x] Nested prompt discovery works (handbook/prompts/base/*.md)
- [x] Configuration in .ace/ works correctly, .ace.example/ serves as reference