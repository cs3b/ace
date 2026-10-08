# Combined source verification, 2026-10-08

Default `bin/ace-test-suite` at unchanged main `6a6a36cbd` completed in 147.53s: 45 package entries passed, six failed; 10,576 tests passed, 14 failed/errors, 32 skipped. Not a release acceptance. ace-lab is registered twice in suite.yml and both entries timed out; ace-assign also timed out at 120s. Do not hide those failures by reporting only narrow green tests.

Other failures: Git ServiceMergeTest lost registered providers (`git/c2cad9a3-960a-4448-8960-b5b22cd98a77`); OpenCode three obsolete parser calls (`llm-providers-cli/af3a1216-164c-4097-9190-576b3b4041ad`); overseer installed-workflow fixture omits required ace-runtime dependency (`overseer/d4ecfb16-2a29-471b-b826-600425b9d919`). Each requires fixture/source classification before repair; no claim that all are historical or environmental.

OpenCode repair: test-defect classification against current typed CaptureResult parser, replacing only the three obsolete calls. All assertions preserved, no compatibility API added. Edge file 55/107 PASS with 10 skips (`d0773f3a-5085-4d4f-8fc6-c019d95e3139`); package fast 452/1140 PASS with 10 skips (`ff8c1f23-0f44-4b37-8a2b-d9b47fac2f89`). Independent audit_runtime_delivery_status APPROVE. Remaining package failures and aggregate timeouts are not closed by this repair.
