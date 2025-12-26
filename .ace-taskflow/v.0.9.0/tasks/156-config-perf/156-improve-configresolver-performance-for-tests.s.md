---
id: v.0.9.0+task.156
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Improve ConfigResolver performance for test environments

## Behavioral Specification

### User Experience
- **Input**: Test runner executes ace-git test suite
- **Process**: Tests should complete quickly without filesystem searches for config files
- **Output**: Tests pass in reasonable time (< 1s for unit tests)

### Expected Behavior
ConfigResolver should NOT perform filesystem searches in test environments. The current implementation searches multiple directories (`project/.ace/git/config.yml`, `~/.ace/git/config.yml`) on every call, causing ace-git organism tests to take 5+ seconds.

In test mode, ConfigResolver should:
1. Skip filesystem searches entirely
2. Return empty config immediately
3. Allow tests to provide mock config via stubs if needed

### Interface Contract

```ruby
# Current behavior (slow in tests)
resolver = Ace::Core::Organisms::ConfigResolver.new(file_patterns: ["git/config.yml"])
config = resolver.resolve  # Does filesystem search - SLOW in tests

# Desired behavior for test environments
# Option 1: Detect test environment and skip search
Ace::Core::Organisms::ConfigResolver.new(test_mode: true).resolve  # Returns empty immediately

# Option 2: Global test mode flag
Ace::Core::Organisms::ConfigResolver.test_mode = true
resolver.resolve  # Returns empty immediately when in test mode

# Option 3: Class-level cache for test environments
Ace::Core::Organisms::ConfigResolver.cached_for_tests  # Single search, cached results
```

**Error Handling:**
- File not found: Return empty config (no errors in test mode)
- Invalid YAML: Return empty config (no errors in test mode)
- Permission denied: Return empty config (no errors in test mode)

**Edge Cases:**
- Test that explicitly needs real config: Can opt-out of test mode
- Config changes during test run: Cache invalidation not needed (tests are isolated)
- Multiple file patterns: Search skipped entirely in test mode

### Success Criteria
- [ ] **Performance**: ace-git organism tests run in < 1s (currently 5.7s)
- [ ] **Test Independence**: Tests don't depend on filesystem state or real config files
- [ ] **Backward Compatibility**: Non-test code continues to work with real config files
- [ ] **Opt-out Available**: Tests can opt-out of test mode if they need real config loading

### Validation Questions
- [ ] **Detection Method**: How should ConfigResolver detect test environment? (ENV var, constant, explicit flag?)
- [ ] **Cache Scope**: Should cache be per-test-class, per-test-suite, or global?
- [ ] **Opt-out Mechanism**: How do tests opt-out of test mode if they need real config?
- [ ] **Multi-package Impact**: Will this affect other ace-* packages that use ConfigResolver?

## Objective

ace-git unit tests are slow (5.7s for 29 organism tests) because ConfigResolver performs filesystem searches on every call. Tests should be fast and isolated from filesystem dependencies.

## Scope of Work

- **User Experience Scope**: Test execution speed and reliability
- **System Behavior Scope**: ConfigResolver behavior in test environments
- **Interface Scope**: ConfigResolver API with optional test mode

### Deliverables

#### Behavioral Specifications
- Test mode detection mechanism
- ConfigResolver test mode behavior
- Opt-out mechanism for tests needing real config

#### Validation Artifacts
- Performance benchmarks showing test time improvement
- Test suite passing with fast config resolution

## Out of Scope
- ❌ **Implementation Details**: Specific caching strategy, code structure
- ❌ **Other Performance Issues**: ace-git atoms tests already fast, other ace-* packages
- ❌ **Config File Format**: Changes to config YAML structure or schema
- ❌ **Non-Test Performance**: ConfigResolver performance in production code (already fast enough)

## References

- ace-git organisms test slowness investigation (2025-01-25)
- Current ConfigResolver implementation in ace-support-core
- ace-git test results: atoms 22ms, organisms 5.7s
