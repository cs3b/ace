---
title: Agent Orchestration for Parallel E2E Testing and Failure Analysis
filename_suggestion: feat-test-agent-orchestration
enhanced_at: 2026-01-26 17:32:47.000000000 +00:00
location: archived
archived_reason: already implemented in ace-test-runner-e2e (SuiteOrchestrator parallel
  execution, /ace:run-e2e-tests subagent orchestration, FailureFinder + fix-e2e-tests
  workflow for failure analysis)
llm_model: gflash
source: taskflow:v.0.9.0
id: 8opqbi
status: pending
tags: []
created_at: '2026-01-26 17:32:46'
---

# Agent Orchestration for Parallel E2E Testing and Failure Analysis

## Problem
When running extensive End-to-End (E2E) test suites using an AI agent (e.g., Claude Code), the main agent's context is burdened by the verbose output of test runners. Furthermore, sequential execution limits the speed of the feedback loop, and failure analysis requires manual intervention or complex prompt engineering within the main agent's session.

## Solution
Enhance the `ace-test-e2e-runner` (part of the `ace-test` or `ace-test-runner` component) to implement a robust agent orchestration layer. This layer will delegate test execution to isolated, ephemeral 'Worker Agents' for parallel processing. A specialized 'Analysis Agent' will then consume structured failure reports to generate actionable recommendations for the main agent.

### Key Components:
1. **Orchestrator Organism:** A core component in `ace-test` responsible for spawning, monitoring, and collecting results from Worker Agents.
2. **Worker Agents:** Ephemeral agents (using `ace-llm` integration) responsible for running individual test suites or cases in parallel, outputting deterministic results (e.g., YAML or JSON).
3. **Analysis Agent:** A specialized agent (`handbook/agents/test-failure-analyzer.ag.md`) that receives the structured failure report, uses `ace-bundle` to load relevant file context (diffs, logs), and generates a concise set of recommended actions (e.g., `ace-git-commit` suggestions, file paths for inspection) back to the main agent.

## Implementation Approach
This feature requires significant extension of the `ace-test` gem:

1. **ATOM Architecture:** The orchestration logic will reside in an **Organism** (`TestOrchestrator`). The structured output parsing will be handled by **Molecules** (`ReportParser`). The communication protocol definition will be a **Model** (`AgentTestReport`).
2. **CLI Interface:** The `ace-test run --agent-orchestration` command will initiate this workflow, ensuring the output remains deterministic and machine-readable for the main agent.
3. **Provider Freedom:** Worker Agents must be configurable via `ace-llm` to use different providers/models optimized for speed (e.g., `openai:mini` or `anthropic:flash`).
4. **Context Management:** The main agent's context is preserved by offloading the heavy I/O and execution details to the Worker Agents, adhering to the 'No isolation boundary' principle solution.

## Considerations
- **Configuration Cascade:** The configuration (ADR-022) must allow specifying the model and concurrency limits for Worker Agents via project (`.ace/test/config.yml`) or user settings.
- **Communication Protocol:** Define a strict, versioned JSON/YAML schema for test results passed between agents to ensure reliable failure analysis.
- **Error Handling:** Robust mechanisms for handling worker agent timeouts or failures without crashing the main orchestration process.

## Benefits
- **Faster Feedback:** Enables parallel execution of E2E tests, significantly reducing the time from code change to failure report.
- **Context Preservation:** Prevents context bloat in the main agent, allowing it to focus on higher-level reasoning and task management.
- **Automated Remediation:** The Analysis Agent provides immediate, actionable insights, accelerating the debugging and fixing process, aligning with the goal of seamless agent-assisted workflow.

---

## Original Idea

```
ace-test-e2e-runner -> add agents that allow to run tests in subagents and only report one agent per suite, and one per each tests case: the goal: a) to run them in parallel b) save context of main agent. Additional we should have subagent that analyze failed test cases and recommend set of actions back to the main agent

--ask-for-approval
```