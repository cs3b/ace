---
id: v.0.9.0+task.244
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Optimize E2E Test Suite Orchestrator Performance

## Behavioral Specification

### User Experience

**Input:**
- User invokes `/ace:run-e2e-tests <package>` to execute E2E test suite
- Optionally: `--all` flag (run all packages), `--sequential` flag (disable parallel)
- New optional flags: `--stream-progress`, `--minimal-reports`

**Process:**
- Orchestrator discovers tests, launches them in parallel
- Tests run concurrently (subagents in Task tool)
- **Current pain point**: Users wait 2x longer than necessary due to orchestrator overhead
- **Desired experience**: Results appear as tests complete, not after all finish

**Output:**
- Progressive results table (when --stream-progress)
- Final summary with test results, durations
- Path to final report
- Individual test report paths

### Expected Behavior

**Current Pain Point:**
For ace-git-commit (4 tests):
- Parallel test execution: ~3 minutes (good - as expected)
- Orchestrator overhead: ~3 minutes (50% of total time)
- Total time: 5m 51s

Orchestrator's 3-minute overhead includes:
- Suite ID generation: <5s
- Test discovery (glob): <5s
- Reading frontmatter: <10s
- **Reading experience reports**: <10s (but verbose - 519 lines)
- **Generating/writing final report**: <10s
- **Task tool overhead**: ~2-3 minutes (subagent startup/teardown, context switching)

**Desired Behavior:**
The orchestrator should be lightweight and efficient. For a 3-minute parallel test run, total time should approach 3.5-4 minutes, not 6 minutes.

**Key Behaviors:**
1. **Fast startup**: Minimize time between invocation and test execution
2. **Efficient waiting**: Don't block on details that can be gathered asynchronously
3. **Stream results**: Provide feedback as tests complete rather than waiting for all
4. **Optional verbosity**: Experience reports are detailed - make them opt-out or summary-only by default

### Interface Contract

```bash
# CLI Interface
/ace:run-e2e-tests <package> [--all] [--sequential] [--stream-progress] [--minimal-reports]

Options:
  --stream-progress    Show results as each test completes
                       (Better user experience, no waiting for all)
  --minimal-reports    Skip experience reports, only generate summaries
                       (Reduces orchestrator post-processing time)
```

**User Output Example (with --stream-progress):**
```markdown
## E2E Test Suite Running...

Suite ID: 8oszup | Tests: 4 | Mode: parallel

✓ MT-COMMIT-001 passed (4/4) - 60s
✓ MT-COMMIT-002 passed (4/4) - 33s
✓ MT-COMMIT-003 passed (4/4) - 142s
✓ MT-COMMIT-004 passed (8/8) - 120s

## Complete
Overall: 20/20 passed (100%)
Total time: 3m 45s
Reports: .cache/ace-test-e2e/8oszyq-final-report.md
```

**Error Handling:**
- No tests found: Display helpful message with suggestion to create tests
- Subagent failure: Record failure, continue collecting, mark as "incomplete"
- Partial results: Highlight failures, still write all reports

**Edge Cases:**
- Single test suite: Minimal overhead optimization still applies
- Large test suites (>10 tests): Streaming benefits increase with scale
- Mixed pass/fail: Continue execution, aggregate properly

### Success Criteria

- [ ] **Overhead Reduction**: Orchestrator overhead reduced to <20% of total time (from current 50%)
- [ ] **Faster Feedback**: Users see test results as they complete via --stream-progress flag
- [ ] **Optional Verbosity**: Experience reports can be skipped via --minimal-reports flag
- [ ] **Scalability**: Performance doesn't degrade linearly with test count

### Validation Questions

- [ ] **Priority**: Which optimizations should be implemented first? (streaming vs. minimal reports vs. Task optimization)
- [ ] **Backward Compatibility**: Should experience reports be opt-out (--minimal-reports to disable) or opt-in?
- [ ] **Task Tool**: Is the 2-3 minute Task tool overhead something we can influence, or is it systemic?
- [ ] **Measurement**: How do we measure orchestrator time separately from test time?

## Objective

Reduce E2E test suite execution time by optimizing the orchestrator's overhead, providing faster feedback to users without sacrificing test coverage or report quality.

## Scope of Work

**User Experience Scope:**
- Faster test suite execution
- Real-time progress feedback as tests complete
- Configurable report verbosity

**System Behavior Scope:**
- Optimized report aggregation (defer non-essential reading)
- Streaming result display
- Optional experience report generation

**Interface Scope:**
- CLI flags: --stream-progress, --minimal-reports
- Output format: Progressive table + final summary
- Report structure: Same files, conditional generation

### Deliverables

#### Behavioral Specifications
- Performance optimization requirements for orchestrator
- Streaming progress interface
- Minimal reports mode specification

#### Performance Metrics
- Baseline: Current orchestrator overhead (~3 min for 4 tests)
- Target: <20% overhead ratio

## Out of Scope

- ❌ **Test Parallelization**: Already working (tests run in parallel via Task tool)
- ❌ **Individual Test Performance**: Test execution time is reasonable (~3 min for 4 tests)
- ❌ **Report Content Quality**: Preserving detailed reports, just optimizing generation
- ❌ **Task Tool Overhead**: Subagent startup/teardown may be systemic limitation

## References

- Current execution data: 5m 51s total, ~3 min parallel tests, ~3 min overhead
- Workflow: `ace-test-e2e-runner/handbook/workflow-instructions/run-e2e-tests.wf.md`
- Related: Task 221 (E2E report persistence and experience reports)
- Plan document: Provided in task context
