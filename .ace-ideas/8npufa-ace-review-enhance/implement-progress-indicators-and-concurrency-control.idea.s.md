---

title: Enhance ace-review Performance and UX with Progress Indicators and Concurrency Control
filename_suggestion: feat-review-performance-ux
enhanced_at: 2025-12-26 20:17:35
location: active
llm_model: gflash
source: "taskflow:v.0.9.0"
---


# Enhance ace-review Performance and UX with Progress Indicators and Concurrency Control

## Problem
Long-running operations in `ace-review`, particularly the LLM Execution phase (90%+ of total time), currently lack granular progress feedback. This leads to a poor user experience, perceived failures, and the risk of duplicate review runs, wasting valuable LLM tokens and time. The current lack of concurrency control means multiple `ace-review` instances can run simultaneously on the same project, leading to resource contention and confusion.

## Solution
Implement three key enhancements to improve UX and efficiency:
1. **Progress Feedback:** Introduce elapsed time indicators during LLM querying to assure the user/agent that the process is active.
2. **Concurrency Control:** Implement a standardized lock file pattern to prevent simultaneous reviews on the same artifact.
3. **Optimization Presets:** Provide flags to skip the sequential Synthesis phase or use predefined model shortcuts for faster feedback.

## Implementation Approach

### 1. Progress Feedback (P1)
Modify `ace-review/lib/ace/review/molecules/llm_executor.rb` and `multi_model_executor.rb` to periodically output elapsed time (e.g., every 15-30 seconds) during the LLM call wait time. This output must be directed to `stderr` or use specific formatting to ensure it does not interfere with the deterministic, parseable output required by autonomous agents.

### 2. Concurrency Control (P1)
Introduce a new Molecule, perhaps `Ace::Review::Molecules::ReviewLockManager`, to manage a lock file at `.cache/ace-review/review.lock`. This manager will check for an existing lock before execution (in `Ace::Review::Organisms::ReviewManager`), warn the user if a review is running (including PID and elapsed time), and implement auto-cleanup for stale locks (e.g., older than 10 minutes).

### 3. Optimization Flags (P2)
Enhance `ace-review/lib/ace/review/cli.rb` to accept:
*   `--no-synthesis`: Skips the final, sequential LLM call for report aggregation, returning raw model outputs immediately.
*   `--fast` / `--thorough`: Presets that configure model selection (e.g., `--fast` uses only `gemini-2.5-flash` or `haiku` and disables synthesis; `--thorough` uses multiple models and enables synthesis).

## Considerations
- **CLI Determinism:** Ensure progress indicators are clearly separated from the final, structured output required by agents.
- **Cache Location:** The lock file must adhere to the standard `.cache/{gem}/` pattern defined in the ACE development guide.
- **Integration:** The optimization flags must correctly interface with the existing `ace-llm` integration layer for model selection.

## Benefits
- Significantly improves the human developer experience during long waits.
- Reduces wasted LLM tokens by preventing accidental duplicate review runs.
- Provides agents with deterministic control over review speed and resource usage via new CLI flags.
- Establishes a standard lock file pattern for other long-running ACE tools.

---

## Original Idea

```
Improve ace-review performance and UX during long-running reviews

## Problem Statement
Reviews taking 5+ minutes with minimal feedback make users think the process failed,
leading to duplicate review runs that waste tokens and time.

## Time Analysis (Multi-Model Review)

### Phase Breakdown
1. **Preparation (5-30s, ~5%)** - Diff, context loading, prompt building
2. **LLM Execution (2-8 min, 75-85%)** - Model queries (concurrent via threads)
3. **Synthesis (1-3 min, 15-25%)** - Another LLM call (sequential)
4. **Output (1-5s, <1%)** - File writes

### Key Findings
- LLM calls dominate (90%+ of total time)
- Model queries already run in parallel via MultiModelExecutor (Thread-based)
- Synthesis is ALWAYS sequential (waits for all models to complete)
- Default timeout: 300s (5 min) per model
- No progress indicator during LLM call beyond initial "⏳ model: querying..."

## Improvement Ideas

### 1. Progress Feedback (Low Effort, High Impact)
- Add elapsed time indicator during LLM calls
- Print dots or elapsed seconds every 10-30 seconds
- Example: "⏳ model: querying... (45s)" or "⏳ model: ......."

### 2. Lock File Pattern (Medium Effort)
- Create `.cache/ace-review/review.lock` with PID and start time
- Check for existing lock before starting new review
- Warn: "Review already running (PID 12345, 2m 30s elapsed). Use --force to override"
- Auto-cleanup stale locks (older than timeout + buffer)

### 3. Status Command (Medium Effort)
- `ace-review --status` - Show running/completed reviews
- List: PID, start time, elapsed, session directory
- Could use lock file or ps/pgrep

### 4. Result Caching (Medium-High Effort)
- Cache reviews by diff hash
- Skip re-review if same diff reviewed within N minutes
- `ace-review --no-cache` to force fresh review

### 5. Faster Synthesis Options
- Use faster model for synthesis (gemini-2.5-flash already default)
- Make synthesis optional: `--no-synthesis`
- Parallel synthesis with first model result (speculative)

### 6. Model Selection Shortcuts
- `ace-review --fast` → haiku or flash only
- `ace-review --thorough` → multiple models + synthesis
- Quick feedback vs comprehensive review tradeoffs

## Implementation Priority

| Solution | Effort | Impact | Priority |
|----------|--------|--------|----------|
| Elapsed time indicator | Low | High | P1 |
| Lock file | Medium | High | P1 |
| --no-synthesis flag | Low | Medium | P2 |
| Status command | Medium | Medium | P2 |
| --fast/--thorough presets | Low | Medium | P2 |
| Result caching | High | Medium | P3 |

## Code Locations
- `ace-review/lib/ace/review/molecules/multi_model_executor.rb` - Parallel execution
- `ace-review/lib/ace/review/molecules/llm_executor.rb` - LLM query wrapper
- `ace-review/lib/ace/review/molecules/report_synthesizer.rb` - Synthesis after models
- `ace-review/lib/ace/review/organisms/review_manager.rb` - Main orchestrator
```