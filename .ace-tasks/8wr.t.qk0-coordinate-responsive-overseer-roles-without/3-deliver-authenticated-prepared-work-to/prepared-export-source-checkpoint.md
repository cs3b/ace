# Prepared artifact export source checkpoint — 2026-10-07

The existing CandidateTransfer owner now exports a validated immutable PreparedWork tree through its existing isolated Git environment, fixed executable, deadline, private temporary storage and bounded bundle reader. It returns the exact complete bundle bytes, their digest and length, Git head/tree and the derived final definition. Registration callers must retain those bytes, never regenerate them after response loss.

Executed `bin/ace-test ace-assign feat test/feat/prepared_work_transfer_test.rb`: **4 tests, 45 assertions, zero errors/failures**, 2.68s, receipt `f6a0cb58-0997-4e0b-8a8e-c7e017e7cbf2`. The production exporter round-trips through actual CandidateTransfer/PreparedWork admission in a clean separate quarantine; exact files, selection, final definition and cleanup agree. Existing executable-file rejection and managed graph/queue checks remain green.

Independent reviewer review_lab_bootstrap: **APPROVE** exact exporter and round-trip diff. Checked immutable inventory, fresh private path writes, isolated Git configuration/environment/hooks, complete branch bundle, bounded read, retained bytes/digest/definition and cleanup. No actionable defect; no reviewer probes.

This is an exporter checkpoint, not qk0.3 completion. Production managed task/context/report capture, its public launch composition, Lab command publication and held worker entry remain unfinished. Native/installed acceptance remains lab-config:gad.2. No test here proves installed execution or native identity behavior.
