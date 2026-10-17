# Complete preservation digest contract and validation

Source delta against `c93177ab8`, independently approved by `audit_runtime_delivery_status` on 2026-10-08. The exact six-field private preservation packet replaces the earlier file-only schemas. Workspace directories, index and every unique staged blob are part of its bound content. Preview inventory and manifest digests must agree; completed receipts additionally require the private manifest digest to agree. No private paths/bytes are added to public output.

Executed, inspected selections:

- From ace-overseer: `../bin/ace-test test/fast/organisms/protected_prune_test.rb` — 2 tests / 33 assertions PASS, `376a45d6-3f30-474f-8b7c-ecaef38c037f`, 14.17ms. Mismatched preview digest refuses before any submission.
- From ace-lab: `../bin/ace-test test/organisms/protected_cleanup_dispatch_test.rb:482` — 1 / 24 PASS, `2555c966-fd50-4d94-ad21-fc5a4906c9dc`, seed 8941, 64.507638s. Actual authenticated root-result import refuses each mismatched digest with unchanged canonical ref, then accepts the matching result and verifies retained evidence without reopening the deleted source result.
- From ace-assign: `../bin/ace-test test/feat/authority/service_settlement_test.rb:77` — 1 / 36 PASS, `b4003461-3e28-473c-9276-8e59b03b9ec1`, 21.71s. Existing composed authenticated preview fixture uses the same manifest digest.

Reviewer inspected source, canonical specification replacements and raw receipts, with no findings. No native/root/installed probes, private physical capture/removal implementation or whole qk0 completion is claimed. Lab-config owns the physical producer and its complete preview/apply/restoration tests. Final whole-program verification remains open.
