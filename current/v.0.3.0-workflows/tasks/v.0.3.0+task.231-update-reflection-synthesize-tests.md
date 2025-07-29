---
id: v.0.3.0+task.231
status: pending
priority: high
estimate: 4h
dependencies: [v.0.3.0+task.227, v.0.3.0+task.228]
---

# Update reflection-synthesize Tests

## 0. Directory Audit ✅

_Command run:_

```bash
grep -n "archived.*default" dev-tools/spec/coding_agent_tools/cli/commands/reflection/synthesize_spec.rb | head -3
```

_Result excerpt:_

```
(No output - tests don't explicitly check default value)
```

## Objective

Update the reflection-synthesize test suite to cover the new output path behavior and changed archive default. Ensure tests validate that synthesis saves to the release-specific directory and that archiving is enabled by default.

## Scope of Work

- Update tests for new output path logic using ReleaseManager
- Add tests for release-relative synthesis directory
- Update tests to expect archived default as true
- Add tests for backward compatibility
- Ensure integration with ReleaseManager is tested

### Deliverables

#### Create

- None

#### Modify

- dev-tools/spec/coding_agent_tools/cli/commands/reflection/synthesize_spec.rb
- dev-tools/spec/coding_agent_tools/molecules/reflection/synthesis_orchestrator_spec.rb (if exists)

#### Delete

- None

## Phases

1. Review current test coverage
2. Update output path tests
3. Update archive default tests
4. Add ReleaseManager integration tests
5. Verify backward compatibility

## Implementation Plan

### Planning Steps

* [ ] Analyze current test structure and coverage
* [ ] Identify tests that need updates
* [ ] Plan new test scenarios
* [ ] Design mock strategy for ReleaseManager

### Execution Steps

- [ ] Update output path determination tests
  ```ruby
  describe "#determine_output_path" do
    it "uses release reflections/synthesis directory by default"
    it "respects explicit --output paths"
    it "creates synthesis directory if missing"
  end
  ```
- [ ] Update archive default behavior tests
  ```ruby
  it "archives by default when --archived not specified"
  it "respects --no-archived flag"
  it "shows archived as true in dry run output"
  ```
- [ ] Add ReleaseManager integration tests
  ```ruby
  describe "ReleaseManager integration" do
    it "uses ReleaseManager for path resolution"
    it "handles missing current release"
    it "auto-discovers using ReleaseManager"
  end
  ```
- [ ] Update existing tests that assume old defaults
- [ ] Ensure mocks properly simulate new behavior

## Acceptance Criteria

- [ ] Tests reflect new output path in release/reflections/synthesis/
- [ ] Tests validate archived defaults to true
- [ ] ReleaseManager integration is properly tested
- [ ] Backward compatibility is verified
- [ ] All existing tests still pass with updates
- [ ] New behavior is comprehensively covered

## Out of Scope

- ❌ Testing synthesis algorithm or LLM integration
- ❌ Testing archive functionality internals
- ❌ Performance testing
- ❌ Integration tests with real file system

## References

- Synthesize spec: dev-tools/spec/coding_agent_tools/cli/commands/reflection/synthesize_spec.rb
- Implementation tasks: v.0.3.0+task.227, v.0.3.0+task.228
- Test should verify new behavior while maintaining compatibility