# Test Performance Strategy - Synthesis Report

**Synthesized**: 2026-01-31
**Sources**: 8oup7s (Claude Opus 4.5), 8oup93 (Gemini), 8oupdg (Codex)
**Research Folder**: .ace-taskflow/v.0.9.0/tasks/253-test-perf/research

## Executive Summary

This synthesis consolidates research from three AI agents analyzing PR #187 (100 commits on test optimization) and industry best practices. The core insight: **slow unit tests are bugs, not performance issues**. Any unit/integration test >100ms indicates hidden I/O that should be stubbed.

### Key Findings

1. **The 100ms Rule**: Unit/integration tests >100ms are bugs requiring immediate remediation
2. **Stub the Boundary**: Always stub the outermost method that triggers I/O (not just inner methods)
3. **Fast/Slow Loop Architecture**: Clear separation between fast feedback (unit/integration) and comprehensive validation (E2E)
4. **Test Responsibility Mapping**: Each behavior belongs to exactly one test layer at the lowest level that can prove it
5. **Planner/Writer Separation**: Distinguish WHAT/WHERE to test (Planner) from HOW to implement (Writer)

## Methodology

This report synthesizes parallel research from 3 AI agents:
- **8oup7s (Claude Opus 4.5)**: Comprehensive analysis of PR #187 and industry research; produced 12 supplementary artifacts
- **8oup93 (Gemini)**: Introduced Fast/Slow Loop framing and Planner/Writer role separation
- **8oupdg (Codex)**: Internal repo synthesis with practical coverage model and 20+ proposed artifacts

Synthesis followed the multi-agent research workflow with:
- 35 artifacts compared
- 3 conflicts resolved
- 4 gaps identified

---

## Findings

### 1. The 100ms Rule

All three agents converged on performance thresholds as indicators of test health:

| Layer | Budget | Status if Exceeded |
|-------|--------|-------------------|
| Unit (Atoms) | <10ms | Warning |
| Integration (Molecules) | <50ms | Warning |
| Organisms | <100ms | Warning |
| Any Fast Loop | >100ms | **Bug** |
| Any Fast Loop | >200ms | **Critical Bug** |

**Why it's a bug**: A slow test indicates hidden I/O that should be stubbed. The test is not properly isolated.

**Remediation**:
1. Profile to find the leak: `ace-test --profile 10`
2. Identify the I/O call (subprocess, network, filesystem)
3. Stub the boundary (outermost method)
4. Move real I/O testing to E2E layer

### 2. Stub the Boundary Principle

The most impactful discovery from PR #187:

```ruby
# INCOMPLETE (still slow):
Open3.stub(:capture3, result) { runner.run(file) }

# COMPLETE (fast):
Runner.stub(:available?, true) do  # Stub the BOUNDARY
  Open3.stub(:capture3, result) { runner.run(file) }
end
```

**Why**: Guard methods like `available?` often call `system()` to check tool installation (~500ms each). Stubbing only the inner execution leaves the guard uncovered.

### 3. Fast/Slow Loop Architecture

Formalized by 8oup93, adopted by all:

| Loop | Layer | Speed Goal | I/O Rules |
|------|-------|------------|-----------|
| **Fast** | Unit (Atoms) | <10ms | **Forbidden** - Mock all |
| **Fast** | Integration (Molecules) | <100ms | **Stubbed** - No real I/O |
| **Slow** | E2E (Systems) | Seconds | **Real** - Sandboxed |

**Fast Loop Goals**:
- Validate logic correctness instantly
- Run on every save/commit
- Total suite <10 seconds

**Slow Loop Goals**:
- Validate system coherence
- Run real CLI, real filesystem, real APIs (sandboxed)
- Focus on critical paths, not edge cases

### 4. Zombie Mocks

Discovered by 8oup7s, verified by 8oup93:

**Definition**: Mocks that stub methods no longer called by the implementation, but tests continue to pass because the real code path happens to work (slowly).

**Symptoms**:
- Tests pass but are unexpectedly slow (>100ms = zombie indicator)
- Mock setup doesn't match actual code implementation
- Refactored code still uses old mock patterns

**Case Study (ace-docs ChangeDetector)**:
- Tests stubbed `ChangeDetector.stub :execute_git_command`
- Implementation evolved to use `Ace::Git::Organisms::DiffOrchestrator.generate`
- Tests passed but ran real git operations (~1 second each)
- **Result**: Fixing zombie mocks reduced test time from 14s to 1.5s (89% improvement)

**Detection**: Added to verify-test-suite workflow: "If a 'mocked' test >100ms, try removing the mock. If it still passes, it's a zombie."

### 5. Cache Architecture Complexity

Real-world complexity from ace-lint optimization:

**Problem**: The system had two separate availability caches:
1. `ValidatorRegistry.@availability_cache` - keyed by validator symbol (`:standardrb`)
2. `BaseRunner.@availability_cache` - keyed by command name (`"standardrb"`)

**Symptom**: Random test slowness - different tests slow each run (cache invalidation + test ordering).

**Solution**:
```ruby
# test_helper.rb - pre-warm ALL availability caches at startup
Ace::Lint::Atoms::ValidatorRegistry.available?(:standardrb)
Ace::Lint::Atoms::ValidatorRegistry.available?(:rubocop)
Ace::Lint::Atoms::StandardrbRunner.available?
Ace::Lint::Atoms::RuboCopRunner.available?
```

### 6. Test Responsibility Mapping

Converged from all three agents:

**Principle**: Each behavior belongs to exactly one test layer at the lowest level that can prove it.

| Behavior Type | Preferred Layer | Example |
|---------------|-----------------|---------|
| Pure logic | Unit (atoms) | Password validation |
| Data transformation | Unit (atoms) | YAML parsing |
| Component wiring | Integration | Config loading with file I/O |
| User workflow | E2E | Full CLI command execution |
| Tool availability | E2E | Checking gitleaks is installed |

**Anti-pattern**: Testing edge cases in E2E when they could be unit tests.

### 7. Planner vs Writer Roles

Introduced by 8oup93, expanded by 8oup7s:

| Role | Focus | Output |
|------|-------|--------|
| **Planner** | WHAT + WHERE to test | Test Responsibility Map |
| **Writer** | HOW to implement | Test files |

**Why separate**:
- Planner thinks strategically: coverage gaps, redundancy, risk
- Writer thinks tactically: implementation, performance, assertions
- AI agents can be assigned either role explicitly

### 8. Behavior vs Implementation Testing

From industry research (Martin Fowler, 8oup7s):

```ruby
# BAD: Tests implementation (method was called)
mock.expect(:process, true, [data])
subject.call(data)
mock.verify  # "Was process() called?"

# GOOD: Tests behavior (output is correct)
result = subject.call(data)
assert_equal expected_output, result.output  # "Is output correct?"
```

**Key insight**: "If your test breaks when you rename a private method, you are testing implementation, not behavior."

### 9. Composite Helpers

For maintainable test code (8oup7s):

```ruby
# BAD: 6-7 levels of nesting
def test_complex_operation
  mock_config_loader do
    mock_diff_generator do
      mock_branch_info do
        result = SUT.call
      end
    end
  end
end

# GOOD: Single composite helper
def test_complex_operation
  with_mock_repo_load(branch: "feature", task_pattern: "123") do
    result = SUT.call
    assert result.success?
  end
end
```

**Design Principles**:
1. Sensible defaults - most tests need standard values
2. Keyword arguments - allow targeted overrides
3. Clear naming - `with_mock_<context>` pattern
4. Single responsibility - each helper handles one "thing" completely

---

## Performance Gains Achieved (PR #187)

| Package | Optimization | Before | After | Reduction |
|---------|--------------|--------|-------|-----------|
| ace-support-timestamp | CLI tests → E2E | 13.93s | 61ms | 99.6% |
| ace-lint | 8 test files → E2E + stubbing | 2.1s | 69ms | 97% |
| ace-git-secrets | Subprocess stubbing | 4.47s | 1.78s | 60% |
| ace-review | Integration → mocked | 19.52s | 13.5s | 31% |
| ace-docs | Zombie mock fix | 14s | 1.5s | 89% |

Created **11 E2E test files** with 74 test cases in `.mt.md` format.

---

## Recommendations

### Proposed Skills

| Skill | Purpose |
|-------|---------|
| `/ace:plan-tests` | Plan tests at each layer BEFORE writing code (Test Planner role) |
| `/ace:verify-test-suite` | Audit suite health (slow tests, zombie mocks, layer issues) |
| `/ace:optimize-tests` | Semi-automated performance optimization |
| `/ace:test-review` | Review test PR for layer fit, mocks, performance |
| `/ace:e2e-sandbox-setup` | Safe E2E setup with external APIs |
| `/ace:test-performance-audit` | Monthly/quarterly performance audit |

### Proposed Guides

| Guide | Description |
|-------|-------------|
| `test-layer-decision.g.md` | Decision matrix for unit vs integration vs E2E |
| `test-mocking-patterns.g.md` | Behavior testing, zombie mock prevention, composite helpers |
| `test-suite-health.g.md` | Metrics, CI integration, periodic audits |
| `test-responsibility-map.g.md` | Behavior→layer mapping, risk-based coverage |
| `test-review-checklist.g.md` | PR review checklist for tests |
| `testing-strategy.g.md` | Fast/Slow loop strategy overview |

### Proposed Workflows

| Workflow | Description |
|----------|-------------|
| `plan-tests.wf.md` | Create test responsibility map before coding |
| `verify-test-suite.wf.md` | Health audit (quick/standard/deep modes) |
| `optimize-tests.wf.md` | Profile and fix slow tests |
| `e2e-sandbox-setup.wf.md` | Safe E2E environment setup |
| `create-test-cases.wf.md` | Generate structured test cases |

### Proposed Templates

| Template | Purpose |
|----------|---------|
| `test-responsibility-map.template.md` | Behavior→layer mapping document |
| `test-performance-audit.template.md` | Monthly audit report structure |
| `test-review-checklist.template.md` | PR review checklist |
| `e2e-sandbox-checklist.template.md` | Safe E2E environment setup |

### Proposed Automation

**CI Performance Gate**:
```yaml
- name: Check test performance
  run: |
    ace-test --profile 20 | tee profile.txt
    if grep -E "test_" profile.txt | awk '{print $NF}' | grep -E "0\.[1-9][0-9][0-9]s"; then
      echo "::error::Unit tests exceeding 100ms threshold"
      exit 1
    fi
```

**Periodic Audit Schedule**:
- Weekly: Profile changed packages
- Monthly: Full suite audit with template
- Quarterly: E2E test health review, mock drift check

---

## Artifacts Produced

| Artifact | Type | Source | Description |
|----------|------|--------|-------------|
| test-layer-decision.g.md | guide | 8oup7s | Layer decision matrix |
| test-mocking-patterns.g.md | guide | 8oup7s | Advanced mocking patterns |
| test-suite-health.g.md | guide | 8oup7s | Health metrics and targets |
| test-responsibility-map.g.md | guide | 8oup7s | Behavior→layer mapping |
| test-review-checklist.g.md | guide | 8oup7s | PR review checklist |
| testing-strategy.g.md | guide | 8oup93 | Fast/Slow loop strategy |
| SUMMARY.md | guide | 8oup7s | Navigation index |
| plan-tests.wf.md | workflow | 8oup7s | Test planning workflow |
| verify-test-suite.wf.md | workflow | 8oup7s+8oup93 | Health audit workflow |
| optimize-tests.wf.md | workflow | 8oup7s | Optimization workflow |
| e2e-sandbox-setup.wf.md | workflow | 8oup7s | E2E setup workflow |
| create-test-cases.wf.md | workflow | 8oup93 | Test case generation |
| Templates (4) | template | 8oup7s | Various templates |
| Skills (6) | skill | 8oupdg | Skill definitions |

---

## Gaps for Future Work

1. **Contract Testing Implementation**: All reports mention contract testing; none provide implementation examples for Ruby/Minitest. Consider creating a guide with Pact or VCR examples.

2. **CI/CD Pipeline Integration**: YAML snippets provided but not validated in actual workflows. Test in `.github/workflows/` before broader rollout.

3. **Test Coverage Metrics**: No tooling for coverage enforcement. Evaluate SimpleCov integration for coverage thresholds.

4. **E2E Test Scheduling**: Not addressed which E2E tests run per-PR vs nightly. Consider scheduling strategy based on risk/runtime.

---

## References

### Industry Sources
- [Martin Fowler - Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html)
- [Martin Fowler - Mocks Aren't Stubs](https://martinfowler.com/articles/mocksArentStubs.html)
- [Google Testing Blog - Test Sizes](https://testing.googleblog.com/2010/12/test-sizes.html)
- [Pact - Consumer-Driven Contract Testing](https://docs.pact.io/)
- [Test Pyramid 2.0 (AI-Assisted)](https://www.frontiersin.org/journals/artificial-intelligence/articles/10.3389/frai.2025.1695965/full)

### Internal Sources
- PR #187: 100 commits on test optimization
- Retro: `8oums2-performant-unit-integration-tests.md`
- Retro: `8ouo8f-performant-unit-tests-cache-management.md`

---

## Attribution

See `sources.md` for detailed contribution breakdown.
