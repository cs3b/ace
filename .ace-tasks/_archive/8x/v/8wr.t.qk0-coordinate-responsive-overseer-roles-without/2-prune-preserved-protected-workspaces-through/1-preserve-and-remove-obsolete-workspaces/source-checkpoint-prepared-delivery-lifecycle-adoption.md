# Prepared delivery original workspace fixture adoption

Integration audit against main65c23e89e found the maintained prepared delivery fixture had never supplied its original lifecycle parent resource. Main whole-file0af7c1d7 failed before provider/release, and its denial assertion was masked by the same prerequisite. Production release remains unchanged.

The successor extracts the existing PreparedWorkFetchTest operator provisioning, readonly parent declaration/identity and production original observer setup into PreparedWorkspaceResourceFixture. Both fetch and prepared delivery reuse it. Delivery composes that setup before reservation and supplies the maintained WorkspaceReader with controlled namespace/filesystem/ACL observations and actual temporary files/flock to PreparedWorker. It does not fabricate workspace_exclusion or relax the canonical original getter. No executable production code changes.

Executed gates on frozen source:

- Full prepared_delivery_flow_test: 3 tests / 132 assertions PASS, reportcfd6e90e-3690-4de3-8659-398b087207c3, reported1m17s, below original120s aggregate budget. Command accidentally specified180s; actual elapsed qualifies within original120s and no deadline contract changed.
- Exact affected fetch release-pin + original issued bytes: 2/27 PASS19.57s, report27c02d42-67c3-45c3-8790-fc3aea80a36a.
- Initial root-relative command159f4561 failed loading existing crosspackage test_helper before any tests (0/0), excluded as cwd/load invocation error. Supported commands ran from ace-assign with ../bin/ace-test, no ad-hoc loadpath or config.

Audit: native admission acquires the host lifetime lease in the original canonical planner before acceptance; cached same observer checks it before StartUnit and closes only original sealed physical proof. PreparedWorker holds its independent readonly lease across queue/provider/RPC. Maintenance exports original projection; actual Lab physical provisioning/effects remain a separate owner scope. No native, root, systemd, installed or process-identity probes. No whole task closure. Independent reviewer verdict required.
