---
name: sim/simulate-next-phase-draft
description: Draft step contract for ace-sim next-phase scenario
doc-type: workflow
purpose: Produce draft-stage structured output for simulation chaining
---

# Next-Phase Draft Step

## Goal
Produce draft-stage output for a simulation run.

## Inputs
- run id
- source reference
- scenario context

## Output
Return YAML with at least:
- `step: draft`
- `objective_summary`
- `acceptance_targets`
