---
name: sim/simulate-next-phase-plan
description: Plan step contract for ace-sim next-phase scenario
doc-type: workflow
purpose: Produce plan-stage structured output using prior draft output
---

# Next-Phase Plan Step

## Goal
Produce plan-stage output using draft-stage output from the same run.

## Inputs
- run id
- source reference
- draft-stage output

## Output
Return YAML with at least:
- `step: plan`
- `execution_plan`
- `risk_notes`
