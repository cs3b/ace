# ADR-010: HTTP Client Strategy with Faraday

## Status

Accepted
Date: 2025-06-08

## Context

The project frequently interacts with external APIs, requiring a robust, flexible, and maintainable HTTP client. Without a standardized approach, different parts of the application might use various HTTP libraries or custom implementations, leading to inconsistent behavior, duplicated effort, and difficulty in applying global configurations (e.g., timeouts, retries, authentication, logging). There was a clear need to adopt a single, well-established HTTP client library that could be configured consistently across all API interactions, ensuring reliability, testability, and ease of development.

## Decision

We decided to standardize on Faraday as the primary HTTP client for all external API interactions. Faraday provides a flexible middleware architecture that allows for easy composition of various HTTP client functionalities (e.g., request/response logging, error handling, retries, caching, authentication).

The implementation strategy involves:
- Using Faraday as the underlying HTTP client library.
- Introducing an `HTTPClient` "atom" (a low-level component or class) that encapsulates the basic Faraday connection setup and configuration. This atom will handle default middleware, connection options, and potentially base URLs.
- Introducing an `HTTPRequestBuilder` "molecule" (a higher-level component or class) that builds upon the `HTTPClient` to construct specific API requests. This molecule will abstract away common request patterns, headers, and payload formatting, providing a consistent interface for different API calls.
- Implementing a `RetryMiddleware` component that provides robust retry logic with exponential backoff for handling rate limits, server errors, and network failures.

```ruby
# Example (conceptual) Faraday HTTPClient atom
require 'faraday'
require 'faraday/retry' # Example for a common middleware

module MyProject
  module HTTP
    class Client
      def initialize(base_url:, notifications: nil)
        @base_url = base_url
        @notifications = notifications # Optional: for dry-monitor integration
        @connection = build_connection
      end

      def connection
        @connection
      end

      private

      def build_connection
        Faraday.new(url: @base_url) do |f|
          f.request :json # Example: Encode request body as JSON
          f.response :json # Example: Decode response body as JSON
          f.response :raise_error # Raise exceptions for 4xx/5xx responses
          f.use RetryMiddleware # Custom retry middleware with exponential backoff
          # f.use FaradayDryMonitorLogger, notifications: @notifications if @notifications # Integration with ADR-008
          f.adapter Faraday.default_adapter # The default adapter (e.g., Net::HTTP)
        end
      end
    end

    # Example (conceptual) HTTPRequestBuilder molecule
    class RequestBuilder
      def initialize(http_client:)
        @http_client = http_client.connection
      end

      def get(path, params: {}, headers: {})
        @http_client.get(path, params, headers)
      end

      def post(path, body: {}, headers: {})
        @http_client.post(path, body, headers)
      end

      # ... other HTTP methods
    end
  end
end

# Example usage
# client = MyProject::HTTP::Client.new(base_url: 'https://api.example.com')
# builder = MyProject::HTTP::RequestBuilder.new(http_client: client)
# response = builder.get('/users/123')
# puts response.body
```

### Retry Strategy Implementation

The `RetryMiddleware` component implements intelligent retry logic with exponential backoff to handle various failure scenarios:

#### Retry Strategy Types

**1. Rate Limit Retries (HTTP 429)**
- Initial Delay: 1 second
- Max Delay: 60 seconds  
- Max Attempts: 5
- Backoff Strategy: Exponential with ±25% jitter
- Respect Retry-After Header: Yes

**2. Server Error Retries (HTTP 5xx)**
- Initial Delay: 2 seconds
- Max Delay: 30 seconds
- Max Attempts: 3
- Backoff Strategy: Exponential with ±25% jitter
- Respect Retry-After Header: If present

**3. Network Error Retries**
- Initial Delay: 1 second
- Max Delay: 16 seconds
- Max Attempts: 4
- Backoff Strategy: Exponential with ±25% jitter
- Error Types: Timeout, Connection refused, DNS errors

**4. Client Error Policy (HTTP 4xx except 429)**
- Retry: No (except 429)
- Reason: Client errors typically indicate request issues that won't resolve with retries

#### Exponential Backoff Formula

```
delay = min(initial_delay * (2 ^ attempt), max_delay)
jittered_delay = delay * (1 + random(-0.25, 0.25))
```

#### RetryMiddleware Architecture

```ruby
class RetryMiddleware < Faraday::Middleware
  def initialize(app, options = {})
    super(app)
    @config = build_config(options)
  end

  def call(env)
    attempt = 0
    begin
      response = @app.call(env)
      handle_response(response, attempt, env)
    rescue => e
      handle_error(e, attempt, env)
    end
  end

  private

  def should_retry?(response_or_error, attempt)
    # Retry logic based on response/error type
  end

  def calculate_delay(error_type, attempt, retry_after = nil)
    # Exponential backoff with jitter calculation
  end
end
```

#### Error Classification

**Retryable Errors:**
```ruby
RETRYABLE_ERRORS = {
  rate_limit: [429],
  server_error: [500, 502, 503, 504],
  network_error: [
    Faraday::TimeoutError,
    Faraday::ConnectionFailed,
    Net::ReadTimeout,
    Net::OpenTimeout,
    SocketError,
    Errno::ECONNREFUSED,
    Errno::EHOSTUNREACH
  ]
}.freeze
```

**Non-Retryable Errors:**
- HTTP 4xx (except 429): Client errors
- HTTP 200-299: Success responses
- Specific network errors: SSL certificate errors
- Application-specific errors: Authentication failures

#### Configuration Options

**Default Configuration:**
```ruby
{
  max_attempts: {
    rate_limit: 5,    # HTTP 429
    server_error: 3,  # HTTP 5xx
    network_error: 4  # Connection/timeout errors
  },
  initial_delay: {
    rate_limit: 1.0,    # seconds
    server_error: 2.0,  # seconds
    network_error: 1.0  # seconds
  },
  max_delay: {
    rate_limit: 60.0,   # seconds
    server_error: 30.0, # seconds
    network_error: 16.0 # seconds
  },
  jitter_factor: 0.25,  # ±25%
  respect_retry_after: true
}
```

## Consequences

### Positive

- **Consistent HTTP Handling**: All external API calls will be made using a unified client, ensuring consistent behavior, error handling, and configuration across the application.
- **Faraday Ecosystem Access**: Leverages the rich ecosystem of Faraday middleware, allowing for easy integration of features like logging, caching, retries, authentication, and more.
- **Improved Testability**: HTTP interactions can be easily mocked or stubbed using libraries compatible with Faraday (e.g., WebMock, VCR), simplifying integration tests.
- **Clear Separation of Concerns**: The `HTTPClient` and `HTTPRequestBuilder` components provide a clean architectural separation, making the code more modular and understandable.
- **Reduced Duplication**: Avoids writing custom HTTP client logic repeatedly for different API calls.
- **Enhanced Reliability**: RetryMiddleware provides intelligent exponential backoff for rate limits, server errors, and network failures, significantly improving system resilience.
- **Configurable Retry Behavior**: Different retry strategies for different error types allow fine-tuning based on provider characteristics and application requirements.
- **Respect for Rate Limits**: Automatic handling of Retry-After headers and jitter prevents thundering herd problems while maintaining good API citizenship.

### Negative

- **New Dependency**: Introduces `faraday` and potentially other `faraday` ecosystem gems as new project dependencies, increasing the gem footprint.
- **Configuration Overhead**: Requires initial setup and configuration of Faraday, including choosing and arranging middleware, which can be a learning curve for new developers.
- **Abstraction Layer**: Adds a layer of abstraction (`HTTPClient`, `HTTPRequestBuilder`, `RetryMiddleware`) which, while beneficial, means developers interact with Faraday indirectly rather than directly.
- **Retry Complexity**: The retry middleware adds complexity to debugging and testing, requiring careful configuration to avoid excessive delays in test environments.
- **Increased Response Times**: Retry logic can increase overall response times during failure scenarios, though this improves overall success rates.

### Neutral

- **Middleware Complexity**: The power of Faraday's middleware can also introduce complexity if not managed carefully, requiring clear documentation of the middleware stack.
- **Retry Strategy Balance**: The retry middleware requires careful tuning between reliability (more retries) and responsiveness (fewer retries), with different optimal configurations for different use cases.

## Alternatives Considered

### `Net::HTTP` Directly

- **Why rejected**: `Net::HTTP` is Ruby's built-in HTTP client but is low-level and lacks many features (e.g., automatic retries, request/response logging, middleware) that are crucial for modern API interactions. Implementing these features directly would involve significant boilerplate and custom code.
- **Trade-offs**: No external dependencies. Very simple for basic, one-off requests. Becomes unwieldy for complex scenarios.

### Other HTTP Client Gems (e.g., `HTTParty`, `RestClient`, `Excon`)

- **Why rejected**: While many good HTTP client gems exist, Faraday was chosen for its strong middleware architecture, making it highly extensible and composable. Some alternatives might be simpler for basic use cases but lack the flexibility and ecosystem of Faraday for complex, enterprise-grade applications.
- **Trade-offs**: Each gem has its own strengths and weaknesses. Some might be simpler for quick prototypes, while others might offer specific features (e.g., performance, specific protocol support). Faraday's extensibility was the decisive factor.

## Related Decisions

- Observability strategy (ADR-008) for integrating `FaradayDryMonitorLogger` and instrumenting HTTP calls.
- CI-Aware VCR configuration (ADR-006) for robust testing of HTTP interactions without relying on external services in CI.

## References

- [Faraday GitHub Repository](https://github.com/lostisland/faraday)
- [Faraday Documentation](https://lostisland.github.io/faraday/)
- `HTTPClient` and `HTTPRequestBuilder` patterns (conceptual, from a component-based design perspective)