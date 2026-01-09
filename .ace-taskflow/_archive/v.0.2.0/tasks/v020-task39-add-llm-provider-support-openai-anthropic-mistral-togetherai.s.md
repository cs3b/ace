---
id: v.0.2.0+task.39
title: Add LLM Provider Support for OpenAI, Anthropic, Mistral, and Together AI
status: done
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

# Add LLM Provider Support for OpenAI, Anthropic, and Mistral

## Objective / Problem Statement

Currently, the coding-agent-tools only supports Google Gemini and LMStudio as LLM providers. Many users need access to other popular LLM providers like OpenAI (GPT models), Anthropic (Claude models), Mistral, and Together AI. Adding support for these providers will significantly expand the toolkit's capabilities and allow users to choose the best model for their specific use cases.

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

- Create provider modules for OpenAI, Anthropic, and Mistral
- Implement API clients for each provider following existing patterns
- Create query commands for each new provider
- Integrate new providers into the existing unified `llm-models` command
- Add proper API key discovery and configuration
- Implement comprehensive error handling and testing

## Deliverables / Manifest

- [ ] Create `lib/coding_agent_tools/organisms/openai_client.rb`
- [ ] Create `lib/coding_agent_tools/organisms/anthropic_client.rb`
- [ ] Create `lib/coding_agent_tools/organisms/mistral_client.rb`
- [ ] Create API client classes for each provider in `organisms/`
- [ ] Create `exe/llm-openai-query` command
- [ ] Create `exe/llm-anthropic-query` command
- [ ] Create `exe/llm-mistral-query` command
- [ ] Create `lib/coding_agent_tools/organisms/together_ai_client.rb` module
- [ ] Create `exe/llm-together-ai-query` command
- [ ] Add provider configuration to API credentials system
- [ ] Create integration tests for each provider
- [ ] Update documentation with provider-specific guides

## Phases

1. **Architecture Phase**: Design provider interfaces following ATOM pattern
2. **OpenAI Implementation**: Implement OpenAI client and query command, integrate into `llm-models`
3. **Anthropic Implementation**: Implement Anthropic client and query command, integrate into `llm-models`
4. **Mistral Implementation**: Implement Mistral client and query command, integrate into `llm-models`
5. **Integration Phase**: Ensure compatibility with unified commands
6. **Testing Phase**: Comprehensive testing of all providers
7. **Documentation Phase**: Create guides and update existing docs

## Implementation Plan

### Planning Steps
* [x] Study existing `Organisms::GeminiClient` and `Organisms::LMStudioClient` implementations
  > TEST: Provider Client Pattern Analysis
  >   Type: Pre-condition Check
  >   Assert: Document common patterns and interfaces in `lib/coding_agent_tools/organisms/`
  >   Command: bin/test --analyze-provider-patterns
* [x] Research API specifications for each provider
  - [x] OpenAI API v1 documentation
  - [x] Anthropic Claude API documentation
  - [x] Mistral AI API documentation
  - [x] Together AI API documentation
* [x] Design consistent interface across all providers
* [x] Plan API key discovery strategy for each provider
  - [x] OpenAI: `OPENAI_API_KEY`
  - [x] Anthropic: `ANTHROPIC_API_KEY`
  - [x] Mistral: `MISTRAL_API_KEY`
  - [x] Together AI: `TOGETHER_API_KEY`

### Execution Steps
- [x] Implement OpenAI provider client
  - [x] Create `lib/coding_agent_tools/organisms/openai_client.rb`
  - [x] Implement OpenAI API client with proper error handling
  - [x] Support GPT-4, GPT-4 Turbo, GPT-3.5 models
  - [x] Handle streaming and non-streaming responses
  > TEST: OpenAI Provider Client Integration
  >   Type: Integration Test
  >   Assert: API client can list models and make queries
  >   Command: bin/test --provider openai --client-only
- [x] Create OpenAI query command
  - [x] Implement `exe/llm-openai-query`
  - [x] Ensure consistent CLI interface with existing query commands
- [x] Integrate OpenAI into unified `llm-models` command
  - [x] Update `lib/coding_agent_tools/cli/commands/llm/models.rb` to support OpenAI
  - [x] Add OpenAI models to caching and listing logic
  > TEST: Unified Models - OpenAI Integration
  >   Type: Integration Test
  >   Assert: `llm-models openai` lists OpenAI models
  >   Command: bin/test --llm-models openai
- [x] Implement Anthropic provider client
  - [x] Create `lib/coding_agent_tools/organisms/anthropic_client.rb`
  - [x] Implement Anthropic API client with proper error handling
  - [x] Support Claude 3 Opus, Sonnet, and Haiku models
  - [x] Handle Anthropic's message format requirements
  > TEST: Anthropic Provider Client Integration
  >   Type: Integration Test
  >   Assert: API client can list models and make queries
  >   Command: bin/test --provider anthropic --client-only
- [x] Create Anthropic query command
  - [x] Implement `exe/llm-anthropic-query`
  - [x] Ensure consistent CLI interface with existing query commands
  - [x] Handle Anthropic's specific requirements (e.g., human/assistant alternation)
- [x] Integrate Anthropic into unified `llm-models` command
  - [x] Update `lib/coding_agent_tools/cli/commands/llm/models.rb` to support Anthropic
  - [x] Add Anthropic models to caching and listing logic
  > TEST: Unified Models - Anthropic Integration
  >   Type: Integration Test
  >   Assert: `llm-models anthropic` lists Anthropic models
  >   Command: bin/test --llm-models anthropic
- [x] Implement Mistral provider client
  - [x] Create `lib/coding_agent_tools/organisms/mistral_client.rb`
  - [x] Implement Together AI or Mistral API client with proper error handling
  - [x] Support Mistral-8x7B and other Mistral models
  - [x] Handle provider-specific response formats
  > TEST: Mistral Provider Client Integration
  >   Type: Integration Test
  >   Assert: API client can list models and make queries
  >   Command: bin/test --provider mistral --client-only
- [x] Create Mistral query command
  - [x] Implement `exe/llm-mistral-query`
  - [x] Ensure consistent CLI interface with existing query commands
- [x] Integrate Mistral into unified `llm-models` command
  - [x] Update `lib/coding_agent_tools/cli/commands/llm/models.rb` to support Mistral
  - [x] Add Mistral models to caching and listing logic
  > TEST: Unified Models - Mistral Integration
  >   Type: Integration Test
  >   Assert: `llm-models mistral` lists Mistral models
  >   Command: bin/test --llm-models mistral
- [x] Implement Together AI provider client
  - [x] Create `lib/coding_agent_tools/organisms/together_ai_client.rb`
  - [x] Implement Together AI API client with proper error handling
  - [x] Support relevant Together AI models (e.g., Llama, Mistral through Together)
  - [x] Handle Together AI response formats
  > TEST: Together AI Provider Client Integration
  >   Type: Integration Test
  >   Assert: API client can list models and make queries programmatically via Together AI
  >   Command: bin/test --provider together_ai --client-only
- [x] Create Together AI query command
  - [x] Implement `exe/llm-together-ai-query`
  - [x] Ensure consistent CLI interface with existing query commands
- [x] Integrate Together AI into unified `llm-models` command
  - [x] Update `lib/coding_agent_tools/cli/commands/llm/models.rb` to support Together AI
  - [x] Add Together AI models to caching and listing logic
  > TEST: Unified Models - Together AI Integration
  >   Type: Integration Test
  >   Assert: `llm-models together_ai` lists Together AI models
  >   Command: bin/test --llm-models together_ai
- [x] Update API credentials system
  - [x] Add OpenAI key discovery
  - [x] Add Anthropic key discovery
  - [x] Add Mistral key discovery
  - [x] Add Together AI key discovery
  - [x] Update configuration documentation
- [x] Ensure unified `llm-models` command compatibility
  - [x] Update `lib/coding_agent_tools/cli/commands/llm/models.rb` to incorporate new providers
  - [x] Ensure `llm-models` can list models for OpenAI, Anthropic, and Mistral
- [x] Add comprehensive error handling
  - [x] Rate limiting responses
  - [x] Invalid API key errors
  - [x] Network timeout handling
  - [x] Model availability errors
- [x] Create provider-specific documentation
  - [x] OpenAI setup and usage guide
  - [x] Anthropic setup and usage guide
  - [x] Mistral setup and usage guide
- [x] Write comprehensive test suite
  - [x] Unit tests for all new client classes
    - [x] Test `Organisms::OpenAIClient` initialization and methods
    - [x] Test `Organisms::AnthropicClient` initialization and methods
    - [x] Test `Organisms::MistralClient` initialization and methods
    - [x] Test `Organisms::TogetherAIClient` initialization and methods
    - [x] Test error handling for all client classes
    - [x] Test payload building and response parsing
  - [x] Update models command tests
    - [x] Test `llm-models openai` functionality
    - [x] Test `llm-models anthropic` functionality
    - [x] Test `llm-models mistral` functionality
    - [x] Test `llm-models together_ai` functionality
    - [x] Test fallback model configuration loading
    - [x] Test model filtering and formatting
  - [x] Integration tests for new provider commands
    - [x] Test `llm-openai-query` command execution
    - [x] Test `llm-anthropic-query` command execution
    - [x] Test `llm-mistral-query` command execution
    - [x] Test `llm-together-ai-query` command execution
    - [x] Test file input/output for all commands
    - [x] Test system instructions for all commands
    - [x] Test various output formats (JSON, Markdown, text)
    - [x] Test error scenarios and debug mode

## Acceptance Criteria

- [x] All three providers (OpenAI, Anthropic, Mistral) are fully implemented
- [x] Each new provider has a working `query` command (`llm-openai-query`, etc.)
- [x] The unified `llm-models` command can list models for all new providers (OpenAI, Anthropic, Mistral)
- [x] API key discovery works for all providers using environment variables
- [x] Error messages are clear and actionable for common issues
- [x] All providers follow the same architectural patterns as existing ones
- [x] Integration tests pass for all providers
- [x] Commands support all features available in Gemini/LMStudio commands
- [x] Documentation clearly explains setup and usage for each provider

- [x] Response formats are consistent across all providers

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
