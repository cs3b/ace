# Source repair evidence — 2026-10-04

Original run 8x3xqd0 remains PARTIAL with failed exact acceptance. This patch binds declared consumer requirements to a new frozen manifest rather than weakening edge validation. Existing widened-edge negative test stays green. New tests reproduce different ~>0.2/~>0.3/~>0.4 consumers resolving provider0.4.0 and reject missing/malformed, duplicate or incompatible requirements.

Executed source tests via bin/ace-test:
- ace-monorepo-e2e all: 62 tests, 241 assertions, zero failures/errors; receipt 8x3y73.
- ace-test-runner-e2e all: 652 tests, 2179 assertions, zero failures/errors; receipt 8x3y7a.

Independent source review and canonical replay with a newly frozen source declaration manifest remain required. No gem published.
