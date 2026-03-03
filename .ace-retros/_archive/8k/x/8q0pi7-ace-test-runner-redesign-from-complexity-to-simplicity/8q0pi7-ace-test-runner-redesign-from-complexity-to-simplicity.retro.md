---
id: 8q0pi7
title: ace-test-runner Redesign - From Complexity to Simplicity
type: conversation-analysis
tags: []
created_at: '2025-09-20 00:00:00'
status: done
source: legacy
migrated_from: ".ace-taskflow/v.0.9.0/retros/ace-test-runner-redesign-from-complexity-to-simplicity.md"
---

# Reflection: ace-test-runner Redesign - From Complexity to Simplicity

**Date**: 2025-09-20
**Context**: Investigation and redesign of ace-test-runner performance issues and over-engineering
**Author**: Development Team
**Type**: Conversation Analysis

## What Went Well

- Successfully identified the root cause of 9x performance degradation (3.2s vs 0.37s)
- Found and recovered the original simple implementation from v.0.8.0
- Recognized the over-engineering problem early in the investigation
- Created a clear task (v.0.9.0+task.011) for the redesign with proper specifications
- User provided excellent guidance about keeping it simple and using native Minitest

## What Could Be Improved

- Initially tried to fix the complex implementation instead of questioning the architecture
- Created an over-engineered ace-test-runner gem when a simple script would suffice
- Didn't compare with rake's approach earlier (single process execution)
- Lost sight of Unix philosophy: do one thing well

## Key Learnings

### Technical Insights

1. **Performance Killer**: Running each test file in a separate process (`execute_with_progress`) caused 9x slowdown
   - Current: `bundle exec ruby -Ilib:test ./test/file.rb` (per file)
   - Better: `ruby -Ilib:test -r./file1 -r./file2 ... -e 'Minitest.autorun'` (all together)

2. **ANSI Color Codes**: ResultParser failed because it didn't strip color codes from output
   - Fixed with: `output.gsub(/\e\[[0-9;]*m/, '')`

3. **Minitest Autorun**: The -e flag needed `Minitest.autorun`, not empty string
   - Wrong: `-e ''`
   - Right: `-e 'Minitest.autorun'`

4. **Test Discovery**: File naming matters - `test_core.rb` → `core_test.rb` for pattern matching

### Architectural Insights

1. **Over-Engineering Trap**: Created complex ATOM architecture for a simple test runner
   - 20+ files across atoms/molecules/organisms
   - Complex result aggregation logic
   - Multiple formatters and report generators
   - All for running: `ruby -Ilib:test -e "require tests..."`

2. **Simple is Better**: The recovered 417-line script does everything needed:
   - YAML configuration for test groups
   - Pattern matching and file discovery
   - Profiling support
   - Parallel execution
   - All in ONE file

3. **Native Tools**: Working WITH Minitest instead of AGAINST it
   - Use Minitest's reporters, not custom ones
   - Use Minitest's autorun, not manual execution
   - Use Minitest's parallel support, not custom

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Performance Degradation**: 9x slower than rake
  - Occurrences: Primary issue throughout session
  - Impact: Developer frustration, slow feedback loop
  - Root Cause: Process-per-file execution model

- **Over-Engineering**: Complex gem for simple task
  - Occurrences: Entire ace-test-runner implementation
  - Impact: Hard to maintain, debug, and optimize
  - Root Cause: Applying ATOM architecture where not needed

#### Medium Impact Issues

- **Missing Features**: No line number support, no profiling
  - Occurrences: Multiple user corrections
  - Impact: Less useful than original implementation
  - Root Cause: Focus on architecture over functionality

### Improvement Proposals

#### Process Improvements

- Always benchmark against existing solutions (rake test)
- Question complexity - is this architecture necessary?
- Start simple, add complexity only when proven necessary

#### Tool Enhancements

- Redesign ace-test-runner with single-process execution
- Add compact formatter with 2-line errors
- Support line numbers: `ace-test file:42`
- Keep ATOM architecture but simplify execution

#### Design Principles

- **Do One Thing Well**: Test runner should just run tests efficiently
- **Use Native Tools**: Leverage Minitest's built-in capabilities
- **Measure First**: Always profile before optimizing
- **Simple Wins**: 417 lines beats 20+ files for maintainability

## Action Items

### Stop Doing

- Creating complex architectures for simple tools
- Running test files in separate processes
- Fighting against framework conventions (Minitest)
- Adding layers of abstraction without clear benefit

### Continue Doing

- Investigating performance with actual measurements
- Comparing with existing solutions (rake)
- Following ATOM architecture WHERE IT MAKES SENSE
- Creating detailed task specifications

### Start Doing

- Benchmark new implementations against existing tools
- Question architectural decisions early
- Prioritize simplicity and performance
- Use native framework features first

## Technical Details

### Performance Comparison
```
rake test:           0.37s (83 tests)
ace-test (current):  3.24s (83 tests) - 8.6x slower
ace-test (target):   <0.5s (83 tests) - match rake
```

### Execution Models
```ruby
# Current (SLOW) - process per file
files.each do |file|
  system("bundle exec ruby -Ilib:test #{file}")
end

# Better (FAST) - single process
requires = files.map { |f| "require './#{f}'" }.join("; ")
system("ruby -Ilib:test -e \"#{requires}; Minitest.autorun\"")
```

### Compact Formatter Design
```
Running 83 tests...
..........F.....E......

FAILURES (2):
  test/atoms/foo_test.rb:42 - Expected "bar" got "baz"
  test/molecules/bar_test.rb:15 - NoMethodError

Details: test-reports/2025-09-20-154522/
83 tests, 240 assertions, 2 failures, 1 error (0.055s)
```

## Additional Context

- Created task v.0.9.0+task.011 for redesign
- Recovered original implementation from v.0.8.0
- Commits: Various fixes to ace-test-runner throughout session
- Related files:
  - `/Users/mc/Ps/ace-meta/ace-test-runner/` - Current over-engineered implementation
  - `/Users/mc/Ps/ace-meta/dev-taskflow/current/v.0.9.0-mono-repo-multiple-gems/docs/lost/ace-test` - Recovered simple implementation

## Key Insight: Simplicity Scales Better

The most important learning from this session is that **simplicity scales better than complexity**. The original 417-line script outperforms and out-features our complex gem because it works WITH the tools (Minitest, Ruby) rather than creating unnecessary abstractions.

When the user said "shouldn't we just have custom formatter and run tests using native minitest approach", they were pointing to the core issue: we had lost sight of the simple solution in pursuit of architectural purity.

Going forward: Start simple, measure performance, add complexity only when proven necessary.