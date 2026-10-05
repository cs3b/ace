# Lab protected handler fixture diagnostic

Read exact verifier candidate `77fd6c51bf0d46c1f67b32e3bb6b5730a91804d6` in own isolated reviewer checkout. No source edits. Verifier APPROVE unchanged.

Verified fixture protocol race: `ace-lab/test/molecules/protected_service_handler_test.rb:27,41` success shell scripts never read the JSON envelope from stdin. Handler `ace-lab/lib/ace/lab/molecules/protected_service_handler.rb:29–38` writes the complete envelope before closing stdin and rescues IOError/SystemCallError (including EPIPE) as nil. The success script may print the correct receipt and exit, closing its input pipe before the parent writes. Scheduler/load changes can therefore turn this purported success fixture into transport failure. This explains a concrete nil-return path; original receipt has no captured EPIPE stack because production intentionally rescues it. Do not claim the historic exact scheduling was reconstructed.

Original failed receipt retained: author worktree .ace-local/test/reports/lab/06375dfd-5073-4f03-b367-8426a4f354a0, failure test_receiver_owned_process_group_cleanup_stops_background_writer: nil.fetch at line42. Focused rerun3/7 and later full configured suite passing do not invalidate this race.

Controlled ordinary executed diagnosis:
`bin/ace-test ace-lab molecules /Users/mc/Ps/ace/.ace-wt/review-9c2-runtime/.ace-local/review/handler_stdin_boundary_test.rb`

7 tests /16 assertions PASS, receipt `ff0a276b-218d-4c69-9938-6dd4e2f6ca8d`. Actual handler/Open3/sh/filesystem, actual valid receipt. A256KiB controlled input makes failure deterministic when the child prints and exits without consuming the envelope; identical handler/input/reply succeeds with `cat >/dev/null;` first. This amplifies the existing observation hazard, not a claim the historical small envelope filled the pipe. Inherited original tests also passed in this run.

Smallest correct fixture correction: prepend `cat >/dev/null;` to each success script, before environment check/output and before spawning the background writer. Then the child consumes the actual input through EOF before reporting success. Parent completes its write and closes stdin, so EOF provides protocol synchronization without arbitrary added sleep. Keep the background writer/process-group cleanup assertion intact. No production EPIPE relaxation or blind success from valid stdout is justified; nil transport failure remains fail-closed. The noisy/mismatched negative fixtures may still fail, but consuming input there too isolates their intended stdout/refusal reasons if touched separately.

No native, system-manager, privilege/security/network probes or broad duplicate suite. No change to77fd source verdict or package versions.
