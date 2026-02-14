# Test Strategy Research Report

**Date**: 2026-01-31
**Task**: 253 - Test Performance Strategy
**Researcher**: Claude Opus 4.5
**Version**: 1.1 (Enhanced with cross-report synthesis)

---

## Executive Summary

Analysis of PR #187 (100 commits) and industry best practices to establish comprehensive test strategy covering fast loop (unit/integration) and slow loop (E2E) testing.

### Core Principles

1. **The 100ms Rule**: Any unit/integration test >100ms is a **bug**, not just "slow"
2. **Stub the Boundary**: Always stub the outermost method that triggers I/O
3. **Test Responsibility Mapping**: Each behavior belongs to exactly one test layer
4. **Separate Roles**: Test Planner (WHAT/WHERE) vs Test Writer (HOW)

---

## Part 1: Analysis of PR #187 Work (Tasks 251 & 252)

### Performance Gains Achieved

| Package | Optimization | Before | After | Reduction |
|---------|--------------|--------|-------|-----------|
| ace-support-timestamp | CLI tests → E2E | 13.93s | 61ms | 99.6% |
| ace-lint | 8 test files → E2E + stubbing | 2.1s | 69ms | 97% |
| ace-git-secrets | Subprocess stubbing | 4.47s | 1.78s | 60% |
| ace-bundle | Section workflow isolation | - | - | Focused |
| ace-review | Integration → mocked | 19.52s | 13.5s | 31% |

Created **11 E2E test files** with 74 test cases in `.mt.md` format.

### Key Patterns Discovered

#### 1. Subprocess Calls Are the Silent Killer

Tests that look fast on the surface can be slow if they don't stub the **entire call chain**:

```ruby
# INCOMPLETE (still slow):
Open3.stub(:capture3, result) { runner.run(file) }

# COMPLETE (fast):
Runner.stub(:available?, true) do
  Open3.stub(:capture3, result) { runner.run(file) }
end
```

**Why**: The `run()` method calls `available?` BEFORE reaching `capture3`, and `available?` calls `system()` which spawns a subprocess (~0.5-1s).

#### 2. Cache Architecture Complexity

The ace-lint system had **two separate availability caches**:
1. `ValidatorRegistry.@availability_cache` - keyed by validator symbol (`:standardrb`)
2. `BaseRunner.@availability_cache` - keyed by command name (`"standardrb"`)

**Problem**: Random test slowness (different tests slow each run) indicates cache invalidation + test ordering issues.

**Solution**:
- Pre-warm ALL caches at test startup
- Reset caches locally inside stub helpers, then pre-populate
- Don't reset caches in global setup

```ruby
# test_helper.rb - pre-warm ALL availability caches at startup
Ace::Lint::Atoms::ValidatorRegistry.available?(:standardrb)
Ace::Lint::Atoms::ValidatorRegistry.available?(:rubocop)
Ace::Lint::Atoms::StandardrbRunner.available?
Ace::Lint::Atoms::RuboCopRunner.available?
```

#### 3. The 100ms Rule: Slow Tests Are Bugs

**Any unit/integration test taking >100ms is a BUG, not just "slow".**

| Threshold | Classification | Action |
|-----------|---------------|--------|
| <10ms | Healthy unit test | None |
| 10-100ms | Warning | Review for optimization |
| >100ms | **Bug** | Must fix before merge |
| >200ms | **Critical bug** | Block PR |

**Why it's a bug**: A slow test indicates hidden I/O that should be stubbed. The test is not properly isolated.

**Remediation**:
1. Profile to find the leak: `ace-test --profile 10`
2. Identify the I/O call (subprocess, network, filesystem)
3. Stub the boundary (outermost method)
4. Move real I/O testing to E2E layer

#### 4. Zombie Mocks

"Zombie Mocks" occur when mocks stub methods that are no longer called by the implementation, but tests continue to pass because the real code path happens to work (slowly).

**Symptoms**:
- Tests pass but are unexpectedly slow (>100ms = zombie indicator)
- Mock setup doesn't match actual code implementation
- Refactored code still uses old mock patterns

**Detection**: Run `ace-test --profile 10` - unit tests taking >100ms often indicate zombie mocks.

**Case Study (ace-docs ChangeDetector)**:
- Tests stubbed `ChangeDetector.stub :execute_git_command`
- Implementation had evolved to use `Ace::Git::Organisms::DiffOrchestrator.generate`
- Tests passed but ran real git operations (~1 second each)
- **Result**: Fixing zombie mocks reduced test time from 14s to 1.5s (89% improvement)

#### 4. Composite Helpers

Reduce deeply nested stubs by creating composite helpers:

```ruby
# BAD: 6-7 levels of nesting
def test_complex_operation
  mock_config_loader do
    mock_diff_generator do
      mock_diff_filter do
        mock_branch_info do
          result = SUT.call
        end
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
1. **Sensible Defaults**: Most tests need standard values
2. **Keyword Arguments**: Allow targeted overrides
3. **Clear Naming**: `with_mock_<context>` pattern
4. **Single Responsibility**: Each helper handles one "thing" completely

### E2E Test Structure

**Location**: `{package}/test/e2e/*.mt.md`

**Directory Structure**:
```
.cache/ace-test-e2e/
├── {timestamp}-{short-pkg}-{short-id}/     # Sandbox folder
│   └── (test artifacts)
└── {timestamp}-{short-pkg}-{short-id}-reports/
    ├── summary.r.md
    ├── experience.r.md
    └── metadata.yml
```

**Format**: Markdown with YAML frontmatter, explicit PASS/FAIL assertions

---

## Part 2: Industry Best Practices (Web Research)

### Testing Pyramid (2025-2026 Standards)

| Layer | % of Tests | Feedback Speed | What It Tests |
|-------|------------|----------------|---------------|
| Unit | 70% | <10ms | Pure logic, single responsibility |
| Integration | 20% | <500ms | Component interactions with controlled I/O |
| E2E | 10% | Seconds-minutes | Critical user journeys, real external calls |

**Key Insight**: "If E2E tests dominate your CI pipeline, your feedback loop will suffer."

**Sources**:
- [Testing Pyramid Guide 2025](https://www.devzery.com/post/software-testing-pyramid-guide-2025)
- [BrowserStack Test Automation Pyramid](https://www.browserstack.com/guide/testing-pyramid-for-test-automation)
- [Qodo Testing Pyramid](https://www.qodo.ai/blog/implementing-testing-pyramid-development-workflows/)

### Behavior vs Implementation Testing

**Anti-pattern**: Testing that specific methods were called (implementation detail)

```ruby
# BAD: Tests implementation
mock.expect(:process, true, [data])
subject.call(data)
mock.verify  # "Was process() called?"

# GOOD: Tests behavior
result = subject.call(data)
assert_equal expected_output, result.output  # "Is output correct?"
```

**Key Quote**: "One of the biggest problems with testing is writing tests too tightly coupled to implementation. One of the biggest points of testing is to reduce the cost of future change; if changing implementation details breaks your tests, you've increased that cost."

**Sources**:
- [Martin Fowler - Mocks Aren't Stubs](https://martinfowler.com/articles/mocksArentStubs.html)
- [BairesDevStub vs Mock](https://www.bairesdev.com/blog/stub-vs-mock/)

### Contract Testing

**Problem**: Mocks with hardcoded data that doesn't match reality
- Mock returns `{status: "ok"}` but real API returns `{status: "success"}`
- Test passes but production fails

**Solution**: Contract testing ensures mocks match real API responses

**Approaches**:
1. **Snapshots from real APIs**: Make actual call, save response, use as mock
2. **OpenAPI validation**: Mock and real API both validated against spec
3. **Drift detection**: Periodic checks that mocks match reality

**Quote**: "Your mocks are only as good as their fidelity to the behavior of the real API."

**Sources**:
- [CircleCI - Contract Testing](https://circleci.com/blog/how-to-test-software-part-i-mocking-stubbing-and-contract-testing/)
- [WireMock Contract Testing](https://www.wiremock.io/post/new-module-in-wiremock-cloud-contract-testing-for-mock-apis)

### Test Suite Health Metrics

| Metric | Target | What It Measures |
|--------|--------|------------------|
| Test execution time | Unit <10ms, Integration <500ms | Feedback loop speed |
| Flake rate | <1% | Test reliability |
| Escaped defects | Trending down | Testing effectiveness |
| Defect Removal Efficiency | >85% | `bugs_caught / (bugs_caught + bugs_in_prod)` |
| Mean Time to Detect | Hours, not days | Pipeline health |

**Source**: [Qodo Testing Metrics](https://www.qodo.ai/blog/software-testing-metrics/)

### Test Pyramid 2.0 (AI-Assisted)

Recent research extends the traditional model:
- Embedding security testing directly into each layer
- Automated testing with fast feedback loops
- AI-assisted test generation and validation

**Quote**: "For practitioners, test coverage alone is not sufficient; automated testing and fast feedback loops are essential to support rapid iteration without compromising reliability or safety."

**Source**: [Frontiers - Test Pyramid 2.0](https://www.frontiersin.org/journals/artificial-intelligence/articles/10.3389/frai.2025.1695965/full)

---

## Part 3: Layer Decision Framework

### What to Test at Each Layer

#### Unit Tests (atoms/molecules)
- Pure function logic
- Edge cases and error handling
- Data transformations
- Configuration parsing
- **NO**: Filesystem, subprocess, network, git

#### Integration Tests (organisms)
- Component orchestration
- Data flow between modules
- Error propagation
- ONE CLI parity test per file (rest mocked)
- **STUB**: External dependencies, subprocess calls

#### E2E Tests
- Critical user workflows end-to-end
- Tool availability and installation validation
- Real API interactions (sandboxed)
- Complex environment setups
- **REAL**: Filesystem, git, CLI, external tools

### Decision Matrix

| Question | Unit | Integration | E2E |
|----------|------|-------------|-----|
| Does it need real filesystem? | No (mock) | Sometimes | Yes |
| Does it need real git? | No (MockGitRepo) | Rarely | Yes |
| Does it need real subprocess? | Never | Stub or avoid | Yes |
| Does it call external APIs? | No (WebMock) | No (WebMock) | Yes (safe) |
| Does it test CLI parity? | No | Rarely (1 per file) | Yes |
| Does it test error codes? | Through API | Through API | Through CLI |

### Performance Cost Reference

| Operation | Typical Cost | Mitigation |
|-----------|--------------|------------|
| Real `git init` | ~150-200ms | Use MockGitRepo |
| Real `git commit` | ~50-100ms | Stub in unit tests |
| Subprocess spawn | ~150ms | Stub or use API |
| Sleep in retry tests | 1-2s per sleep | Stub `Kernel.sleep` |
| ace-nav subprocess | ~150-400ms | Use `stub_synthesizer_prompt_path` |
| Real LLM API call | 1-20s | WebMock |
| Real GitHub API call | 100-500ms | WebMock |

### Test Responsibility Map

A **Test Responsibility Map** assigns each behavior to the lowest test layer that can prove it. This prevents:
- Duplicate testing of same behavior across layers
- E2E tests for edge cases (should be unit tests)
- Missing coverage for critical workflows

**Template**:

| Behavior | Risk | Layer | Test File | Source of Truth | Notes |
|----------|------|-------|-----------|-----------------|-------|
| Config parsing | Medium | Unit (atoms) | config_parser_test.rb | YAML schema | No I/O |
| CLI exit codes | High | E2E | MT-TOOL-001 | CLI spec | Real subprocess |
| Retry backoff | Low | Unit (atoms) | backoff_test.rb | Spec | Stub sleep |

**Mapping Rules**:
1. Start at the lowest layer that can validate the behavior
2. Promote to higher layers only when lower layer cannot prove it
3. Keep ONE E2E test per critical workflow, not per flag/edge case
4. Record the source of truth for inputs/outputs

### Risk-Based Coverage

Assign risk levels to prioritize testing effort:

| Risk Level | Coverage Required | Layer Preference |
|------------|-------------------|------------------|
| **High** | Must have E2E + unit | E2E for workflow, unit for edge cases |
| **Medium** | Unit required, E2E optional | Unit with good stubs |
| **Low** | Unit if time permits | Basic happy path |

**High-risk behaviors**: Security, data integrity, core business logic, user-facing errors
**Low-risk behaviors**: Logging, cosmetic output, internal helpers

---

## Part 3.5: Test Planning Roles

### The Test Planner (WHAT + WHERE)

Before writing tests, the Planner decides:

1. **Identify behaviors** to test from requirements
2. **Assign risk levels** (high/medium/low)
3. **Map to test layers** using decision matrix
4. **Identify E2E candidates** (one per critical workflow)
5. **List fixtures/contracts** needed

**Planner output**: Test Responsibility Map document

### The Test Writer (HOW)

After planning, the Writer implements:

1. **Write tests efficiently** following patterns
2. **Use profiling** to verify speed (`ace-test --profile`)
3. **Apply stubbing patterns** ("stub the boundary")
4. **Write meaningful assertions** (behavior, not implementation)

**Writer output**: Test files that pass and run fast

### Why Separate Roles?

- **Planner thinks strategically**: Coverage gaps, redundancy, risk
- **Writer thinks tactically**: Implementation, performance, assertions
- **AI agents**: Can be assigned either role explicitly

---

## Part 4: Avoiding Useless Tests

### Test Quality Checklist

- [ ] Test verifies **behavior** (output), not **implementation** (method calls)
- [ ] Mock data comes from real API snapshots or validated schemas
- [ ] Negative test cases exist (errors, edge cases)
- [ ] Test fails when production code is broken (try breaking it)
- [ ] No zombie mocks (stub targets match actual code paths)

### E2E Test Anti-Patterns

1. **Testing Only Happy Path**: Include error/negative test cases
2. **Hardcoding File Structures**: Discover paths from CLI output
3. **Verification Commands That Silently Adapt**: Use explicit PASS/FAIL logic
4. **Missing Error Path Coverage**: Test wrong arguments, missing files, exit codes

### Reviewer Checklist for E2E Tests

- [ ] At least one error/negative TC is present
- [ ] File paths are discovered at runtime, not hardcoded
- [ ] Every verification step produces explicit PASS/FAIL output
- [ ] TCs follow a real user workflow sequence
- [ ] Exit codes are checked for error commands
- [ ] Negative assertions exist (files that should NOT exist)

---

## Part 5: Recommendations

### Proposed Skills/Workflows

| Skill/Workflow | Purpose |
|----------------|---------|
| `/ace:plan-tests` | Plan tests at each layer BEFORE writing code (Test Planner role) |
| `/ace:verify-test-suite` | Audit suite health (slow tests, zombie mocks, layer issues) |
| `/ace:optimize-tests` | Semi-automated performance optimization |
| `/ace:test-review` | Review test PR for layer fit, mocks, performance |
| `e2e-sandbox-setup.wf.md` | Safe E2E setup with external APIs |

### Proposed Guides

| Guide | Content |
|-------|---------|
| `test-layer-decision.g.md` | Decision matrix for unit vs integration vs E2E |
| `test-mocking-patterns.g.md` | Behavior testing, contract testing, zombie mock prevention |
| `test-suite-health.g.md` | Metrics, periodic audits, CI integration |
| `test-responsibility-map.g.md` | Behavior→layer mapping, risk-based coverage |
| `test-review-checklist.g.md` | PR review checklist for tests |
| `SUMMARY.md` | Navigation index for all testing guides |

### Proposed Templates

| Template | Purpose |
|----------|---------|
| `test-responsibility-map.template.md` | Behavior→layer mapping document |
| `test-performance-audit.template.md` | Monthly audit report structure |
| `test-review-checklist.template.md` | PR review checklist |
| `e2e-sandbox-checklist.template.md` | Safe E2E environment setup |

### Proposed Automation

**1. CI Performance Gates**
```yaml
- name: Check test performance
  run: |
    ace-test --profile 20 | tee profile.txt
    if grep -E "test_" profile.txt | awk '{print $NF}' | grep -E "0\.[1-9][0-9][0-9]s"; then
      echo "::error::Unit tests exceeding 100ms threshold"
      exit 1
    fi
```

**2. Pre-commit Hook**
```bash
changed_packages=$(git diff --cached --name-only | grep "^ace-" | cut -d/ -f1 | sort -u)
for pkg in $changed_packages; do
  ace-test "$pkg" --profile 5 --fail-slow 100
done
```

**3. Periodic Audit Schedule**
- Weekly: Profile changed packages
- Monthly: Full suite audit
- Quarterly: E2E test health review, mock drift check

---

## References

### Industry Sources
- [Martin Fowler - Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html)
- [Martin Fowler - Mocks Aren't Stubs](https://martinfowler.com/articles/mocksArentStubs.html)
- [Google Testing Blog - Test Sizes](https://testing.googleblog.com/2010/12/test-sizes.html)
- [Testing Pyramid Guide 2025](https://www.devzery.com/post/software-testing-pyramid-guide-2025)
- [BrowserStack Test Automation Pyramid](https://www.browserstack.com/guide/testing-pyramid-for-test-automation)
- [CircleCI - Contract Testing](https://circleci.com/blog/how-to-test-software-part-i-mocking-stubbing-and-contract-testing/)
- [Pact - Consumer-Driven Contract Testing](https://docs.pact.io/)
- [Qodo - Testing Metrics](https://www.qodo.ai/blog/software-testing-metrics/)
- [Test Pyramid 2.0 (AI-Assisted)](https://www.frontiersin.org/journals/artificial-intelligence/articles/10.3389/frai.2025.1695965/full)
- [WireMock Contract Testing](https://www.wiremock.io/post/new-module-in-wiremock-cloud-contract-testing-for-mock-apis)
- [Wikipedia - Risk-Based Testing](https://en.wikipedia.org/wiki/Risk-based_testing)

### Internal Sources
- PR #187: 100 commits on test optimization
- Retro: `8oums2-performant-unit-integration-tests.md`
- Retro: `8ouo8f-performant-unit-tests-cache-management.md`
- Guide: `ace-test/handbook/guides/test-performance.g.md`
- Guide: `ace-test-e2e-runner/handbook/guides/e2e-testing.g.md`

### Cross-Report Sources
- Report 8oup93 (Gemini): Fast/Slow Loop strategy, Planner/Writer roles
- Report 8oupdg (Codex): Test Responsibility Map, risk-based coverage
