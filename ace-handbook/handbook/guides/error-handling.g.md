---
doc-type: guide
title: Error Handling Guidelines
purpose: Documentation for ace-handbook/handbook/guides/error-handling.g.md
ace-docs:
  last-updated: 2026-01-08
  last-checked: 2026-03-21
---

# Error Handling Guidelines

## Goal

This guide outlines the fundamental principles and standards for handling errors consistently and effectively
throughout the project, ensuring robustness, debuggability, and a good user experience.

## Exception Hierarchy

Establish a clear hierarchy for custom exceptions or error types specific to your application or
library. This allows for more granular error handling.

- Define a base error class/type for your application (e.g., `MyAppError`).
- Create specific error subclasses that inherit from the base error (e.g., `ConfigurationError`, `ApiError`, `DatabaseError`).
- Include relevant context within your error objects (see 'Rich Context' below).

```javascript
// Pseudo-code example hierarchy
class MyAppError extends Error {}
class ConfigurationError extends MyAppError {}
class AgentError extends MyAppError {
  constructor(message, context = {}) {
    super(message);
    this.context = context;
  }
}
class ToolError extends MyAppError {}
class ExternalServiceError extends MyAppError {
  constructor(message, requestId = null) {
    super(message);
    this.requestId = requestId;
  }
}
```

## Best Practices

1. **Rich Context**:
   When catching and logging errors, include as much relevant context as possible without logging sensitive data.
   This aids debugging.

   ```javascript
   // Pseudo-code example
   try {
     agent.execute(task);
   } catch (error) {
     if (error instanceof AgentError) {
       logger.error("Agent execution failed", {
         errorMessage: error.message,
         errorContext: error.context,
         stackTrace: error.stack.substring(0, 500) // Log part of the stack
       });
     } else {
       logger.error("Unexpected error during agent execution", {
         errorMessage: error.message,
         stackTrace: error.stack.substring(0, 500)
       });
     }
   }
   ```

2. **Recovery Strategies**:
   Implement strategies to recover from transient errors, especially network-related issues.

   ```javascript
   // Pseudo-code example: Retry with exponential backoff
   function executeWithRetry(task) {
     let retries = 0;
     const maxRetries = 3;
     while (true) {
       try {
         return agent.execute(task);
       } catch (error) {
         if (error instanceof ExternalServiceError && retries < maxRetries) {
           retries++;
           const delay = Math.pow(2, retries) * 1000; // Exponential backoff
           sleep(delay);
         } else {
           throw error; // Re-throw if max retries reached or not a recoverable error
         }
       }
     }
   }
   ```

3. **Clean Resource Management**:
   Ensure resources (files, network connections, locks) are properly released, even if errors occur. Use
   `try...finally` or equivalent language constructs (like Python\'s `with` statement or Go\'s `defer`).

   ```javascript
   // Pseudo-code example
   let resource = acquireResource();
   try {
     // Use the resource
     yield resource;
   } finally {
     releaseResource(resource);
   }
   ```

## Debugging Guide

## Advanced Error Handling Patterns

Consider these patterns for more robust applications:

- **Structured Error Objects:** Define custom error classes/types that include relevant context (e.g., status codes,
  internal error codes, request IDs). This helps in programmatic error handling and monitoring.

  ```javascript
  // Pseudo-code example
  class ApiError extends Error {
    constructor(message, { statusCode = 500, errorCode = 'UNKNOWN', details = {} } = {}) {
      super(message);
      this.statusCode = statusCode;
      this.errorCode = errorCode;
      this.details = details;
    }
  }
  // Example usage:
  // throw new ApiError("User not found", { statusCode: 404, errorCode: 'USER_NOT_FOUND', details: { userId: id } });
  ```

- **Error Categorization:** Distinguish between:
  - **Operational Errors:** Expected issues (e.g., invalid input, resource not found) that can often be handled
    gracefully.
  - **Programming Errors:** Bugs in the code that need fixing (e.g., type errors, null references).
  - **System Errors:** External issues (e.g., database unavailable, network failure).
- **Recovery Strategies:** Implement strategies for transient failures:
  - **Retry with Backoff:** Automatically retry failed operations (especially network requests) with increasing
    delays.
  - **Circuit Breaker:** Prevent repeated calls to a failing service by temporarily blocking
    requests after a certain number of failures.
  - **Fallbacks:** Provide a degraded but functional experience if a primary operation
    fails (e.g., return cached data if a live fetch fails).
- **Contextual Logging:** Ensure logs capture sufficient context (user ID, request ID,
  operation parameters) to diagnose errors effectively, while avoiding sensitive data.

1. **Enable Debug Logging**:
   Configure your application\'s logger to output detailed debug messages when needed.
   This often involves setting a log level via configuration.

   ```javascript
   // Example: Conceptual configuration
   MyApp.configure({
     logLevel: 'debug', // Or 'info', 'warn', 'error'
     logFormatter: (severity, timestamp, message) => {
       return `[${timestamp}] ${severity.toUpperCase()}: ${message}`;
     }
   });
   ```

2. **Inspect State**:
   Provide mechanisms to inspect the internal state of key components during debugging, if feasible and safe.

   ```javascript
   // Example: Conceptual methods (actual implementation depends on language/design)
   let debugInfo = agent.getDebugInfo();
   let trace = agent.getExecutionTrace();
   ```

3. **Common Issues**:

- LLM timeouts: Check network and retry settings
- Memory issues: Review resource cleanup
- Thread deadlocks: Check lock ordering

## Error Context

Always include relevant context when raising or logging errors. This aids debugging significantly.

**Good Context:**

```plaintext
// Log the error with context
logError(\"Failed to process user data\", error, { userId: 123, operation: \'updateProfile\' });

// Raise error with context
throw new UserProcessingError(\"Failed to update profile for user 123\", { originalError: error, userId: 123 });
```

**Avoid Generic Messages:**

```plaintext
// Less helpful
logError("An error occurred", error);
throw new Error("Something went wrong");
```

## Language/Environment-Specific Examples

For specific code examples demonstrating error handling patterns, custom error classes, or library integrations
in different languages (e.g., Ruby\'s `begin/rescue`, Python\'s `try/except`, JavaScript\'s `try/catch`,

## Related Documentation

- [Coding Standards](./coding-standards.g.md)
- [Quality Assurance](./quality-assurance.g.md) (Logging, Monitoring)
