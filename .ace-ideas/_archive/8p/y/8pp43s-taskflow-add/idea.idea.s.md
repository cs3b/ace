---
title: Simulation-Based Prototype for Workflow Review Dry Runs
filename_suggestion: feat-taskflow-sim-proto
enhanced_at: 2026-02-26 02:44:13.000000000 +00:00
llm_model: pi:glm
status: done
completed_at: 2026-02-26 15:32:38.000000000 +00:00
id: 8pp43s
tags: []
created_at: '2026-02-26 02:44:11'
---

# Simulation-Based Prototype for Workflow Review Dry Runs

## What I Hope to Accomplish
Create a simulation-based prototype layer for ace-taskflow review workflows that models tool execution and workflow transitions through pure LLM inference, without actual code execution or tool calls. This enables rapid iteration on the "next-phase dry run" concept by running multiple model instances or the same model multiple times, comparing outputs to identify robust insights, and validating the simulation approach before committing to full implementation.

## What "Complete" Looks Like
A simulation framework that: (1) defines tool execution schemas (inputs, outputs, side effects) for key ace-* commands used in idea→task→plan workflows; (2) implements a simulator agent that predicts tool outputs based on input state without invoking actual CLI tools; (3) supports comparative mode—running the same simulation with different models or multiple runs to surface consensus vs. divergence; (4) generates structured insights (questions, refinements) from simulation results; (5) integrates with existing ace-taskflow workflow-instructions via wfi:// protocol for easy adoption.

## Success Criteria
- Simulator can predict outputs for ace-taskflow, ace-git, ace-bundle tool calls with 80%+ accuracy on validation set
- Comparative mode surfaces at least 3 distinct perspectives when using 3 different models (or 3 runs)
- Dry-run workflow completes in under 10 seconds vs. 60+ seconds for actual tool execution
- Simulation insights match real execution insights in 70%+ of test cases
- Framework provides migration path from simulation to real tool execution once validated

---

## Original Idea

```
how to build prototyp without code - as pure simulation, so we dont use as much tools calls and we run it faster, we can even use few models to do it (or even the same model do it more then once) and then compare - it plays with idea .ace-taskflow/v.0.9.0/ideas/_maybe/8poz4f-taskflow-add/idea.idea.s.md:15
```