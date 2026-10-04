# Native inbox observations — draft usage

## Positive observation
Trusted supervisor runs `ace-herdr inbox observe --event event-1 --format json`. Expected: `observed` only with provider-native acknowledgement correlated to exact event, attempt, claim generation, payload digest and target, plus sanitized verifiable source reference. No event transition occurs.

## Missing evidence
Queue entry disappears without positive native non-consumption evidence. The same command returns `uncertain`; no signed proof, resend or resource cleanup.

## Stale observation
The event generation changes before settlement. gad.b rechecks observation against current event; rejects stale evidence rather than signing it. Provider-specific schema and extraction interfaces must be resolved by readiness review.
