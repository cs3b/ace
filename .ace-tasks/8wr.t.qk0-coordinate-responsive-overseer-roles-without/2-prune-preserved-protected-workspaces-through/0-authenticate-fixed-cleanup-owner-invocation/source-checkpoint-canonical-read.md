# Canonical read snapshot and fixed root self observation — source checkpoint

Scope: existing EvidenceJournal read-only command/blob boundary, operation-private canonical Git snapshot, and fixed root self-observation. This does not deliver actual root listener admission/action/recovery or the Lab direct entry/unit. Whole qk0.2.0 remains in progress; no SC/status promotion.

The reader copies the fixed installed source under existing shared journal flock, checks exact original loose/packed ref and held source metadata, then releases the source lock before using the private view. It never executes source config as repository settings, follows object redirects, truncates history, writes source refs/admin, or persists another accepted journal. Current policy admission remains distinct; source advance after copying cannot invalidate an authenticated immutable prefix. Fixed 256 MiB/4096-entry/deadline exhaustion is typed unavailable, never success/no-effect.

Actual source paths: new `ace-assign/lib/ace/assign/molecules/canonical_read_snapshot.rb`, narrow read-boundary branches in EvidenceJournal/JournalMutation, and `ProtectedCleanupOwnerIdentity#observe_self!`. The two raw blob readers were explicitly audited/coordinated with the prepared owner; ordinary byte/admission paths stay unchanged.

## Executed selected evidence

- Pre-lock-review Assign snapshot + maintained JournalMutation + maintained EvidenceJournal: `bin/ace-test ace-assign ace-assign/test/feat/canonical_read_snapshot_test.rb ace-assign/test/feat/journal_mutation_test.rb ace-assign/test/fast/molecules/evidence_journal_test.rb --timeout 180`: **44 tests / 448 assertions / 0 failures/errors**, **59.49 s**, report `d997d0f8-fa59-4d92-a3ab-7ad3c989445c`.
- Final fixed root observer target: `bin/ace-test ace-lab ace-lab/test/molecules/protected_cleanup_owner_identity_test.rb --timeout 180`: **11 / 60 / 0 failures/errors**, report `c27e71e0-d2d3-4b16-9d2e-4b64fb2ed2a2`. Summary 0 ms is not timing evidence.
- Earlier real snapshot/read owner gates: 28/219 PASS `931383c3-fd50-47f6-a3a9-1c93efb66689` (32.75 s); raw binary reads + maintained owners 42/391 PASS `89526b16-b1e0-461c-8f34-76497149163f` (52.22 s). These precede final backend parser tests/directory precision and are scoped earlier evidence.

Controlled tests use actual temporary files/Git/object copies/bounded processes/flock; root kernel/manager/installed identity remains injected. Positive source cases cover loose and repacked objects, packed references, inert includes/malicious source loader config, complete event/introduction/prefix owners, binary raw/bounded reads, source advance vs pinned copy, source writer refusal and empty private view cleanup. Negatives cover symbolic references, storage redirects, corrupted Git objects, fixed byte/count/deadline bounds, changed ref/lock during copy, busy snapshot, shared lock exclusion, private parent exposure, mixed-case unsupported backend and duplicate format declaration.

Final pre-freeze review repaired the lock open through the same `held_file!` boundary: NONBLOCK, regular-file/128-byte bound, held full ancestor identity checks and unchanged lock identity. Actual FIFO without writer and symlink checkout ancestry refuse. Affected snapshot target after repair: **11 tests / 196 assertions / 0 failures/errors**, **32.39 s**, report `f5276045-8b9a-4806-9f03-1003c878ecdb`. Other source bytes remain as tested by the selected owner matrix above.

## Retained failures and repair

- `d88fd837-a29b-4de0-850e-c23933f65825`: 4/49, one fixture failure and one error (reuse of class-level temp cache across repeated fixture blocks; nonexistent stub_const). Replaced with unique per-fixture directories and real sparse-file bound check.
- `2419da33-2b74-49e3-ade8-0bf1695a5f93`: 4/55, repeated fixture setup commit failure; exact argv/status identified class cache reuse, not snapshot behavior.
- `37a17727-c9a0-4684-ab89-c15d047b817a`: 4/63, fixture EACCES while deliberately overwriting a read-only Git object. Explicit controlled chmod before tamper.
- `0e3f5ef2-848f-453e-b06d-f63c09b49684`: 44/430, one source_changed error from recording shared ancestor directory size/mtime/ctime. Root-reviewed correction retains directory identity/owner/mode and exact selected inventory/file/ref checks; final expanded matrix above passed.

Independent readiness is retained in `root-canonical-read-source-contract-candidate.md`. Independent source verdict for this checkpoint is still required. Tests are on the own branch before final current-main integration; no default/unfiltered suite or native/installed acceptance claim.

## Remaining actual producer/consumer work

Actual fixed root listener must combine positive installed receiver authentication, self observation and original canonical request/started dispatch before invoking the fixed Installer cleanup phase once; replacement may only inspect/recover. Lab same-Assembly direct interpreter/entry/full closure/unit and clean original startup environment producer remain undelivered. Manager environment observations after startup cannot prove a clean original load. Root effect, immutable result publication, operation-specific inspection and full recovery composition remain required; imported SDK result bytes alone are not physical-cleanup proof.

## Private-root review successor

Independent root review of `13cb79d6e` found leaf-only private-root validation insufficient. Existing `Authority::PrivateDirectory.verify!` now validates every ancestor before creating the private view and again before private writes; retained leaf identity must still match. Refusal becomes typed snapshot unavailable. Controlled writable/symlink ancestor negatives assert no private files created. Final affected target: **12 tests / 212 assertions / 0 failures/errors**, **13.4 s**, report `eb893911-3f2b-4496-b8f2-df56e1108288`. This supersedes leaf-only source acceptance; prior receipts remain historical evidence. Independent successor verdict pending.
