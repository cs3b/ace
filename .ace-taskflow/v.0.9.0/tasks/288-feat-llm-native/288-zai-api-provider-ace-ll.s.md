---
id: v.0.9.0+task.288
status: in-progress
priority: medium
estimate: TBD
dependencies: []
worktree:
  branch: 288-add-native-zai-api-provider-to-ace-llm-and-run-ace-git-commit-trial
  path: "../ace-task.288"
  created_at: '2026-02-27 14:41:47'
  updated_at: '2026-02-27 14:41:47'
  target_branch: main
---

# Add native Z.AI API provider to ace-llm and run ace-git-commit trial

## Behavioral Specification

### User Experience
- **Input**: Maintainer configures `ace-llm` with a new `zai` provider and sets `git.model` for `ace-git-commit` in `.ace/git/commit.yml`.
- **Process**: `ace-git-commit` generates commit messages through direct Z.AI API calls (no CLI provider wrapper).
- **Output**: Commit message generation works with the new provider using existing command workflows and clear error messages when auth/API issues occur.

### Expected Behavior
- `ace-llm` recognizes a new provider ID `zai` as a first-class API provider.
- Query execution through `Ace::LLM::QueryInterface` can call Z.AI directly via HTTP with bearer auth (`ZAI_API_KEY`).
- `ace-git-commit` can switch to the configured Z.AI model by changing only `.ace/git/commit.yml`.
- Existing `ace-git-commit` UX remains unchanged: same flags, same command patterns, same dry-run behavior.
- API failures surface actionable errors (auth issue, provider unavailable, invalid model, non-JSON response).
- Trial scope is limited to `ace-git-commit`; no global default model switch for other tools.

### Interface Contract
```yaml
# Provider registration contract (ace-llm defaults)
name: zai
class: Ace::LLM::Organisms::ZaiClient
gem: ace-llm
api_key:
  env: ZAI_API_KEY
  required: true
models:
  - glm-4.7-flashx
  - glm-4.7
  - glm-5
```

```yaml
# Project-level ace-git-commit trial config
git:
  model: zai:glm-4.7-flashx
```

```bash
# Runtime behavior should remain unchanged for users
ace-git-commit
ace-git-commit -n
ace-llm zai:glm-4.7-flashx "test prompt"
```

**Error Handling:**
- Missing `ZAI_API_KEY`: explicit auth error with env var guidance.
- HTTP 4xx/5xx from Z.AI: provider error includes status and parsed message.
- Non-JSON response bodies: fallback error text with response snippet.

**Edge Cases:**
- Invalid or unavailable model name should fail clearly without silent fallback.
- Trial config affects only `ace-git-commit`; other tools keep current model settings.
- Existing CLI-based Z.AI wrappers (`pi`, `claudeoai`, `codexoai`) continue to coexist.

### Success Criteria
- [ ] `ace-llm` loads `zai` provider and can execute direct API query with `zai:glm-4.7-flashx`.
- [ ] `ace-git-commit` successfully generates commit messages when `git.model` is set to `zai:glm-4.7-flashx`.
- [ ] One-month trial runs with `ace-git-commit`-only scope and no required changes to user command flow.
- [ ] User can decide post-trial whether Z.AI becomes default model or future fallback candidate based on perceived speed/reliability.

### Validation Questions
- [ ] Should we keep alias naming minimal (`zai:glm-4.7-flashx` only) or add short aliases in defaults for trial ergonomics?
- [ ] Do we want trial notes captured in a dedicated doc file or only via changelog/task updates?
- [ ] Should we include `glm-5` in provider model list immediately, even if the trial default remains `glm-4.7-flashx`?

## Objective

Introduce a native Z.AI API provider in `ace-llm` so `ace-git-commit` can be tested for one month on a direct API path that avoids CLI-agent overhead and enables a practical comparison of speed/reliability in daily usage.

## Scope of Work

- **User Experience Scope**: Seamless model switch for `ace-git-commit` via config, with unchanged command UX.
- **System Behavior Scope**: New API provider registration, request/response handling, and provider-level error surfacing in `ace-llm`.
- **Interface Scope**: Provider config contract (`zai`), environment credential contract (`ZAI_API_KEY`), and `git.model` trial selection in `.ace/git/commit.yml`.

### Deliverables

#### Behavioral Specifications
- Provider behavior contract for direct Z.AI API calls.
- Trial behavior contract for `ace-git-commit`-only rollout.
- Error behavior contract for auth, API status, and malformed responses.

#### Validation Artifacts
- Provider/client tests for request mapping and response/error handling.
- Query/registry tests confirming provider discovery and invocation.
- Commit-generation smoke verification using `ace-git-commit` with trial model.

## Out of Scope

- ❌ Fallback-chain implementation or routing policy changes.
- ❌ Multi-tool default model migration across ACE packages.
- ❌ Coding Plan endpoint integration path for this task.
- ❌ Cost/performance automation or KPI instrumentation.

## References

- Decision thread: add native Z.AI API provider in `ace-llm`, trial on `ace-git-commit` via `.ace/git/commit.yml:4`.
- Existing CLI-based Z.AI paths for comparison: `.ace/llm/providers/pi.yml`, `.ace/llm/providers/claudeoai.yml`, `.ace/llm/providers/codexoai.yml`.