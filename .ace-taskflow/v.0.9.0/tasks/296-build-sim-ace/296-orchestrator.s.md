---
id: v.0.9.0+task.296
status: draft
priority: high
estimate: TBD
dependencies: []
needs_review: true
---

# Build ace-sim: General-Purpose Step-Based Simulation Tool

## Overview

Build a standalone `ace-sim` tool that runs ordered simulation pipelines. Each step is defined by a workflow (ace-bundle URI) and executed by an LLM provider (via ace-llm). Multiple providers can run the same step for comparison.

This orchestrator enforces a two-phase sequence learned from the task-285 failure (7 hours, 6 sessions, killed):

1. **Prove the approach with workflows only** — no Ruby code. Validate multi-step simulation using existing tools (ace-bundle + ace-llm CLI + shell scripting).
2. **Build the ace-sim Ruby gem** — wrap proven workflows into a proper gem. Does NOT redesign them.

**Kill checkpoint**: If Subtask 1 fails after 2 sessions, kill the approach entirely.

## Behavioral Specification

### User Experience
- **Input**: Maintainer runs `ace-sim run` with a config name and source file
- **Process**: Pipeline executes steps sequentially, each step's output feeds into the next. Multiple providers can run the same step for comparison.
- **Output**: Cached artifacts in `.cache/ace-sim/simulations/<run-id>/` with step-level subdirs and synthesis report

### Expected Behavior
- Simulations are ordered pipelines of steps defined in YAML config
- Each step: name, workflow URI/preset, provider(s), output format
- Multi-provider: same step on google:flash AND anthropic:haiku to compare
- General-purpose: NOT hardcoded to "next-phase review"
- Ecosystem-native: ace-bundle for context, ace-llm for invocation, ace-support-config for cascade
- Standalone: NO dependency on ace-task, ace-idea, or ace-taskflow

### Interface Contract

```bash
# Run a simulation
ace-sim run --config review-next-phase --source path/to/input.md

# Dry run (show plan without LLM calls)
ace-sim run --config review-next-phase --source input.md --dry-run

# Run single step with specific provider
ace-sim run --config review-next-phase --source input.md --step draft --provider google:flash

# List available configs
ace-sim list

# Show run summary
ace-sim show <run-id>
```

### Success Criteria
- [ ] Two-subtask sequence enforced: 296.01 (workflows only) -> 296.02 (gem implementation)
- [ ] Phase 1 proves approach WITHOUT any Ruby code
- [ ] Phase 2 wraps proven workflows, does NOT redesign them
- [ ] Both subtasks have concrete happy-path usage examples
- [ ] All ecosystem tools used (ace-bundle, ace-llm, ace-support-config)
- [ ] No hardcoded values that should be config-driven
- [ ] Kill-or-continue checkpoint between subtasks

## Subtasks

- **296.01**: Prove Simulation Pipeline with Workflows Only (No Code)
- **296.02**: Build the ace-sim Ruby Gem (blocked by 296.01)

### Concept Inventory

| Concept | Introduced by | Removed by | Status |
|---------|---------------|------------|--------|
| Step-based simulation pipeline | 296.01 | — | KEPT |
| YAML simulation config format | 296.01 | — | KEPT |
| ace-bundle presets for sim context | 296.01 | — | KEPT |
| Multi-provider comparison | 296.01 | — | KEPT |
| Synthesis from step outputs | 296.01 | — | KEPT |
| Standalone ace-sim gem | 296.02 | — | KEPT |
| ATOM gem structure | 296.02 | — | KEPT |
| Config cascade (.ace-defaults -> .ace -> CLI) | 296.02 | — | KEPT |

## Review Questions (Pending Human Input)

### [HIGH] Kill checkpoint enforcement
- [ ] After how many failed sessions on Subtask 1 should we kill the approach?
  - Proposed default: 2 failed sessions.

### [HIGH] Scope of v1 simulation configs
- [ ] Should v1 ship only `review-next-phase` config, or also include other use cases?
  - Proposed default: `review-next-phase` only; generic runner interface supports future configs.

### [MEDIUM] Provider defaults
- [ ] Which providers should be the default comparison pair?
  - Proposed default: `google:flash` and `anthropic:haiku`.

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/8pqjdu-taskflow-enhance/ace-sim-general-purpose-step-based-simulation-t.idea.s.md`
- Retros: `.ace-taskflow/v.0.9.0/retros/8pq3qi-task-285-postmortem-kill-implementation.md`
- Prior draft 295: `.ace-taskflow/v.0.9.0/tasks/295-task-sim-extract/295-ace-sim-gem-285-worktr.s.md`
- Failed executor (anti-patterns): `ace-taskflow/lib/ace/taskflow/molecules/next_phase_stage_executor.rb`
