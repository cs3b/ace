# JavaScript JSDoc Documentation Template

```javascript
/**
 * [Brief description of what this function/class does]
 * 
 * @description [Detailed description including purpose, behavior, and context.
 * Explain what the function/class does, why it's useful, and how it fits
 * into the larger system.]
 *
 * @param {Type} parameterName - [Description of parameter]
 * @param {Type} anotherParam - [Description with constraints/validation]
 * @param {Object} [options={}] - [Description of options object]
 * @param {Type} [options.optionName=defaultValue] - [Description of option]
 * @param {Type} [options.anotherOption] - [Description of another option]
 * 
 * @returns {Type|Promise<Type>} [Description of what is returned]
 * 
 * @throws {ErrorClass} [Description of when this error is thrown]
 * @throws {AnotherError} [Description of another error condition]
 * 
 * @example
 * // [Example title - basic usage]
 * const result = functionName(param1, param2);
 * 
 * @example
 * // [Example title - advanced usage]
 * try {
 *   const result = await functionName({
 *     param: 'value',
 *     options: { setting: true }
 *   });
 * } catch (error) {
 *   console.error('Error:', error.message);
 * }
 * 
 * @since [version when added]
 * @deprecated [version when deprecated] Use [alternative] instead
 */
function functionName(parameterName, anotherParam, options = {}) {
  // Implementation
}
```

## JSDoc Tag Reference

### Basic Tags

- `@param {Type} name - description` - Parameter documentation
- `@returns {Type} description` - Return value documentation  
- `@throws {ErrorType} description` - Exception documentation
- `@example` - Code examples
- `@description` - Detailed description

### Type Annotations

- `{string}` - String type
- `{number}` - Number type
- `{boolean}` - Boolean type
- `{Object}` - Object type
- `{Array<Type>}` - Array of specific type
- `{Type|null}` - Union types
- `{Promise<Type>}` - Promise types

### Optional Parameters

- `{Type} [paramName]` - Optional parameter
- `{Type} [paramName=defaultValue]` - Optional with default

### Metadata Tags

- `@since` - Version when added
- `@deprecated` - Deprecation notice
- `@author` - Author information
- `@version` - Version information

### Advanced Tags

- `@namespace` - Namespace documentation
- `@class` - Class documentation
- `@module` - Module documentation
- `@async` - Async function marker
- `@static` - Static method marker

## Documentation Guidelines

1. **Use TypeScript-style type annotations**
2. **Provide clear parameter descriptions**
3. **Include realistic examples**
4. **Document all possible exceptions**
5. **Use @description for complex explanations**
6. **Mark optional parameters clearly**
7. **Include version information for new features**
