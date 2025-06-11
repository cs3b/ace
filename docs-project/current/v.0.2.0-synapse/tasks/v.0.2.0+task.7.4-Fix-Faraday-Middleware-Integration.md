---
id: v.0.2.0+task.7.4
status: done
priority: medium
estimate: 3h
dependencies: ["v.0.2.0+task.7.3"]
parent_task: v.0.2.0+task.7
---

# Fix Faraday Middleware Integration Issues

## Problem Analysis

After implementing dry-monitor integration and Faraday middleware refactoring in task v.0.2.0+task.7, there are potential issues with the middleware stack configuration that may be contributing to test failures. The custom `FaradayDryMonitorLogger` middleware and the standard JSON parsing middleware may have integration problems.

### Root Cause

The middleware integration issues stem from:
1. Incorrect middleware ordering in the Faraday stack
2. Potential conflicts between custom dry-monitor middleware and standard Faraday middleware
3. Missing or incorrectly configured middleware dependencies
4. Middleware not being properly registered or loaded

### Potential Issues Identified

1. **Middleware Load Order**:
   - Custom middleware may interfere with JSON parsing
   - Request/response flow through middleware stack may be disrupted

2. **Missing Dependencies**:
   - `dry-monitor` or `dry-configurable` gems may not be properly loaded
   - Notifications module may not be initialized correctly

3. **Middleware Registration**:
   - Custom middleware may not be properly registered with Faraday
   - Middleware class loading issues

## Objective

Ensure the Faraday middleware stack is properly configured with correct ordering and all middleware components work together harmoniously. Verify that the dry-monitor integration doesn't interfere with core HTTP functionality.

## Scope of Work

### Files to Investigate and Fix

1. **HTTPClient** (`lib/coding_agent_tools/atoms/http_client.rb`)
   - Middleware ordering in connection setup
   - Middleware configuration parameters
   - Error handling for middleware failures

2. **FaradayDryMonitorLogger** (`lib/coding_agent_tools/middlewares/faraday_dry_monitor_logger.rb`)
   - Middleware implementation correctness
   - Proper integration with Faraday middleware API
   - Error handling and edge cases

3. **Notifications Module** (`lib/coding_agent_tools/notifications.rb`)
   - Proper initialization of dry-monitor
   - Thread safety considerations
   - Error handling for missing dependencies

4. **Main Library File** (`lib/coding_agent_tools.rb`)
   - Zeitwerk configuration for middleware loading
   - Dependency loading order

## Detailed Investigation

### Current Middleware Stack
```ruby
# In HTTPClient#connection
faraday.request :json
faraday.use :faraday_dry_monitor_logger,
  notifications_instance: CodingAgentTools::Notifications.notifications,
  event_namespace: @event_namespace
faraday.response :json, parser_options: {symbolize_names: true}
faraday.adapter Faraday.default_adapter
```

### Potential Issues

1. **Middleware Symbol vs Class**:
   - Using `:faraday_dry_monitor_logger` symbol requires proper registration
   - May need to use class directly: `FaradayDryMonitorLogger`

2. **Middleware Ordering**:
   - Request middleware should come before response middleware
   - Custom logging middleware position affects what it can observe

3. **Dependency Loading**:
   - Notifications module must be loaded before middleware instantiation
   - dry-monitor gems must be available

## Implementation Plan

### Phase 1: Verify Middleware Loading

1. **Test middleware registration**:
```ruby
# Test if middleware is properly registered
puts Faraday::Middleware.registered_middleware.key?(:faraday_dry_monitor_logger)
```

2. **Check direct class usage**:
```ruby
# Test direct class reference
faraday.use CodingAgentTools::Middlewares::FaradayDryMonitorLogger,
  notifications_instance: CodingAgentTools::Notifications.notifications,
  event_namespace: @event_namespace
```

### Phase 2: Fix Middleware Registration

**Option A: Register Middleware Properly**
```ruby
# In lib/coding_agent_tools/middlewares/faraday_dry_monitor_logger.rb
Faraday::Middleware.register_middleware(
  faraday_dry_monitor_logger: CodingAgentTools::Middlewares::FaradayDryMonitorLogger
)
```

**Option B: Use Class Directly**
```ruby
# In HTTPClient
faraday.use CodingAgentTools::Middlewares::FaradayDryMonitorLogger,
  notifications_instance: CodingAgentTools::Notifications.notifications,
  event_namespace: @event_namespace
```

### Phase 3: Optimize Middleware Ordering

```ruby
def connection(url)
  Faraday.new(url: url) do |faraday|
    # Request middleware (processes outgoing requests)
    faraday.request :json
    
    # Custom middleware (logging/monitoring)
    faraday.use CodingAgentTools::Middlewares::FaradayDryMonitorLogger,
      notifications_instance: CodingAgentTools::Notifications.notifications,
      event_namespace: @event_namespace
    
    # Response middleware (processes incoming responses) 
    faraday.response :json, parser_options: {symbolize_names: true}
    
    # Adapter (must be last)
    faraday.adapter Faraday.default_adapter
  end
end
```

### Phase 4: Add Error Handling

```ruby
def connection(url)
  Faraday.new(url: url) do |faraday|
    faraday.request :json
    
    # Add middleware with error handling
    begin
      faraday.use CodingAgentTools::Middlewares::FaradayDryMonitorLogger,
        notifications_instance: CodingAgentTools::Notifications.notifications,
        event_namespace: @event_namespace
    rescue LoadError, NameError => e
      # Log warning but continue without middleware
      warn "Warning: Could not load dry-monitor middleware: #{e.message}"
    end
    
    faraday.response :json, parser_options: {symbolize_names: true}
    faraday.adapter Faraday.default_adapter
  end
end
```

### Phase 5: Test Integration

1. **Test with middleware disabled**:
```ruby
# Temporarily disable custom middleware to isolate issues
# Comment out dry-monitor middleware and test
```

2. **Test middleware in isolation**:
```ruby
# Create minimal test to verify middleware works
conn = Faraday.new do |f|
  f.use CodingAgentTools::Middlewares::FaradayDryMonitorLogger,
    notifications_instance: CodingAgentTools::Notifications.notifications,
    event_namespace: :test
  f.adapter :test do |stub|
    stub.get('/test') { [200, {}, '{"success": true}'] }
  end
end

response = conn.get('/test')
```

## Testing Strategy

### Middleware-Specific Tests

1. **Test middleware registration**:
```bash
ruby -e "
require './lib/coding_agent_tools'
puts CodingAgentTools::Middlewares::FaradayDryMonitorLogger.name
"
```

2. **Test HTTP client with middleware**:
```bash
ruby -e "
require './lib/coding_agent_tools'
require 'webmock/rspec'
WebMock.enable!
stub_request(:get, 'http://example.com').to_return(body: '{\"test\": true}')
client = CodingAgentTools::Atoms::HTTPClient.new
response = client.get('http://example.com')
puts response.body.class
"
```

### Integration Tests

1. **Full request/response cycle**:
```bash
bundle exec rspec spec/coding_agent_tools/atoms/http_client_spec.rb
```

2. **Middleware event emission**:
```ruby
# Test that events are properly emitted
notifications = CodingAgentTools::Notifications.notifications
received_events = []
notifications.subscribe('http_client.request.coding_agent_tools') do |event|
  received_events << event
end

# Make request and verify events
```

## Deliverables

### Modified Files

- `lib/coding_agent_tools/atoms/http_client.rb` - Fixed middleware configuration
- `lib/coding_agent_tools/middlewares/faraday_dry_monitor_logger.rb` - Proper registration and error handling
- `lib/coding_agent_tools/notifications.rb` - Improved initialization and error handling

### Tests

- Middleware integration tests
- HTTP client tests with middleware enabled/disabled
- Error handling tests for missing dependencies

## Acceptance Criteria

- [x] AC1: Custom FaradayDryMonitorLogger middleware loads without errors
- [x] AC2: Middleware is properly integrated into Faraday stack
- [x] AC3: JSON parsing still works correctly with custom middleware
- [x] AC4: HTTP requests complete successfully with middleware enabled
- [x] AC5: Events are properly emitted to dry-monitor notifications
- [x] AC6: System gracefully handles missing dry-monitor dependencies
- [x] AC7: Middleware ordering doesn't interfere with request/response processing
- [x] AC8: All HTTP client tests pass with middleware enabled

## Risk Assessment

**Low-Medium Risk**: Middleware issues could break HTTP functionality entirely.

**Mitigation**: 
- Add fallback behavior when middleware fails to load
- Comprehensive testing with middleware enabled/disabled
- Option to disable custom middleware via configuration

## Debugging Commands

```bash
# Test middleware loading in isolation
ruby -e "
require './lib/coding_agent_tools/middlewares/faraday_dry_monitor_logger'
puts CodingAgentTools::Middlewares::FaradayDryMonitorLogger
"

# Test notifications module
ruby -e "
require './lib/coding_agent_tools/notifications'
puts CodingAgentTools::Notifications.notifications.class
"

# Test full HTTP client
ruby -e "
require './lib/coding_agent_tools'
client = CodingAgentTools::Atoms::HTTPClient.new
puts 'HTTP client loaded successfully'
"

# Test specific failing scenarios
bundle exec rspec spec/coding_agent_tools/atoms/http_client_spec.rb --format documentation
```

## Configuration Options

Consider adding configuration to control middleware behavior:
```ruby
# In HTTPClient
def initialize(options = {})
  @enable_monitoring = options.fetch(:enable_monitoring, true)
  # ... rest of initialization
end

def connection(url)
  Faraday.new(url: url) do |faraday|
    faraday.request :json
    
    if @enable_monitoring
      faraday.use CodingAgentTools::Middlewares::FaradayDryMonitorLogger,
        notifications_instance: CodingAgentTools::Notifications.notifications,
        event_namespace: @event_namespace
    end
    
    faraday.response :json, parser_options: {symbolize_names: true}
    faraday.adapter Faraday.default_adapter
  end
end
```

## References

- [Faraday Middleware Documentation](https://lostisland.github.io/faraday/middleware/)
- [dry-monitor Documentation](https://dry-rb.org/gems/dry-monitor/)
- [Original Task v.0.2.0+task.7](v.0.2.0+task.7-Implement-Code-Quality-Improvements.md)
- [Faraday Middleware Registration](https://lostisland.github.io/faraday/middleware/custom)