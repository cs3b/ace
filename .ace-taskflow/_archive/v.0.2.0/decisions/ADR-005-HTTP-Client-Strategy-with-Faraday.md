# ADR-005: HTTP Client Strategy with Faraday

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
          f.use Faraday::Retry::Middleware # Example: Automatic retries
          # f.use FaradayDryMonitorLogger, notifications: @notifications if @notifications # Integration with ADR-003
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

## Consequences

### Positive

- **Consistent HTTP Handling**: All external API calls will be made using a unified client, ensuring consistent behavior, error handling, and configuration across the application.
- **Faraday Ecosystem Access**: Leverages the rich ecosystem of Faraday middleware, allowing for easy integration of features like logging, caching, retries, authentication, and more.
- **Improved Testability**: HTTP interactions can be easily mocked or stubbed using libraries compatible with Faraday (e.g., WebMock, VCR), simplifying integration tests.
- **Clear Separation of Concerns**: The `HTTPClient` and `HTTPRequestBuilder` components provide a clean architectural separation, making the code more modular and understandable.
- **Reduced Duplication**: Avoids writing custom HTTP client logic repeatedly for different API calls.

### Negative

- **New Dependency**: Introduces `faraday` and potentially other `faraday` ecosystem gems as new project dependencies, increasing the gem footprint.
- **Configuration Overhead**: Requires initial setup and configuration of Faraday, including choosing and arranging middleware, which can be a learning curve for new developers.
- **Abstraction Layer**: Adds a layer of abstraction (`HTTPClient`, `HTTPRequestBuilder`) which, while beneficial, means developers interact with Faraday indirectly rather than directly.

### Neutral

- **Middleware Complexity**: The power of Faraday's middleware can also introduce complexity if not managed carefully, requiring clear documentation of the middleware stack.

## Alternatives Considered

### `Net::HTTP` Directly

- **Why rejected**: `Net::HTTP` is Ruby's built-in HTTP client but is low-level and lacks many features (e.g., automatic retries, request/response logging, middleware) that are crucial for modern API interactions. Implementing these features directly would involve significant boilerplate and custom code.
- **Trade-offs**: No external dependencies. Very simple for basic, one-off requests. Becomes unwieldy for complex scenarios.

### Other HTTP Client Gems (e.g., `HTTParty`, `RestClient`, `Excon`)

- **Why rejected**: While many good HTTP client gems exist, Faraday was chosen for its strong middleware architecture, making it highly extensible and composable. Some alternatives might be simpler for basic use cases but lack the flexibility and ecosystem of Faraday for complex, enterprise-grade applications.
- **Trade-offs**: Each gem has its own strengths and weaknesses. Some might be simpler for quick prototypes, while others might offer specific features (e.g., performance, specific protocol support). Faraday's extensibility was the decisive factor.

## Related Decisions

- Observability strategy (ADR-003) for integrating `FaradayDryMonitorLogger` and instrumenting HTTP calls.
- CI-Aware VCR configuration (ADR-001) for robust testing of HTTP interactions without relying on external services in CI.

## References

- [Faraday GitHub Repository](https://github.com/lostisland/faraday)
- [Faraday Documentation](https://lostisland.github.io/faraday/)
- `HTTPClient` and `HTTPRequestBuilder` patterns (conceptual, from a component-based design perspective)