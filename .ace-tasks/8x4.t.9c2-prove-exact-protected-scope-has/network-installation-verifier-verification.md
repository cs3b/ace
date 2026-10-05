# Local generic network evidence verifier checkpoint — 2026-10-05

Frozen source candidate: `77fd6c51bf0d46c1f67b32e3bb6b5730a91804d6`, based on
`95f1242f64265783f59b7af3b81efda7c563f4e6`. Independent review
[APPROVE](9c2-network-installation-verifier-source-review.md) covers this bounded
generic verifier and the two normative clarification paragraphs in
[the accepted amendment](network-installation-evidence-amendment.md).
Root integrated the exact source commit after review and executed verification.

`NetworkInstallationEvidence.verify!(selection:, expected:)` validates the
closed profile/report/check graph, exact context and referenced bytes through
protected descriptor-held regular files and ancestors. Strict JSON rejects
duplicate keys and comments. Success returns deeply frozen authenticated context.
The exact argument/result shapes and responsibility boundary are documented in
[Runtime usage](../../ace-runtime/docs/usage.md#network-installation-evidence).
Runtime directly declares `json >= 2.20, < 3`; the root lock keeps existing
2.21.2. Installed dependency CHANGES identifies duplicate-key refusal in 2.13.0
and comment refusal in 2.20.0; regression tests verify the features used.
No package version changed.

The outer profile budget counts families + protected_controls + loopback_tools +
credential_profiles. Nested values remain bounded by the closed schemas, byte
budget and transitive artifact graph. Actual fixed executable digest matching is
a domain producer obligation: generic authenticates the declared observation
references without inventing an executable path or comparing its digest to raw
trace bytes. Digest-bearing filenames and immutable historical publication also
remain producer obligations; artifact refs specify no basename grammar.

## Executed verification

All retained full receipts are byte-identical copies of the generated files;
[receipt-index.json](evidence/network-installation-verifier/receipt-index.json)
records their original paths, lengths and hashes. Suite manifests preserve
invocation paths, selected files, targets, summary objects and report hashes;
they distinguish the two configured ace-lab entries.

| Invocation | Outcome | Retained evidence |
| --- | --- | --- |
| `bin/ace-test ace-runtime all` | 235 tests, 833 assertions, no failures/errors/skips | [Author receipt](evidence/network-installation-verifier/author-runtime-all/779661f9-318a-48fa-9fdc-34daa1c3e9d6/summary.json) |
| Initial `bin/ace-test-suite`, default 120-second ceiling | 49 package passes, 2 failed entries; Assign timeout and Lab nil.fetch | [Initial manifest](evidence/network-installation-verifier/initial-120-suite-manifest.json), [Lab failure output](evidence/network-installation-verifier/initial-lab-failure/06375dfd-5073-4f03-b367-8426a4f354a0/raw_output.txt) |
| `bin/ace-test ace-lab test/molecules/protected_service_handler_test.rb` | 3 tests, 7 assertions, no failures/errors/skips | [Focused Lab receipt](evidence/network-installation-verifier/focused-lab/481b28f7-0ace-4ab9-9d8e-67f73df90fd2/summary.json) |
| Independent focused Runtime checks | 28 tests, 174 assertions, no failures/errors | [Independent receipt](evidence/network-installation-verifier/independent-reviewer/8946b94e-92d6-478b-89d0-eba0f018b85c/summary.json) |
| Frozen `bin/ace-test-suite --timeout 300` | 51 package passes; 11,273 tests passed, 24 skipped; 34,612 assertions; zero failures/errors; 130.65 seconds | [Final manifest](evidence/network-installation-verifier/combined-300-suite-manifest.json), [captured terminal chunks](evidence/network-installation-verifier/combined-300-terminal-output.txt) |

Author Runtime all tested the final product source before the commit was frozen;
the 300-second suite and independent review executed at the exact frozen SHA.
The first 120-second suite tested the earlier evolving uncommitted candidate,
before the final EOF refusal/helper/dependency regressions. Its failure remains
a failed run and is not relabeled as a pass. Assign timed out after 120.31 seconds
without a generated report. The failing Lab entry reported
`ProtectedServiceHandlerTest#test_receiver_owned_process_group_cleanup_stops_background_writer`:
`undefined method 'fetch' for nil` at test line42. Focused green and both later
green configured entries establish rerun outcomes; these receipts do not by
themselves prove a failure cause. Root owns the separate Lab fixture diagnosis.
The final suite used the already justified 300-second ceiling and unchanged
configured package targets; its Assign entry completed in 107.48 seconds.

## Delivery boundary

Controlled source fixtures substitute ownership/ancestor trust and filesystem
classification while exercising real descriptors, paths, lengths, bytes and
replacement faults. They are not installed root, namespace, packet-filter or
native enforcement proof. No nft parser, network probe, privileged operation,
namespace pin primitive or actual installer was added. The installed owner must
supply values from its genuinely held namespace descriptor and boot identity;
this content verifier cannot establish descriptor type or lifetime.

This checkpoint does not deliver parent/private/native stage joins, canonical
admission or slot inventory, maintenance exclusion, authority replacement,
domain producer or installed enforcement. All 9c2 success criteria remain open;
status stays in-progress. Source integration precedes interactive publication,
which precedes actual Lab acceptance. No gem publication, Lab deployment or task
completion is claimed.

