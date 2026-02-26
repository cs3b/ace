---
update:
  frequency: on-change
  last-updated: '2026-02-26'
---

# Simulate Next-Phase Plan Workflow

## Goal

Generate a complete implementation plan from the draft task spec produced by the
preceding draft stage. Produce a real, usable plan under `artifact:`.

## Read-Only Guardrails

- Simulation only: do not create or modify downstream draft/plan/work artifacts.
- Return structured output only; do not persist stage artifacts from this workflow.

## Input Contract

- Source content from `--source <idea-ref|task-ref|path>` (the original idea or task).
- Prior draft stage artifact from `previous_stage_output.artifact` — this is the
  generated draft task spec. Use it as the **primary** input for planning.
- When running against a task source (no prior draft stage), use the task spec directly.

## Output Contract

Return a single structured YAML payload with this exact shape:

```yaml
status: ok|partial|failed
artifact: |                   # The full implementation plan (markdown)
  # Plan: [task title]

  ## Overview
  ...

  ## Implementation Steps
  ...

  ## Files to Change
  ...

  ## Verification
  ...
questions:
  - "..."                     # Only unresolved blockers that prevent planning
```

- `artifact`: The complete implementation plan in markdown. Include: Overview,
  Implementation Steps (ordered), Files to Change, and Verification steps.
- `questions`: Only list items that genuinely block planning. Omit if none.
- `status`: Set to `ok` for a solid plan, `partial` when the plan is usable but
  incomplete context forced guesses, `failed` when input is too incomplete to plan.

## Plan Generation Requirements

- Use `previous_stage_output.artifact` (the draft spec) as the primary planning input.
  If it is null or empty, use the source content directly.
- Write the plan as if you are the agent that would produce the real implementation plan.
- Be specific: name actual files, describe concrete steps, list test commands.
- Do NOT produce a meta-analysis or bullet list of findings — produce the actual plan.

## Failure Guidance

### Missing or Malformed Draft Input

When prior draft artifact is unavailable or too incomplete to plan from:
- Set `status: partial`.
- Still produce the best plan possible from the source content.
- List the missing context as `questions`.

### Insufficient Combined Context

When neither source nor draft context is sufficient for a reliable plan:
- Set `status: failed`.
- Describe the blocker in `questions`.

## Example Output

```yaml
status: ok
artifact: |
  # Plan: Add configurable retry policy to HTTP client

  ## Overview
  Introduce a `RetryPolicy` struct and wrap `HttpClient#request` to support
  configurable exponential-backoff retries.

  ## Implementation Steps
  1. Create `lib/http/retry_policy.rb` with `RetryPolicy` struct
     - Fields: `attempts` (default 3), `base_delay_ms` (default 500),
       `retryable_codes` (default [429, 500, 502, 503, 504])
  2. Update `HttpClient#request` in `lib/http/client.rb`
     - Accept optional `retry_policy:` keyword arg
     - Wrap request loop with `RetryPolicy#with_retry`
  3. Add `RetryPolicy#with_retry` method with exponential backoff + jitter
  4. Add unit tests in `test/http/retry_policy_test.rb`
  5. Add integration smoke test in `test/http/client_test.rb`

  ## Files to Change
  | File | Change |
  |------|--------|
  | `lib/http/retry_policy.rb` | New file |
  | `lib/http/client.rb` | Add retry_policy: param |
  | `test/http/retry_policy_test.rb` | New test file |

  ## Verification
  ```bash
  ace-test test/http/retry_policy_test.rb
  ace-test test/http/client_test.rb
  ```
questions: []
```
