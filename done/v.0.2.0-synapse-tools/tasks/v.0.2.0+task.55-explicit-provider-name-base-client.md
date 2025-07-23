---
id: v.0.2.0+task.55
title: Make provider_name an Explicit Class Method in BaseClient
created_at: '2025-06-24T20:05:00Z'
updated_at: '2025-06-24T20:05:00Z'
release: v.0.2.0
status: done
priority: low
tags: [refactoring, code-clarity, nice-to-have]
owner: TBD
estimate: 1-2h
dependencies: [task.45]
note: |
  As identified in the code review from gpro (commits-after-1361d77-20250624-205941/cr-report-gpro.md),
  the current implementation infers provider name from class name, which is clever but could be
  more explicit and declarative.
---

# Task: Make provider_name an Explicit Class Method in BaseClient

## Objective

Replace the implicit provider name inference (from class name) in `BaseClient` with an explicit class-level declaration to make the provider-to-client mapping more declarative and self-documenting.

## Directory Audit

```bash
# Current structure
lib/coding_agent_tools/organisms/
├── base_client.rb          # Contains provider_name method that infers from class name
├── google_client.rb        # Inherits provider_name behavior
├── anthropic_client.rb     # Inherits provider_name behavior
├── openai_client.rb        # Inherits provider_name behavior
├── mistral_client.rb       # Inherits provider_name behavior
├── together_ai_client.rb   # Inherits provider_name behavior
└── lm_studio_client.rb     # Inherits provider_name behavior
```

## Scope of Work

Transform the provider name from an inferred value to an explicitly declared class attribute:
1. Make provider_name an abstract method that subclasses must implement
2. Update all client classes to explicitly declare their provider name
3. Maintain backward compatibility and existing functionality
4. Improve code clarity and self-documentation

## Deliverables

### Files to Modify
- [ ] `lib/coding_agent_tools/organisms/base_client.rb` - Add abstract provider_name method
- [ ] `lib/coding_agent_tools/organisms/google_client.rb` - Add explicit provider_name
- [ ] `lib/coding_agent_tools/organisms/anthropic_client.rb` - Add explicit provider_name
- [ ] `lib/coding_agent_tools/organisms/openai_client.rb` - Add explicit provider_name
- [ ] `lib/coding_agent_tools/organisms/mistral_client.rb` - Add explicit provider_name
- [ ] `lib/coding_agent_tools/organisms/together_ai_client.rb` - Add explicit provider_name
- [ ] `lib/coding_agent_tools/organisms/lm_studio_client.rb` - Add explicit provider_name

### Tests to Update
- [ ] `spec/coding_agent_tools/organisms/base_client_spec.rb` - Test abstract method behavior

## Phases

1. **Analysis Phase**: Review current usage of provider_name
2. **Design Phase**: Determine best approach for explicit declaration
3. **Implementation Phase**: Update base class and all subclasses
4. **Verification Phase**: Ensure all functionality preserved

## Implementation Plan

### Planning Steps
* [x] Analyze current provider_name implementation and all usages
  > TEST: Current Implementation Review
  >   Type: Pre-condition Check
  >   Assert: Understanding of current implementation
  >   Command: grep -n "provider_name" lib/coding_agent_tools/organisms/base_client.rb
  >   Result: Found 6 references to provider_name method
* [x] Identify all places where provider_name is called
* [x] Design approach that maintains backward compatibility

### Execution Steps
- [x] Update BaseClient to define abstract provider_name method
  ```ruby
  class BaseClient
    def self.provider_name
      raise NotImplementedError, "#{self.name} must implement .provider_name"
    end
    
    def provider_name
      self.class.provider_name
    end
  end
  ```
- [x] Update GoogleClient with explicit declaration
  ```ruby
  class GoogleClient < BaseChatCompletionClient
    def self.provider_name
      'google'
    end
  end
  ```
- [x] Update AnthropicClient with explicit declaration
  ```ruby
  class AnthropicClient < BaseChatCompletionClient
    def self.provider_name
      'anthropic'
    end
  end
  ```
- [x] Update remaining client classes (OpenAI, Mistral, TogetherAI, LMStudio)
  > TEST: All Clients Declare Provider
  >   Type: Action Validation
  >   Assert: All client classes explicitly declare provider_name
  >   Command: grep -l "def self.provider_name" lib/coding_agent_tools/organisms/*_client.rb | wc -l
  >   Result: 7 files (6 concrete clients + BaseClient abstract method)
- [x] Add tests to verify abstract method raises error if not implemented
- [x] Verify all existing tests still pass
  > TEST: Test Suite Passes
  >   Type: Action Validation
  >   Assert: No regressions introduced
  >   Command: bundle exec rspec spec/coding_agent_tools/organisms/

## Acceptance Criteria

- [x] BaseClient defines provider_name as an abstract method
- [x] All client subclasses explicitly declare their provider name
- [x] Provider names match current inferred values (no behavior change)
- [x] Tests verify NotImplementedError raised for classes without provider_name
- [x] All existing functionality preserved
- [x] Code is more self-documenting and explicit

## Out of Scope

- Changing provider name values
- Modifying how provider names are used
- Adding new providers
- Changing the provider_name method signature

## References

- Code review report: `docs-project/current/v.0.2.0-synapse/code_review/commits-after-1361d77-20250624-205941/cr-report-gpro.md` (line 69-71)
- Current implementation: `lib/coding_agent_tools/organisms/base_client.rb:provider_name`
- [ATOM Architecture Guide](docs-dev/guides/atom-architecture-house-rules.g.md)

## Risks & Mitigations

**Risk**: Breaking existing code that relies on provider_name
**Mitigation**: Maintain exact same return values, only change implementation

**Risk**: Forgetting to implement provider_name in new client classes
**Mitigation**: Clear NotImplementedError with helpful message guides developers