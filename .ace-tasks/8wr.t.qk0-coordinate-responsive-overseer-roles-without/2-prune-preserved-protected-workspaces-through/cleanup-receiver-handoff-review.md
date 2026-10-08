# Cleanup receiver handoff — 2026-10-08

The same root listener forwards a deeply frozen copy of the actual authenticated
socket peer through the internal `receiver_peer:` keyword to Installer execute
and inspect, matching preview. It never reconstructs caller identity from the
historical executor record. Public wire fields and original effect ownership do
not change. Lab Installer revalidation under fresh canonical snapshot and held
exclusions is separate required work in gad.b.

Independent reviewer `review_lab_bootstrap` inspected the two changed code/test
paths and approved this scope. Executed in the isolated worktree, package cwd:
`../bin/ace-test test/organisms/protected_cleanup_dispatch_test.rb:77 test/organisms/protected_cleanup_dispatch_test.rb:411 --timeout 120`.
Report `57e4118b-98e7-4ff2-bf06-76816fc94d34`: **2 tests / 51 assertions PASS**,
40.61s, no failures or errors. Actual socket/admission paths prove execute gets
the original authenticated peer and inspect gets a new admitted process birth
distinct from the canonical original executor; nested data is frozen. Physical
Installer effects remain controlled in these tests, not accepted as implemented.
