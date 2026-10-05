# Protected attempt steering — draft usage

## Send direction once

The qk0 consumer calls `prompt_attempt(mapping_id, assignment_id, attempt_id,
expected_generation, mutation_id, text)` with a persisted mutation ID and bounded
text. The owner derives the original target and authorizes the existing mapped
driver. An acknowledgement returns `submitted`, not consumed. Repeating the
exact call returns its canonical result without another send. Changed text with
the same identity is refused.

## Stop while a descendant or service effect remains uncertain

`stop_attempt(mapping_id, assignment_id, attempt_id, expected_generation,
mutation_id)` records the request and blocks conflicting new dispatch. Closing
the original pane without complete scope-exit proof returns `uncertain` and
required reconciliation. The worktree remains protected; no accepted completion
or prune permission is invented.

## Recover a lost reply

After an issued prompt or stop loses its reply, restart and query the same
canonical mutation. Exact retry never retransmits control. The recorded outcome
remains uncertain until the owner accepts attributable native evidence. A new
attempt generation or substituted target is not a retry of the original action.
