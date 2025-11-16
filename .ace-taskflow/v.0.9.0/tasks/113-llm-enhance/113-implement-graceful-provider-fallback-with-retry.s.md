---
id: v.0.9.0+task.113
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Implement graceful LLM provider fallback with automatic retry and alternative providers

## Behavioral Specification

### User Experience
- **Input**: Users run ace-llm-query, ace-git-commit, ace-review, or any ace-* tool that uses LLM providers with their normal commands and flags
- **Process**: When primary provider fails (503, rate limit, timeout), users see informative status messages about retry attempts and fallback provider switching
- **Output**: Commands complete successfully with results from any available provider, or clear error message if all providers exhausted

### Expected Behavior
When users execute LLM-dependent commands, the system should handle provider failures transparently. If the configured primary provider returns errors (503 overloaded, 429 rate limit, timeouts), the system automatically:
1. Retries the request with exponential backoff (up to configured limits)
2. Falls back to alternative providers in priority order
3. Provides clear feedback about provider switching
4. Completes the operation successfully with any working provider
5. Returns actionable error only if all providers and retries are exhausted

Users experience resilient operation where temporary provider issues don't interrupt their workflow. The system adapts to provider availability dynamically while keeping users informed.

### Interface Contract

```bash
# CLI Interface - No changes to existing commands
ace-llm-query "prompt" -m gemini-2.0-exp
# Normal operation: uses gemini-2.0-exp
# On 503 error: "gemini-2.0-exp unavailable (503), retrying... (attempt 2/3)"
# After retries: "gemini-2.0-exp unavailable, trying fallback provider claude-3.5-sonnet..."
# Success: returns result normally
# All fail: "Error: All configured providers unavailable. Configure additional providers or try again later."

ace-git-commit
# Normal operation: generates commit using configured provider
# On provider error: "Primary provider (gemini) unavailable, using fallback (gpt-4)..."
# Success: creates commit normally
# All fail: "Error: Cannot generate commit - all LLM providers unavailable"

# Configuration Interface
.ace/llm/config.yml:
fallback:
  enabled: true
  retry_count: 3
  retry_delay: 1.0  # seconds, exponential backoff
  providers:     # Fallback order
    - claude-3.5-sonnet
    - gpt-4
    - gemini-1.5-pro
```

**Error Handling:**
- [503 Service Unavailable]: Retry with backoff, then try next provider
- [429 Rate Limited]: Wait if retry-after header present, otherwise fallback
- [Timeout]: Immediate fallback to next provider
- [401/403 Auth Error]: Skip provider, try next (don't retry auth failures)
- [Network Error]: Retry once, then fallback

**Edge Cases:**
- [All providers fail]: Return clear error with suggested actions
- [Circular dependencies]: Prevent infinite fallback loops
- [Partial success]: Handle streaming responses that fail mid-stream
- [Config changes]: Reload fallback configuration without restart

### Success Criteria

- [ ] **Automatic Recovery**: Commands complete successfully when primary provider has temporary issues (503, rate limit)
- [ ] **User Feedback**: Clear, actionable messages about retry attempts and provider switching
- [ ] **Configuration Control**: Users can configure retry behavior, fallback order, and disable fallback
- [ ] **Performance**: Fallback adds minimal latency (< 2s for immediate fallback scenarios)
- [ ] **Backwards Compatible**: Existing commands work without modification

### Validation Questions

- [ ] **Provider Priority**: Should fallback order be global or per-command configurable?
- [ ] **Retry Strategy**: What's the optimal retry count and backoff strategy (fixed vs exponential)?
- [ ] **Partial Failures**: How to handle providers that work but give degraded results?
- [ ] **Cost Consideration**: Should users confirm when falling back to more expensive providers?
- [ ] **State Management**: Should successful fallbacks update the default provider temporarily?

## Objective

Improve reliability and user experience by making LLM-dependent operations resilient to temporary provider failures. Users should be able to work uninterrupted when providers have transient issues, with the system handling complexity transparently.

## Scope of Work

- **User Experience Scope**: All ace-* tools that use ace-llm for LLM operations (ace-git-commit, ace-review, ace-llm-query, etc.)
- **System Behavior Scope**: Retry logic, provider switching, status reporting, configuration management
- **Interface Scope**: Existing CLI interfaces maintained, new configuration options for fallback behavior

### Deliverables

#### Behavioral Specifications
- Retry and fallback behavior flow definitions
- Provider switching decision logic
- User feedback message specifications

#### Validation Artifacts
- Test scenarios for various failure modes
- Performance benchmarks for fallback latency
- User acceptance criteria for reliability

## Out of Scope

- ❌ **Implementation Details**: Specific retry algorithms, state machine design, provider adapter patterns
- ❌ **Technology Decisions**: HTTP client libraries, async/threading model, caching strategies
- ❌ **Performance Optimization**: Connection pooling, request batching, response caching
- ❌ **Future Enhancements**: Provider health monitoring, automatic provider selection based on task type

## References

- Original issue: .ace-taskflow/v.0.9.0/ideas/done/20251002-201230-we-need-to-handle-the-api-errors-and-have-fallbac/idea.s.md
- Error trace showing Google API 503 failure in ace-git-commit
- Similar resilience patterns in ace-review preset fallback behavior