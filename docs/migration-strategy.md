# Migration Strategy for Base Client Hierarchy

## Migration Order

### Phase 1: GoogleClient (Most Complex)
- GoogleClient has the most unique patterns (query-based auth, special URL building)
- Refactoring it first will help identify any missing abstractions in base classes
- Google-specific patterns: `candidates` response format, query parameter authentication

### Phase 2: AnthropicClient (Moderate Complexity)
- Anthropic has unique response format (`content` blocks instead of `choices`)
- Custom header authentication with API version
- Handles pagination in list_models

### Phase 3-6: OpenAI-Compatible Clients (Similar Patterns)
- OpenAI, Mistral, TogetherAI, and LMStudio all follow similar patterns
- Can be done in parallel or rapid succession
- Standard `choices[0].message.content` response format

## Rollback Strategy

### Git Branch Strategy
- Create feature branch for each client refactoring
- Keep original client implementation until all tests pass
- Use git stash or temporary backup if immediate rollback needed

### Validation Checklist per Client
1. All existing tests pass without modification
2. CLI commands work correctly
3. API calls produce same responses
4. Error handling maintains same behavior
5. Performance characteristics unchanged

### Backup Approach
- Copy current client to `{Provider}ClientOriginal` before refactoring
- Remove backup only after final integration tests pass
- Maintain original imports as aliases during transition

## Backward Compatibility Preservation

### Public API Maintenance
- All public method signatures remain unchanged
- Same return value formats and structures
- Identical error message patterns
- Same configuration option handling

### Configuration Compatibility
- All initialization options continue to work
- Environment variable names unchanged
- Default behavior preserved
- Optional parameters maintain same defaults

### Integration Point Stability
- CLI command behavior unchanged
- Same response formats for external consumers
- Error codes and messages preserved
- Logging and monitoring events maintained

## Risk Mitigation

### Pre-Migration Validation
- Comprehensive test coverage review
- Integration test baseline establishment
- Performance benchmark capture
- Documentation of current behavior

### During Migration
- One client at a time approach
- Continuous test execution
- Regular integration verification
- Performance monitoring

### Post-Migration Validation
- Full regression testing
- Integration test suite execution
- CLI command verification
- Error handling validation

## Client-Specific Considerations

### GoogleClient
- **Special Auth**: Query parameter instead of headers
- **URL Building**: Model-specific paths with query params
- **Response Format**: `candidates` structure unique to Google
- **Token Counting**: Only Google implements this feature

### AnthropicClient
- **Response Format**: `content` blocks array instead of single choice
- **System Messages**: Uses `system` field instead of messages array
- **List Models**: Implements pagination logic
- **Error Format**: Different error structure from OpenAI

### LMStudioClient
- **No Credentials**: No APICredentials component needed
- **Server Availability**: Unique `server_available?` check
- **Local Server**: Different timeout defaults
- **Optional Auth**: API key optional for localhost

### OpenAI/Mistral/TogetherAI
- **Standard Format**: Follow OpenAI chat completions API
- **Bearer Auth**: Standard Authorization header
- **Similar Responses**: `choices[0].message.content` pattern
- **Model Filtering**: TogetherAI has unique model filtering logic

## Success Criteria

### Duplication Reduction
- Target: >50% reduction in duplicated code
- Measure: Lines of code before/after comparison
- Focus areas: Initialization, request handling, error processing

### Functionality Preservation
- All existing tests pass unchanged
- CLI commands work identically
- Same error messages and handling
- Performance within 5% of baseline

### Architecture Improvement
- Clear separation of concerns
- Template method pattern implementation
- Consistent error handling across providers
- Easier addition of new providers