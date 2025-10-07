---
id: v.0.9.0+task.063
status: pending
priority: high
estimate: 4h
dependencies: []
---

# Add Flexible Metadata Flags to Task Create Command

## Behavioral Specification

### User Experience

- **Input**: Users invoke `ace-taskflow task create` with either positional title or `--title` flag, plus optional metadata flags (`--status`, `--priority`, `--estimate`, `--dependencies`)
- **Process**: System parses arguments correctly, handles `--help` flag gracefully, validates input, and creates task with specified metadata
- **Output**: Task created with user-specified metadata in frontmatter, confirmation message with task ID and path

### Expected Behavior

**Current Problem:**
- `ace-taskflow task create --help` creates a task named "--help" instead of showing help
- Only positional arguments supported for title (inflexible)
- Limited metadata configuration at creation time
- No way to set status, priority, estimate, or dependencies during creation

**Desired Behavior:**
Users can create tasks with full metadata control using flexible flag-based syntax:

```bash
# Positional title (existing behavior - still works)
ace-taskflow task create 'Add caching layer'

# Flag-based title (new)
ace-taskflow task create --title 'Add caching layer'

# With metadata flags (new)
ace-taskflow task create --title 'Add caching' \
  --status pending \
  --priority high \
  --estimate 3h \
  --dependencies 018,019

# Show help (currently broken - must fix)
ace-taskflow task create --help

# Mix positional and flags
ace-taskflow task create 'My task' --priority critical --estimate 2d
```

### Interface Contract

**CLI Interface:**

```bash
ace-taskflow task create [TITLE] [OPTIONS]

Options:
  --title TITLE           Task title (alternative to positional arg)
  --status STATUS         Initial status (pending, draft, in-progress, done, blocked)
  --priority PRIORITY     Priority level (critical, high, medium, low)
  --estimate ESTIMATE     Effort estimate (e.g., 2h, 1d, TBD)
  --dependencies DEPS     Comma-separated dependency list (e.g., 018,019,020)
  --backlog              Create task in backlog
  --release VERSION      Create task in specific release
  -h, --help             Show help message

Examples:
  # Positional title
  ace-taskflow task create 'Implement feature X'

  # Flag-based with metadata
  ace-taskflow task create --title 'Fix bug Y' --priority critical --status pending

  # With dependencies
  ace-taskflow task create 'Write tests' --dependencies 041,042 --estimate 4h

  # Help (must not create task!)
  ace-taskflow task create --help
```

**Expected Outputs:**

Success:
```
Created task v.0.9.0+task.064
Path: /Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/t/064-implement-feature-x/task.064.md
```

Help output:
```
Usage: ace-taskflow task create [TITLE] [options]
...
[Full help text displayed]
```

Error (missing title):
```
Error: Task title is required

Usage: ace-taskflow task create <title> [options]
   or: ace-taskflow task create --title 'Task title' [options]

Run 'ace-taskflow task create --help' for full usage
```

**Error Handling:**
- `--help` flag: Display help, exit 0, **do not create task**
- Missing title: Show error with usage hint, exit 1
- Invalid flag: Show error suggesting `--help`, exit 1
- Invalid metadata value (e.g., bad status): Validate and show error with valid options, exit 1

**Edge Cases:**
- Both positional title and `--title` flag: Positional takes precedence (or error?)
- Empty title string: Reject with error
- Duplicate flags: Last value wins (standard behavior)
- Mixed quoted/unquoted args: Handle per shell quoting rules

### Success Criteria

- [ ] **--help flag works**: `ace-taskflow task create --help` shows help and does NOT create a task
- [ ] **Positional title works**: Existing `ace-taskflow task create 'Title'` syntax continues to work (backwards compatible)
- [ ] **--title flag works**: `ace-taskflow task create --title 'Title'` creates task correctly
- [ ] **Metadata flags work**: All flags (`--status`, `--priority`, `--estimate`, `--dependencies`) set frontmatter correctly
- [ ] **Dependencies parsed**: `--dependencies 018,019` creates array `[018, 019]` in frontmatter
- [ ] **Error handling**: Invalid flags show clear error messages with `--help` suggestion
- [ ] **Backwards compatible**: All existing commands and tests pass without modification

### Validation Questions

- [ ] **Flag precedence**: If both positional title and `--title` flag provided, which wins? (Suggest: positional or show error)
- [ ] **Status validation**: Should we validate status values (pending, draft, etc.) or allow any string?
- [ ] **Dependency format**: Should we validate dependency references (e.g., task.018, 018, v.0.9.0+018)?
- [ ] **Help integration**: Should each subcommand have its own `--help` or delegate to parent?

## Objective

Make task creation flexible and intuitive by supporting both positional arguments and named flags for title and metadata, fixing the critical bug where `--help` creates a task instead of showing help.

## Scope of Work

- **User Experience Scope**:
  - Task creation via CLI with full metadata control
  - Help system that works correctly for `task create` subcommand
  - Clear error messages for invalid input

- **System Behavior Scope**:
  - Proper argument parsing with OptionParser
  - Metadata validation (status, priority, dependencies format)
  - Backwards compatibility with existing syntax

- **Interface Scope**:
  - `ace-taskflow task create` command and all its flags
  - Help output for task creation
  - Error messages and validation feedback

### Deliverables

#### Behavioral Specifications
- Complete CLI interface specification with all flags
- Error handling and validation rules
- Help text and usage examples

#### Validation Artifacts
- Manual testing checklist covering all flag combinations
- Backwards compatibility validation (existing commands work)
- Error condition testing (invalid input handled gracefully)

## Out of Scope

- ❌ **Implementation Details**: Whether to use OptionParser vs manual parsing (implementation decision)
- ❌ **File Organization**: How task files are structured internally
- ❌ **Future Enhancements**: Bulk task creation, task templates, task cloning
- ❌ **Related Commands**: Changes to `task update`, `task show`, etc. (separate concerns)

## References

- Original implementation plan provided by user in conversation
- Existing `ace-taskflow task create` implementation in `lib/ace/taskflow/commands/task_command.rb`
- Current argument parsing in `lib/ace/taskflow/molecules/task_arg_parser.rb`

---

## Technical Approach

### Architecture Pattern

The implementation follows the existing ACE ATOM architecture pattern:

- **Atoms**: Pure argument parsing logic (no I/O, fully testable)
- **Molecules**: `TaskArgParser` - parsing logic with OptionParser
- **Organisms**: `TaskManager` - orchestrates task creation with metadata
- **Commands**: `TaskCommand` - CLI interface layer

**Pattern Integration:**
- Extend existing `TaskArgParser` molecule with new `parse_create_args_with_optparse` method
- Maintain separation between parsing (molecule) and business logic (organism)
- Keep command layer thin - delegate to molecules and organisms

**Impact on System:**
- No breaking changes to existing architecture
- Natural extension of current ATOM pattern
- Maintains testability and separation of concerns

### Technology Stack

**Required Libraries:**
- `optparse` (Ruby stdlib) - Already available, no new dependencies needed
- Existing test framework (minitest) - No changes required

**Version Compatibility:**
- Ruby 2.7+ (current requirement)
- No new gem dependencies

**Performance Implications:**
- OptionParser has minimal performance overhead (~microseconds)
- Argument parsing is I/O-bound (user input), not CPU-bound
- No impact on task creation performance

**Security Considerations:**
- OptionParser provides safe argument parsing (no shell injection risk)
- Input validation still required for metadata values
- No new security attack surface

### Implementation Strategy

**Phased Approach:**

1. **Phase 1: Add OptionParser-based parsing** (Atoms/Molecules layer)
   - Create `parse_create_args_with_optparse` method
   - Handle `--help` flag correctly (exit before creating task)
   - Support all metadata flags

2. **Phase 2: Update command layer** (Commands layer)
   - Switch `create_task` method to use new parser
   - Add error handling for invalid flags
   - Update help text

3. **Phase 3: Testing** (All layers)
   - Unit tests for parsing logic
   - Integration tests for command execution
   - Backwards compatibility verification

4. **Phase 4: Documentation** (External)
   - Update README with new flag examples
   - Add to CHANGELOG
   - Update tools.md reference

**Rollback Considerations:**
- Keep old `parse_create_args` method intact during transition
- Can toggle between parsers via feature flag if needed
- Git revert is straightforward (single PR)

**Testing Strategy:**
- Unit tests: ~15 test cases for argument parsing
- Integration tests: ~10 test cases for full command execution
- Manual testing: Critical path validation
- Regression testing: Run full existing test suite

**Performance Monitoring:**
- Not applicable (CLI tool, no production metrics)
- Manual timing checks during development

## File Modifications

### Create

**None** - All changes are modifications to existing files

### Modify

**1. `ace-taskflow/lib/ace/taskflow/molecules/task_arg_parser.rb`**
- **Changes:** Add new method `parse_create_args_with_optparse` using OptionParser
- **Impact:** Provides robust argument parsing with proper help handling
- **Integration points:** Called by `TaskCommand.create_task`
- **Lines to add:** ~60 lines (new method)

**2. `ace-taskflow/lib/ace/taskflow/commands/task_command.rb`**
- **Changes:**
  - Update `create_task` method (lines 148-188) to use new parser
  - Handle OptionParser exceptions
  - Improve error messages
  - Update `show_help` method (lines 464-504) with new flag documentation
- **Impact:** Better UX for task creation, proper help handling
- **Integration points:** Uses `TaskArgParser`, calls `TaskManager.create_task`
- **Lines to modify:** ~50 lines total

**3. `ace-taskflow/test/molecules/task_arg_parser_test.rb`**
- **Changes:** Add comprehensive test cases for new parsing method
- **Impact:** Ensures parsing logic correctness
- **Integration points:** Tests `TaskArgParser` molecule
- **Lines to add:** ~200 lines (15+ test cases)

**4. `ace-taskflow/test/commands/task_command_test.rb`**
- **Changes:** Add integration tests for new command behavior
- **Impact:** Ensures end-to-end functionality
- **Integration points:** Tests full command execution flow
- **Lines to add:** ~150 lines (10+ test cases)

**5. `ace-taskflow/README.md`**
- **Changes:** Add examples of new flag usage
- **Impact:** Documentation for end users
- **Lines to add:** ~30 lines (examples section)

**6. `CHANGELOG.md`**
- **Changes:** Document new feature under next version
- **Impact:** Release notes
- **Lines to add:** ~10 lines

### Delete

**None** - No files need deletion

### Rename

**None** - No files need renaming

## Test Case Planning

### Analyze Testing Requirements

**Testable Components:**
- Argument parsing logic (pure function - highly testable)
- Help flag handling (must not create task)
- Metadata validation (status, priority values)
- Dependency CSV parsing
- Error message generation

**Input Validation Rules:**
- Title required (positional or flag)
- Status must be valid enum (if validated)
- Dependencies must be comma-separated
- Help flag short-circuits execution

**Business Logic Flows:**
1. Parse args → validate → create task → return result
2. Parse args → detect --help → show help → exit
3. Parse args → invalid flag → show error → exit

**Error Scenarios:**
- Missing title
- Invalid flag name
- Both positional and --title provided
- Invalid status/priority value

### Scenario Identification

#### Happy Path Scenarios

1. **Positional title only** (existing behavior)
   - Input: `["Add feature"]`
   - Expected: `{ title: "Add feature", context: "current", metadata: {} }`

2. **--title flag only**
   - Input: `["--title", "Add feature"]`
   - Expected: `{ title: "Add feature", context: "current", metadata: {} }`

3. **Title with all metadata flags**
   - Input: `["--title", "Task", "--status", "draft", "--priority", "high", "--estimate", "2h", "--dependencies", "018,019"]`
   - Expected: `{ title: "Task", metadata: { status: "draft", priority: "high", estimate: "2h", dependencies: ["018", "019"] } }`

4. **Positional title with metadata**
   - Input: `["My task", "--priority", "critical"]`
   - Expected: `{ title: "My task", metadata: { priority: "critical" } }`

5. **--help flag**
   - Input: `["--help"]`
   - Expected: Show help text, exit 0, no task created

#### Edge Case Scenarios

1. **Empty title string**
   - Input: `["--title", ""]`
   - Expected: Error "Task title is required"

2. **Multi-word positional title**
   - Input: `["Add", "new", "feature"]`
   - Expected: `{ title: "Add new feature" }`

3. **Both positional and --title flag**
   - Input: `["Positional", "--title", "Flag"]`
   - Expected: Positional wins OR show error (decision needed)

4. **Duplicate flags**
   - Input: `["--title", "First", "--title", "Second"]`
   - Expected: Last value wins (OptionParser default behavior)

5. **Special characters in title**
   - Input: `["--title", "Fix: bug #42 [urgent]"]`
   - Expected: Title preserved with special chars

6. **Dependencies with spaces**
   - Input: `["--dependencies", "018, 019, 020"]`
   - Expected: `dependencies: ["018", "019", "020"]` (spaces trimmed)

#### Error Condition Scenarios

1. **Invalid flag name**
   - Input: `["--invalid-flag", "value"]`
   - Expected: Error "invalid option: --invalid-flag", suggest --help

2. **Missing title**
   - Input: `[]`
   - Expected: Error "Task title is required" with usage hint

3. **Missing flag value**
   - Input: `["--title"]`
   - Expected: OptionParser error "missing argument: --title"

4. **Invalid dependency format** (future validation)
   - Input: `["--dependencies", "not-a-number"]`
   - Expected: Currently allowed, validation optional

#### Integration Point Scenarios

1. **TaskManager.create_task receives metadata**
   - Verify metadata hash passed correctly
   - Verify task file frontmatter contains metadata

2. **Context flags still work** (--backlog, --release)
   - Input: `["--title", "Task", "--backlog"]`
   - Expected: `context: "backlog"`

3. **Help delegates to OptionParser**
   - Verify OptionParser generates help text
   - Verify custom banner appears

### Test Type Categorization

#### Unit Tests (High Priority)

**TaskArgParser molecule tests:**
1. Parse positional title
2. Parse --title flag
3. Parse --status flag
4. Parse --priority flag
5. Parse --estimate flag
6. Parse --dependencies flag (CSV parsing)
7. Parse --backlog flag
8. Parse --release flag
9. Handle --help flag (capture exit)
10. Handle missing title error
11. Handle invalid flag error
12. Handle multi-word positional title
13. Handle dependencies with spaces
14. Handle empty title
15. Handle both positional and --title

#### Integration Tests (Medium Priority)

**TaskCommand tests:**
1. Create task with positional title (existing)
2. Create task with --title flag
3. Create task with all metadata flags
4. Show help with --help flag (no task created!)
5. Error on missing title
6. Error on invalid flag
7. Verify metadata in task file frontmatter
8. Backwards compatibility (existing commands work)
9. --backlog flag still works
10. --release flag still works

#### End-to-End Tests (Low Priority)

Not applicable - CLI tool, integration tests sufficient

#### Performance Tests

Not applicable - CLI tool, no performance requirements

#### Security Tests

Not applicable - input validation only, no authentication/authorization

### Test Planning Documentation

**Test Data Requirements:**
- Sample task titles (simple, multi-word, special chars)
- Valid/invalid metadata values
- Valid/invalid flag combinations

**Test Environment Setup:**
- Use existing minitest framework
- Mock filesystem for task creation tests
- Capture stdout/stderr for help/error tests

**Test Framework Requirements:**
- Minitest (already in use)
- Assert libraries for exit codes
- Stdout/stderr capture utilities

**Test Coverage Expectations:**
- Target: 100% coverage of new `parse_create_args_with_optparse` method
- Target: 95%+ coverage of modified `create_task` method
- All happy path, edge case, and error scenarios covered

**Success Criteria:**
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Existing test suite passes (regression)
- [ ] Code coverage meets targets
- [ ] Manual testing checklist completed

### Test Prioritization

**High Priority (Must Have):**
- --help flag handling (critical bug fix)
- Positional title parsing (backwards compatibility)
- --title flag parsing (core feature)
- Metadata flags parsing (core feature)
- Error handling (UX)

**Medium Priority (Should Have):**
- Edge cases (empty title, special chars)
- Integration tests (end-to-end flow)
- Backwards compatibility verification

**Low Priority (Nice to Have):**
- Performance validation (not critical for CLI)
- Complex flag combinations (rare use cases)

## Implementation Plan

### Planning Steps

* [ ] Verify existing test coverage for task creation
  > TEST: Coverage Baseline
  > Type: Pre-condition Check
  > Assert: Current test coverage documented
  > Command: cd ace-taskflow && bundle exec rake test && bundle exec simplecov

* [ ] Review OptionParser documentation and best practices
  - Study exit handling for --help flag
  - Understand exception types for error handling
  - Review parse! vs parse behavior

* [ ] Design argument precedence rules
  - Decision: What happens with both positional and --title?
  - Document chosen behavior
  - Add to validation questions if uncertain

### Execution Steps

- [ ] **Step 1:** Update `task_arg_parser.rb` - Add `parse_create_args_with_optparse` method
  - Add `require 'optparse'` if not present
  - Create OptionParser instance with banner
  - Define all flags (--title, --status, --priority, --estimate, --dependencies, --backlog, --release, --help)
  - Handle dependency CSV parsing
  - Handle positional title fallback
  - Return options hash
  > TEST: Parser Method Exists
  > Type: Action Validation
  > Assert: New method defined and returns hash with expected keys
  > Command: cd ace-taskflow && bundle exec ruby -r ./lib/ace/taskflow/molecules/task_arg_parser -e "puts Ace::Taskflow::Molecules::TaskArgParser.respond_to?(:parse_create_args_with_optparse)"

- [ ] **Step 2:** Add unit tests for `TaskArgParser.parse_create_args_with_optparse`
  - Create test file if needed (already exists)
  - Add ~15 test cases covering all scenarios
  - Test happy paths, edge cases, error conditions
  - Test help flag handling (capture exit)
  > TEST: Parser Tests Pass
  > Type: Action Validation
  > Assert: All new parser tests passing
  > Command: cd ace-taskflow && bundle exec ruby -Ilib:test test/molecules/task_arg_parser_test.rb -n "/parse_create/"

- [ ] **Step 3:** Update `task_command.rb` - Modify `create_task` method
  - Replace manual arg parsing with call to new parser method
  - Add OptionParser::InvalidOption exception handling
  - Improve error messages with usage hints
  - Update validation logic for metadata
  > TEST: Command Method Updated
  > Type: Action Validation
  > Assert: create_task method uses new parser
  > Command: cd ace-taskflow && grep -A 10 "def create_task" lib/ace/taskflow/commands/task_command.rb | grep "parse_create_args_with_optparse"

- [ ] **Step 4:** Update `task_command.rb` - Enhance `show_help` method
  - Add documentation for new flags
  - Add usage examples
  - Update examples section
  > TEST: Help Text Updated
  > Type: Action Validation
  > Assert: Help text includes new flags
  > Command: cd ace-taskflow && bundle exec ruby -Ilib -r ace/taskflow/commands/task_command -e "cmd = Ace::Taskflow::Commands::TaskCommand.new; cmd.send(:show_help)" | grep -E "(--title|--status|--priority)"

- [ ] **Step 5:** Add integration tests for `TaskCommand.execute`
  - Add test cases for end-to-end task creation
  - Test --help flag (verify no task created!)
  - Test metadata in created task files
  - Test error conditions
  > TEST: Integration Tests Pass
  > Type: Action Validation
  > Assert: All integration tests passing
  > Command: cd ace-taskflow && bundle exec ruby -Ilib:test test/commands/task_command_test.rb -n "/create/"

- [ ] **Step 6:** Run full test suite for regression check
  - Verify no existing tests broken
  - Check for unexpected failures
  - Fix any broken tests
  > TEST: No Regressions
  > Type: Regression Check
  > Assert: All existing tests still pass
  > Command: cd ace-taskflow && bundle exec rake test

- [ ] **Step 7:** Manual testing - Critical path validation
  - Test: `ace-taskflow task create --help` (must NOT create task!)
  - Test: `ace-taskflow task create 'Test'` (positional still works)
  - Test: `ace-taskflow task create --title 'Test'` (flag works)
  - Test: `ace-taskflow task create --title 'Test' --priority high --status draft` (metadata works)
  - Test: `ace-taskflow task create --dependencies 018,019 --title 'Test'` (dependencies work)
  - Verify metadata in created task file frontmatter
  > TEST: Manual Validation Complete
  > Type: Manual Validation
  > Assert: All critical paths work as expected
  > Command: # Manual testing checklist above

- [ ] **Step 8:** Update documentation
  - Update `ace-taskflow/README.md` with new flag examples
  - Add to CHANGELOG.md under "Unreleased" or next version
  - Update `docs/tools.md` if applicable
  > TEST: Documentation Updated
  > Type: Action Validation
  > Assert: Documentation includes new features
  > Command: grep -E "(--title|--status|--priority)" ace-taskflow/README.md

- [ ] **Step 9:** Clean up and finalize
  - Remove debug statements
  - Ensure code follows style guide
  - Run linter if available
  - Verify all tests pass one final time
  > TEST: Final Validation
  > Type: Final Check
  > Assert: All tests pass, code clean
  > Command: cd ace-taskflow && bundle exec rake test && rubocop lib/ace/taskflow/molecules/task_arg_parser.rb lib/ace/taskflow/commands/task_command.rb

## Acceptance Criteria

- [ ] **Critical bug fixed**: `ace-taskflow task create --help` shows help and does NOT create a task
- [ ] **Backwards compatible**: Existing `ace-taskflow task create 'Title'` syntax works unchanged
- [ ] **--title flag works**: `ace-taskflow task create --title 'Title'` creates task correctly
- [ ] **Metadata flags work**: All flags (--status, --priority, --estimate, --dependencies) set frontmatter
- [ ] **Dependencies parsed**: `--dependencies 018,019` creates array in frontmatter
- [ ] **Error handling**: Invalid flags show clear errors with --help suggestion
- [ ] **All tests pass**: Unit tests, integration tests, and existing test suite pass
- [ ] **Documentation updated**: README, CHANGELOG, and tools docs include new features

## Risk Assessment

### Technical Risks

- **Risk:** OptionParser behavior differs from manual parsing
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Comprehensive test coverage, manual validation
  - **Rollback:** Keep old parsing method, revert changes

- **Risk:** Breaking change to existing command behavior
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Extensive backwards compatibility testing
  - **Rollback:** Git revert, release patch

- **Risk:** Edge cases not covered in testing
  - **Probability:** Medium
  - **Impact:** Low
  - **Mitigation:** User feedback in next release, quick patch
  - **Rollback:** Not needed unless critical

### Integration Risks

- **Risk:** TaskManager.create_task doesn't handle new metadata format
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Verify TaskManager already accepts metadata hash (it does)
  - **Monitoring:** Integration tests verify end-to-end

- **Risk:** Help text conflicts with parent command help
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Test help at all command levels
  - **Monitoring:** Manual testing of help output

### Performance Risks

Not applicable - CLI tool with no performance requirements
