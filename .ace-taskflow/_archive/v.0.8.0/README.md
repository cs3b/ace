# v.0.8.0 Minitest Migration

## Release Overview

This release focuses on migrating the test suite from RSpec to Minitest, establishing modern testing best practices, and creating a comprehensive testing guide. The migration emphasizes testing important behaviors rather than implementation details, with a balanced approach to mocking.

## Release Information

- **Type**: Feature
- **Start Date**: 2025-09-17
- **Target Date**: 2025-10-15
- **Status**: Planning

## Collected Notes

### User Goals
- Setup minitest for unit tests and document best practices
- Migrate all unit tests -> focus on analyzing implementation and test only what is important behaviours
- Think how to test cmd line without using VCR - to have fast integration tests
- Think how to do integration tests - usually one at cmd - the most complex case
- Do not write tests only to run tests
- We should mock only important parts (do not mock everything to make unit test / use balance approach)
- Write @docs/dev/testing.md guide (how to deal with all of the tests and capture all best practice)

### Research Notes
- Test split strategy: Unit tests (Minitest) for fast, pure Ruby tests; CLI/integration tests (Aruba + Minitest) for user-facing behavior
- Minitest + VCR + Aruba combination for comprehensive testing
- In-process testing with Aruba for WebMock/VCR to intercept HTTP
- Minitest-reporters gem for better output formatting
- Backtrace filtering and diff configuration for cleaner test output

## Goals & Requirements

### Primary Goals

- [ ] Establish Minitest as the primary testing framework with proper configuration for unit and integration tests
- [ ] Migrate existing RSpec tests focusing on important behaviors, not 1:1 conversion (target: 80%+ coverage of critical paths)
- [ ] Create comprehensive testing documentation guide at docs/dev/testing.md with best practices and examples
- [ ] Implement fast CLI testing approach without VCR for basic integration tests (target: <5s for basic CLI test suite)
- [ ] Design balanced mocking strategy that tests real behavior while maintaining test speed

### Dependencies

- Minitest gem and related testing dependencies (minitest-reporters, webmock, vcr, aruba)
- Existing RSpec test suite as reference for behavior coverage
- Current CLI architecture using dry-cli
- Git submodules properly initialized

### Risks & Mitigation

- **Risk**: Loss of test coverage during migration | **Mitigation**: Analyze existing tests first, map critical behaviors before migration
- **Risk**: Slow test suite after migration | **Mitigation**: Separate unit/integration tests, use in-process testing for CLI, selective VCR usage
- **Risk**: Complex mocking setups | **Mitigation**: Document mocking patterns, create test helpers, balanced approach to mocking

## Implementation Plan

### Core Components

1. **Test Framework Setup**
   - [ ] Configure Minitest with proper test_helper.rb
   - [ ] Setup Aruba for CLI testing with in-process launcher
   - [ ] Configure VCR for HTTP boundary testing
   - [ ] Establish test directory structure (test/unit, test/integration, test/cassettes)

2. **Test Migration Strategy**
   - [ ] Analyze current RSpec test coverage and identify critical behaviors
   - [ ] Map tests to important implementation behaviors vs implementation details
   - [ ] Create migration priority list based on code criticality
   - [ ] Develop test helper utilities for common patterns

3. **Implementation Phases**
   - [ ] Phase 1: Foundation - Setup Minitest, create testing guide, establish patterns
   - [ ] Phase 2: Core migration - Migrate atoms/molecules/organisms tests with behavior focus
   - [ ] Phase 3: CLI & Integration - Implement fast CLI tests and complex integration scenarios
   - [ ] Phase 4: Cleanup - Remove RSpec, optimize performance, finalize documentation

## Quality Assurance

### Test Coverage

- [ ] Unit Tests (>80% coverage for critical business logic)
- [ ] Fast CLI Integration Tests (basic command validation)
- [ ] Complex Integration Tests (one comprehensive test per major command)
- [ ] VCR cassettes properly managed for HTTP boundaries

### Documentation

- [ ] docs/dev/testing.md comprehensive testing guide
- [ ] Test helper documentation
- [ ] Migration notes for future reference
- [ ] CHANGELOG Entry

## Release Checklist

- [ ] All RSpec tests analyzed and critical behaviors identified
- [ ] Minitest framework properly configured with Aruba and VCR
- [ ] Test migration completed with focus on behaviors, not implementation
- [ ] Fast CLI testing approach implemented and documented
- [ ] Complex integration tests created for major commands
- [ ] docs/dev/testing.md guide written with best practices
- [ ] All tests passing with Minitest
- [ ] RSpec dependencies removed from Gemfile
- [ ] CI configuration updated for Minitest
- [ ] Performance benchmarks show acceptable test suite speed (<30s for unit, <2min for full suite)
- [ ] Test coverage metrics documented (target: 80%+ for critical paths)
- [ ] Migration guide prepared for team reference

## Notes

This migration is not a 1:1 conversion from RSpec to Minitest. The focus is on:
- Testing important behaviors rather than implementation details
- Creating a maintainable test suite that provides confidence without brittleness
- Establishing patterns that make tests easy to write and understand
- Balancing test isolation with realistic behavior testing
- Optimizing for both developer experience and CI performance

The testing philosophy emphasizes pragmatic testing that catches real bugs while avoiding tests that only verify Ruby works as expected.