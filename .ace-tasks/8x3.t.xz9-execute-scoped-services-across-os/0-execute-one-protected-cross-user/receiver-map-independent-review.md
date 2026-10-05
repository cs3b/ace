# Installed receiver mapping — independent source review

2026-10-05. This is a source checkpoint within xz9.0, not installed receiver
acceptance or completion of the parent task.

Initial source 7f0f28eea was rejected by an independent GPT-6.1 Sol review
(`receiver-map-7f0-readiness-round1`): authority traversal did not establish
executor traversal. A root-owned ancestor accessible only to the authority's
group could pass while denying the executor access to its own staging.
The root reviewer confirmed that defect against the implementation. The
reviewer's broader authority run was stopped and supplies no passing evidence.

Repair 731c7c9cf adds bounded Linux access-ACL inspection for the fixed executor
UID and groups. Unknown, unreadable or malformed ACL state refuses; only
ENODATA permits ordinary mode-bit evaluation. Current authority inspection,
protected ownership, symlink and writable-ancestor checks remain.

Independent repair review `receiver-map-731-acl-round2` completed with
**APPROVE, zero findings** and 15 tests / 71 assertions passing. Root read the
report and inspected the repair against the primary ACL semantics. Author
focused checks passed 19/93; the task-owned receiver-acl evidence records four
actual Linux discretionary access comparisons. The review on macOS substitutes
ACL retrieval and does not itself prove native Linux or receiver readiness.

Combined source f2beb66b204740761264a8ef260b7d8610cbbecf includes accepted main
915aafa1a and leaves the reviewed deployment/server/ACL source byte-identical.
Its ordinary full Assign run completed successfully: **905 tests, 4032
assertions, zero failures/errors, two existing skips**, receipt `8x47hb`.
Root read the success summary. No timeout override was used.

**APPROVE for source integration.** Search permission is not a claim of bind
readiness, LSM permission, a live executor, effect authorization, or full service
acceptance. Receiver startup must perform its actual private-directory/listener
checks; the installed cross-user receiver remains a separate open gate.
