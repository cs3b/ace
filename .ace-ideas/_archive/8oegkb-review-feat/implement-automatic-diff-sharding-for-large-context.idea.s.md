---
title: Automatic Diff Sharding for Large Context Reviews in ace-review
filename_suggestion: feat-review-diff-sharding
enhanced_at: 2026-01-15 11:02:34.000000000 +00:00
location: active
llm_model: gflash
id: 8oegkb
status: done
tags: []
created_at: '2026-01-15 11:02:33'
---

# Automatic Diff Sharding for Large Context Reviews in ace-review

## Problem
Large pull requests or complex feature branches often generate diffs that exceed the maximum context window (e.g., 200k tokens) of high-quality LLMs, as demonstrated by the failure of `ace-review` on PR 158. This context overflow prevents autonomous code review execution, forcing manual intervention to segment the input. This violates the ACE principle of providing self-contained, predictable workflows (ADR-001).

## Solution
Implement an intelligent, configurable diff sharding mechanism within the `ace-review` pipeline. This mechanism will automatically detect context overflow based on the configured LLM's `max_context_tokens` and logically split the input diff into smaller, manageable chunks. The system will then execute parallel or sequential reviews for each shard and synthesize the results into a single, cohesive review report.

## Implementation Approach
1. **Orchestration (ace-review Organism):** The `ReviewManager` (Organism) must first estimate the token count of the combined prompt and diff. If it exceeds the LLM limit, it delegates to the sharding process.
2. **Diff Analysis (ace-git):** Leverage `ace-git` to provide structured diff statistics (e.g., file path, lines added/removed) suitable for programmatic segmentation.
3. **Sharding Molecule:** Introduce a new Molecule, `DiffSplitter`, within `ace-review/lib/ace/review/molecules/`. This component will use file path boundaries as the primary sharding unit to ensure logical coherence, minimizing the chance of splitting related code blocks.
4. **Parallel Execution (ace-llm):** The `ReviewManager` will orchestrate multiple `ace-llm` calls, one for each shard, potentially running them in parallel to reduce latency.
5. **Synthesis:** Implement a final, dedicated LLM call (using a model with a large enough context window for the aggregated reviews) to synthesize the individual shard reviews into a single `review-synthesis.md` output, following the multi-model execution pattern.

## Considerations
- **Configuration:** Allow users to define sharding thresholds and strategies (e.g., `strategy: path-based`, `max_shard_tokens: 100000`) in `.ace/review/config.yml`.
- **Synthesis Quality:** The synthesis prompt must be robust enough to handle potentially overlapping or redundant findings from different shards.
- **CLI Interface:** The CLI output must clearly indicate when sharding occurred and track the progress of individual shard reviews.

## Benefits
- Enables `ace-review` to handle arbitrarily large code changes autonomously, significantly improving the Agent Experience (AX).
- Ensures deterministic behavior and predictable success rates for complex review workflows.
- Upholds the principle of Configuration Without Lock-In by allowing users to tune sharding based on their chosen LLM provider and context limits.

---

## Original Idea

```
ace-review we need to to have sharding mechanism for big diff, if what we review is too big for the context windowd ~180_000 tokens then we have to logically shard the diff and run review for each shard seperately (probably by paths, in some logical orrdder - leave it to the agent to decide but we should provide information of diff - that stats by paths or by module - not sure )

⏺ Now I have the workflow. Let me run the PR review with the code-deep preset for PR 158.

⏺ Bash(ace-review --pr 158 --preset code-deep) timeout: 10m 0s
  ⎿  ⏳ openrouter:minimax: querying...
       ✗ openrouter:minimax: failed (LLM error: openrouter API error: OpenRouter API error (400): unknown - This endpoint's maximum context
     length is 204800 tokens. However, you requested about 205654 tokens (205654 of text input). Please reduce the length of either one, or
     use the "middle-out" transform to compress your prompt automatically.)
       ✗ claude:opus: failed (LLM error: Claude CLI failed:
     +4 more lines (2m 50s)
     ctrl+b to run in background
```