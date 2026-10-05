# Native surface inspection — 2026-10-04

Executed `codex --version`: codex-cli 0.159.3. Executed `codex queue --help`: submission CLI accepts thread/message, but offers no public consumption query. Generated the actual installed experimental app-server schema with `codex app-server generate-json-schema --experimental --out .ace-local/lab-readiness/codex-schema`. No live conversation was read or changed.

The generated v2 schema provides:
- thread/queue/add input: clientUserMessageId, input, threadId; response queuedSubmission has id, clientUserMessageId, input.
- thread/queue/list returns queued submissions and cursor; list absence alone remains insufficient.
- thread/queue/changed notification contains only threadId, no reason or consumed identity.
- thread/read with includeTurns can expose userMessage items with clientId, id and content, in identified turns. This suggests an exact native correlation path, but schema existence does NOT prove clientId propagation/consumption semantics. Execute real disposable native scenarios before selecting/promoting the contract.
- thread/queue/start returns a turn; explicit delete/start acknowledgements and their retained provenance need review for positive non-consumption/consumption proof. Do not reinterpret queue disappearance as acknowledgement.

Current lab-config pi-overseer-queue.ts checks payload digest and calls sendUserMessage (idle direct or followUp); it acknowledges enqueue immediately. It does not retain a consumption observation. This generic Pi queue/observation mechanism belongs in an ACE package; lab-config installs it. No provider-owned instrumentation was implemented in this inspection.

Remaining: execute native correlation/retention/restart scenarios, specify protected source provenance and snapshot-to-sign race behavior, and independent readiness review.

## Further installed Pi API boundary — 2026-10-05

Read-only inspection of installed `@earendil-works/pi-coding-agent` 0.87.1:
- `dist/index.d.ts` exports both `createAgentSession` and `InteractiveMode`;
  `AgentSession.agent` is a public readonly `Agent` reference. This is a candidate
  provider-owned composition surface for preserving the actual TUI while adding
  correlation at native enqueue/dequeue, rather than substituting custom-message
  roles or inventing unsupported extension hook fields. No such composition has
  been implemented or accepted by this inspection.
- `dist/core/agent-session.js` `_queueFollowUp` (around 1448) stores text in its
  UI queue and passes a user-message object to `agent.followUp`. Its native event
  handler (around 559) removes queue entries with `indexOf(messageText)`. The
  session queue projection therefore cannot independently attribute equal text
  to a managed delivery. Do not use that projection as signed consumption proof.
- On `message_end`, the session appends the native message and records its entry
  ID against the message object, after emitting to listeners. Public callback
  timing and exact identity/persistence would have to be proved by the actual
  managed runtime before choosing instrumentation. Object identity interception
  is only a research candidate; it is not demonstrated restart-safe correlation.

Inspected artifact SHA-256 values:
- `dist/index.d.ts`: `1e89f64c284248e8004bc040be1b8d886f20c158091d4e466cb130fa9d13d458`
- `dist/core/agent-session.d.ts`: `ee0b9c2c2fefeef292c9da884b92c0fa5fce73f04bc834655720253d477f391d`
- `dist/core/agent-session.js`: `5ebfae51db5a900596145159428e7cb57d195af9d54a28f41d4ac8ff1bfd5729`

No credentials or live conversations were read. No native Pi model run, positive
consumption, supersession, protected provenance or draft promotion is claimed.
The existing target-provider/model prerequisite and installed equal-payload,
restart/fork/reload, trust-boundary and cancellation drills remain required.
