---
title: Sandbox-Root Execution for E2E Test Runner
filename_suggestion: feat-test-sandbox-root-exec
enhanced_at: 2026-02-19 01:44:12
location: backlog
llm_model: gflash
---

# Sandbox-Root Execution for E2E Test Runner

## Problem
Current E2E tests in `ace-test-runner-e2e` execute from the monorepo root, necessitating complex environment variable plumbing (e.g., `PROJECT_ROOT_PATH`) and fragile path handoffs. This 'context leakage' often leads to subagents running in the wrong directory, stale reports being reused, and verbose workflow instructions that increase prompt token usage and error rates.

## Solution
Shift the E2E execution model to use the sandbox root as the primary `cwd` for all agent processes. By treating the sandbox as an isolated, first-class project context (complete with its own `.git` and configuration), we align the test environment with real-world production usage. The filesystem becomes the source of truth, significantly reducing the need for mandatory environment variables and path caveats in prompts.

## Implementation Approach
- **ace-test-runner-e2e (Organisms):** Update `TestOrchestrator` and `TestExecutor` to spawn agent processes with the working directory set to the per-run sandbox path.
- **Molecules:** Enhance `SetupExecutor` to provision a local `.ace/` config and `.mise.toml` within the sandbox, ensuring toolchain resolution (via `ace-nav` and `mise`) is local and deterministic.
- **Report Management:** Implement a 'Harvesting' molecule that writes reports to a local `.ace-test-reports/` directory inside the sandbox first, then exports them to the orchestrator's global cache for suite aggregation.
- **Workflow Instructions:** Refactor `e2e-run.wf.md` to remove redundant path parameters, simplifying the instructions for the LLM.

## Considerations
- **Tool Parity:** Ensure `ace-*` binaries are accessible within the sandbox PATH without requiring full re-installs (leveraging shared `mise` or `bundle` caches).
- **Git Boundary:** Use `git init` or `git worktree` within the sandbox to prevent agents from accidentally interacting with the monorepo's git state.
- **Preflight Checks:** Add validation to ensure the agent's `cwd` is correctly set within the sandbox before executing scenario steps.

## Benefits
- **High Fidelity:** Tests mirror actual user environments, catching pathing and configuration bugs earlier.
- **Reduced Prompt Fragility:** Simpler, more robust instructions lead to higher agent success rates.
- **Improved Isolation:** Clearer boundaries between the test orchestrator and the test subject, preventing side effects on the monorepo.

---

## Original Idea

```
Run E2E execution from sandbox root instead of monorepo root.

Context:
Current E2E flow requires significant env/path plumbing (PROJECT_ROOT_PATH, sandbox path handoff, report path assumptions), and we have seen failures where subagents run in wrong context, stale reports are reused, or shell/chat command boundaries cause ambiguity.

Proposal:
- Start the LLM agent process with current working directory set to the per-run sandbox root.
- Treat sandbox as an isolated project execution context (own git repo + own project-root-path).
- Keep deterministic run-id naming, but write reports inside sandbox first, then copy/export them to orchestrator-visible cache location.
- Use a dedicated mise/env setup in sandbox so toolchain resolution behaves like production execution.
- Reduce mandatory env-vars passed through prompts/workflows by making cwd the source of truth.

Expected benefits:
- Simpler workflow instructions (fewer env handoffs and path caveats).
- Better fidelity to production-like execution context.
- Fewer context/path mismatch bugs and lower chance of stale report confusion.
- Clearer isolation boundaries for E2E and easier debugging.

Design notes / constraints:
- Keep orchestration/discovery in repo root, but execute scenario/test-case steps in sandbox root.
- Preserve deterministic report IDs and final external report paths for suite aggregation.
- Add preflight checks (cwd under sandbox, slash-command availability, tool presence).
- Avoid per-run full dependency reinstall; leverage bundle/mise cache where possible.
- Roll out behind feature flag first, then migrate default after validation.

Potential implementation touchpoints:
- ace-test-runner-e2e: SetupExecutor, TestExecutor, TestOrchestrator, workflow instructions.
- report writer/collector path contract between sandbox-local and exported reports.
- e2e handbook updates for new execution model.
```