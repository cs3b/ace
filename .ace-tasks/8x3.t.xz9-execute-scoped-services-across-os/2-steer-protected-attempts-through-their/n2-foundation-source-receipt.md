# N2 additive source foundation

This checkpoint adds closed original native guard capture and prompt/drain decoding, bounded private prompt framing, canonical durable prompt issuance with journal-wide external-ID uniqueness, and fixed issue-authenticated immutable completion. It preserves maintained launch process-binding bytes and verifies the actual LaunchDriver/readiness callback path. It does not activate public steering, the retained foreground channel, canonical guard recording, or stopped terminal projection. xz9.2 remains in progress. Channel WIP files are excluded.

Executed source selections on the frozen checkpoint tree:

- Herdr guarded_native_origin_test.rb and protected_native_control_test.rb: 12 tests/67 assertions, PASS, 40047e46-cf00-4832-8030-f56181fafe5a.
- Assign transfer_codec_test.rb, prompt_intent_test.rb, journal_mutation_test.rb and completion_generation_test.rb: 58 tests/559 assertions, PASS, 6dbf947d-d60b-4f87-8f84-ed98b9e1618f, 1m43s.
- Assign full inspected launch_lifecycle_test.rb: 22 tests/175 assertions, PASS, 392fb5d1-ba46-45eb-bf83-8e3ae38bed81, 3m16s.

Tests use controlled native/kernel/manager boundaries, actual immutable Git/CAS and bounded socket framing. No installed/native/PTY probes or unfiltered/default suite was run. Earlier mixed-ref regression failed and was repaired by consistently reading the selected old commit before CAS; the final selection above passes. Independent exact-candidate review is required before integration.

## Strict shared wire follow-up

ProtectedSocket.read now rejects raw duplicate keys at any nesting, invalid UTF-8, comments and excessive nesting, preserving exact held frame bytes and subsequent frame boundaries. Controlled raw UNIXSocket tests PASS5/12 (96ef8d05-aec6-4913-b01d-962b866f31f3); private codec regression PASS15/98 (5c73d88e-d184-4f6a-b617-190d9e5675b1); native decoder selection PASS9/50 (0616afc8-ded1-4703-b9a9-922f5f292fd1). Generic reader repair requires separate independent review.
