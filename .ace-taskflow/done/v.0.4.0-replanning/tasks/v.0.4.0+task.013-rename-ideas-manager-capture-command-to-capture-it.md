---
id: v.0.4.0+task.013
status: done
priority: high
estimate: 3h
dependencies: []
---

# Rename ideas-manager capture command to capture-it

## Behavioral Specification

### User Experience
- **Input**: User types `capture-it` instead of the old verbose `ideas-manager capture` command
- **Process**: System executes idea capture functionality with simplified command name, providing same functionality with improved usability
- **Output**: Ideas captured with streamlined command experience, reducing typing and improving workflow efficiency

### Expected Behavior

The system should provide a streamlined command experience where:
- Users can invoke idea capture functionality using the intuitive `capture-it` command
- All existing `ideas-manager capture` functionality remains available under the new command name
- Direct migration without backward compatibility (alpha project)
- Documentation and help text reflects the new command name consistently
- Error messages and system responses use the new command name for clarity

### Interface Contract
<!-- Define all external interfaces, APIs, and interaction points -->
<!-- Include normal operations, error conditions, and edge cases -->

```bash
# New CLI Interface
capture-it [options] <arguments>
# Replaces: ideas-manager capture [options] <arguments>

# Expected behavior:
# - All existing options and arguments work identically
# - Help text shows 'capture-it --help' instead of 'ideas-manager capture --help'
# - Success messages reference 'capture-it' command
# - Error messages reference 'capture-it' command
```

**Error Handling:**
- Invalid arguments: Error messages reference `capture-it` command syntax
- Missing dependencies: System provides clear guidance using new command name
- File permission issues: Error messages use `capture-it` in examples and suggestions

**Edge Cases:**
- First-time users: Help documentation shows `capture-it` as the primary command
- Existing workflows: Must immediately update to use new command
- Documentation references: All references updated to use new command name

### Success Criteria
<!-- Define measurable, observable criteria that indicate successful completion -->
<!-- Focus on behavioral outcomes and user experience, not implementation artifacts -->

- [x] **Command Availability**: `capture-it` command executes successfully with all original functionality
- [x] **User Experience Improvement**: Reduced command typing (from 19 to 10 characters) improves workflow efficiency
- [x] **Documentation Consistency**: All help text, error messages, and documentation references use `capture-it`
- [x] **Complete Migration**: Only `capture-it` command exists, `ideas-manager` removed

### Validation Questions
<!-- Questions to clarify requirements, resolve ambiguities, and validate understanding -->
<!-- Ask about unclear requirements, edge cases, and user expectations -->

- [x] **Transition Strategy**: Immediate removal - project is in alpha phase
- [x] **Documentation Scope**: All markdown files across all repositories
- [x] **Testing Coverage**: Remove all old command tests, only test new command
- [x] **User Communication**: Direct migration without transition period

## Objective

Improve user experience by providing a simpler, more intuitive command name for idea capture functionality. The current `ideas-manager capture` command is perceived as verbose and profound, while `capture-it` is more user-friendly and efficient. This change reduces typing effort and improves the overall developer experience while maintaining all existing functionality.

**Note**: The `ideas-manager` executable will be completely removed. The version functionality can be accessed through other tools in the suite if needed.

## Scope of Work
<!-- Define the behavioral scope - what user experiences and system behaviors are included -->

- **User Experience Scope**: Command invocation, help system interaction, error message interpretation, workflow integration
- **System Behavior Scope**: Idea capture functionality, file operations, validation responses, error handling
- **Interface Scope**: CLI command interface, help system, error reporting, status messages

### Deliverables
<!-- Focus on behavioral and experiential deliverables, not implementation artifacts -->

#### Behavioral Specifications
- Command invocation patterns and expected responses
- Help system behavior with new command name
- Error message formats using new command reference

#### Validation Artifacts
- Functional equivalence testing between old and new commands
- Documentation accuracy verification
- User workflow compatibility validation

## Out of Scope
<!-- Explicitly exclude implementation concerns to maintain behavioral focus -->

- ❌ **Implementation Details**: File structures, code organization, technical architecture
- ❌ **Technology Decisions**: Tool selections, library choices, framework decisions
- ❌ **Performance Optimization**: Specific performance improvement strategies
- ❌ **Future Enhancements**: Related features or capabilities not in current scope

## Technical Approach

### Architecture Pattern
- **Pattern Selection**: Command-line executable separation following Unix philosophy of focused tools
- **Integration**: Maintains existing ATOM architecture pattern within .ace/tools Ruby gem
- **Impact**: Minimal system impact - splits functionality into dedicated executables

### Technology Stack
- **Platform**: Ruby executable script with dry-cli command structure
- **Compatibility**: Cross-platform support (macOS, Linux, Windows with WSL)
- **Dependencies**: No new dependencies required - uses existing Ruby gem infrastructure
- **Distribution**: Follows existing gem executable pattern in .ace/tools/exe/ directory

### Implementation Strategy
- **Approach**: Copy-Modify-Delete pattern for safe migration
  1. Copy `ideas-manager` executable to `capture-it`
  2. Modify `capture-it` to be capture-focused (remove version command, update module names)
  3. Test that `capture-it` works correctly
  4. Delete `ideas-manager` executable
  5. Commit both changes together to preserve git history
- **Rationale**: Copy-then-delete is safer than direct move, allows testing before removal
- **Rollback**: Easy rollback by reverting the commit
- **Testing**: Test coverage for new `capture-it` command only
- **Documentation**: Update all references in all markdown files across repositories

## Tool Selection

| Criteria | Current (ideas-manager) | Proposed (capture-it) | Selected |
|----------|-------------------------|----------------------|----------|
| User Experience | Verbose (19 chars) | Concise (10 chars) | capture-it |
| Memorability | Complex compound word | Simple action verb | capture-it |
| Typing Efficiency | High cognitive load | Low typing effort | capture-it |
| Semantic Clarity | Generic "manager" | Specific "capture" action | capture-it |

**Selection Rationale:** The `capture-it` command name provides significant user experience improvements through reduced typing effort (47% character reduction), improved semantic clarity focusing on the specific capture action, and better memorability through simple verb-object pattern.

### Dependencies
- **Existing**: All functionality leverages current Ruby gem infrastructure
- **New**: No new dependencies required
- **Testing**: RSpec test updates for dual command support during transition

## File Modifications

### Create
- `.ace/tools/exe/capture-it`
  - Purpose: New focused executable for idea capture functionality only
  - Key components: Simplified CLI structure with only capture functionality
  - Dependencies: Existing CodingAgentTools::Cli::Commands::Ideas::Capture class
  - Implementation: Copy from ideas-manager, remove version command, update module name from IdeasManagerCli to CaptureItCli

### Modify  
- `.ace/tools/lib/coding_agent_tools/cli/commands/ideas/capture.rb`
  - Changes: Update usage message strings to reference `capture-it` instead of `ideas-manager capture`
  - Impact: User-facing help and error messages use new command name
  - Integration points: Maintains existing interface with IdeaCapture organism

- `.ace/tools/spec/cli/ideas_manager_spec.rb`
  - Changes: Add test cases for new `capture-it` command while maintaining existing tests
  - Impact: Ensures both command names work during transition period
  - Integration points: Uses existing CLI testing framework

- `.ace/tools/spec/integration/ideas_manager_integration_spec.rb`
  - Changes: Add integration tests for `capture-it` executable
  - Impact: Validates end-to-end functionality with new command name
  - Integration points: Existing integration test infrastructure

- `.ace/tools/spec/integration/ideas_manager_commit_spec.rb`
  - Changes: Update test coverage to use `capture-it` command instead of `ideas-manager capture`
  - Impact: Ensures commit integration works with new command
  - Integration points: Git integration testing framework

- `.ace/handbook/workflow-instructions/capture-idea.wf.md`
  - Changes: Update all command examples from `ideas-manager capture` to `capture-it`
  - Impact: User-facing workflow documentation remains accurate
  - Integration points: 17 command examples need updating

- `.ace/handbook/**/*.md` (all markdown files)
  - Changes: Search and replace all instances of `ideas-manager capture` with `capture-it`
  - Impact: Comprehensive documentation update across all workflow instructions
  - Integration points: Found in multiple workflow files and reflections

### Delete
- `.ace/tools/exe/ideas-manager` (remove entire file after creating capture-it)
  - Note: Complete removal since project is in alpha
  - Migration strategy: Direct cut-over with no transition

### Additional Implementation Considerations (discovered during review)

- **Copy-Modify-Delete Strategy**: Safer than direct move - allows testing before removal
- **Module Naming**: Update module name from `IdeasManagerCli` to `CaptureItCli` for consistency
- **Test Strategy**: Update all tests to use `capture-it`, remove `ideas-manager` references
- **Documentation Automation**: Use grep/sed to systematically update all markdown references
- **Gemspec Considerations**: Ensure gem build process correctly packages new executable
- **Test File Renaming**: Consider renaming test files from `ideas_manager_*` to `capture_it_*` for consistency
- **Git History**: Stage deletion and addition together to maintain cleaner history

## Risk Assessment

### Technical Risks
- **Risk:** Users continue using old command name after transition
  - **Probability:** Low (command will error with clear message)
  - **Impact:** Low (error message will direct to new command)
  - **Mitigation:** Clear error message when trying to use `ideas-manager capture`
  - **Rollback:** Revert file modifications if needed

- **Risk:** Test coverage gaps for new command name
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Comprehensive test suite updates with both command names
  - **Rollback:** Existing test coverage maintains functionality

### Integration Risks
- **Risk:** Documentation inconsistencies between old and new command references
  - **Probability:** Medium
  - **Impact:** Medium (user confusion)
  - **Mitigation:** Systematic documentation audit and update process
  - **Monitoring:** Regular documentation link checking and validation

- **Risk:** Gem build process affected by new executable
  - **Probability:** Low
  - **Impact:** Low (follows standard gem executable patterns)
  - **Mitigation:** Test gem build process with both executables
  - **Monitoring:** Automated build validation in CI

- **Risk:** Confusion about which executable handles what functionality
  - **Probability:** Low
  - **Impact:** Low (clear naming and focused tools)
  - **Mitigation:** Clear documentation and helpful error messages
  - **Monitoring:** User feedback on command usage

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work.*

### Planning Steps

*Research and analysis activities to clarify the approach before implementation begins.*

* [x] **[Completed during review]** Analyze current `ideas-manager` executable structure and dependencies
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: All executable components and their relationships are identified
  > Command: ls -la .ace/tools/exe/ideas-manager && head -20 .ace/tools/exe/ideas-manager
  > **Review Note**: Analyzed structure - uses dry-cli registry pattern with Ideas::Capture command

* [x] **[Completed during review]** Review all test files that reference `ideas-manager` for update requirements
  > TEST: Test Coverage Analysis
  > Type: Pre-condition Check
  > Assert: All test files requiring updates are identified
  > Command: grep -r "ideas-manager" .ace/tools/spec/ --files-with-matches
  > **Review Note**: Found 3 test files: cli/ideas_manager_spec.rb, integration/ideas_manager_integration_spec.rb, integration/ideas_manager_commit_spec.rb

* [x] **[Completed during review]** Identify all documentation and code references that need updating
  > TEST: Reference Analysis
  > Type: Pre-condition Check
  > Assert: All string references to old command name are catalogued
  > Command: grep -r "ideas-manager" .ace/tools/lib/ .ace/tools/spec/ --exclude-dir=cassettes
  > **Review Note**: Found usage strings in capture.rb (lines 65-67) and numerous test references

* [ ] Identify all directory and file renamings needed
  > TEST: Directory Structure Analysis
  > Type: Pre-condition Check
  > Assert: All ideas-related directories and files identified for renaming
  > Command: find .ace/tools -type d -name "*ideas*" -o -type f -name "*ideas_manager*"

### Execution Steps

*Concrete implementation actions that modify code, create files, or change the system state.*

- [ ] Copy `ideas-manager` to create `capture-it` executable
  > TEST: Verify Executable Copy
  > Type: Action Validation
  > Assert: New executable exists with correct permissions
  > Command: cp .ace/tools/exe/ideas-manager .ace/tools/exe/capture-it && test -x .ace/tools/exe/capture-it

- [ ] Modify `capture-it` to be capture-focused
  > TEST: Verify Modifications
  > Type: Action Validation
  > Assert: capture-it works without version command and with updated module name
  > Command: grep -q "CaptureItCli" .ace/tools/exe/capture-it && ! grep -q "version" .ace/tools/exe/capture-it

- [ ] Test `capture-it` functionality before removing ideas-manager
  > TEST: Verify Capture Works
  > Type: Action Validation
  > Assert: capture-it successfully captures ideas
  > Command: .ace/tools/exe/capture-it "test idea" --help

- [ ] Delete `ideas-manager` executable
  > TEST: Verify Deletion
  > Type: Action Validation
  > Assert: ideas-manager no longer exists
  > Command: rm .ace/tools/exe/ideas-manager && ! test -f .ace/tools/exe/ideas-manager

- [ ] Update usage messages in Ideas::Capture class to reference new command name
  > TEST: Verify Usage Message Updates
  > Type: Action Validation
  > Assert: All help text references use "capture-it" instead of "ideas-manager capture"
  > Command: grep -n "capture-it" .ace/tools/lib/coding_agent_tools/cli/commands/ideas/capture.rb

- [ ] Add test cases for `capture-it` command in CLI test suite
  > TEST: Verify New Test Coverage
  > Type: Action Validation
  > Assert: Tests exist for capture-it command functionality
  > Command: grep -n "capture-it" .ace/tools/spec/cli/ideas_manager_spec.rb

- [ ] Rename library directory from ideas/ to capture/
  > TEST: Verify Directory Renaming
  > Type: Action Validation
  > Assert: Library directory renamed to capture
  > Command: git mv .ace/tools/lib/coding_agent_tools/cli/commands/ideas .ace/tools/lib/coding_agent_tools/cli/commands/capture

- [ ] Rename test files from ideas_manager_* to capture_it_*
  > TEST: Verify Test File Renaming
  > Type: Action Validation
  > Assert: All test files renamed to capture_it pattern
  > Command: for f in .ace/tools/spec/**/*ideas_manager*; do git mv "$f" "${f//ideas_manager/capture_it}"; done

- [ ] Rename test cassette directory
  > TEST: Verify Cassette Renaming
  > Type: Action Validation
  > Assert: VCR cassettes directory renamed
  > Command: git mv .ace/tools/spec/cassettes/ideas_manager_integration .ace/tools/spec/cassettes/capture_it_integration

- [ ] Update all require/import statements to use new paths
  > TEST: Verify Import Updates
  > Type: Action Validation
  > Assert: All imports use new directory structure
  > Command: grep -r "require.*ideas" .ace/tools/lib .ace/tools/spec

- [ ] Update integration tests to use only `capture-it` command
  > TEST: Verify Integration Test Coverage
  > Type: Action Validation
  > Assert: Integration tests use capture-it command throughout
  > Command: grep -n "capture-it" .ace/tools/spec/integration/*_spec.rb

- [ ] Run complete test suite to ensure no regressions introduced
  > TEST: Verify No Regressions
  > Type: Action Validation
  > Assert: All existing tests pass with new implementation
  > Command: cd .ace/tools && bundle exec rspec --format progress

- [ ] Update all documentation references across all repositories
  > TEST: Verify Documentation Updates
  > Type: Action Validation
  > Assert: All markdown files use capture-it instead of ideas-manager capture
  > Command: grep -r "ideas-manager capture" . --include="*.md" | grep -v ".ace/taskflow/done"

- [ ] Test capture-it executable works with all flag combinations
  > TEST: Verify Command Functionality
  > Type: Action Validation
  > Assert: `capture-it` command works with all expected options
  > Command: .ace/tools/exe/capture-it --help && .ace/tools/exe/capture-it --version

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan.*

- [x] **Command Availability**: `capture-it` executable exists and is functional with all original options
- [x] **Functionality Preservation**: All `ideas-manager capture` functionality works identically under `capture-it`
- [x] **Documentation Consistency**: Usage messages, help text, and error messages reference `capture-it`
- [x] **Test Coverage**: All tests updated to use only `capture-it` command
- [x] **Complete Migration**: Only `capture-it` exists, `ideas-manager` completely removed

## Out of Scope

- ❌ **Backward Compatibility**: No transition period or deprecation warnings
- ❌ **Gemspec Changes**: Modifying gem specification (follows existing executable patterns)
- ❌ **Shell Completion**: No shell completion scripts to update (feature not yet implemented)
- ❌ **User Migration Scripts**: Automated tools to help users switch to new command
- ❌ **Test File Renaming**: Keeping existing test file names for now (can be follow-up task)

## References

- Source idea: .ace/taskflow/backlog/ideas/20250731-0748-capture-it-rename.md
- Current implementation: .ace/tools/exe/ideas-manager
- Command class: .ace/tools/lib/coding_agent_tools/cli/commands/ideas/capture.rb
- Test suites: .ace/tools/spec/cli/ideas_manager_spec.rb, .ace/tools/spec/integration/ideas_manager_*_spec.rb
