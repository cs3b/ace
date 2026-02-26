---
update:
  frequency: on-change
  last-updated: '2026-02-26'
---

# Simulate Next-Phase Draft Workflow

## Goal

Generate a complete draft task specification from the idea content, as if running the
`wfi://task/draft` workflow. Produce a real, usable draft spec under `artifact:`.

## Read-Only Guardrails

- Simulation only: do not create or modify downstream draft/plan/work artifacts.
- Return structured output only; do not persist stage artifacts from this workflow.

## Input Contract

- Source content from `--source <idea-ref|path>`.
- Source must be parseable as an idea-style structured content file.

## Output Contract

Return a single structured YAML payload with this exact shape:

```yaml
status: ok|partial|failed
artifact: |                   # The full generated draft task spec (markdown)
  # Task: [title]

  ## Description
  ...

  ## Acceptance Criteria
  ...

  ## Implementation Notes
  ...
questions:
  - "..."                     # Only unresolved blockers that prevent drafting
```

- `artifact`: The complete draft task spec in markdown. Follow the same format as
  `wfi://task/draft`. Use clear section headings: Description, Acceptance Criteria,
  Implementation Notes, Success Criteria, etc.
- `questions`: Only list items that genuinely block drafting confidence. Omit if none.
- `status`: Set to `ok` when a solid draft is produced, `partial` when the draft is
  usable but incomplete context forced guesses, `failed` when source is too malformed
  to draft from.

## Draft Generation Requirements

- Extract intent, scope, and constraints from the source idea content.
- Write the draft spec as if you are the agent that would produce the real draft.
- Be specific: use concrete titles, clear acceptance criteria, and actionable notes.
- Do NOT produce a meta-analysis or bullet list of findings — produce the actual spec.

## Failure Guidance

### Malformed Source Content

When source is malformed, missing required structure, or unreadable:
- Set `status: failed`.
- Leave `artifact:` empty or with a minimal placeholder.
- Describe the problem in `questions`.

### Insufficient Context

When source is valid but incomplete for a fully reliable draft:
- Set `status: partial`.
- Still produce the best draft possible under `artifact:`.
- List gaps as `questions`.

## Example Output

```yaml
status: ok
artifact: |
  # Task: Add configurable retry policy to HTTP client

  ## Description
  The HTTP client currently has no retry logic. Add a configurable retry policy
  that supports exponential backoff with jitter, max attempts, and retryable
  status code configuration.

  ## Acceptance Criteria
  - Retry policy is configurable via `RetryPolicy` struct (attempts, backoff, codes)
  - Default policy: 3 attempts, exponential backoff starting at 500ms
  - Retryable status codes default to [429, 500, 502, 503, 504]
  - Non-retryable errors (4xx except 429) fail immediately
  - All retry logic is unit-tested

  ## Implementation Notes
  - Introduce `RetryPolicy` struct in `lib/http/retry_policy.rb`
  - Wrap `HttpClient#request` to loop with policy
  - Use `SecureRandom` jitter to avoid thundering herd

  ## Success Criteria
  - `ace-test` passes
  - Manual smoke: retries visible in debug logs on 503
questions: []
```
