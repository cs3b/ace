# Retro: Task 285 Postmortem — Kill the Implementation

**Date**: 2026-02-27
**Context**: Task 285 (iterative review with next-phase dry runs) spent ~7 hours across 6+ sessions molding AI-generated code. The implementation still doesn't deliver core value. Output is overcomplicated, hardcoded, and fragile. This is the 7th retro — previous 6 documented incremental gaps but didn't address the systemic failure.
**Author**: Codex
**Type**: Postmortem

## What Went Well

- Nothing. That's the point of this retro.
- The retro process itself worked — each session produced a retro. But 6 incremental retros failed to trigger the kill decision that should have come after session 2.

## What Could Be Improved

Everything. This section is replaced by Root Causes below.

## Root Causes

### 1. Spec lacked a concrete usage example

No happy-path command + expected output. Architecture docs ≠ UX intent. The spec described _what to build_ in abstract terms but never showed _what a user runs and what they see_.

### 2. Implementation ignored ace ecosystem

- Hardcoded YAML bundle configs in Ruby string heredocs instead of using ace-bundle presets/files.
- Hardcoded `max_tokens: 3000` instead of using provider defaults from config.
- Built a custom adapter file instead of composing existing workflows.
- The implementation reinvented infrastructure that already existed.

### 3. AI slop accumulated

Each session generated plausible-looking code that passed mocked tests but failed real execution. 6 retros documenting incremental gaps instead of one retro recognizing systemic failure. The code looked right, read right, and did nothing right.

### 4. Mocks hid integration failures

Every test passed because mocks returned expected structures. Real ace-bundle output, real LLM calls, real token limits — none were tested until the very end. The test suite was a green wall of lies.

### 5. String/symbol key mismatch in ace-llm

Provider config `default_options` uses YAML string keys. Client code performs symbol key lookups. The `max_tokens: 8192` in google.yml was dead code all along — silently ignored, never applied.

## Pattern: Death by Incremental Fixes

- **Session 1**: Scaffold delivered, marked done. No runnable behavior.
- **Session 2**: Retro says "add workflows". Added workflow files.
- **Session 3**: Retro says "prompt missing project context". Added ace-bundle.
- **Session 4**: Retro says "adapter buried at line 1831". Moved to preamble.
- **Session 5**: Retro says "max_tokens too low". Bumped 3000 → 6000 → 8000 → 16000 → 32000.
- **Session 6**: Discovered provider config is dead code. Model still truncates.
- **7 hours. 6 retros. Still doesn't work.**

Each session fixed the symptom identified by the previous retro without questioning whether the foundation was sound. The sunk cost fallacy kept the implementation alive 5 sessions too long.

## What Should Have Happened

1. **Spec includes a runnable example**: "Run `ace-taskflow review-next-phase --source X --modes draft --dry-run` → produces complete draft + review artifact in `.cache/...`"
2. **Implementation uses `ace-bundle` preset file** — not Ruby string heredoc with inline YAML.
3. **`max_tokens` comes from config** — not a hardcoded constant that gets manually bumped across sessions.
4. **First integration test runs real `ace-bundle`** (not mock) to verify prompt structure.
5. **Kill and restart after session 2, not session 7.**

## Key Learnings

- **Kill decisions are cheaper than fix decisions.** A clean rewrite with a concrete usage example would have taken 1-2 hours. Instead, 7 hours of incremental fixes produced nothing usable.
- **Mocked tests that always pass are worse than no tests.** They provide false confidence and delay the discovery of real failures.
- **"Plausible-looking code" is the most dangerous AI output.** It passes review, passes mocked tests, and fails silently in production.
- **Retros that only identify the next incremental fix are not retros.** A real retro asks: "Should we keep going at all?"
- **Hardcoded values are a smell for missing ecosystem integration.** If you're typing a literal number or a YAML string into Ruby source, you're probably ignoring existing config infrastructure.

## Action Items

### Stop Doing

- Accepting AI-generated scaffolds as "done" without a runnable integration test.
- Writing retros that only identify the next incremental gap without questioning the foundation.
- Mocking ace-bundle, ace-llm, and other ecosystem tools in tests that are supposed to verify integration.
- Hardcoding config values (max_tokens, bundle content, model names) in implementation code.

### Continue Doing

- Writing retros after every session (but make them systemic, not incremental).
- Using ace-bundle presets for context loading (when actually used, not bypassed).

### Start Doing

- Requiring a concrete happy-path usage example in every task spec before implementation begins.
- Running at least one real integration test (no mocks for ecosystem tools) before marking any session "done".
- Adding a "kill or continue?" checkpoint after every 2 failed sessions.
- Treating string/symbol key mismatches as a first-class bug category in ace-llm.

## Technical Details

### The max_tokens Saga

```
Session 1: max_tokens: 3000  (hardcoded)
Session 5: max_tokens: 6000  (bumped)
Session 5: max_tokens: 8000  (bumped again)
Session 5: max_tokens: 16000 (bumped again)
Session 5: max_tokens: 32000 (bumped again)
Session 6: Discovered google.yml default_options max_tokens: 8192 was dead code
           because YAML produces string keys, client looks up symbol keys
```

The entire max_tokens debugging arc was treating symptoms of two compounding bugs: (1) hardcoded value instead of config, and (2) config itself was broken due to key type mismatch.

### The Ecosystem Bypass

Instead of:
```ruby
# Use existing preset
content = AceBundle.load("next-phase-review")
```

The implementation did:
```ruby
# Hardcoded YAML in Ruby string
BUNDLE_CONFIG = <<~YAML
  sources:
    - type: file
      path: ...
    - type: command
      command: ace-bundle ...
YAML
```

This pattern repeated across prompt construction, model selection, and output formatting.

## Additional Context

- Previous retros: `8pppak`, `8pps6l`, `8ppxcf`, `8ppzfu`, `8pq3jr` — all for task 285.
- This retro recommends killing the current implementation and starting fresh with a spec-first approach if the feature is still desired.
- The string/symbol key mismatch in ace-llm affects all providers using `default_options` in YAML config — not just this task.
