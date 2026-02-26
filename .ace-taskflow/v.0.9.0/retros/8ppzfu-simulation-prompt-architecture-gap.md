# Reflection: Simulation Prompt Architecture Gap

**Date**: 2026-02-26
**Context**: Failed implementation of project context loading via ace-bundle for next-phase simulation
**Author**: Claude
**Type**: Self-Review

## What Went Well

- Test-first approach caught syntax errors early
- `.prompts/` folder for introspection was a good idea for debugging

## What Could Be Improved

- **System prompt missing project context** - Only workflow file included, no docs/vision.md etc.
- **Assumed ace-bundle behavior** - Did not verify that `presets: - project` inside a section actually works
- **Integration not tested** - Mock returned expected values, not real ace-bundle output

## Key Learnings

- **Verify external system behavior BEFORE implementing** - Run the CLI and inspect actual output
- **Mocks hide integration bugs** - Test with real ace-bundle data, not mocks
- **Inspect generated artifacts** - The `.prompts/` folder exists for debugging, USE IT

## Challenge Patterns Identified

### High Impact Issues

- **Unverified Assumption**: Assumed ace-bundle section preset composition works
  - Occurrences: 1 (entire implementation)
  - Impact: Released v0.45.0 with broken feature - no project context in prompts
  - Root Cause: Did not run `ace-bundle simulation-draft` to verify output before coding

- **Mock-based Testing**: Tests passed but code was broken
  - Occurrences: All executor tests
  - Impact: False confidence, released broken code
  - Root Cause: Mock returned expected structure, not actual ace-bundle data

## Action Items

### Stop Doing

- Assuming external system behavior without running the actual tool
- Using mocks that return expected values instead of real data
- Committing without end-to-end verification of generated artifacts

### Continue Doing

- Writing tests (but make them integration tests for external systems)
- Creating introspection folders like `.prompts/` for debugging

### Start Doing

- **Verify first**: Run ace-bundle CLI and inspect output BEFORE writing consumer code
- **Integration tests**: Use real ace-bundle data in tests, not mocks
- **Check artifacts**: `cat .cache/.../prompts/*.md` after running simulation

## Technical Details

### The Bug

Preset configuration:
```yaml
sections:
  system:
    presets:
      - project  # ASSUMED this would merge project docs - DIDN'T VERIFY
    files:
      - ace-taskflow/handbook/.../workflow.wf.md  # Only this appears
```

Result: System prompt only has workflow file, missing project context (docs/vision.md, docs/architecture.md, etc.)

### Verification (for the fix)

```bash
# 1. Run simulation
ace-taskflow review-next-phase --source 8pp0s1 --modes draft --dry-run

# 2. Check system prompt has project context
cat .cache/ace-taskflow/simulations/<id>/.prompts/draft-system.md

# 3. VERIFY: Must contain project context
grep "ACE Vision" .cache/ace-taskflow/simulations/<id>/.prompts/draft-system.md
```

## Additional Context

- Commits: `e61e4abe9`, `28378d596`, `afae6ee6b`
- Released: v0.45.0 (needs fix)
- Related: Task-285 next-phase simulation improvements
