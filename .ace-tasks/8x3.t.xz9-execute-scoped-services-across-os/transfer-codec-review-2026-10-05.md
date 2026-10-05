# Independent transfer-codec review — 2026-10-05

Verdict: APPROVE the internal codec for source integration into the shared 09j server. Reviewer: root, independent of endcap author. Scope is exactly `ace-assign/lib/ace/assign/authority/transfer_codec.rb`, `private_directory.rb`, and `test/feat/transfer_codec_test.rb` from `bf72aa6215b6e111610ee2ff6649ecc8104a19cb`; these files are byte-unchanged through `710c68c07`.

Inspected fixed source-purpose limits, strict descriptor shape, per-part and aggregate SHA/size checks, bounded monotonic deadline, required write-EOF before consumer invocation, protected private spool creation/removal, exact binary reads and rejection cleanup preserving unrelated files. The codec does not grant authentication or decide an operation's purpose: the shared source-owned Server/Router must authorize the peer, select the fixed purpose and enforce at most two admitted transfers before reading the body. Full server wiring is not approved by this module review.

Independent command in the endcap worktree: `bin/ace-test ace-assign test/feat/transfer_codec_test.rb`. Receipt `assign/8x42u7`: 6 tests, 31 assertions, zero failures/errors, terminal exit 0. Tests cover exact binary multipart/EOF, short/extra/different payload refusal, missing EOF deadline, purpose/count/size/field refusal, exact export, and spool cleanup on consumer rejection.

09j author may consume these exact files to implement the shared endpoint. The commit also changes CandidateTransfer, which is outside this approval; do not treat the entire commit or full candidate/endcap as accepted. Remaining receiver/service CAS, role admission, native launch, installed privilege and end-to-end Lab gates remain open.
