# Goal 6 — Structured Output Integration

## Goal

Using your knowledge of the tool's output formats from Goal 1, use one structured format's output directly as input to a real downstream tool — for example, create a directory from path-like output, or parse JSON output with `jq`. Save evidence of the successful integration.

## Workspace

Save all output to `results/tc/06/`. Include both the raw structured output from the tool and the evidence that a downstream tool consumed it successfully (e.g., a created directory, a jq-extracted field, or similar).

## Constraints

- Using your knowledge of the tool's output formats from Goal 1, select a structured format for integration.
- The downstream tool must consume the output directly — no manual string munging, sed/awk transformations, or intermediate parsing by the runner.
- At least one integration must be demonstrated with a real tool (e.g., `mkdir`, `jq`, `xargs`).
- Do not fabricate output — all artifacts must come from actual tool execution and downstream tool consumption.
