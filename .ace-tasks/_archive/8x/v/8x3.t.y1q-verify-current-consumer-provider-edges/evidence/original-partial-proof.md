# Postpublication RubyGems proof

TS-MONO-001 run 8x3xqd0, checked 2026-10-04. Ruby 3.4.8; 49-package frozen release context b4bcb42a9aa998c67c5552c7d2bf9f31a464f664. Artifact build source f7416cbfc8f51daf26f3fa312ff03cfd12a8ec2d; frozen manifest records the later release context (artifact contents unchanged), not an independent rebuild claim. Manifest SHA256 e17bfdcd0d57a00a9e5b212f7293fefa7d3a920c15c0b75ec6a08580c3681832; source and sandbox copies match.

Normal install exit 0; full-index install exit 0. All 49 context packages resolve and activate exact manifest versions, including all ten newly published artifacts. All six consumer-only installs exit 0 and activate ace-git-github 0.4.0 through their consumer graphs in isolated sandbox gem paths. No global uninstalls or credential mutations occurred.

Classifier: SAFE. Exact acceptance: FAIL. Wrapper: exit 1, PARTIAL 3/4. Host finalizer: FAIL. Four acceptance findings arise because install_receipt.rb:986 hardcodes provider requirement ~> 0.2; published ace-review uses ~> 0.3 and ace-task ~> 0.4, matching current source gemspecs. Their lockfiles declare these real edges, but the predicate reports them absent. Pipeline completion consequently remains partial. Do not claim canonical scenario pass.

Next action: repair the stale consumer-edge predicate with reviewed tests, then replay canonical proof. Preserve original evidence.

Evidence: ../postpublish/final-verdict.json; ../postpublish/wave3-manifest.json; ../test-e2e/8x3xqd0-monorepo-e2e-ts001/results/tc/04/proof.md; ../test-e2e/8x3xqd0-monorepo-e2e-ts001-reports/report.md. Full raw receipts are retained under the sandbox results/tc/02 and /03 directories.
