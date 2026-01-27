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

- [ ] Pending discussion
- [ ] Decided: _____________
