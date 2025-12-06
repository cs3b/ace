# Idea

Create shared OpenAICompatibleParams concern for LLM providers

Several providers (XAI, OpenAI, Mistral) share identical parameter extraction logic for OpenAI-compatible APIs: frequency_penalty, presence_penalty, etc. This duplication could be extracted into a shared concern/mixin in Ace::LLM::Molecules.

Benefits:
- Reduce code duplication across OpenAI-compatible providers
- Single place to add new OpenAI-compatible parameters
- Easier testing of shared behavior

Current duplication locations:
- `ace-llm/lib/ace/llm/organisms/xai_client.rb` (extract_generation_options)
- `ace-llm/lib/ace/llm/organisms/openai_client.rb` (extract_generation_options)

Tags: refactor, ace-llm, low-priority

---
Captured: 2025-12-06 14:00:00
