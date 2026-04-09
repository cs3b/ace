# Goal 3 — Unknown Provider Routing

## Goal

Run `ace-llm nope "Reply with token OK"` and capture output that proves the CLI
reported an explicit unknown-provider routing error.

## Workspace

Save artifacts to `results/tc/03/`.

## Constraints

- Preserve raw output exactly.
- Capture stdout, stderr, and exit code for the command.
- Do not convert this into a provider-auth test; the evidence target is routing
  failure for unsupported provider alias.
