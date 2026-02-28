# Question: Failure Modes & Retries

## The Question

How do we handle worker crashes, timeouts, invalid reports, and repeated failures?

## Context

The overseer must be resilient without hiding failures. Clear retry and abort rules are required.

## Prompts

- What counts as a retryable failure vs a hard stop?
- Should retries be per-step or global (max iterations)?
- How are invalid/missing reports handled?
- What is the default timeout policy for workers?

## Decision Status

- [x] Decided: **Configurable per-step with generous defaults**

**Failure types:**
| Type | Behavior |
|------|----------|
| Verification failed / missing report | Retry (up to 5x default) |
| Same status repeated (tracked in log) | 3 retries, then escalate/stop |
| Crash / unknown | Dedicated analysis workflow |

**Trust agents:** They're good at reaching goals if goals aren't too big.

**Per-step config (optional, generous defaults):**
```yaml
steps:
  - name: test
    instructions: ace-bundle wfi://run-tests
    retries: 5              # generous default
    timeout: 30m            # generous default
    on_repeated_failure: 3  # same error 3x → stop
    restart_hint: "Check test output, fix one test at a time"
```

**Logging:** Track all failures in session log to detect patterns and enable analysis.
