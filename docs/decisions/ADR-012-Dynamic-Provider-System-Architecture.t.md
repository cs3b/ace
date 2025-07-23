# ADR-012: Dynamic Provider System Architecture

## Status

Accepted
Date: 2025-06-25

## Context

The LLM provider system previously relied on hardcoded constants (`SUPPORTED_PROVIDERS` and `DYNAMIC_ALIASES`) in `ProviderModelParser`, creating maintenance overhead when adding new providers. Each new provider required updates to multiple hardcoded lists and mappings, violating DRY principles and creating friction for system extensibility.

Additionally, the filename-to-class-name mapping contained special cases for client classes that didn't follow predictable patterns, requiring hardcoded mappings in the dynamic loading logic.

## Decision

We are implementing a fully dynamic provider system with the following components:

1. **Client-Side Configuration**: Each provider client class defines its own metadata via class methods:
   - `provider_name`: Returns the provider identifier
   - `dynamic_aliases`: Returns a hash of aliases specific to that provider

2. **Dynamic Registration**: `ClientFactory` collects provider metadata during client registration and notifies `ProviderModelParser`

3. **Algorithmic Class Name Resolution**: Provider client filenames follow consistent snake_case patterns that can be transformed algorithmically without special cases

4. **Runtime Provider Discovery**: `ProviderModelParser` dynamically discovers providers and aliases during client loading, eliminating static constants

## Consequences

### Positive

- **Zero Maintenance Overhead**: Adding new providers requires no updates to shared constants
- **Self-Configuring System**: Provider discovery happens automatically during client loading
- **DRY Compliance**: Provider-specific configuration lives with the provider
- **Extensibility**: System can support unlimited providers without core changes
- **Type Safety**: Each provider manages its own configuration contract

### Negative

- **Runtime Dependency**: Provider discovery happens at runtime rather than compile time
- **Test Complexity**: Requires careful test isolation due to global registration state
- **Debugging Challenges**: Provider issues may only surface during dynamic loading

### Neutral

- **Architecture Shift**: Moves from static configuration to dynamic discovery pattern
- **Code Distribution**: Provider configuration spreads across client classes rather than centralized

## Alternatives Considered

- **Centralized Configuration File**: JSON/YAML file with all provider mappings
  - Why rejected: Still requires manual maintenance, doesn't solve core issue
  
- **Registry Pattern with Manual Registration**: Explicit registration calls
  - Why rejected: Adds boilerplate and still requires manual intervention
  
- **Convention Over Configuration Only**: Rely purely on naming conventions
  - Why rejected: Doesn't handle provider-specific aliases and special cases

## Related Decisions

- [ADR-011: ATOM Architecture House Rules](ADR-011-ATOM-Architecture-House-Rules.t.md) - Defines the architectural layers this system operates within
- [ADR-007: Zeitwerk for Autoloading](ADR-007-Zeitwerk-for-Autoloading.t.md) - Provides the autoloading mechanism that enables dynamic discovery

## References

- Task 60: Standardize Client Filename Conventions
- Task 61: Make Provider System Fully Dynamic
- Ruby Zeitwerk documentation for autoloading patterns
- Design pattern: Registry Pattern for dynamic component discovery