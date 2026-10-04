# Independent source review — 2026-10-04

Reviewer: /root/wave3_otp_services_lane, gpt-6.1-sol; author of patch: root. Exact reviewed commit dd97ee1efe55795f1dc2418e5f929e2352df0071. Reviewer used separate worktree .ace-wt/wave4-review-install-proof.

VERDICT: APPROVE. Nine-file diff inspected. Focused source receipt60/172 + manifest23/111 =83tests/283assertions passed (8x3y8r). Reviewer adversarial5tests/11assertions passed (8x3y9a): actual distinct ~>0.2/~>0.3/~>0.4 edges; widened/source mismatch; duplicate edge/header; noncanonical requirement; incompatible provider; multi-constraint ordering/exclusion. Exact source requirement equality is preserved; absent frozen metadata refuses; original failed installed proof is unchanged.

Canonical replay with new frozen input remains required. This review does not accept later changes automatically.

Second exact-head review: a1ffe7328b11a034814c58db491689b9b8ce63d6 APPROVE by the same independent reviewer in a fresh worktree. Executed receipt61tests/174assertions (8x3ycz); literal shell command regression confirmed. Prior dd97 manifest/adversarial verdict retained. Root full monorepo63tests/243assertions passed (8x3yc1). Both reviewed changes are integrated; canonical replay is running against new manifest SHA256 4c9b7be77d08ccaaad90384baec02ebbe4d2746f6c337e42ce431bbd267ff78e, with requirements extracted from each consumer's exact source commit.
