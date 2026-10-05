# Primitive source repair — 2026-10-05

The source-only primitive candidate `793a21c2f04836f6a6cd94282b7d2e1138781241` was imported onto the delivery-integrated main in `codex/wave5-journal-repair`. Both independently verified P1 findings are repaired here; acceptance awaits independent exact-head review.

- `8x40rw7e`: all journal writers synchronize the disposable checkout to the accepted ref and remove untracked execution/evidence transaction files. A failed writer cleans under the same lock before releasing it. Real Git index-lock staging failure followed by append, record or service claim cannot admit rejected mutation events, reply or blob. All four writer entry paths discard abandoned files. Candidate checkout is untouched.
- `8x40rw7f`: intent-only remains reserved. Resume reports reconcile-required and preserves ownership. Reconcile explains that protected launch recovery needs positive no-execution/no-surviving-writer proof; start refuses an unresolved reservation rather than reusing or launching another writer. Journal state overrides stale cached state. Missing process-start history never proves no execution. The obsolete taskless missing-start-to-stopped assumption is removed too.

Fail-before: `8x410m` reproduced restart-required for an intent-only reservation; corrected staging regression `8x411p` (8 tests / 62 assertions, one failure) reproduced admission of rejected events after a real git-add failure. Initial staging fixture placed its lock too early, causing checkout rebuild instead of staging failure; the corrected injection installs the real lock after event files are written. Repeated writer cases use isolated repositories.

Focused repaired source: `bin/ace-test ace-assign test/feat/journal_mutation_test.rb test/fast/organisms/attempt_coordinator_test.rb test/fast/molecules/attempt_reconciler_test.rb test/fast/molecules/evidence_journal_test.rb test/fast/molecules/canonical_evidence_test.rb test/fast/commands/resume_test.rb` => `8x416m`, 85 tests / 455 assertions, zero failures/errors, 1m27s.

Full Assign verification runs on the frozen candidate; its actual final receipt is required separately. No protected authority, positive abort path, distinct-UID or installed acceptance is claimed. 09j owns those producer requirements. No task is marked done and no release is prepared or published by this repair.
