# Prepared delivery integration — 2026-10-08

## Regression resolved — main `c055e9a09`

Root independently approved fixture-only `b3c111807`, integrated as `c055e9a09`: the existing maintained original workspace provisioner/observer helper is shared with prepared delivery, and PreparedWorker uses the actual workspace reader with controlled OS boundaries. Production release validation and intended authorization assertions are unchanged. Root reran the complete file from ace-assign with the original `--timeout 120`: **3 tests / 132 assertions PASS**, no skips/errors, 1m20s, report `.ace-local/test/reports/assign/a75c65c8-d59a-4c15-888d-efe1be31db27/`. This supersedes the current-regression status below; that failed receipt is retained as history. It restores bounded SC2 integration evidence, not whole qkb.1 acceptance.

## Current integration regression — main `65c23e89e`

The earlier `70a391ce2` result below remains evidence for that revision only. After original workspace/control integration, root reran the same complete file with `--timeout 120`: **3 tests / 20 assertions, 1 failure and 1 error**, report `.ace-local/test/reports/assign/0af7c1d7-3364-4c4f-8acf-c3ce0f79efd9/`. Both failures stop at `ExecutionScopeNativeOwnerFixture#workspace_exclusion_projection!` with `fixture original lifecycle resource missing`, reached through `LaunchLifecycle#release` from `ProtectedMergeFlowFixture`; the authorization-denial scenario therefore does not reach its intended boundary. The fixture-adoption owner is repairing this exact original resource join without weakening production release checks. Current-main SC2 integration proof is pending that repair and rerun.

Separate maintained registration/parent-cap regression checks passed **5 tests / 84 assertions**, report `.ace-local/test/reports/assign/b2281831-5d49-4edd-929d-b4183747e8a3/`. These do not substitute for the failed delivery scenario.

Independent reviewer `review_lab_bootstrap` approved frozen `375e69468` and
`250c55d67`: captured shipped child, original PreparedWorker/queue, actual public
request/status and canonical delivery consumption, then queue completion. Actual
policy denial keeps the child unfinished and makes the worker refuse completion.
The provider boundary is controlled Ruby, not an external LLM/tool subprocess.
The shell default rewrite preserves behavior without relaxing template validation.

Root integrated these as `d3b71575c` and `70a391ce2`. On `70a391ce2`, from
ace-assign, `../bin/ace-test test/feat/prepared_delivery_flow_test.rb --timeout 120`
passed **3 tests / 132 assertions**, no skips, seed58553, 70.76409s. Report:
`6488e119-08ff-4aac-8cba-7b3efa00e07d`. Raw output confirms the actual child
delivery, authorization-denial, and pre-registration capture methods executed.
The process remained live during buffered silence and was not restarted.

These results satisfy the deterministic integrated-assignment proof required by qkb.1 SC2. They do not close qkb.1: unresolved PR-order policy, physical cleanup, and the remaining dependent source contracts still need their own evidence. The controlled Ruby provider is an explicit evidence boundary, not an additional unimplemented source requirement. Actual installed external-agent and cross-user workflow acceptance remains exclusively gad.2.

Independent scope audit by review_lab_bootstrap on 2026-10-08 confirmed that the canonical SC2 permits deterministic workflow fixtures and one integrated assignment run, and that the central acceptance amendment assigns installed scenarios to gad.2. No accepted requirement mandates an extra shipped-LLM-agent/tool-loop source gate. The earlier checkpoint wording incorrectly elevated this evidence limitation into a source blocker; this correction removes that invented gate without claiming installed proof.
