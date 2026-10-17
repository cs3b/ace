# Configured independent review classification

The retained raw report reviewed source `d5b11b93ebb384ebe04d6f4c6ae57e4ea2c29bef` with actual Pi `zai/glm-5.3`, high, read-only. Its no-critical/blocking wording did not waive the valid Medium item.

- Medium rescue scope: reproduced with the real canonical collection fixture (1 test, 9 assertions, 1 failure). Proof construction now owns its own KeyError/TypeError rescue. Consumer exceptions retain identity and reader lifetime still closes on exceptional exit. GREEN: 1 test / 20 assertions.
- Low reference mismatch classification: split exact result ID/digest comparison into ReceiptRejected after terminal evidence validation; both mismatch cases are executed in the same regression.
- Low formatting: fixed the missing method separator.
- Optional named predicate: proof construction was extracted to a named helper and result-reference checks separated. The remaining conjunction represents one exact terminal-evidence invariant, so no new predicate indirection is introduced.
- Optional cancellation helper: declined as a design choice. Latest-candidate selection and exact historical selection intentionally have distinct selection semantics; their small cancellation predicates stay explicit.
- Suggested failed-collection/dry-run scenarios remain the existing terminal-state and store transaction contracts; this diagnostic delta changes neither. The focused original reservation/store tests were rerun (16 / 108). A full Review fast run completed against d5 before this fix (1007 / 3327); no new full-suite claim.

This is a source execution-evidence prerequisite. Campaign composition, configured provider ingress, accepted-head consumers and installed acceptance remain open under ei9.8. The fresh delta verdict is recorded separately after completion.
