# Bounded positive receiver listener checkpoint

This partial source slice composes ProtectedServiceClient, ProtectedServiceListener and the existing Receiver/Worker with actual canonical request_service. It does not deliver the root owner entry, root identity admission, physical pruning or result inspection. All task success criteria remain unchecked.

The installed mapping selects the positive executor endpoint and credentials. Control JSON is strict and closed; transfer bytes use the existing service_input owner and explicit EOF. All ingress rejects ancillary descriptors. One absolute monotonic five-second budget covers peer selection, upload, canonical claim and claim ACK. Invalid input and busy capacity refuse before canonical mutation. Lost claim transport is uncertain, never a no-effect proof. The listener owns its endpoint-specific lifetime flock until its admitted worker actually exits; stopping admission cannot release it early. A new listener instance replays the original canonical request without another handler.

Executed source tests (injected identity/protection observations, ordinary temporary Unix sockets/flock/Git; no root/native/installed probes):

- Final `bin/ace-test ace-lab ace-lab/test/organisms/protected_service_listener_test.rb --timeout 180`: **2 tests/43 assertions PASS**, raw duration **28.209764s**, receipt `586f5952-6a96-4e45-9caf-4723783a4b46`. Covers genuine canonical accepted claim/completion/restart replay; busy zero effect; first deadline expiry then healthy listener; decoded duplicate/float version/trailing input; real SCM_RIGHTS refusal; shutdown while handler active retains lock and endpoint.
- `bin/ace-test ace-lab ace-lab/test/organisms/protected_service_boundary_test.rb:176 --timeout 180`: **1/8 PASS**, receipt `2fbb7ec4-04d0-4145-ba45-4e1b219664c8`. Canonical claim transfer timeout has no accepted claim, callback or handler.
- Prior unchanged receiver-capacity foundation full boundary file: **4/54 PASS**, raw76.598515s, receipt `02e0e431-e7cf-4ac2-be08-3619fd8cc605`; independently approved/integrated by root.

Retained failing runs: test-only Thread syntax load failure; `dc2c3d1d` exposed nil stream EOF in recvmsg and was fixed; `f4c7d5e2` exposed actual TransferCodec Timeout escaping the intake loop and was fixed by specific transport timeout classification. Passing successors `31849f08`2/16, `d3edd073`2/22, `f84e21d1`2/34 preceded final restart replay coverage. Summary duration0ms is a reporter defect; durations above come from raw test output.

Independent source review requested at the frozen checkpoint. The separate root-entry-provenance amendment is a candidate and is excluded from this source commit.
