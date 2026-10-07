# Handler cleanup and receiver recovery responsibility map

Root approved the source/installed audit and amendment; wave412 confirms gad.b inspection remains source-owned.

| Behavior | Risk/layer | Owner and checks |
|---|---|---|
| Cleanup never performs implicit/unbounded child wait | High, controlled unit | Existing BoundedProcess owner, injected Open3 handles/waiter; unreaped, timeout and IO failure paths assert finite join and closed streams. No actual native/protected/descendant probe. |
| Handler preserves closed environment, exact receipt and stdout/stderr caps | High, controlled unit | Handler calls actual maintained bounded owner; injected result/error checks and one existing ordinary fixed-command positive if authorized. Existing descendant test is excluded under current restriction. |
| Receiver recovery never reissues original effect | High, canonical/socket integration | Existing status/challenge/complete_no_effect APIs; fixed selected inspector produces exact artifacts, never caller boolean or timestamp. Domain inspector delivery remains gad.b requirement. |
| Concurrent/replayed claim and begin loss | High, canonical integration | Reuse existing actual JournalMutation/Client/Server fixtures; count handler invocations, immutable result replay, lease-expiry truth. |

No new journal/controller, no new privilege, no broad suite containing installed/native tests. Independent source review and exact receipts precede integration.
