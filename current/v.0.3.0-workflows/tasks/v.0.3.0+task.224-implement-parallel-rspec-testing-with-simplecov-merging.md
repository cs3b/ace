---
id: v.0.3.0+task.224
status: in-progress
priority: high
estimate: 14-21h
dependencies: []
---

# Task 224: Implement Parallel RSpec Testing with SimpleCov Merging

## Context

The dev-tools test suite currently runs ~3,000 unit tests sequentially in 8 seconds (7s tests + 1s startup). We want to implement parallel execution using 4 runners to reduce runtime to ~2.5 seconds while maintaining SimpleCov coverage reporting.

## Objective

Implement parallel RSpec testing with the `parallel_tests` gem, update the `bin/test` script for enhanced functionality, and ensure proper SimpleCov coverage merging - all while maintaining backward compatibility.

## Acceptance Criteria

- [ ] Test suite runs in parallel by default (4 workers)
- [ ] Runtime reduced from 8s to ~2.5s (60-65% improvement)
- [ ] SimpleCov coverage reports merge correctly from parallel processes
- [ ] All existing `bin/test` functionality preserved (backward compatibility)
- [ ] CLI tests run with proper isolation (one test per runner)
- [ ] New test commands available: `:all`, `:unit`, `:integration`, `:slow`, `:sequential`
- [ ] Worker count configurable via `-w/--workers N` option
- [ ] Automatic fallback to sequential execution if parallel_tests unavailable

## Implementation Plan

### Phase 0: Test Count Investigation (PRIORITY)
- [ ] **Investigate test count discrepancy**
  - Current dry-run shows ~6,933 tests but actual execution shows ~3,000
  - Analyze why counts differ (pending/skipped tests, conditional execution, etc.)
  - Establish accurate baseline for performance calculations
- [ ] **Identify CLI tests requiring isolation**
  - Find CLI test files that load many libraries (likely `spec/cli/`)
  - Document which tests cause inflated/fake code coverage
  - Plan isolation strategy for these tests

### Phase 1: Dependencies & Configuration
- [ ] **Add parallel_tests gem**
  - Add `gem "parallel_tests"` to Gemfile in development/test group
  - Run `bundle install` and verify installation
- [ ] **Update SimpleCov configuration (spec_helper.rb)**
  ```ruby
  SimpleCov.start do
    command_name "RSpec:#{Process.pid}#{ENV['TEST_ENV_NUMBER']}"
    formatter SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::JSONFormatter  # Add for merging
    ])
  end
  ```
- [ ] **Add coverage merging task (Rakefile)**
  - Create rake task using `SimpleCov.collate` method for parallel report merging

### Phase 2: Enhanced bin/test Script
- [ ] **Maintain backward compatibility**
  - `bin/test` → Run unit tests in parallel (current default behavior)
  - `bin/test spec/path/file_spec.rb` → Run ONLY specified files in parallel
  - `bin/test spec/atoms/` → Run ONLY specified directory in parallel
  - `bin/test -- --tag focus` → Pass through RSpec options
- [ ] **Add new commands**
  - `bin/test :all` → All test suites (unit + integration + slow) in phases
  - `bin/test :unit` → Unit tests only (explicit)
  - `bin/test :integration` → Integration tests only
  - `bin/test :slow` → Slow tests only
  - `bin/test :sequential` → Force sequential execution (fallback)
- [ ] **Add worker control options**
  - `-w N, --workers N` → Specify number of parallel workers (default: 4)
  - `--help` → Usage information and examples

### Phase 3: CLI Test Special Handling
- [ ] **Implement CLI test isolation**
  - Configure CLI tests to run one test per runner
  - Use `parallel_tests` isolation flags (`--single`, `--isolate`)
  - Consider separate coverage handling for CLI tests
- [ ] **Smart execution strategy**
  - Unit tests: 4 workers
  - Integration tests: 2 workers (I/O intensive)
  - Slow tests: 1 worker (avoid conflicts)
  - CLI tests: 1 test per runner (special isolation)

### Phase 4: Coverage Integration
- [ ] **Automatic coverage management**
  - Clean coverage reports before test runs
  - Merge parallel coverage reports after execution
  - Generate unified HTML coverage report
- [ ] **Validate coverage accuracy**
  - Ensure parallel coverage matches sequential coverage
  - Handle CLI test coverage properly

### Phase 5: Performance Validation
- [ ] **Benchmark performance improvements**
  - Measure before/after execution times
  - Test with different worker counts (2, 4, 6)
  - Validate 60-65% improvement target
- [ ] **Functionality testing**
  - Test all new commands and options
  - Verify fallback to sequential execution works
  - Test custom file/directory targeting

### Phase 6: Documentation & Integration
- [ ] **Update documentation**
  - Update DEVELOPMENT.md with parallel testing instructions
  - Document new bin/test command options
  - Add troubleshooting section
- [ ] **CI/CD considerations**
  - Ensure parallel testing works in CI environment
  - Update any CI scripts if needed

## Technical Details

### Current Test Structure
- **Total files**: 218 spec files
- **Actual test count**: ~3,000 tests (needs verification)
- **Current runtime**: 8 seconds (7s tests + 1s startup)
- **Integration tests**: 5 files in `spec/integration/`
- **Slow tests**: ~20 tests tagged with `:slow`
- **SimpleCov**: v0.22 already configured

### Expected Performance
- **Target runtime**: 2.5-3 seconds total
- **Parallel efficiency**: 7s ÷ 4 workers = 1.75s + 0.75s coordination
- **Improvement**: 60-65% faster execution

### Risk Mitigation
- **Database conflicts**: Use parallel_tests database setup if needed
- **Resource contention**: Configurable worker counts
- **Flaky tests**: Maintain isolation options and sequential fallback
- **Coverage accuracy**: Use proven SimpleCov collate method
- **Breaking changes**: Comprehensive backward compatibility testing

## Dependencies

- `parallel_tests` gem (to be added)
- Ruby >= 3.2 (already available)
- SimpleCov v0.22 (already configured)
- Current RSpec setup (already functional)

## Success Metrics

- ✅ 60%+ reduction in test execution time
- ✅ Accurate merged coverage reports (same % as sequential)
- ✅ Zero breaking changes to existing workflows
- ✅ All new commands function correctly
- ✅ Smooth fallback behavior when parallel_tests unavailable

## Priority

High - Performance improvement for development workflow efficiency

## Estimated Effort

- **Investigation Phase**: 2-4 hours
- **Implementation**: 6-8 hours
- **Testing & Validation**: 4-6 hours
- **Documentation**: 2-3 hours
- **Total**: 14-21 hours

## Related Tasks

- Previous test coverage improvements (ongoing)
- CI/CD optimization (potential follow-up)
- Performance monitoring setup (potential follow-up)