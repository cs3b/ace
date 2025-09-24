---
id: v.0.2.0+task.52
status: done
priority: medium
estimate: 6h
dependencies: [v.0.2.0+task.45]
---

# Implement XDG_CACHE_HOME Support and Retry/Back-off Middleware

## 0. Directory Audit ✅

_Command run:_

```bash
find . -name "*cache*" -o -name "*retry*" -o -name "*middleware*" -type f | head -10
```

_Result excerpt:_

```
./lib/coding_agent_tools/cli/commands/llm/models.rb  # Contains existing cache implementation
./lib/coding_agent_tools/atoms/http_client.rb       # Ready for retry middleware
./spec/coding_agent_tools/atoms/http_client_spec.rb
```

## Objective

Implement support for XDG Base Directory Specification for cached data and add retry/back-off middleware for HTTP requests to handle transient failures gracefully. Additionally, enhance model information with context size data and integrate with the existing llm-models command caching system. This addresses Subsequent Enhancement #10 from the code review findings and improves both user experience through proper cache directory handling and system reliability through resilient HTTP operations.

## Scope of Work

- Implement XDG_CACHE_HOME support for all cached data
- Create retry middleware with exponential back-off for HTTP 429/5xx errors
- Add configurable retry policies for different error types
- Implement cache directory management following XDG standards
- Add comprehensive error handling and logging for retry operations
- Ensure backward compatibility with existing cache behavior
- Enhance LlmModelInfo with context size information
- Integrate context size data collection with existing llm-models caching system
- Migrate existing cache data from ~/.coding-agent-tools-cache to XDG-compliant paths

### Deliverables

#### Create

- `lib/coding_agent_tools/atoms/xdg_directory_resolver.rb`
- `lib/coding_agent_tools/molecules/retry_middleware.rb`
- `lib/coding_agent_tools/molecules/cache_manager.rb`
- `spec/coding_agent_tools/atoms/xdg_directory_resolver_spec.rb`
- `spec/coding_agent_tools/molecules/retry_middleware_spec.rb`
- `spec/coding_agent_tools/molecules/cache_manager_spec.rb`

#### Modify

- `lib/coding_agent_tools/atoms/http_client.rb` (add retry middleware)
- `lib/coding_agent_tools/models/llm_model_info.rb` (add context_size field)
- `lib/coding_agent_tools/cli/commands/llm/models.rb` (integrate XDG cache manager and context size)
- `lib/coding_agent_tools/organisms/google_client.rb` (use XDG cache paths and collect context size)
- `lib/coding_agent_tools/organisms/lm_studio_client.rb` (use XDG cache paths)
- All other client organisms (add context size collection where available)
- `spec/coding_agent_tools/atoms/http_client_spec.rb` (add retry tests)
- `spec/coding_agent_tools/models/llm_model_info_spec.rb` (test context size field)
- `lib/coding_agent_tools.rb` (update requires)

#### Delete

- Hardcoded cache directory paths (migrate to XDG-compliant CacheManager)

## Phases

1. Research XDG Base Directory Specification requirements
2. Design retry middleware with configurable back-off strategies
3. Implement XDG directory resolution and cache management
4. Add retry middleware to HTTP client infrastructure
5. Update existing components to use XDG-compliant caching
6. Add comprehensive testing and error handling

## Implementation Plan

### Planning Steps

* [x] Research XDG Base Directory Specification for proper cache handling
  > TEST: XDG Research Complete
  > Type: Pre-condition Check
  > Assert: XDG specification requirements documented and implementation plan created
  > Command: test -f docs/xdg-implementation-plan.md
* [x] Analyze current caching patterns and identify hardcoded paths
* [x] Plan migration strategy from ~/.coding-agent-tools-cache to XDG paths
  > TEST: Cache Migration Strategy
  > Type: Pre-condition Check  
  > Assert: Migration plan handles existing cache data without loss
  > Command: test -f docs/cache-migration-plan.md
* [x] Design retry strategies for different HTTP error types (429, 5xx, network)
* [x] Plan backward compatibility for existing cache locations
* [x] Research context size availability across different LLM providers
  > TEST: Context Size Research Complete
  > Type: Pre-condition Check
  > Assert: Provider context size capabilities documented
  > Command: test -f docs/provider-context-sizes.md

### Execution Steps

- [x] Create `XDGDirectoryResolver` atom for XDG-compliant directory resolution
  > TEST: XDG Directory Resolver
  > Type: Action Validation
  > Assert: XDGDirectoryResolver correctly resolves cache directories per XDG spec
  > Command: bundle exec rspec spec/coding_agent_tools/atoms/xdg_directory_resolver_spec.rb
- [x] Implement cache directory detection with XDG_CACHE_HOME fallback to ~/.cache
- [x] Add environment variable handling and directory creation logic
- [x] Create `CacheManager` molecule for managing cached data with XDG paths
  > TEST: Cache Manager Functionality
  > Type: Action Validation
  > Assert: CacheManager uses XDG-compliant paths and handles cache operations
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/cache_manager_spec.rb
- [x] Implement cache migration from old locations to XDG-compliant paths
- [x] Enhance `LlmModelInfo` model with context_size field
  > TEST: Model Enhancement
  > Type: Action Validation
  > Assert: LlmModelInfo supports context_size field and maintains backward compatibility
  > Command: bundle exec rspec spec/coding_agent_tools/models/llm_model_info_spec.rb
- [x] Create `RetryMiddleware` molecule with exponential back-off logic
  > TEST: Retry Middleware Creation
  > Type: Action Validation
  > Assert: RetryMiddleware handles HTTP errors with appropriate back-off
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/retry_middleware_spec.rb
- [x] Implement configurable retry policies for different error types
- [x] Add jitter to prevent thundering herd problems
- [x] Integrate retry middleware into `HTTPClient`
  > TEST: HTTP Client Integration
  > Type: Action Validation
  > Assert: HTTPClient automatically retries transient failures
  > Command: bundle exec rspec spec/coding_agent_tools/atoms/http_client_spec.rb
- [x] Update `GoogleClient` to use XDG-compliant cache paths and collect context size data
- [x] Update `LMStudioClient` to use XDG-compliant cache paths
- [x] Update all provider clients to collect context size where API supports it
- [x] Integrate context size data collection with llm-models command caching
  > TEST: Context Size Integration
  > Type: Action Validation
  > Assert: llm-models command displays and caches context size information
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/llm/models_spec.rb -e "includes context size"
- [x] Add comprehensive logging for retry operations and cache management
  > TEST: Integration Validation
  > Type: Action Validation
  > Assert: All components use XDG paths and retry middleware correctly
  > Command: bundle exec rspec spec/coding_agent_tools/atoms/http_client_spec.rb
- [x] Create integration tests for retry scenarios and cache migration
- [x] Validate backward compatibility and migration of existing cache data

## Acceptance Criteria

- [x] AC 1: Cache data stored in XDG_CACHE_HOME or ~/.cache/coding-agent-tools
- [x] AC 2: HTTP 429 errors trigger exponential back-off retry with jitter
- [x] AC 3: HTTP 5xx errors retry with configurable maximum attempts
- [x] AC 4: Network errors handled with appropriate retry strategy
- [x] AC 5: Existing cache data migrates to XDG-compliant locations
- [x] AC 6: Retry operations logged with appropriate detail level
- [x] AC 7: All existing functionality works with new caching and retry logic
- [x] AC 8: Configurable retry policies allow customization per use case
- [x] AC 9: LlmModelInfo includes context_size field with appropriate values
- [x] AC 10: llm-models command displays context size information
- [x] AC 11: Context size data cached and refreshed with model information
- [x] AC 12: All providers collect context size where API supports it

## Out of Scope

- ❌ Complex cache invalidation strategies beyond basic TTL
- ❌ Distributed caching or shared cache mechanisms
- ❌ Advanced retry strategies like circuit breakers
- ❌ Cache compression or encryption features

## References

- [Code Review Task 39 - Subsequent Enhancement #10](../code-review/task.39/cr-user.md)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [HTTP Retry Best Practices](https://docs.aws.amazon.com/general/latest/gr/api-retries.html)
- [ATOM Architecture - Atoms and Molecules](../../../../docs/architecture.md)
- [Testing Standards](../../../../docs-dev/guides/.meta/workflow-instructions-embeding-tests.g.md)