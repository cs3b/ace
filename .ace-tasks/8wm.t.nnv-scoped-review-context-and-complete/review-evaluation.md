# Historical review evaluation, 2026-09-23

This is a bounded quality and packet-size check for the scoped-review implementation in PR #329. It is not a claim that every historical finding is reproduced or that the current PlayaGo PRs are defect-free. The reviewer was Codex CLI 0.156.1, `gpt-6-sol` with high reasoning, in a fresh read-only session per case. The historical patch was the only code supplied to each session; no present-day checkout was inspected. Ground-truth claims were taken from the documented PR #140/#145 fixes before running the controls.

## Complete-PR input and scope pressure

| PR snapshot | Whole diff | ACE full-packet dry run | Focused historical patch used for quality check |
|---|---:|---|---:|
| #140 current, head `67ea19e8`, base `742d45ed` | 188 files, 829,400 bytes | ~276,463 input tokens; rejected above 128,000 | Pre-foundations route/i18n slice at `2764e3d2`: 14 files, 38,090 bytes, ~11,903 diff tokens |
| #145 final, head `da0a35d6`, base `25f6204c` | 114 files, 2,711,212 bytes | Selected diff alone ~847,254 tokens; rejected above 128,000 | Initial dev-environment code slice at `e1c6279d`: 14 files, 87,151 bytes, ~27,234 diff tokens |
| ACE #329, head `aacdcfbb5` at the time of check | One coherent ACE change | Complete rendered packet ~81,417/128,000 tokens; accepted | Small-PR control of the packet gate |

Token figures are the ACE conservative character estimate, not provider-billed tokens. For #140, `.ace-*` artifacts account for ~67k estimated diff tokens and lock/generated files ~14k. Traveler-web alone is ~129k; a single directory is therefore not automatically a viable scope. For #145, seed records and published payloads account for ~761k estimated diff tokens; implementation plus tests is ~79k. Those data files still require explicit validation or review disposition. Removing them from a code lens does not make them covered.

The cross-repository CLI test initially failed because `gh pr diff owner/repo#number` treats the qualified reference as a branch. PR #329 now invokes `gh pr diff number --repo owner/repo` and fetches oversized fallback revisions from the selected repository. A 2.6 MB diff then exposed the bundle reader's 1 MB file limit; the selected-diff preflight now returns the actionable 128k budget error before bundle processing. The complete file inventory is verified first.

## Defect and control outcomes

| Case | Expected representative claims | Observed result |
|---|---|---|
| #140 before routing/i18n foundations | Locale routes duplicated; UI labels hardcoded instead of admin-published per-locale catalog | **0/2 found spontaneously.** Reviewer found five other concrete route concerns, including a hardcoded Spanish locale, inconsistent published-route resolution and legacy map aliases. The two architecture issues need a product-aware architecture lens and accepted requirement context. |
| #145 before feedback rounds | Manual draft protection; per-worktree Vite config isolation; safe restore; selected environment port | **4/4 representative classes found.** Reviewer also found `--only` import scope and importer-status concerns. Findings require normal code verification; this exercise records model detection, not automatic acceptance. |
| #140 after foundations, focused control | Old per-locale homepage duplication; old hardcoded-only UI catalog | **0/2 false positives.** Reviewer contradicted both claims, citing the shared locale route and published UI catalog read. |
| #145 after feedback, focused control | Old manual draft publication; old destructive prevalidation restore | **0/2 false positives.** Reviewer contradicted both claims, citing ownership checks and staged restore. |

The broad post-fix #140 route slice still produced other findings. It is not a clean no-defect control, so those findings are not included in the false-positive count. The focused controls measure only the six resolved claims above. The #140 before run demonstrates a real recall gap; project presets must explicitly ask about route-template duplication, localization source of truth, and admin → publisher → frontend boundaries. Upstream ACE supplies scope, provenance and completeness mechanics, not PlayaGo's product judgment.

## Cost, latency and limits

The focused patch diff alone is ~95% smaller than the corresponding whole-PR diff estimate in each historical case. That is a *per-scope input proxy*, not total PR cost: all required scopes, shared context, integration within each round and reruns count toward the total. The #140 before Codex CLI run reported 28,671 total tokens and took about 45 seconds; its focused post-fix control reported 10,931 total tokens and took about 24 seconds. The #145 before run took about 89 seconds. The CLI did not provide an input/cache/output token split or a billed currency amount for all runs, so monetary savings and provider-cache effects are **not measured** here. They must not be inferred from diff bytes alone.

The test is intentionally small: one model, one run per case, no randomized repetitions, and selected historical code rather than full integration. Treat the observed counts as diagnostic examples, not statistical recall or false-positive rates. A later product-aware review of the PlayaGo consumer presets should repeat these cases with the actual project context and record actual model metadata, provider usage and cost when available.

## Review-loop simplification

The initial implementation added current-head certificates and repeated final review. Real use of PR #329 showed that small fixes invalidated every prior scope and made each new review another opportunity to expand scope. That design was removed after user feedback. The shared agent workflow now uses minimum three completed PR rounds, ending after two consecutive rounds without confirmed P0/P1, with integration inside each round and no SHA-driven resets. Earlier benchmark observations above remain historical evidence, not a guarantee of review quality.
