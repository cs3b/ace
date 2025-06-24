# Client Duplication Analysis

## Summary
Analysis of duplication patterns across all 6 LLM client classes to inform base class hierarchy design.

## Initialization Patterns (~80% duplication)

### Common Pattern:
```ruby
def initialize(api_key: nil, model: nil, **options)
  @model = model || default_model
  @base_url = options.fetch(:base_url, API_BASE_URL)
  @generation_config = DEFAULT_GENERATION_CONFIG.merge(
    options.fetch(:generation_config, {})
  )
  
  # Initialize components
  @credentials = Molecules::APICredentials.new(
    env_key_name: options.fetch(:api_key_env, DEFAULT_API_KEY_ENV)
  )
  @api_key = api_key || @credentials.api_key
  
  @request_builder = Molecules::HTTPRequestBuilder.new(
    timeout: options.fetch(:timeout, 30).to_i,
    event_namespace: :provider_api
  )
  @response_parser = Molecules::APIResponseParser.new
end
```

### Variations:
- **LMStudioClient**: No APICredentials component, direct ENV access
- **GoogleClient**: Uses query parameters for auth instead of headers
- **AnthropicClient**: Additional API_VERSION constant

## Core Interface Methods (~90% duplication)

### Common Methods:
1. `generate_text(prompt, **options)` - 100% same pattern
2. `generate_text_stream(prompt, **options)` - 100% same (all raise NotImplementedError)
3. `list_models()` - 90% same pattern
4. `model_info()` - 80% same pattern
5. `count_tokens(text)` - Only GoogleClient implements, others raise NotImplementedError

### Shared Workflow Pattern:
```ruby
def generate_text(prompt, **options)
  payload = build_generation_payload(prompt, options)
  url = build_api_url("endpoint")
  
  response_data = @request_builder.post_json(url, payload, headers: auth_headers)
  parsed = @response_parser.parse_response(response_data)
  
  if parsed[:success]
    extract_generated_text(parsed)
  else
    handle_error(parsed)
  end
end
```

## Helper Method Patterns (~70% duplication)

### URL Building:
- **GoogleClient**: Complex URL with query parameters and model paths
- **Others**: Simple URL concatenation with headers for auth

### Authentication:
- **GoogleClient**: Query parameter authentication
- **AnthropicClient**: Custom headers with version
- **OpenAI/Mistral/TogetherAI**: Bearer token headers
- **LMStudioClient**: Optional or no authentication

### Payload Building:
- **GoogleClient**: Unique format with `contents` and `generationConfig`
- **AnthropicClient**: `messages` array + `system` field
- **Others**: Standard OpenAI-compatible format

## Response Processing Patterns (~60% duplication)

### Error Handling:
- All follow same pattern but with provider-specific message formatting
- Common structure: extract error object, status, and messages
- Provider-specific error field access patterns

### Text Extraction:
- **GoogleClient**: `candidates[0].content.parts[0].text`
- **AnthropicClient**: `content[0].text` (array of content blocks)
- **Others**: `choices[0].message.content`

## Default Model Resolution (~100% duplication)
All use identical pattern:
```ruby
def default_model
  CodingAgentTools::Models::DefaultModelConfig.default.default_model_for("provider")
end
```

## Constants and Configuration (~50% duplication)
- API_BASE_URL - unique per provider
- DEFAULT_API_KEY_ENV - follows pattern but unique values
- DEFAULT_GENERATION_CONFIG - similar structure, different parameters

## Extraction Plan

### BaseClient (Common Infrastructure)
- Initialization pattern with configuration merging
- Component setup (credentials, request_builder, response_parser)
- Default model resolution
- Common helper methods

### BaseChatCompletionClient (Chat Workflow)
- `generate_text` workflow template
- `generate_text_stream` placeholder
- `list_models` and `model_info` base implementations
- Abstract methods for provider-specific operations:
  - `build_api_url(endpoint)`
  - `build_generation_payload(prompt, options)`
  - `extract_generated_text(parsed_response)`
  - `handle_error(parsed_response)`
  - `auth_headers` (where applicable)

### Provider-Specific Hooks
- URL construction patterns
- Authentication methods
- Request payload formatting
- Response parsing specifics
- Error message formatting