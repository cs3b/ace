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
