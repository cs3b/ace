# Protected attempt steering — draft usage

## Send direction once

Desired API pending the explicit native acknowledgement/body framing question:
the qk0 consumer calls `prompt_attempt(mapping_id, assignment_id, attempt_id,
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

## Stop consumes accepted scope closure

stop_attempt sends the exact four params {mapping_id, assignment_id, attempt_id,
expected_generation}, required mutation ID, no body. It delegates sealing/stop
to 9c2 and records uncertain while proof or service/inbox settlement is pending.
A later fresh current-generation call may admit stopped; exact old retry keeps
its original uncertain reply. Slot release follows terminal commit and verified
release-before-reuse. Native pane closure or descendant absence alone cannot
settle independent service/inbox truth.

Positive prompt acceptance remains unspecified until the existing task closes
the pinned native method/ack/error and body framing question. The generic CLI
send and ProtectedNativeControl.request are source research, not selected public
protected prompt handlers. No blocked probes are authorized by these examples.
