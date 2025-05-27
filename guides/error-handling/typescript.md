# TypeScript Error Handling Examples

This file provides TypeScript-specific examples related to the main [Error Handling Guide](../error-handling.md).

* **Mechanism:** try/catch/finally/throw
* **Custom Errors:** Extend the built-in Error class.

```typescript
class CustomError extends Error {
  context: Record<string, any>;

  constructor(message: string, context: Record<string, any> = {}) {
    super(message);
    this.name = 'CustomError'; // Important for identifying error type
    this.context = context;
    // Ensure the prototype chain is set correctly
    Object.setPrototypeOf(this, CustomError.prototype);
  }
}

try {
  // Code that might throw an error
  if (someCondition) {
    throw new CustomError('Failed operation', { data: 'example' });
  }
} catch (error) {
  if (error instanceof CustomError) {
    console.error(`Caught custom error: ${error.message}, Context:`, error.context);
  } else if (error instanceof Error) {
    console.error(`Caught other error: ${error.message}`);
  } else {
    console.error('Caught unknown error:', error);
  }
} finally {
  // Cleanup code
  console.log('Ensuring cleanup');
}
```
