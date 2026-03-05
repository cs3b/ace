---

id: 8pqjdu
status: pending
title: ace sim general purpose step based simulation t
tags: []
created_at: "2026-02-28 17:37:36"
source: "user"
---

# ace sim general purpose step based simulation t

# ace-sim: General-purpose step-based simulation too...

## Description

ace-sim: General-purpose step-based simulation tool for the ace ecosystem.

A simulation is an ordered pipeline of steps. Each step takes an input (first step takes a source artifact; subsequent steps use the previous step's output). Each step is defined by a workflow (ace-bundle URI) and executed by an LLM provider (via ace-llm). Multiple providers can run the same step for comparison.

Key properties:
- Steps are the core abstraction. A simulation config defines: step name, workflow URI/preset, provider(s), output format.
- Multi-provider: Run the same step on google:flash AND anthropic:haiku to compare outputs.
- General-purpose: NOT hardcoded to "next-phase review". Use cases: idea->draft->plan lifecycle, what-if scenarios, provider comparison, spec quality.
- Ecosystem-native: Uses ace-bundle for context (presets, not hardcoded YAML). Uses ace-llm for invocation (config-driven, not hardcoded max_tokens). Uses ace-support-config for cascade.
- Cache: All artifacts in `.cache/ace-sim/simulations/<run-id>/` with step-level subdirs.
- Standalone: NO dependency on ace-task, ace-idea, or ace-taskflow.

Lessons from task 285 failure (7 hours, 6 sessions, killed):
1. Spec MUST include concrete happy-path usage examples
2. Prove the approach with workflows BEFORE writing Ruby code
3. Never bypass ecosystem tools
4. Integration tests with real tools, not mocks
5. Kill checkpoint after 2 failed sessions

CLI sketch:
```
ace-sim run --config review-next-phase --source path/to/input.md
ace-sim run --config review-next-phase --source input.md --dry-run
ace-sim run --config review-next-phase --source input.md --step draft --provider google:flash
```

## What I Hope to Accomplish

Replace the failed task-285 hardcoded simulation approach with a general-purpose, ecosystem-native simulation tool. Enable any multi-step LLM pipeline (idea->draft->plan, what-if scenarios, provider comparison) to be defined declaratively and executed reproducibly. The key insight: prove workflows work BEFORE writing Ruby code.

## What "Complete" Looks Like

- `ace-sim run --config review-next-phase --source my-idea.s.md` runs a multi-step simulation end-to-end
- Steps are defined in YAML configs, not hardcoded in Ruby
- All LLM calls go through ace-llm, all context through ace-bundle presets
- Multi-provider comparison works (same step, different providers)
- Cached artifacts in `.cache/ace-sim/simulations/<run-id>/` with step-level subdirs
- No dependency on ace-task, ace-idea, or ace-taskflow

## Success Criteria

- [ ] Simulation config YAML format validated with at least one real config
- [ ] Multi-step pipeline chains output from step N as input to step N+1
- [ ] Multi-provider comparison produces side-by-side artifacts
- [ ] All ecosystem tools used (ace-bundle presets, ace-llm config, ace-support-config cascade)
- [ ] Integration tests with real tool invocations (no mocks for ecosystem tools)
- [ ] Approach proven with workflows only BEFORE any Ruby gem code

## Context

- Location: active
- Created: 2026-02-27 12:55:23


---
Captured: 2026-02-27 12:53:21
