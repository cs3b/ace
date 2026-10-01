# Persist review campaigns independently of head receipts — Usage

The implemented interface and complete schemas/examples are in `ace-review/docs/campaigns.md` (packaged with ace-review). In this checkout invoke tools as `bin/ace-review` and `bin/ace-assign`.

| Scenario | Public action | Expected result / control |
|---|---|---|
| Resume across head | Record pinned completed H1 evidence, commit H2, run campaign status in a fresh process | Rounds/streak remain; source/current heads differ; finish rejects stale evidence. Earlier High remains open when absent later. |
| Replay/incomplete scope | Submit complete attempt twice, conflicting replay, then partial coverage | Identical replay counts once; conflict fails; partial work persists without completing a round. |
| Dry-run/old review options | Start with --dry-run; review with repeated model/subject/evidence flags | No campaign state writes in dry-run; existing flag semantics preserved. Empty/mixed subject and contract fail. |
| Mixed-head/concurrent recording | Complete one scoped round concurrently; alter a scope's bound head/base | Count once; mismatched binding fails with accepted history unchanged. |
| Contract successor | Start same contract across commits, then changed requirements with --reason | Same identity for implementation changes; linked successor for changed requirements, retaining findings. |
| Assignment consumption | Finish current campaign and include its result reference in existing review attempt receipt | Coordinator independently validates authority/head/checks/reviewer and journals evidence without advancing candidate. Self-approval, fabricated identity and stale receipt are rejected. |

Executable deterministic scenarios: `bin/ace-test ace-review test/feat/campaign_cli_test.rb` and `bin/ace-test ace-assign test/feat/campaign_receipt_test.rb`. These use controlled execution artifacts to validate the contracts; they do not claim live paid-provider readiness or authorize merge/publication.
