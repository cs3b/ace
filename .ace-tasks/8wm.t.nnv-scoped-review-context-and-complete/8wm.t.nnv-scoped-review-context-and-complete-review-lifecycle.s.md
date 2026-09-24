---
id: 8wm.t.nnv
status: in-progress
priority: high
created_at: "2026-09-23 15:46:31"
estimate: 
dependencies: []
tags: []
github_issue: 321
---

# Scoped, budget-aware context and complete review lifecycle

## Outcome
One ACE-owned workflow gives coding agents and reviewers the relevant project knowledge and a complete high-level review scope, without loading the whole monorepo. Projects configure their domains; they do not implement a competing review engine.

## Approved policy
- High-level product modules (admin, public app, each website, backend/publication, shared packages, infrastructure/tools) OR functional views (whole UI, architecture/code without tests, implementation with tests, tests/coverage). Compose module + view when useful. Do not automatically execute every combination.
- Project + selected-scope context ideally below 20k tokens, maximum 30k. Review instructions ideally a few thousand, maximum 30k. Whole prepared input maximum 128k. These are ceilings, not targets.
- Up to 128k, review a coherent change whole. Above it select declared high-level scopes. Never silently slice by arbitrary file counts, routing components or hunks; never truncate code and count it as fully reviewed. If declared scopes still exceed budget, report required scope selection or explicit budget exception.
- Measure instructions, context, goals brief, diff and evidence together. Report native token counts where available, otherwise explicitly label the estimate and reserve 20%; account for model context/output limits.
- One shared goals brief: objective, accepted requirements, constraints, deferred work and source links. Preserve before/after requirement changes; new head prose is not automatically accepted authority.
- Prefer GLM 5.3 Flash for summarization; Gemini 3.8 Flash fallback. Configuration, not model allowlist. Reuse existing compressor/cache by source contents + prompt contract + actual model identity.
- Every changed file gets required-scope coverage or an explicit alternative verification disposition. Tests omitted from an architecture pass still need implementation/test coverage. Generated and lock changes require appropriate provenance/checks. Do not blanket-ignore executable ACE/CI/security config.
- Minimum one available independent reviewer completes EACH required scope. Model preferences never prohibit substitutes. Preserve all verified findings, even from one reviewer.
- Agent-led rounds: minimum 3 completed PR rounds and last 2 consecutive rounds without confirmed P0/P1. Verify findings, implement concrete fixes and run appropriate tests. P2 does not independently extend review; recurring unresolved blockers require diagnosis.
- Integration is part of a round, not an additional final pass. Commits, squash and rebase do not reset counters. Keep a short round/finding record, not a coverage certificate. No new engine or review gate; formal checks belong at merge time.
- Persist base/head, merge-base/diff identity, packet hashes, actual provider/model/reasoning, execution status, completeness, usage and limitations. Process exit success alone is insufficient.

## Evidence
PR140 snapshot head 147566b1b62d740ee0fd565bd30f5579b33dcb90 / base 742d45ed3e1ef97b830780d197df5f8ec34f1d38: full diff 172 files / 754,895 bytes / 209,422 o200k reference tokens; basic filtered diff + brief 103,490; with tests + brief 140,590. Original assembled system+user prompts 340,862 reference tokens. These are local reference counts, not provider billing counts. Apps/web alone: ~97k filtered diff tokens including tests, so directory counts alone are not sufficient.

## Delivery sequence
Fix model/response reliability and activate existing strategy/filter plumbing; add whole-input budgeting and declared scopes; integrate bundle/summary contracts; document the simple shared round workflow; release tested ACE packages; then consumer upgrade and review. Preserve existing useful APIs rather than add a second framework.

## Tracking
Child issue links will be added below. Existing large-prompt transport issue #320 is a related dependency; do not duplicate it.

## Acceptance / evaluation
Test small whole-review and large declared-scope review; 30k/30k/128k boundaries; huge context with tiny diff; unpartitionable oversize; coverage overlap/gaps; rename/deletion; cross-module contract drift; cache invalidation; round progress across changing SHA; one/substitute/no reviewers; incomplete or truncated output; recurring findings. Run representative PR140/145 defect cases and valid controls; measure recall, false positives, completeness, input/cache/output tokens, cost and latency. Do not claim quality improvements from token reduction alone.

## Consumer and delivery boundary

Requested from PlayaGo PR https://github.com/cs3b/st-playago-travel/pull/148. Generic implementation/tests belong in ACE. The consumer PR is draft and must retain only project configuration/docs; it must not ship a local gate, scripts, monkey patches or adapters. Reuse the existing ACE machinery. No PR merge is authorized by this work.

Baseline reproduced with ace-review 0.54.0, ace-bundle 0.43.8, ace-compressor 0.25.4, ace-llm 0.38.4, ace-llm-providers-cli 0.31.7. Recheck each reproduction against current main before implementing.

## Child issues

- [ ] https://github.com/cs3b/ace/issues/322 — Wire existing review strategies and reviewer filters through CLI execution
- [ ] https://github.com/cs3b/ace/issues/323 — Budget the complete review input and never accept truncated scope coverage
- [ ] https://github.com/cs3b/ace/issues/324 — Compose reusable high-level module and functional context for agents and reviewers
- [ ] https://github.com/cs3b/ace/issues/325 — Reuse one provenance-preserving goals brief through ace-compressor and bundle cache
- [ ] https://github.com/cs3b/ace/issues/326 — Own complete scoped review evidence and iterative fix lifecycle in ACE skills and Assign
- [ ] https://github.com/cs3b/ace/issues/327 — Fix reasoning/model resolution and Codex response integrity; persist actual execution identity

Related: https://github.com/cs3b/ace/issues/320 (large-prompt transport).
