---
id: v.0.2.0+task.39
title: Add LLM Provider Support for OpenAI, Anthropic, and Mixtral
status: pending
priority: high
assignee: unassigned
labels:
  - enhancement
  - integration
  - providers
dependencies:
  - v.0.2.0+task.37
  - v.0.2.0+task.38
estimated_hours: 24
actual_hours: 0
created_at: 2024-01-01
updated_at: 2024-01-01
---

# Add LLM Provider Support for OpenAI, Anthropic, and Mixtral

## Objective / Problem Statement

Currently, the coding-agent-tools only supports Google Gemini and LMStudio as LLM providers. Many users need access to other popular LLM providers like OpenAI (GPT models), Anthropic (Claude models), and Mixtral. Adding support for these providers will significantly expand the toolkit's capabilities and allow users to choose the best model for their specific use cases.

## Directory Audit

```bash
tree -L 2 lib/coding_agent_tools/providers
lib/coding_agent_tools/providers
├── gemini.rb
└── lmstudio.rb

tree -L 1 exe | grep -E "(gemini|lmstudio)"
├── llm-gemini-models
├── llm-gemini-query
├── llm-lmstudio-models
└── llm-lmstudio-query
```

## Scope of Work

- Create provider modules for OpenAI, Anthropic, and Mixtral
- Implement API clients for each provider following existing patterns
- Create query and models commands for each provider
- Ensure compatibility with planned unified commands (from task.37)
- Add proper API key discovery and configuration
- Implement comprehensive error handling and testing

## Deliverables / Manifest

- [ ] Create `lib/coding_agent_tools/providers/openai.rb` module
- [ ] Create `lib/coding_agent_tools/providers/anthropic.rb` module
- [ ] Create `lib/coding_agent_tools/providers/mixtral.rb` module
- [ ] Create API client classes for each provider
- [ ] Create `exe/llm-openai-query` command
- [ ] Create `exe/llm-openai-models` command
- [ ] Create `exe/llm-anthropic-query` command
- [ ] Create `exe/llm-anthropic-models` command
- [ ] Create `exe/llm-mixtral-query` command
- [ ] Create `exe/llm-mixtral-models` command
- [ ] Add provider configuration to API credentials system
- [ ] Create integration tests for each provider
- [ ] Update documentation with provider-specific guides

## Phases

1. **Architecture Phase**: Design provider interfaces following ATOM pattern
2. **OpenAI Implementation**: Implement OpenAI provider and commands
3. **Anthropic Implementation**: Implement Anthropic provider and commands
4. **Mixtral Implementation**: Implement Mixtral provider and commands
5. **Integration Phase**: Ensure compatibility with unified commands
6. **Testing Phase**: Comprehensive testing of all providers
7. **Documentation Phase**: Create guides and update existing docs

## Implementation Plan

### Planning Steps
* [ ] Study existing Gemini and LMStudio provider implementations
  > TEST: Provider Pattern Analysis
  >   Type: Pre-condition Check
  >   Assert: Document common patterns and interfaces
  >   Command: bin/test --analyze-provider-patterns
* [ ] Research API specifications for each provider
  - [ ] OpenAI API v1 documentation
  - [ ] Anthropic Claude API documentation
  - [ ] Mixtral/Together AI API documentation
* [ ] Design consistent interface across all providers
* [ ] Plan API key discovery strategy for each provider
  - [ ] OpenAI: `OPENAI_API_KEY`
  - [ ] Anthropic: `ANTHROPIC_API_KEY`
  - [ ] Mixtral: `MIXTRAL_API_KEY` or `TOGETHER_API_KEY`

### Execution Steps
- [ ] Implement OpenAI provider
  - [ ] Create `lib/coding_agent_tools/providers/openai.rb`
  - [ ] Implement OpenAI API client with proper error handling
  - [ ] Support GPT-4, GPT-4 Turbo, GPT-3.5 models
  - [ ] Handle streaming and non-streaming responses
  > TEST: OpenAI Provider Integration
  >   Type: Integration Test
  >   Assert: Can list models and make queries
  >   Command: bin/test --provider openai
- [ ] Create OpenAI commands
  - [ ] Implement `exe/llm-openai-query`
  - [ ] Implement `exe/llm-openai-models`
  - [ ] Ensure consistent CLI interface with existing commands
- [ ] Implement Anthropic provider
  - [ ] Create `lib/coding_agent_tools/providers/anthropic.rb`
  - [ ] Implement Anthropic API client
  - [ ] Support Claude 3 Opus, Sonnet, and Haiku models
  - [ ] Handle Anthropic's message format requirements
  > TEST: Anthropic Provider Integration
  >   Type: Integration Test
  >   Assert: Can list models and make queries
  >   Command: bin/test --provider anthropic
- [ ] Create Anthropic commands
  - [ ] Implement `exe/llm-anthropic-query`
  - [ ] Implement `exe/llm-anthropic-models`
  - [ ] Handle Anthropic's specific requirements (e.g., human/assistant alternation)
- [ ] Implement Mixtral provider
  - [ ] Create `lib/coding_agent_tools/providers/mixtral.rb`
  - [ ] Implement Together AI or Mistral API client
  - [ ] Support Mixtral-8x7B and other Mistral models
  - [ ] Handle provider-specific response formats
  > TEST: Mixtral Provider Integration
  >   Type: Integration Test
  >   Assert: Can list models and make queries
  >   Command: bin/test --provider mixtral
- [ ] Create Mixtral commands
  - [ ] Implement `exe/llm-mixtral-query`
  - [ ] Implement `exe/llm-mixtral-models`
- [ ] Update API credentials system
  - [ ] Add OpenAI key discovery
  - [ ] Add Anthropic key discovery
  - [ ] Add Mixtral/Together key discovery
  - [ ] Update configuration documentation
- [ ] Ensure unified command compatibility
  - [ ] Update provider registry for `llm-models` command
  - [ ] Ensure consistent interfaces for future integration
- [ ] Add comprehensive error handling
  - [ ] Rate limiting responses
  - [ ] Invalid API key errors
  - [ ] Network timeout handling
  - [ ] Model availability errors
- [ ] Create provider-specific documentation
  - [ ] OpenAI setup and usage guide
  - [ ] Anthropic setup and usage guide
  - [ ] Mixtral setup and usage guide

## Acceptance Criteria

- [ ] All three providers (OpenAI, Anthropic, Mixtral) are fully implemented
- [ ] Each provider has working `query` and `models` commands
- [ ] API key discovery works for all providers using environment variables
- [ ] Error messages are clear and actionable for common issues
- [ ] All providers follow the same architectural patterns as existing ones
- [ ] Integration tests pass for all providers
- [ ] Commands support all features available in Gemini/LMStudio commands
- [ ] Documentation clearly explains setup and usage for each provider
- [ ] Provider modules are compatible with planned unified commands
- [ ] Response formats are consistent across all providers

## Out of Scope

- Advanced provider-specific features (function calling, vision, etc.)
- Streaming response support (unless already implemented in existing providers)
- Cost tracking implementation (covered in separate task)
- Model fine-tuning or training endpoints
- Embedding endpoints
- Provider-specific authentication methods beyond API keys

## References & Risks

- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [Anthropic API Reference](https://docs.anthropic.com/claude/reference)
- [Together AI API Reference](https://docs.together.ai/reference)
- Risk: API changes from providers - mitigate with version pinning
- Risk: Rate limiting differences - implement provider-specific retry logic
- Risk: Cost implications - ensure users understand pricing differences
- Follow existing patterns in `lib/coding_agent_tools/providers/`
- Use existing HTTP client patterns from Gemini implementation