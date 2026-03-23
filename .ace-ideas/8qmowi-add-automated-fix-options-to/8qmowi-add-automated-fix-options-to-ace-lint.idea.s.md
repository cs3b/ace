---
id: 8qmowi
status: pending
title: Add Automated Fix Options to ace-lint
tags: []
created_at: "2026-03-23 16:36:08"
---

# Add Automated Fix Options to ace-lint

## What I Hope to Accomplish
Streamline the developer workflow for resolving linting violations by providing integrated repair options within `ace-lint`. This reduces the friction of manually fixing common issues and leverages AI agents for more complex structural linting repairs.

## What "Complete" Looks Like
`ace-lint` is updated to support `--autofix` and `--autofix-with-agent` flags, mirroring the "doctor" repair pattern found in other `ace` CLI tools. Standard fixes are handled by the underlying linter, while more complex issues can be delegated to an LLM-powered agent.

## Success Criteria
- `ace-lint --autofix` correctly triggers the native auto-correction capabilities of the underlying linters (e.g., RuboCop, ESLint).
- `ace-lint --autofix-with-agent` successfully initializes an agentic session to resolve linting errors that standard tools cannot fix.
- Both flags are clearly documented in the `ace-lint --help` output.
- The implementation adheres to the existing architectural patterns for automated repairs used across the `ace` ecosystem.
