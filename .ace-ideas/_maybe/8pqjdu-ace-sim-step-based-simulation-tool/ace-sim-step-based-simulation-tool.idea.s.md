---
title: "ace-sim: General-Purpose Step-Based Simulation Tool"
filename_suggestion: ace-sim-step-based-simulation-tool
enhanced_at: 2026-03-05 00:00:00.000000000 +00:00
llm_model: claude-opus-4-6
id: 8pqjdu
status: pending
tags:
- simulation
- llm
- new-gem
created_at: '2026-02-28 17:37:36'
source: user
---

# ace-sim: General-Purpose Step-Based Simulation Tool

## What I Hope to Accomplish

Replace the failed task-285 hardcoded simulation approach with a general-purpose, ecosystem-native simulation tool. A simulation is an ordered pipeline of steps where each step takes input (source artifact for the first, previous step's output for subsequent), is defined by a workflow (ace-bundle URI), and executed by an LLM provider (via ace-llm). Enable any multi-step LLM pipeline (idea->draft->plan, what-if scenarios, provider comparison) to be defined declaratively and executed reproducibly.

## What "Complete" Looks Like

- **ace-sim gem** with step-based pipeline execution, standalone from ace-task/ace-idea/ace-taskflow
- **Declarative configs**: steps defined in YAML (step name, workflow URI/preset, provider(s), output format) -- not hardcoded in Ruby
- **Multi-provider comparison**: run the same step on google:flash AND anthropic:haiku to produce side-by-side artifacts
- **Ecosystem-native**: ace-bundle for context (presets), ace-llm for invocation (config-driven), ace-support-config for cascade
- **Cached artifacts**: all outputs in `.cache/ace-sim/simulations/<run-id>/` with step-level subdirs for reproducibility
- **CLI interface**:
  ```
  ace-sim run --config review-next-phase --source path/to/input.md
  ace-sim run --config review-next-phase --source input.md --dry-run
  ace-sim run --config review-next-phase --source input.md --step draft --provider google:flash
  ```

## Success Criteria

- Simulation config YAML format validated with at least one real config
- Multi-step pipeline chains output from step N as input to step N+1
- Multi-provider comparison produces side-by-side artifacts
- All ecosystem tools used (ace-bundle presets, ace-llm config, ace-support-config cascade)
- Integration tests with real tool invocations (no mocks for ecosystem tools)
- Approach proven with workflows only BEFORE any Ruby gem code

## Lessons from Task 285

The previous attempt failed (7 hours, 6 sessions, killed). Key takeaways:
1. Spec MUST include concrete happy-path usage examples
2. Prove the approach with workflows BEFORE writing Ruby code
3. Never bypass ecosystem tools
4. Integration tests with real tools, not mocks
5. Kill checkpoint after 2 failed sessions

---

## Original Idea

```
ace-sim: General-purpose step-based simulation tool for the ace ecosystem. A simulation is an ordered pipeline of steps. Each step takes an input (first step takes a source artifact; subsequent steps use the previous step's output). Each step is defined by a workflow (ace-bundle URI) and executed by an LLM provider (via ace-llm). Multiple providers can run the same step for comparison.
```
