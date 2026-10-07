# Authenticated Endcap settlement evidence producer/consumer contract

Normative source interface for the existing xz9.2 stop owner. Root independently approved this contract on2026-10-07; producer/consumer agreement and implementation/checkpoint review remain required. This is not a delivered stop, maintenance or installed acceptance claim.

## Source facts and ownership

Endcap#service_settlement_complete! (endcap_services.rb:14) checks complete attempt request inventory against claim/transition references, exact project/map and terminal succeeded/failed-settled states. EvidenceJournal#service_request(commit:) authenticates the latest accepted record_digest and every terminal/no-effect imported artifact at that exact commit (evidence_journal.rb:352,609). No separate service verifier is needed.

Endcap#inbox_settlement_complete! (endcap_inboxes.rb:34) checks exact canonical attempt chain, current retained event inventory and every registered current claim. Its verified_inbox_record delegates signature/original descriptor/key/accepted reply authentication to HistoricalInboxEvidence#verify_selected!, which already returns immutable reconciliation+reply events. Current method discards that returned selection and returns proof payload only. HistoricalInboxEvidence#verify! authenticates the entire registered historical completed set but currently returns true. Superseded/queued is a completed reconcile effect, never final settlement.

I own Endcap services/inboxes and HistoricalInboxEvidence projection factoring. N0n owns stop/coordinator planning, canonical stopped CAS, launch steering/status/history/release consumers. No change to N1/native/control or a second journal/controller/verifier.

## Required internal APIs

All methods have existing keyword inputs journal:, events:, params:, map:, commit:. Historical inbox additionally takes deployment:, history: as its existing method. They are source-owned calls only, never wire endpoints or caller proof selectors.

- service_settlement_evidence! returns deeply frozen {commit,services:[{request_id,state,event_digest,record_digest,receipt_digest,evidence_refs:[{ref,sha256}]}]}.
- inbox_settlement_evidence! returns deeply frozen {commit,inboxes:[{inbox_context_id,event_id,claim_generation,reconciliation_event_digest,reply_event_digest,receipt_ref,signature_ref}]}.
- historical_inbox_settlement_evidence! returns the same inbox projection using the original retained descriptor/key at the supplied original prefix, with no current Inbox/endpoint read or discovery.

Hash keys are strings. services sorted by request_id; evidence_refs sorted by ref+sha256; inboxes sorted by inbox_context_id+event_id. Existing imported reference shapes/bytes are preserved. Empty arrays are authenticated exhaustive empty sets only after existing full inventory checks; they do not grant no-writers or retirement permission. No raw signed bytes or errors in projections.

Before service projection, require journal.verify_commit!(commit), exact retained attempt events==events and chain_valid?; retain complete journal-wide attempt inventory comparison. For each terminal request use the actual service_request verified return and the latest accepted matching claim/transition identified by that reader's record_digest invariant; require a service_transition and matching terminal state/receipt_digest, not a caller-selected event. Its event introduction is positively selected at commit through event_commit!. Project imported evidence refs from the verified terminal receipt. No second evidence reader or signature verifier.

Factor current inbox private reader into one shared authenticated selection result retaining its existing snapshot/native/claim/raw ref checks plus the existing HistoricalInboxEvidence selected result. Existing ordinary readers continue to receive the payload from that same result. Settlement projects only the authenticated current completed claim and exact accepted reply. Historical full reader accumulates those same original authenticated terminal selections while checking the entire history; it projects the last completed claim per registration, never an earlier queued/obsolete claim. Existing boolean predicates call the evidence methods and return true, preserving maintained normal release/abort/reuse semantics without duplicate verification.

## Consumer and lock contract

N0n's public stop owner owns the full terminal transaction: after actual input inhibition, fresh exact before-release no-writers proof and outer context admissions, enter existing slot/assignment/journal exclusions; obtain BOTH evidence projections at the CAS input commit; give exact service event digests and inbox reconciliation digests to the existing coordinator's pure legal active-to-stopped plan. The existing JournalMutation CAS binds attempt_stopped to original descriptor/scope/seal/closed proof and those exact sorted sets. A CAS retry rederives all inputs at its new commit. Neither projection emits terminal events nor changes attempt state.

Original release/history consumer reauthenticates the original pre-stopped prefix with these same owner methods and requires exact projected digest sets and original joins to equal accepted attempt_stopped fields. It must not accept arbitrary digest membership, a partial selected subset, boolean caller flags or current key substitutions. Accepted input drain does not upgrade unknown public prompt outcomes, prove successful task result, or itself settle service/Inbox work.

No context RPC completion under lifecycle locks. Existing outer context admission stays before slot/assignment/journal locks. Evidence methods perform the same existing held-context snapshot reads and canonical Git reads; no native issue/wait, state mutation or new exclusion protocol. Full all-root context maintenance/orphan reclaim remains open.

## Checklist before source checkpoint

1. Root exact contract APPROVE recorded2026-10-07. N0n reciprocal agreement recorded2026-10-07: service_settlement_event_digests and inbox_settlement_event_digests equal the exact complete sorted owner projections. Implementation remains held until containment repair integration.
2. Factor shared owner results once; retain existing boolean callers and all current/historical rejection rules.
3. Controlled actual service producer positive for succeeded and failed-settled, exact refs/event digests, immutable nested outputs and exhaustive empty set.
4. Controlled actual signed Inbox+canonical pipeline positive plus original historical descriptor/key selection. Current claim supersession/queued refuses final settlement; accepted completed selects latest exact claim/reply.
5. Negative omitted/foreign attempt event set, malformed/unverified commit, omitted extra service/Inbox item, altered record/event/import, wrong original key, partial claimed set and mutable returned output. Do not build fake accepted flags.
6. Consumer equality tests belong n0n: stopped plan/CAS/history exact sets, original joins, replay and changed-ref retry. No fake stopped receipt or unknown-to-submitted upgrade.
7. Only permitted selected deterministic ace-test targets; no native/installed/privileged/process probes; frozen source with actual receipts then independent review. This projection checkpoint alone does not complete public stop or xza.3.
