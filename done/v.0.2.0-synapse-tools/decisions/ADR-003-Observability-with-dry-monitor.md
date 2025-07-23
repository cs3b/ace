# ADR-003: Observability with dry-monitor

## Status

Accepted
Date: 2025-06-08

## Context

As the project grew in complexity, the need for better observability into key operations and internal events became critical for debugging, performance monitoring, and understanding system behavior. Without a standardized mechanism for event publishing and subscription, introducing new logging, metrics, or tracing capabilities would require intrusive modifications across various parts of the codebase. We needed a decoupled approach where components could publish events without knowing their subscribers, and subscribers could react to events without knowing their publishers.

## Decision

We decided to implement observability using `dry-monitor` via a central `Notifications` instance. This approach leverages `dry-monitor`'s publish/subscribe pattern to allow different parts of the application to emit events, which can then be consumed by various monitors (e.g., loggers, metrics collectors, debuggers).

A specific integration includes:
- A central `Notifications` instance, acting as the global event bus.
- Integration with `FaradayDryMonitorLogger` (or a similar custom logger adapter) to capture HTTP request/response events from the Faraday HTTP client. This ensures that all outgoing HTTP calls are automatically instrumented and logged through the `dry-monitor` system.

```ruby
# Example (conceptual) dry-monitor setup
# This would typically be initialized globally, e.g., in `config/initializers/monitor.rb`
# or injected into components that need to publish/subscribe.

require 'dry/monitor/notifications'
require 'faraday/dry_monitor_logger' # Assuming this gem/class exists or is custom-defined

module MyProject
  module Core
    class Notifications < Dry::Monitor::Notifications
      # Custom event definitions or additional setup can go here
    end

    # Global notifications instance
    NOTIFICATION_BUS = Notifications.new(:my_project)
  end
end

# Example of how Faraday might be configured to use the dry-monitor logger
# This would typically be part of the Faraday connection setup
# conn = Faraday.new(...) do |f|
#   f.use FaradayDryMonitorLogger, notifications: MyProject::Core::NOTIFICATION_BUS
#   # ... other middleware
# end

# Example of subscribing to an event
# MyProject::Core::NOTIFICATION_BUS.subscribe('http.request.finished') do |event|
#   # Log, metric, or trace the event
#   puts "HTTP Request finished: #{event.payload[:url]} in #{event.payload[:duration]}ms"
# end
```

## Consequences

### Positive

- **Standardized Event Publishing**: Provides a consistent and decoupled way for different parts of the application to emit events without direct dependencies on logging, metrics, or tracing systems.
- **Enhanced Observability**: Enables easy integration of various monitoring tools (logging, metrics, tracing) by simply subscribing to relevant events on the central `Notifications` instance.
- **Improved Debugging**: Critical events can be easily logged or inspected during development and production, aiding in diagnosing issues.
- **Testability**: Components that publish events can be tested in isolation, and monitors can be mocked or swapped out easily during testing.
- **Extensibility**: New monitoring requirements (e.g., adding a new metric provider) can be met by adding new subscribers without modifying existing business logic.

### Negative

- **Adds Dependencies**: Introduces `dry-monitor` and potentially related gems (like `FaradayDryMonitorLogger`) as new project dependencies.
- **Learning Curve**: New contributors may need to understand the `dry-monitor` concepts and the publish/subscribe pattern.
- **Potential for Event Overload**: Without careful design, too many events or overly verbose events could lead to performance overhead or noisy logs/metrics.
- **Event Definition Management**: Requires discipline in defining and documenting event names and their payloads to ensure consistency and usability.

### Neutral

- **Centralized `Notifications` Instance**: While beneficial for global reach, it means the `Notifications` instance needs to be accessible where events are published, potentially via dependency injection or a global singleton.

## Alternatives Considered

### Custom Logger / Direct Logging Calls

- **Why rejected**: Leads to tight coupling between business logic and logging implementation. Extending to metrics or tracing would require pervasive changes.
- **Trade-offs**: Simpler for very basic logging needs, but does not scale for comprehensive observability or multiple monitoring concerns.

### Other Monitoring Libraries (e.g., `ActiveSupport::Notifications`, `Prometheus Client for Ruby`)

- **Why rejected**: `ActiveSupport::Notifications` is tied to Rails and might be overkill or bring unnecessary dependencies for a non-Rails project. Direct Prometheus client integration would be too specific to metrics and not generic enough for general event publishing for debugging or logging.
- **Trade-offs**: `ActiveSupport::Notifications` is a viable alternative for Rails projects. Direct metric libraries are good for metrics-only concerns but less flexible for a broader observability strategy.

## Related Decisions

- HTTP client strategy (ADR-005) due to `FaradayDryMonitorLogger` integration.
- Error reporting strategy (ADR-004) for consistency in handling exceptions, although `dry-monitor` focuses on events.

## References

- [dry-monitor GitHub Repository](https://github.com/dry-rb/dry-monitor)
- [dry-rb ecosystem documentation](https://dry-rb.org/)
- `FaradayDryMonitorLogger` (conceptual/custom component, refers to the idea of an adapter for Faraday)