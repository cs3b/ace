---
id: v.0.2.0+task.39
title: Add LLM Provider Support for OpenAI, Anthropic, Mixtral, and Together AI
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

Currently, the coding-agent-tools only supports Google Gemini and LMStudio as LLM providers. Many users need access to other popular LLM providers like OpenAI (GPT models), Anthropic (Claude models), Mixtral, and Together AI. Adding support for these providers will significantly expand the toolkit's capabilities and allow users to choose the best model for their specific use cases.

## Directory Audit

```bash
tree -L 2 lib/coding_agent_tools/organisms
lib/coding_agent_tools/organisms
├── gemini_client.rb
└── lm_studio_client.rb

tree -L 1 exe | grep -E "(query|models)"
├── llm-gemini-query
├── llm-lmstudio-query
└── llm-models
```

## Scope of Work

- Create provider modules for OpenAI, Anthropic, and Mixtral
- Implement API clients for each provider following existing patterns
- Create query commands for each new provider
- Integrate new providers into the existing unified `llm-models` command
- Add proper API key discovery and configuration
- Implement comprehensive error handling and testing

## Deliverables / Manifest

- [ ] Create `lib/coding_agent_tools/organisms/openai_client.rb`
- [ ] Create `lib/coding_agent_tools/organisms/anthropic_client.rb`
- [ ] Create `lib/coding_agent_tools/organisms/mixtral_client.rb`
- [ ] Create API client classes for each provider in `organisms/`
- [ ] Create `exe/llm-openai-query` command
- [ ] Create `exe/llm-anthropic-query` command
- [ ] Create `exe/llm-mixtral-query` command
- [ ] Create `lib/coding_agent_tools/organisms/together_ai_client.rb` module
- [ ] Create `exe/llm-together-ai-query` command
- [ ] Add provider configuration to API credentials system
- [ ] Create integration tests for each provider
- [ ] Update documentation with provider-specific guides

## Phases

1. **Architecture Phase**: Design provider interfaces following ATOM pattern
2. **OpenAI Implementation**: Implement OpenAI client and query command, integrate into `llm-models`
3. **Anthropic Implementation**: Implement Anthropic client and query command, integrate into `llm-models`
4. **Mixtral Implementation**: Implement Mixtral client and query command, integrate into `llm-models`
5. **Integration Phase**: Ensure compatibility with unified commands
6. **Testing Phase**: Comprehensive testing of all providers
7. **Documentation Phase**: Create guides and update existing docs

## Implementation Plan

### Planning Steps
* [ ] Study existing `Organisms::GeminiClient` and `Organisms::LMStudioClient` implementations
  > TEST: Provider Client Pattern Analysis
  >   Type: Pre-condition Check
  >   Assert: Document common patterns and interfaces in `lib/coding_agent_tools/organisms/`
  >   Command: bin/test --analyze-provider-patterns
* [ ] Research API specifications for each provider
  - [ ] OpenAI API v1 documentation
  - [ ] Anthropic Claude API documentation
  - [ ] Mistral AI API documentation
  - [ ] Together AI API documentation
* [ ] Design consistent interface across all providers
* [ ] Plan API key discovery strategy for each provider
  - [ ] OpenAI: `OPENAI_API_KEY`
  - [ ] Anthropic: `ANTHROPIC_API_KEY`
  - [ ] Mixtral: `MISTRAL_API_KEY`
  - [ ] Together AI: `TOGETHER_API_KEY`

### Execution Steps
- [ ] Implement OpenAI provider client
  - [ ] Create `lib/coding_agent_tools/organisms/openai_client.rb`
  - [ ] Implement OpenAI API client with proper error handling
  - [ ] Support GPT-4, GPT-4 Turbo, GPT-3.5 models
  - [ ] Handle streaming and non-streaming responses
  > TEST: OpenAI Provider Client Integration
  >   Type: Integration Test
  >   Assert: API client can list models and make queries
  >   Command: bin/test --provider openai --client-only
- [ ] Create OpenAI query command
  - [ ] Implement `exe/llm-openai-query`
  - [ ] Ensure consistent CLI interface with existing query commands
- [ ] Integrate OpenAI into unified `llm-models` command
  - [ ] Update `lib/coding_agent_tools/cli/commands/llm/models.rb` to support OpenAI
  - [ ] Add OpenAI models to caching and listing logic
  > TEST: Unified Models - OpenAI Integration
  >   Type: Integration Test
  >   Assert: `llm-models openai` lists OpenAI models
  >   Command: bin/test --llm-models openai
- [ ] Implement Anthropic provider client
  - [ ] Create `lib/coding_agent_tools/organisms/anthropic_client.rb`
  - [ ] Implement Anthropic API client with proper error handling
  - [ ] Support Claude 3 Opus, Sonnet, and Haiku models
  - [ ] Handle Anthropic's message format requirements
  > TEST: Anthropic Provider Client Integration
  >   Type: Integration Test
  >   Assert: API client can list models and make queries
  >   Command: bin/test --provider anthropic --client-only
- [ ] Create Anthropic query command
  - [ ] Implement `exe/llm-anthropic-query`
  - [ ] Ensure consistent CLI interface with existing query commands
  - [ ] Handle Anthropic's specific requirements (e.g., human/assistant alternation)
- [ ] Integrate Anthropic into unified `llm-models` command
  - [ ] Update `lib/coding_agent_tools/cli/commands/llm/models.rb` to support Anthropic
  - [ ] Add Anthropic models to caching and listing logic
  > TEST: Unified Models - Anthropic Integration
  >   Type: Integration Test
  >   Assert: `llm-models anthropic` lists Anthropic models
  >   Command: bin/test --llm-models anthropic
- [ ] Implement Mixtral provider client
  - [ ] Create `lib/coding_agent_tools/organisms/mixtral_client.rb`
  - [ ] Implement Together AI or Mistral API client with proper error handling
  - [ ] Support Mixtral-8x7B and other Mistral models
  - [ ] Handle provider-specific response formats
  > TEST: Mixtral Provider Client Integration
  >   Type: Integration Test
  >   Assert: API client can list models and make queries
  >   Command: bin/test --provider mixtral --client-only
- [ ] Create Mixtral query command
  - [ ] Implement `exe/llm-mixtral-query`
  - [ ] Ensure consistent CLI interface with existing query commands
- [ ] Integrate Mixtral into unified `llm-models` command
  - [ ] Update `lib/coding_agent_tools/cli/commands/llm/models.rb` to support Mixtral
  - [ ] Add Mixtral models to caching and listing logic
  > TEST: Unified Models - Mixtral Integration
  >   Type: Integration Test
  >   Assert: `llm-models mixtral` lists Mixtral models
  >   Command: bin/test --llm-models mixtral
- [ ] Implement Together AI provider client
  - [ ] Create `lib/coding_agent_tools/organisms/together_ai_client.rb`
  - [ ] Implement Together AI API client with proper error handling
  - [ ] Support relevant Together AI models (e.g., Llama, Mixtral through Together)
  - [ ] Handle Together AI response formats
  > TEST: Together AI Provider Client Integration
  >   Type: Integration Test
  >   Assert: API client can list models and make queries programmatically via Together AI
  >   Command: bin/test --provider together_ai --client-only
- [ ] Create Together AI query command
  - [ ] Implement `exe/llm-together-ai-query`
  - [ ] Ensure consistent CLI interface with existing query commands
- [ ] Integrate Together AI into unified `llm-models` command
  - [ ] Update `lib/coding_agent_tools/cli/commands/llm/models.rb` to support Together AI
  - [ ] Add Together AI models to caching and listing logic
  > TEST: Unified Models - Together AI Integration
  >   Type: Integration Test
  >   Assert: `llm-models together_ai` lists Together AI models
  >   Command: bin/test --llm-models together_ai
- [ ] Update API credentials system
  - [ ] Add OpenAI key discovery
  - [ ] Add Anthropic key discovery
  - [ ] Add Mistral key discovery
  - [ ] Add Together AI key discovery
  - [ ] Update configuration documentation
- [ ] Ensure unified `llm-models` command compatibility
  - [ ] Update `lib/coding_agent_tools/cli/commands/llm/models.rb` to incorporate new providers
  - [ ] Ensure `llm-models` can list models for OpenAI, Anthropic, and Mixtral
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
- [ ] Each new provider has a working `query` command (`llm-openai-query`, etc.)
- [ ] The unified `llm-models` command can list models for all new providers (OpenAI, Anthropic, Mixtral)
- [ ] API key discovery works for all providers using environment variables
- [ ] Error messages are clear and actionable for common issues
- [ ] All providers follow the same architectural patterns as existing ones
- [ ] Integration tests pass for all providers
- [ ] Commands support all features available in Gemini/LMStudio commands
- [ ] Documentation clearly explains setup and usage for each provider

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
- [Mistral AI API Reference](https://docs.mistral.ai/api/)
- [Together AI API Reference](https://docs.together.ai/reference)
- Risk: API changes from providers - mitigate with version pinning
- Risk: Rate limiting differences - implement provider-specific retry logic
- Risk: Cost implications - ensure users understand pricing differences
- Follow existing patterns in `lib/coding_agent_tools/organisms/` (e.g., `gemini_client.rb`, `lm_studio_client.rb`)
- Use existing HTTP client patterns from Gemini client implementation