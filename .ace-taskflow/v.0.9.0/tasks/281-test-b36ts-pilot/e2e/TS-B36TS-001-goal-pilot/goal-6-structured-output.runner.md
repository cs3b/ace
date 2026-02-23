# Goal 6 — Structured Output Integration

## Goal

Discover the tool's structured output formats via `--help`. Use one format's output directly as input to a real downstream tool — for example, create a directory from path-like output, or parse JSON output with `jq`. Save evidence of the successful integration.

## Workspace

Save all output to `goal/6/`. Include both the raw structured output from the tool and the evidence that a downstream tool consumed it successfully (e.g., a created directory, a jq-extracted field, or similar).

## Constraints

- Use `--help` to discover what structured output formats the tool supports. Do not assume format names.
- The downstream tool must consume the output directly — no manual string munging, sed/awk transformations, or intermediate parsing by the runner.
- At least one integration must be demonstrated with a real tool (e.g., `mkdir`, `jq`, `xargs`).
- Do not fabricate output — all artifacts must come from actual tool execution and downstream tool consumption.
