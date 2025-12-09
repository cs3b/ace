---
id: v.0.9.0+task.133
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Extract shared OpenAICompatibleParams concern for LLM providers

## Description

Extract shared OpenAI-compatible parameter extraction logic from individual provider clients into a reusable concern/mixin. Currently, XAIClient and OpenAIClient have identical `extract_generation_options` implementations that handle `frequency_penalty` and `presence_penalty` parameters. This duplication should be eliminated by creating a shared concern that can be included by any OpenAI-compatible provider.

## Acceptance Criteria

- [ ] Create `OpenAICompatibleParams` concern/module in `ace-llm/lib/ace/llm/molecules/`
- [ ] Concern extracts `frequency_penalty` and `presence_penalty` parameters using nil-safe logic
- [ ] Concern preserves zero values (uses `nil?` check, not truthiness)
- [ ] XAIClient includes and uses the concern, removing duplicated code
- [ ] OpenAIClient includes and uses the concern, removing duplicated code
- [ ] All existing tests for XAIClient and OpenAIClient continue to pass
- [ ] Add unit tests for the new concern in `ace-llm/test/molecules/`

## Implementation Notes

### Current Duplication

Both XAIClient and OpenAIClient have identical `extract_generation_options` methods:

```ruby
def extract_generation_options(options)
  gen_opts = super(options)

  # Add OpenAI-specific options (use nil? to preserve zero values)
  gen_opts[:frequency_penalty] = options[:frequency_penalty] unless options[:frequency_penalty].nil?
  gen_opts[:presence_penalty] = options[:presence_penalty] unless options[:presence_penalty].nil?

  gen_opts.compact
end
```

### Proposed Solution

Create a module in `ace-llm/lib/ace/llm/molecules/openai_compatible_params.rb`:

```ruby
module Ace::LLM::Molecules::OpenAICompatibleParams
  # Extract OpenAI-compatible parameters (frequency_penalty, presence_penalty)
  # Preserves zero values using nil? check
  def extract_openai_compatible_options(options, gen_opts)
    gen_opts[:frequency_penalty] = options[:frequency_penalty] unless options[:frequency_penalty].nil?
    gen_opts[:presence_penalty] = options[:presence_penalty] unless options[:presence_penalty].nil?
    gen_opts
  end
end
```

Then update XAIClient and OpenAIClient to:
1. Include the concern
2. Call `extract_openai_compatible_options(options, gen_opts)` in their `extract_generation_options` methods

### Testing Strategy

- Test that zero values are preserved (e.g., `frequency_penalty: 0`)
- Test that nil values are ignored
- Test that positive values are included
- Integration tests should verify existing provider behavior is unchanged

### Future Extensions

This pattern can be extended to handle additional OpenAI-compatible parameters (e.g., `stop`, `logit_bias`, `user`) as more providers adopt them.
