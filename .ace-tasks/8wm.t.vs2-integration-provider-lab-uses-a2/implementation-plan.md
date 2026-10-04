# Implementation and test responsibility

The shared managed envelope is a pure codec in ace-hitl-contract. HITL owns its semantics and authenticated lifecycle; Hermes keeps message.v1 and ingress coverage ownership; Herdr keeps native inbox delivery and signed receipt verification. ace-assign remains the sole attempt journal and process binding authority.

1. Define and package the strict envelope and shared examples. Unit tests own structure, exact correlation and binding comparisons, and secret exclusion; dependency tests enforce the leaf graph.
2. Remove Work/daemon/composite request contracts in source, CLI and tests. Store tests own exact assignment authority, no blanket expiration, terminal replay and independent effect state. Service tests own authenticated caller attribution and protected OTP consume.
3. Capture the verified active runtime reverse address and expose an in-process public client plus pane-less consume/wait. The client binds each ordinary answer to the existing Herdr inbox before delivery; it never queues OTPs. Deterministic integration tests own duplicate answers, requester death, uncertain native submissions and crash recovery.
4. Consume recovery's public bind_inbox/reconcile_inbox interfaces after root integration. Existing Herdr verifier owns signature/native binding/generation/key checks; consumer tests prove invalid proofs remain uncertain, valid consumed settles once, and superseded permits only the explicit verified retry. No new journal or requester signer.
5. Update public usage and remove obsolete deployment instructions. Run modified-package suites and installed local package proof. Record actual Telegram, signer OS-user, native observation and Lab gates separately; synthetic transport cannot satisfy them.

No changes to ace-assign before the recovery author is integrated. No publication, main writes, task completion or full installed acceptance claims.
