# HTTP Retry Strategy Design

## Overview

Design retry middleware with exponential back-off for HTTP 429/5xx errors to improve reliability of HTTP operations in the Coding Agent Tools gem.

## Retry Strategy Types

### 1. Rate Limit Retries (HTTP 429)
- **Initial Delay**: 1 second
- **Max Delay**: 60 seconds
- **Max Attempts**: 5
- **Backoff Strategy**: Exponential with jitter
- **Jitter**: ±25% to prevent thundering herd
- **Respect Retry-After Header**: Yes

### 2. Server Error Retries (HTTP 5xx)
- **Initial Delay**: 2 seconds
- **Max Delay**: 30 seconds
- **Max Attempts**: 3
- **Backoff Strategy**: Exponential with jitter
- **Jitter**: ±25%
- **Respect Retry-After Header**: If present

### 3. Network Error Retries
- **Initial Delay**: 1 second
- **Max Delay**: 16 seconds
- **Max Attempts**: 4
- **Backoff Strategy**: Exponential with jitter
- **Jitter**: ±25%
- **Error Types**: Timeout, Connection refused, DNS errors

### 4. Client Error Policy (HTTP 4xx except 429)
- **Retry**: No (except 429)
- **Reason**: Client errors typically indicate request issues that won't resolve with retries

## Exponential Backoff Formula

```
delay = min(initial_delay * (2 ^ attempt), max_delay)
jittered_delay = delay * (1 + random(-0.25, 0.25))
```

## Configuration Options

### Default Configuration
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

### Customizable Per Client
- Allow providers to override default retry policies
- Support disabling retries for testing
- Allow custom retry conditions

## Implementation Architecture

### RetryMiddleware Class
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

### Integration Points
1. **HTTPClient Atom**: Add retry middleware to Faraday connection
2. **Configuration**: Allow clients to customize retry behavior
3. **Logging**: Log retry attempts and decisions
4. **Monitoring**: Emit events for retry operations

## Error Classification

### Retryable Errors
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

### Non-Retryable Errors
- HTTP 4xx (except 429): Client errors
- HTTP 200-299: Success responses
- Specific network errors: SSL certificate errors
- Application-specific errors: Authentication failures

## Retry-After Header Support

### HTTP 429 with Retry-After
- Parse Retry-After header (seconds or HTTP date)
- Use header value if present and reasonable
- Cap at max_delay to prevent excessive waits
- Fall back to exponential backoff if header missing

### Implementation
```ruby
def parse_retry_after(header_value)
  return nil if header_value.nil?
  
  # Try parsing as seconds
  if header_value.match?(/^\d+$/)
    header_value.to_i
  else
    # Try parsing as HTTP date
    begin
      Time.parse(header_value) - Time.now
    rescue
      nil
    end
  end
end
```

## Logging and Monitoring

### Log Events
- Retry attempt started
- Retry delay calculated
- Retry attempt completed/failed
- Final success/failure after all retries

### Log Levels
- INFO: Retry attempts and final outcomes
- DEBUG: Detailed retry calculations and delays
- WARN: Unusual retry scenarios (high delay, max attempts reached)
- ERROR: Final failure after all retries exhausted

### Monitoring Events
```ruby
# Events emitted via dry-monitor
retry.attempt_started
retry.delay_calculated
retry.attempt_completed
retry.final_success
retry.final_failure
```

## Testing Strategy

### Unit Tests
- Test retry decision logic for different error types
- Test exponential backoff calculations
- Test jitter application
- Test Retry-After header parsing
- Test configuration validation

### Integration Tests
- Test end-to-end retry behavior with HTTP client
- Test timeout behavior during retries
- Test circuit breaker scenarios (max attempts)
- Test interaction with provider clients

### Mock Scenarios
- Simulate rate limit responses (429)
- Simulate server errors (5xx)
- Simulate network failures
- Test retry-after header compliance

## Security Considerations

### Request Replay Safety
- Only retry idempotent operations (GET, HEAD, PUT with idempotency)
- Avoid retrying POST requests by default
- Allow explicit configuration for non-idempotent retries

### Credential Security
- Don't log sensitive headers during retry logging
- Ensure credentials aren't exposed in retry error messages
- Validate retry headers to prevent injection attacks

### DoS Prevention
- Respect server-indicated retry delays
- Implement maximum retry limits
- Add circuit breaker patterns for consistent failures

## Configuration Examples

### Conservative (Default)
```ruby
retry_config = {
  enabled: true,
  max_attempts: { rate_limit: 3, server_error: 2, network_error: 3 },
  initial_delay: { rate_limit: 1.0, server_error: 2.0, network_error: 1.0 },
  max_delay: { rate_limit: 30.0, server_error: 15.0, network_error: 8.0 }
}
```

### Aggressive (High Availability)
```ruby
retry_config = {
  enabled: true,
  max_attempts: { rate_limit: 8, server_error: 5, network_error: 6 },
  initial_delay: { rate_limit: 0.5, server_error: 1.0, network_error: 0.5 },
  max_delay: { rate_limit: 120.0, server_error: 60.0, network_error: 32.0 }
}
```

### Testing (Disabled)
```ruby
retry_config = {
  enabled: false
}
```