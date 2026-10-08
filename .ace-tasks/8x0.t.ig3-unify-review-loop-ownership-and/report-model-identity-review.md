# Report model identity source checkpoint

The approval reviewer remains the authenticated actor validated against the accepted assignment receipt. Each approval now requires a closed report_models mapping, exactly one entry per unique checksummed report, matching verified session execution metadata. Normalized mappings are persisted and participate in current approval revalidation. No compatibility fallback or second journal was added.

Verification on isolated worktree based on e00141be9:
- Targeted campaign evidence: 13 tests, 73 assertions, zero failures/errors; receipt d87f3db0-1232-46a0-9ae4-7b1a1d0576ec.
- Full ace-review fast: 962 tests, 3006 assertions, zero failures/errors; receipt da41af98-c663-4e3f-8699-74f0d625f44f.
- Independent reviewer /root/wave_n0n: APPROVE source/tests/docs. Checked actor authority, exact one-to-one mapping, normalized persistence and current revalidation; historical receipt authority unchanged.

This checkpoint does not complete R2. Protected campaign execution, child artifact ownership and downstream integration remain required, with existing dependencies retained. Task stays in progress.
