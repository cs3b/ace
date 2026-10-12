# Research: Harness Learning paper + ACE gap map

Compiled 2026-10-12 during task drafting (task 8xb.t.k3v). Shared reference for all subtasks.

## Source paper

**"Harness Learning Enables Generalizable Test-Time Adaptation"** — arXiv:2609.35738 (submitted 2026-09-28)
Authors: Alvin Zhang, Xuecheng Liu, Zixuan Wang, Fahim Tajwar, Daman Arora, Ruslan Salakhutdinov, Daniel Khashabi, Yuda Song, Andrea Zanette.
URL: https://arxiv.org/abs/2609.35738

### Core claims

- An agent = model + **harness** (the executable program organizing model calls, tool use, and information flow). The harness is a distinct, improvable lever independent of model weights.
- **Harness learning**: an RL-trained *proposer* model revises the solver's harness using execution feedback; harness revisions play the role of weight updates in gradient-based adaptation (meta-learning over executable programs).
- At test time both models stay **frozen** — the proposer refines the harness from feedback across successive executions, with no parameter update.
- Reward = task performance of revised harnesses.
- **Key result: the skill of improving harnesses transfers to unseen tasks** (reasoning, multi-hop QA).
- **Caution:** single-round revision quality improves reliably; benefits of training on full revision *sequences* are inconsistent across settings.

### Relevance to ACE

1. **Validates ACE's founding thesis.** The paper's central claim — harness organization matters as much as the model — is academic evidence for why ACE's layer (workflows, skills, config cascade, deterministic CLI) is valuable.
2. **ACE workflows ARE harnesses.** `*.wf.md` workflows, skills, and prompts map 1:1 onto the paper's "harness": executable programs organizing model calls and information flow.
3. **ACE's self-improvement is the manual version of harness learning.** `as-handbook-selfimprove`, `as-retro-synthesize`, `as-review-verify-feedback` already implement propose-from-feedback, but are prompted, not measured.
4. **Granularity guidance:** paper's mixed multi-round results endorse ACE's evidence-gated, single-revision-per-cycle model (cf. ADR-032 rerun evidence + failure-surface gate), not autonomous endless workflow rewriting.

## ACE gap map (what we can do better)

| # | Gap | Today | Target |
|---|-----|-------|--------|
| 1 | Retro findings end as documents, not harness changes | `as-retro-create`/`as-retro-synthesize` produce "recommendations" with no enforced, tracked path to a workflow/skill edit | Finding → tracked harness-edit task with verification criterion (previously failing E2E scenario); unlinked finding = visible debt |
| 2 | Workflow changes are not validated by measurement | Merged after text review; no old-vs-new comparison on fresh tasks | Comparative run (same task set, old vs new variant) before adoption; promote only on measurable improvement |
| 3 | Execution feedback is scattered and human-formatted | Reports/review output/failure analysis exist but are not machine-reusable as improvement signal | Standardized, deterministic feedback record emitted by `ace-assign`/`ace-e2e` on every run (`.ace-local/`, ADR-029 layout) |
| 4 | No project-level decision governing harness evolution | Ad-hoc practices spread across skills | One ADR: one harness revision per cycle, validate on fresh tasks, promote via ADR-022 cascade (gem defaults → user → project); never "rewrite the whole handbook" |

**Priority / sequencing:** 3 (data) → 1 (retro loop) → 2 (comparative validation); 4 is the decision that frames all of them and is drafted first as the smallest real slice.

## Mapping to existing ACE infrastructure

- ADR-032 (e2e rerun + checkpoint contract) → verification-gate precedent for harness revisions.
- ADR-022 (config cascade) → promotion path for validated harness revisions.
- ADR-029 (`.ace-local/<short-name>/`) → storage location for feedback records.
- `ace-sim run` already compares **providers**; comparative harness validation is the same pattern one level up.
- `as-demo-analyze-cast`, `ace-review` reports, E2E failure analyses → existing feedback sources to standardize into records.
