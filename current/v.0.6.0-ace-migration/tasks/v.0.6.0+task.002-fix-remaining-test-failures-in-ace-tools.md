# Fix Remaining Test Failures in ACE Tools

## Task Metadata
- **ID**: v.0.6.0+task.002
- **Title**: Fix Remaining Test Failures in ACE Tools
- **Status**: pending
- **Priority**: high
- **Estimate**: 2h
- **Dependencies**: v.0.6.0+task.001 (complete migration cleanup)
- **Created**: 2025-09-16

## Behavioral Specification

### What Users Experience
After running the test suite in `.ace/tools`, developers should see:
- All tests passing (898 examples, 0 failures)
- Clear test output with no errors
- Confidence that the migration is complete and stable

### Current State
- 23 test failures remaining after initial UnifiedSearcher fixes
- Test suite at 97.4% passing (875/898 tests)
- Multiple categories of failures affecting different components

### Success Criteria
- [ ] All 898 tests pass successfully
- [ ] No LoadError or missing file errors
- [ ] Test suite runs in under 5 seconds
- [ ] Coverage maintained or improved from current 33.5%

## Interface Contract

### CLI Experience
```bash
# Running tests should show:
$ bundle exec rspec
............................................... [898 dots]

Finished in 3.5 seconds
898 examples, 0 failures, 2 pending

# Individual component tests pass:
$ bundle exec rspec spec/ace_tools/organisms/search/unified_searcher_spec.rb
27 examples, 0 failures

$ bundle exec rspec spec/ace_tools/cli_spec.rb
[X] examples, 0 failures
```

### Test Categories Requiring Fixes

#### Category 1: UnifiedSearcher (9 failures)
- Invalid pattern handling should return `success: false`
- File search results need proper hash structure
- Metadata validation needs Ruby-compatible checks

#### Category 2: CLI Command Registration (8 failures)
- Remove obsolete `register_dotfiles_commands` tests
- Update handbook claude subcommand expectations
- Fix release command path expectations

#### Category 3: Coverage Result Model (3 failures)
- Mock objects need `needs_tests?` method stub

#### Category 4: Minor Issues (3 failures)
- Update model alias expectations
- Fix template validation logic
- Correct allowed-tools format

## Implementation Strategy

### Phase 1: Quick Fixes (15 min, 12 failures)
1. Fix Coverage Result mocks - add `needs_tests?` stub
2. Update Capture-It model alias expectation
3. Remove obsolete CLI command registrations
4. Update release command path

### Phase 2: UnifiedSearcher Completion (45 min, 9 failures)
1. Add nil/empty pattern validation
2. Fix file search result structure
3. Replace Rails helpers with Ruby checks

### Phase 3: Template/Generator Issues (20 min, 2 failures)
1. Update CommandTemplateRenderer validation
2. Fix ClaudeCommandGenerator output format

## Validation Questions
- Should we maintain backward compatibility for removed commands?
- Is the current 33.5% coverage acceptable or should we improve it?
- Should pending tests be addressed or left as-is?

## Testing Requirements
- Run full test suite after each phase
- Verify no new failures introduced
- Document any intentional test removals

## Notes
- This task completes the v0.6.0 ACE migration cleanup
- Focuses on test stability rather than new functionality
- Some tests may be obsolete after migration and should be removed rather than fixed

## Implementation Plan

### Technical Research Findings
- **Pattern**: Test failures fall into 4 distinct categories requiring different approaches
- **Root Causes**: Migration left orphaned expectations, mock configuration gaps, and structural mismatches
- **Approach**: Fix tests rather than implementation where tests have outdated expectations

### File Modifications

#### Files to Modify

**Phase 1 - Quick Fixes:**
1. `spec/ace_tools/models/coverage_result_spec.rb`
   - Add `.and_return(false)` stub for `needs_tests?` method on MethodCoverage mock
   - Lines: 82, 98, 149 (3 locations)

2. `spec/cli/capture_it_spec.rb`
   - Update line 431: Change expectation from `"gflash"` to `"google:gemini-2.5-flash-lite"`

**Phase 2 - CLI Command Registration:**
3. `spec/ace_tools/cli_spec.rb`
   - Remove entire `register_dotfiles_commands` describe block (lines ~86-95)
   - Remove references to `register_dotfiles_commands` in other tests (lines 284, 311, 333)
   - Remove expectations for handbook/claude subcommands (lines 451, 463)
   - Update line 70: Change `release/current` to `release/draft`

**Phase 3 - UnifiedSearcher:**
4. `lib/ace_tools/organisms/search/unified_searcher.rb`
   - Add pattern validation at start of search method:
     ```ruby
     return {success: false, error: "Pattern cannot be nil"} if pattern.nil?
     return {success: false, error: "Pattern cannot be empty"} if pattern.empty?
     ```

5. `lib/ace_tools/organisms/search/result_aggregator.rb`
   - Ensure `extract_flat_results` returns proper hash structures for file searches
   - Add error handling for malformed results

6. `spec/ace_tools/organisms/search/unified_searcher_spec.rb`
   - Replace `be_present` with `!nil? && !empty?` checks
   - Update metadata validation expectations

**Phase 4 - Template/Generator:**
7. `spec/ace_tools/molecules/command_template_renderer_spec.rb`
   - Update line 76: Adjust validation expectation or fix validation logic

8. `spec/ace_tools/organisms/claude_command_generator_spec.rb`
   - Update line 193: Fix allowed-tools format expectation

#### Files to Delete
- None required (only modify existing test files)

### Dependencies
- No new dependencies required
- Uses existing RSpec testing framework

### Test Strategy

Since this task IS about fixing tests themselves:
1. **Incremental Testing**: Run tests after each phase to verify fixes
2. **No New Tests**: This task fixes existing tests, doesn't create new ones
3. **Validation**: Ensure no new failures introduced by fixes

### Execution Sequence

1. **Phase 1**: Quick mock fixes (5 min)
   - Fix coverage_result_spec.rb mocks
   - Update capture_it_spec.rb expectation
   - Run: `bundle exec rspec spec/ace_tools/models/coverage_result_spec.rb spec/cli/capture_it_spec.rb`

2. **Phase 2**: CLI cleanup (10 min)
   - Remove obsolete command expectations
   - Update paths
   - Run: `bundle exec rspec spec/ace_tools/cli_spec.rb`

3. **Phase 3**: UnifiedSearcher fixes (30 min)
   - Add pattern validation
   - Fix result structures
   - Replace Rails helpers
   - Run: `bundle exec rspec spec/ace_tools/organisms/search/unified_searcher_spec.rb`

4. **Phase 4**: Template fixes (10 min)
   - Update template expectations
   - Fix generator format
   - Run full suite: `bundle exec rspec`

### Risk Mitigation
- **Risk**: Removing tests might hide real issues
  - **Mitigation**: Only remove tests for genuinely deleted functionality
- **Risk**: Mock fixes might mask implementation bugs
  - **Mitigation**: Verify mocks match actual implementation interfaces