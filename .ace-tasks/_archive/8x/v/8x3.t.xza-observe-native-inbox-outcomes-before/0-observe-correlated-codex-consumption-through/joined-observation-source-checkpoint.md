# Joined producer/signer source checks — 2026-10-08

Temporary dependency assembly based on primary 33b432e6c in
/tmp/ace-observation-joined-flow, copying only root producer/CLI/context/signer
source and signer test changes. Root-owned context/CLI files are excluded from
this commit. Tests reuse the maintained Endcap journal/context fixture and real
RSA signatures; native completed-turn query, installed credentials and protected
key reader are controlled source seams. No installed/native evidence is claimed.

Failure analysis: report 08130bf9-484f-43e4-9168-908e834f6ea8 identifies
implementation-bug in InboxObservationProducer runtime selection. Herdr retains
agent_status alongside payload_sha256 in the full binding; fixed native_target
has exactly the six target fields. Removing only payload_sha256 left
agent_status, causing legitimate retained bindings to report ambiguous runtime.
Fix target/layer: producer selection, using existing ObservationTrust::TARGET,
matching the canonical issuer's same projection. Confidence: high. Do not touch
native transport, issuer trust, root startup/ACL or unrelated context/CLI files.
Earlier joined fixture defects (missing original binding digest and instance
query seam lost on owner Inbox recreation) were corrected in the test layer.

Executed checks:

- bin/ace-test ace-assign feat test/feat/endcap_observations_test.rb:
  5 tests, 59 assertions, pass in 37.36s; report
  d5fcddfc-7d2f-40cb-ab19-59485f374c35.
- bin/ace-test ace-assign fast test/fast/authority/inbox_observation_signer_test.rb
  test/fast/commands/inbox_settle_test.rb: 6 tests, 47 assertions, pass in
  8.56ms; report adcee12c-6668-41b6-83c6-c429af4761ec.
- git diff --check passed.

The actual joined tests cover import association, owner-native correlation,
uncertainty, rejected candidate association, lost canonical import response
retaining the existing admission, unchanged mutation retry, lost reconciliation
reply retaining signing admission, identical deterministic receipt/signature
bytes after completion, canonical journal deduplication and no resend.

The producer patch was relayed to root and adopted there; temporary copied
producer/signer/context/CLI source is excluded from this test commit. Root owns
committing the public flow. Whole-task status, installed acceptance and one final
combined independent review remain open.
