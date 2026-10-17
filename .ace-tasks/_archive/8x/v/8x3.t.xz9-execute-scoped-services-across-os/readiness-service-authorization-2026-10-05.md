# Service authorization read readiness amendment

Status: independently APPROVED for this bounded amendment after clarification, 2026-10-05. This is a bounded xz9.0 consumer boundary, with no new producer, dependency, authority endpoint, journal or policy dialect. The existing Lab composition remains the sole technical policy owner; qjz remains the sole canonical proposal producer.

The companion contract now specifies the fixed `service_authorization` read, closed request/reply fields, original body revalidation, no mutation/replay cache and explicit one-shot begin permission separation. Child usage covers successful invocation, changed authorization, and lost replies. The test plan maps hostile bindings, policy changes, no journal mutation, body redaction, retained/replayed permission refusal and late completion.

Implementation is not included in this amendment. Current source remains frozen at c5c7f5d9b for independent replay review. Full Endcap and installed acceptance remain open, including adoption of independently accepted final 09j source.

Review clarification: operation digest is recomputed locally by the same normalized Lab operation/digest owner; full current policy digest is computed only by authority and compared with the immutable claim projection. Final fresh read defines admission linearization; later changes do not retroactively cancel admission. No polling or extra controller is introduced.


## Independent root verdict

Reviewed `eb582ea24`, requested two clarifications, then inspected `4674d821a` and the actual ProtectedServicePolicy adapter. **APPROVE**, no remaining readiness blockers for this amendment. Scope is only the existing xz9.0 executor read boundary; final source/installed acceptance remains open.

The receiver compares the operation digest using the same existing normalized operation/digest owner and the policy digest against the immutable canonical claim. It never reconstructs private proposal state. The final fresh authority check defines admission ordering; changes before it refuse, changes after it cannot retroactively cancel an admitted effect, and local operation mismatch still prevents invocation. Fresh begin remains separately necessary, read success is not reusable permission, and lost replies retain uncertainty. Completion records truth independently of new effect eligibility.

Verification explicitly covers wrong peers/bindings, repeated fresh reads, no journal mutation, revoked or changed policy before admission, late completion and no second effect after begin replay. Implement in the isolated continuation, then independently review final combined source and actual installed distinct-user behavior.
