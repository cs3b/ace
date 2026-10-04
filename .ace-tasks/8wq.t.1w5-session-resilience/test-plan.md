# Recovery test responsibility map

Task: 8wq.t.1w5. Risk: high (writer ownership, effect duplication, signed observation).

| Behavior | Layer | Owner and coverage |
|---|---|---|
| PID birth/UID/host comparison; reused PID; inaccessible/zombie/foreign ancestry; retained shell alone | runtime molecule | ProcessIdentity tests with controlled ps table and real current process |
| Dead owner with live writing orphan retains unknown ownership and files | runtime feature | Real forked owner/writing descendant, exact-pid cleanup; no simulated proof of native stop |
| Native session/pane identity, typed errors and read-only unknown result | runtime contract + adapter | Shared adapter contract plus production tmux/Herdr transports with controlled native process replies |
| Managed driver obtains owner from production resolver/adapter and re-observes it after restart | assignment feature | Native transport fixture with real OS owner identity; reused pane blocks adoption; no test-injected Identity for this path |
| Adopt surviving owner, missing cache/checkpoint, unproven owner, unresolved external claim, dry-run writes nothing | assignment organism/CLI | Real Git journal/store and public resume command |
| Signed consumption/supersession, wrong signer/key/digest/generation/target, observer/missing evidence, consumer crash, replay and key rotation | assignment feature + Herdr verifier | Actual RSA signatures; native submission/observation fixture; same event and existing journal only |
| Unknown evidence stays visible in JSON and dashboard | overseer molecule/atom | Unknown discovery/recovery fields and question mark row |

The native transport fixture is the controlled dependency; the signature verifier, OS identity capture, attempt journal and recovery logic are real. These tests do not certify actual Codex/Pi queue consumption, requester/signer OS-user isolation, Pi reload hooks or installed native process-tree close. Those are separately required Lab acceptance through gad.8/.b and the live Herdr/Pi failure drill.
