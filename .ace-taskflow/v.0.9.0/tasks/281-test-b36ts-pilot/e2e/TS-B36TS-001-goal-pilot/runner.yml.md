---
description: "E2E runner input for ace-b36ts goal-based pilot"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./goal-1-help-survey.runner.md
    - ./goal-2-encode-today.runner.md
    - ./goal-3-decode-token.runner.md
    - ./goal-4-error-behavior.runner.md
    - ./goal-5-output-routing.runner.md
    - ./goal-6-structured-output.runner.md
    - ./goal-7-roundtrip-pipeline.runner.md
    - ./goal-8-batch-sort.runner.md
---

# E2E Test Runner: ace-b36ts Goal-Based Pilot

Tool under test: ace-b36ts
Required tools: ace-b36ts, jq
Workspace root: (current directory)

Execute each goal sequentially. Goal 1 is discovery — all later goals
build on what you learn there. Do not re-run --help after Goal 1.

## Rules

- Execute each goal in order (1 through 8)
- Use only ace-b36ts, jq, and standard shell utilities
- Save all artifacts to results/{N}/ directories as specified
- Do not fabricate output — all artifacts must come from real tool execution
- If a goal fails, note the failure and continue to the next goal
- After all goals, output a brief summary of what you produced for each goal

## Artifact conventions

When a goal requires capturing command output:
- Save stdout to `{name}.stdout`, stderr to `{name}.stderr`, exit code to `{name}.exit`
- The `.exit` file contains only the numeric exit code (e.g., `0` or `1`)
- When a goal says "save the output to a file", default to this three-file pattern unless the goal specifies a different format
- Summary or analysis files (.md) are optional extras — the raw captures are the primary artifacts
