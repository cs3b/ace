---
id: v.0.2.0+task.50
status: pending
priority: high
estimate: 4h
dependencies: []
---

# Scrub API Keys from Debug and Log Output

## 0. Directory Audit ✅

_Command run:_

```bash
grep -r "API_KEY\|api.*key\|auth.*token\|bearer" . --include="*.rb" | grep -v spec | head -10
```

_Result excerpt:_

```
./lib/coding_agent_tools/molecules/api_credentials.rb:    def api_key
./lib/coding_agent_tools/organisms/gemini_client.rb:      @api_key = credentials.api_key
./lib/coding_agent_tools/cli/commands/llm/gemini_query.rb:        puts "Using API key: #{api_key}" if verbose
```

## Objective

Implement comprehensive API key scrubbing to prevent sensitive credentials from appearing in debug output, log messages, error traces, and any other output that could expose authentication tokens. This addresses Priority 3 requirement #8 from the code review findings and ensures security best practices for credential handling.

## Scope of Work

- Identify all locations where API keys might appear in output
- Implement credential scrubbing utility for logs and debug output
- Add automatic redaction of sensitive values in error messages
- Update verbose output to mask API keys appropriately
- Add logging security patterns to prevent accidental exposure
- Establish secure debugging practices across the codebase

### Deliverables

#### Create

- `lib/coding_agent_tools/atoms/credential_scrubber.rb`
- `lib/coding_agent_tools/molecules/secure_logger.rb`
- `spec/coding_agent_tools/atoms/credential_scrubber_spec.rb`
- `spec/coding_agent_tools/molecules/secure_logger_spec.rb`
- `spec/support/shared_examples/secure_logging_behavior.rb`

#### Modify

- `lib/coding_agent_tools/organisms/gemini_client.rb` (remove API key exposure)
- `lib/coding_agent_tools/organisms/lm_studio_client.rb` (secure debug output)
- `lib/coding_agent_tools/cli/commands/llm/gemini_query.rb` (scrub verbose output)
- `lib/coding_agent_tools/cli/commands/lms/studio_query.rb` (scrub verbose output)
- `lib/coding_agent_tools/molecules/api_credentials.rb` (secure toString methods)
- `lib/coding_agent_tools.rb` (update requires)

#### Delete

- Explicit API key logging statements

## Phases

1. Audit all locations where credentials might be exposed
2. Design credential scrubbing and secure logging system
3. Implement scrubbing utilities and secure logger
4. Update all components to use secure output practices
5. Add comprehensive security testing
6. Validate no credentials appear in any output

## Implementation Plan

### Planning Steps

* [ ] Audit all debug output, logging, and error messages for credential exposure
  > TEST: Credential Exposure Audit Complete
  > Type: Pre-condition Check
  > Assert: All potential credential exposure points catalogued
  > Command: grep -r "puts.*api\|puts.*key\|puts.*token\|puts.*auth" . --include="*.rb" | wc -l
* [ ] Research industry best practices for credential scrubbing
* [ ] Design secure logging patterns that maintain debugging utility
* [ ] Plan detection patterns for various credential formats

### Execution Steps

- [ ] Create `CredentialScrubber` atom with pattern-based redaction
  > TEST: Credential Scrubber Creation
  > Type: Action Validation
  > Assert: CredentialScrubber redacts common credential patterns
  > Command: bundle exec rspec spec/coding_agent_tools/atoms/credential_scrubber_spec.rb
- [ ] Implement detection patterns for API keys, tokens, and authentication headers
- [ ] Add configurable redaction strategies (masking, partial reveal, complete removal)
- [ ] Create `SecureLogger` molecule with automatic credential scrubbing
  > TEST: Secure Logger Functionality
  > Type: Action Validation
  > Assert: SecureLogger never logs actual credentials
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/secure_logger_spec.rb
- [ ] Implement safe debugging methods that automatically scrub sensitive data
- [ ] Update `GeminiClient` to remove explicit API key logging
  > TEST: Gemini Client Security
  > Type: Action Validation
  > Assert: GeminiClient never exposes API keys in any output
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/gemini_client_spec.rb --tag security
- [ ] Update `LMStudioClient` to use secure logging practices
- [ ] Update CLI commands to scrub verbose output containing credentials
  > TEST: CLI Security
  > Type: Action Validation
  > Assert: CLI commands never display actual credentials
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/ --tag security
- [ ] Update `APICredentials` with secure toString methods
- [ ] Add automatic scrubbing to error handling and exception messages
- [ ] Create shared test examples for secure logging behaviors
  > TEST: Security Test Coverage
  > Type: Action Validation
  > Assert: All security scenarios covered with comprehensive tests
  > Command: bundle exec rspec spec/support/shared_examples/secure_logging_behavior.rb --format json | jq '.summary.coverage_percent'
- [ ] Validate no credentials appear in any output across all components

## Acceptance Criteria

- [ ] AC 1: API keys and tokens never appear in debug output or logs
- [ ] AC 2: Verbose mode shows masked credentials (e.g., "sk-***...***xyz")
- [ ] AC 3: Error messages automatically redact sensitive information
- [ ] AC 4: All CLI commands use secure output practices
- [ ] AC 5: Exception traces don't expose credential values
- [ ] AC 6: Secure logger maintains debugging utility while protecting secrets
- [ ] AC 7: All existing functionality works with credential scrubbing enabled
- [ ] AC 8: Comprehensive test coverage for credential exposure scenarios

## Out of Scope

- ❌ Implementing credential encryption at rest
- ❌ Advanced secret management or vault integration
- ❌ Audit trails or credential usage tracking
- ❌ Network traffic scrubbing (focus on application output only)

## References

- [Code Review Task 39 - Priority 3 Requirements](../code-review/task.39/cr-user.md)
- [OWASP Logging Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html)
- [ATOM Architecture - Atoms and Molecules](../../../../docs/architecture.md)
- [Testing Standards](../../../../docs-dev/guides/.meta/workflow-instructions-embeding-tests.g.md)