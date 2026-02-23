# Experimental E2E Execution: ace-b36ts Goal-Based Pilot

## Overview

Manual end-to-end execution of the 8 goal-based E2E tests for ace-b36ts,
running outside the orchestrator to validate that goal specs work in practice.

## Phases

| Phase | File | Purpose |
|-------|------|---------|
| A | [phase-a-setup-sandbox.wf.md](phase-a-setup-sandbox.wf.md) | Create isolated sandbox with git repo and mise.toml |
| B | [phase-b-prepare-runner.wf.md](phase-b-prepare-runner.wf.md) | Bundle all 8 runner.md files into a single prompt |
| C | [phase-c-execute-runner.wf.md](phase-c-execute-runner.wf.md) | Invoke runner agent via ace-llm |
| D | [phase-d-prepare-verifier.wf.md](phase-d-prepare-verifier.wf.md) | Collect artifacts and bundle with verify.md files |
| E | [phase-e-execute-verifier.wf.md](phase-e-execute-verifier.wf.md) | Invoke verifier agent via ace-llm |
| F | [phase-f-generate-report.wf.md](phase-f-generate-report.wf.md) | Parse verifier output into final report |

## Directory Layout

```
experiment/
├── plan.md                          # This file
├── phase-a-setup-sandbox.wf.md
├── phase-b-prepare-runner.wf.md
├── phase-c-execute-runner.wf.md
├── phase-d-prepare-verifier.wf.md
├── phase-e-execute-verifier.wf.md
├── phase-f-generate-report.wf.md
└── sandbox/                         # Created by phase A (gitignored)
    ├── mise.toml
    ├── results/{1..8}/                # Runner writes artifacts here
    └── .cache/ace-e2e/                      # Prompts, outputs, final report
```

## Key Design Decisions

- **ace-llm with CLI provider** (`claude:sonnet`) — invokes `claude -p` which has full bash/tool access
- **Same tool for runner + verifier** — uniform execution model
- **sandbox/ is gitignored** — ephemeral execution artifacts
- **Report with YAML frontmatter** — machine-parseable metadata + human-readable body

## Goal Sources

Goals are defined in `../e2e/TS-B36TS-001-goal-pilot/goal-{1..8}-*.{runner,verify}.md`.
