# ADR-008: Class Naming Conventions and Zeitwerk Inflections

## Status

Accepted
Date: 2025-06-25

## Context

Ruby's Zeitwerk autoloader requires a predictable mapping between file names and class names. However, certain technical acronyms (JSON, HTTP, API) have established conventions in the Ruby community that differ from simple capitalization rules. Meanwhile, provider-specific client classes were using inconsistent naming that required hardcoded inflection mappings.

The question arose: should all class names follow algorithmic transformation rules, or should we maintain exceptions for well-established technical conventions?

## Decision

We adopt a **hybrid approach** for class naming conventions:

1. **Preserve Established Technical Acronyms**: Keep Zeitwerk inflections for widely-recognized technical terms:
   - `json_formatter.rb` → `JSONFormatter`
   - `http_client.rb` → `HTTPClient`  
   - `http_request_builder.rb` → `HTTPRequestBuilder`
   - `api_credentials.rb` → `APICredentials`
   - `api_response_parser.rb` → `APIResponseParser`

2. **Standardize Provider Client Names**: Use algorithmic transformation for provider clients:
   - `lmstudio_client.rb` → `LmstudioClient` (not `LMStudioClient`)
   - `openai_client.rb` → `OpenaiClient` (not `OpenAIClient`)
   - `togetherai_client.rb` → `TogetheraiClient` (not `TogetherAIClient`)

3. **Exception Policy**: Zeitwerk inflections are **only** permitted for:
   - Widely-established technical acronyms (JSON, HTTP, API, XML, etc.)
   - Infrastructure/utility classes that predate this decision
   - NOT for provider names, company names, or product names

## Consequences

### Positive

- **Developer Familiarity**: Maintains expected naming for common technical terms
- **Readability**: `HTTPClient` is more readable than `HttpClient`
- **Consistency**: All new provider clients follow predictable patterns
- **Maintainability**: Eliminates special-case mappings for business logic classes

### Negative

- **Dual Standards**: Developers must learn when to use inflections vs. algorithmic naming
- **Judgment Calls**: Determining what qualifies as an "established technical acronym"

### Neutral

- **Migration Impact**: Existing code required updates to follow new patterns
- **Documentation Overhead**: Need to document the exception policy clearly

## Alternatives Considered

- **Pure Algorithmic Approach**: Remove all Zeitwerk inflections
  - Why rejected: `HttpClient` and `JsonFormatter` reduce readability for established terms
  
- **Liberal Inflection Policy**: Keep inflections for all acronyms including company names
  - Why rejected: Creates maintenance overhead and inconsistent patterns
  
- **File Renaming**: Rename files to match desired class names
  - Why rejected: Would break established patterns for infrastructure classes

## Related Decisions

- [ADR-002: Zeitwerk for Autoloading](ADR-002-Zeitwerk-for-Autoloading.md) - Establishes the autoloading mechanism
- [ADR-007: Dynamic Provider System Architecture](ADR-007-Dynamic-Provider-System-Architecture.md) - Eliminates hardcoded client mappings

## References

- Zeitwerk documentation on inflections
- Ruby community conventions for acronym handling
- Rails Active Support inflection patterns