---
id: 8wr.t.qkc.0
status: in-progress
priority: high
created_at: "2026-10-08 15:30:37"
estimate:
dependencies: []
tags: [ace-review, forge-neutral]
parent: 8wr.t.qkc
---

# Accept forge-neutral URLs in typed review PR subjects

## Observable result and ownership

Owner: ace-review. Typed `pr:REFERENCE` inputs validate with the same `Ace::Git::Atoms::PrReference` parser used by the forge-neutral lifecycle. Numbers, owner/repository references, GitHub `/pull/` URLs and Forgejo `/pulls/` URLs retain their explicit target; no server lookup, network call or inference of github.com occurs during parsing. Zero PR numbers and unrecognized references fail before bundle extraction. Actual endpoint/server identity validation remains the provider lifecycle's responsibility. No archived qk1 result is expanded retrospectively.

## Delivered source and acceptance

- [x] Replace GitHub-specific prevalidation/require in SubjectExtractor with the existing neutral parser. Source commit `9b9d72d65`.
- [x] Exercise both Forgejo URL forms, named port/base path, zero and malformed identifiers alongside existing subject behavior. `bin/ace-test ace-review test/fast/molecules/subject_extractor_test.rb`: 91 tests / 182 assertions PASS, receipt `bbda106c-0e4a-4a88-943a-1e8739d73d19`.
- [ ] Include exact source and this case in the one final independent integrated review.
- [ ] Integrate main and include owning package in the prepared release batch.

This was found during qkc coupling inspection. It is a small source correction, not another installed Lab test. No remote query, PR operation, model call or deployment was performed. The task stays in-progress until the remaining delivery gates pass.
