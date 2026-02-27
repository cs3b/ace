---
id: v.0.9.0+task.287
status: done
priority: medium
estimate: TBD
dependencies: []
worktree:
  branch: 287-global-llm-fallback-chain-with-quotaoverload-failover
  path: "../ace-task.287"
  created_at: '2026-02-26 19:53:04'
  updated_at: '2026-02-26 19:53:04'
  target_branch: 289-allow-ace-overseer-work-on-to-accept-ordered-multi-task-task-lists
---

# Global LLM fallback chain with quota/overload failover

## Behavioral Specification

### User Experience
- **Input**: Users configure a global fallback chain in `.ace/llm/config.yml` and run tools that use LLMs (starting with `ace-git-commit`).
- **Process**: On provider/model failure, the system retries or switches models/providers automatically based on error type.
- **Output**: Commands complete using fallback targets when possible, with clear status messaging about retries and fallback transitions.

### Expected Behavior
- Fallback configuration is centralized in `llm.fallback` and applied consistently via `Ace::LLM::QueryInterface`.
- For overload/unavailable/rate-limit failures, the system retries the current target according to configured retry policy, then advances to the next fallback target.
- For quota/credit/window-limit failures, the system skips retries on the current target and immediately advances to the next fallback target.
- If all fallback targets fail, the command returns a clear actionable error with attempted targets listed.
- `ace-git-commit` benefits automatically from centralized fallback behavior without tool-specific fallback settings.
- `ace-llm query` follows the same fallback behavior as Ruby API callers.

### Interface Contract
```yaml
# .ace/llm/config.yml
llm:
  fallback:
    enabled: true
    retry_count: 3
    retry_delay: 1.0
    max_total_timeout: 30.0
    providers:
      - gflash
      - anthropic:claude-haiku-4-5
      - openai:gpt-5.1-codex-mini
```

```bash
# Existing command contracts remain unchanged
ace-git-commit
ace-llm google:gemini-2.5-flash-lite "prompt"
```

**Error Handling:**
- Overload/rate-limit/unavailable: retry current target, then fallback.
- Quota/credits/window-limit exhausted: immediate fallback.
- Exhausted chain: fail with attempted target list and actionable guidance.

**Edge Cases:**
- Duplicate fallback entries are ignored/deduplicated while preserving order.
- Alias entries in fallback chain resolve consistently to provider/model targets.
- Explicit call-site fallback overrides continue to work (`fallback: false`, explicit providers).

### Success Criteria
- [ ] Tools using `Ace::LLM::QueryInterface` apply fallback from centralized `llm.fallback` config without per-tool fallback keys.
- [ ] Overload/unavailable failures retry then fallback; quota/credit/window-limit failures fallback immediately.
- [ ] `ace-git-commit` succeeds via fallback chain when primary model fails due to overload or limit exhaustion.
- [ ] `ace-llm query` uses the same fallback path and behavior as QueryInterface callers.

### Validation Questions
- [ ] Should fallback status messages be identical across all tools or allow tool-specific phrasing?
- [ ] Do we want any permanently disabled providers excluded from the chain at runtime when credentials are missing?
- [ ] Should fallback chain resolution be exposed in a debug-only summary before first request?

## Objective

Establish a general, centralized LLM fallback mechanism that improves reliability under provider overload and credit/quota exhaustion, starting with `ace-git-commit` but reusable across ACE tools.

## Scope of Work

- **User Experience Scope**: Reliable command execution with transparent fallback behavior and actionable failure messages.
- **System Behavior Scope**: Centralized fallback configuration loading, error-type-aware retry/fallback policy, and shared execution path for CLI + Ruby API.
- **Interface Scope**: `llm.fallback` config contract, `Ace::LLM::QueryInterface` behavior, and `ace-llm query` runtime behavior.

### Deliverables

#### Behavioral Specifications
- Global fallback configuration contract and precedence behavior.
- Error-classification behavior for overload vs quota/credit exhaustion.
- Shared fallback execution behavior for `ace-git-commit` and `ace-llm query`.

#### Validation Artifacts
- Tests covering config resolution, fallback sequencing, and immediate fallback on limit exhaustion.
- Behavioral verification scenarios for `ace-git-commit` and `ace-llm query`.

## Out of Scope

- ❌ Per-tool custom fallback configuration schemas.
- ❌ Full model-specific route maps (beyond single global chain in this task).
- ❌ Non-QueryInterface call paths that explicitly disable fallback.

## References

- Plan discussion: Global fallback chain, centralized in `llm.fallback`, with quota/credits immediate fallback policy.