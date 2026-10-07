# Protected artifact directory identity source checkpoint

Existing 9c2 protected-artifact owner correction, 2026-10-07. Parent root independently approved the precise contract before implementation: directory snapshots retain dev/inode/uid/gid/mode, regular files retain those plus size/mtime/ctime, at both opening and final verification. Every held descriptor and pathname identity is rechecked and Protection.verify! remains mandatory. Exact inventory owners are unchanged. CanonicalReadSnapshot already uses the same stable directory identity contract.

This repairs actual unrelated /private/tmp sibling mutation refusal in the Lab composed fixture without exempting fixture protection. Existing selected-file SHA/bytes, bounds, nofollow and protection remain unchanged. No filesystem/native/root probes; tests use controlled protection and real owned temporary files.

Executed bin/ace-test ace-runtime/test/molecules/protected_artifact_set_test.rb: PASS18 tests/76 assertions, receipt8ee4e208-32ab-4a1a-986d-a64bc4704273,126.06ms. New actual-filesystem cases cover unrelated sibling create/delete acceptance, directory replacement/chmod refusal and selected regular file content/replacement refusal. diffcheck clean. Independent final source review pending; no installed/whole-task acceptance.

Independent root final source verdict APPROVE exact four-path checkpoint: all pin/verify call sites, directory identity, unchanged regular metadata/protection and real-file positive/negative regressions reviewed. PASS18/76 supports this bounded source correction only.
