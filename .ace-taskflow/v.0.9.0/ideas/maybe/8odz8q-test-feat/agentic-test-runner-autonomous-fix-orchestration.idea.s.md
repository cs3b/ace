---
title: Agentic Test Runner with Autonomous Fix Orchestration
filename_suggestion: feat-test-agent-fix-runner
enhanced_at: 2026-01-14 23:29:41
location: active
llm_model: gflash
---

# Agentic Test Runner with Autonomous Fix Orchestration

## Problem
While `ace-test` provides deterministic execution and reporting, current test failures often result in unstructured output (stack traces, raw messages). For an AI agent to autonomously fix failing tests, it requires a structured, action-oriented summary of the failure, combined with the relevant source code context. The agent needs a dedicated workflow to analyze the failure, generate a fix, apply it, and verify the result.

## Solution
Introduce an enhanced capability within the `ace-test` gem, potentially exposed via a new command like `ace-test fix` or an agent workflow `/ace:test-fix`. This capability will orchestrate the entire self-healing loop:

1. **Execute Tests:** Run the test suite using `ace-test`.
2. **Capture Failures:** Parse the output into structured failure objects (file, line, error message).
3. **Load Context:** Use `ace-context` to gather the failing test file, the relevant source file, and surrounding architectural context.
4. **LLM Analysis:** Send the structured failure data and context to an LLM (via `ace-llm`) with a specialized prompt (managed by `ace-prompt`) to generate a patch or suggested code changes.
5. **Apply and Verify:** Apply the suggested fix and immediately re-run the affected tests for verification. If successful, the agent can proceed to commit the fix using `ace-git-commit`.

## Implementation Approach
This feature will primarily reside in `ace-test` and `ace-test-support`.

*   **Organism:** A `TestFixOrchestrator` will manage the multi-step process (run, parse, prompt, apply, verify).
*   **Molecules:** A `TestFailureParser` molecule will convert raw test output into structured data models. A `ContextGatherer` molecule will leverage `ace-context` for efficient context loading.
*   **Atoms:** Pure functions for patch application and file manipulation.
*   **Configuration:** Configuration for the LLM model, temperature, and maximum retry attempts will be managed via the standard configuration cascade in `.ace/test/fix.yml`.

## Considerations
- **Safety and Reversibility:** The fix application should ideally happen within an `ace-git-worktree` or ensure changes are staged and easily reverted if the fix fails verification.
- **Prompt Engineering:** The LLM prompt must be highly specific, demanding a unified diff or structured JSON output for the fix, ensuring deterministic parsing by the orchestrator.
- **Integration:** Must integrate seamlessly with `ace-llm` for model selection and `ace-git-commit` for finalizing the successful fix.
- **Output:** The CLI output must be optimized for AX, clearly reporting the status of the fix attempt (e.g., `SUCCESS: Test 123 fixed in file X.rb`).

## Benefits
- Enables true self-healing and autonomous bug fixing workflows within the ACE environment.
- Provides highly structured, actionable data from test failures, optimizing the Agent Experience (AX).
- Reduces the manual loop of running tests, analyzing failures, and applying fixes for both human developers and agents.
- Showcases the power of combining deterministic CLI tools (`ace-test`, `ace-context`) with LLM reasoning (`ace-llm`) for complex, multi-step agentic tasks.

---

## Original Idea

```
test runner - agent that run tests, summarize resutls in the action based way -> what we can do about it if any tests are failing; similar text fixer, if we need to fix anything it should get the isues, context, and work on their won to fix it
```