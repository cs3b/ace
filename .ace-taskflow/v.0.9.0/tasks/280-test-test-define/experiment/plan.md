# Experimental E2E Execution: ace-b36ts Goal-Based Pilot

## Overview

Manual end-to-end execution of 8 goal-mode TCs for ace-b36ts,
running outside the orchestrator to validate that standalone TC specs work in practice.

## Phases

| Phase | File | Purpose |
|-------|------|---------|
| A | [phase-a-setup-sandbox.wf.md](phase-a-setup-sandbox.wf.md) | Create isolated sandbox with git repo and mise.toml |
| B | [phase-b-prepare-runner.wf.md](phase-b-prepare-runner.wf.md) | Bundle all 8 `TC-*.runner.md` files into a single prompt |
| C | [phase-c-execute-runner.wf.md](phase-c-execute-runner.wf.md) | Invoke runner agent via ace-llm |
| D | [phase-d-prepare-verifier.wf.md](phase-d-prepare-verifier.wf.md) | Collect artifacts and bundle with `TC-*.verify.md` files |
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
    ├── results/tc/{01..08}/                # Runner writes artifacts here
    └── .cache/ace-e2e/                      # Prompts, outputs, final report
```

## Key Design Decisions

- **ace-llm with CLI provider** — runner uses `claude:haiku`, verifier uses `claude:opus`
- **Same tool for runner + verifier** — uniform execution model
- **sandbox/ is gitignored** — ephemeral execution artifacts
- **Report with YAML frontmatter** — machine-parseable metadata + human-readable body

## TC Sources

Standalone goal-mode TCs are defined in `../e2e/TS-B36TS-001-pilot/TC-00{1..8}-*.{runner,verify}.md`.
