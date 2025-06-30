# Create API Documentation Workflow Instruction

## Goal

Generate or update API documentation for public interfaces (classes, modules, methods) using standard documentation tools and following consistent documentation patterns.

## Prerequisites

- Code with public interfaces that need documentation
- Documentation generation tool configured (e.g., YARD for Ruby, JSDoc for JavaScript)
- Understanding of the code's functionality and intended usage

## Project Context Loading

- Load project objectives: `docs/what-do-we-build.md`
- Load architecture overview: `docs/architecture.md`
- Load project structure: `docs/blueprint.md`

## High-Level Execution Plan

### Planning Steps

- [ ] Identify target code requiring API documentation
- [ ] Analyze code structure to understand interfaces and functionality
- [ ] Determine appropriate documentation standards for the project's technology stack

### Execution Steps

- [ ] Write comprehensive documentation comments for all public APIs
- [ ] Include usage examples and parameter descriptions
- [ ] Generate and review documentation output
- [ ] Fix any formatting or content issues
- [ ] Commit documentation updates to version control

## Process Steps

1. **Identify Target Code:**
   - Determine which code needs documentation:
     - New classes, modules, or methods
     - Modified public APIs
     - Undocumented public interfaces
     - Code with outdated documentation
   - Priority order:
     - Public APIs used by external consumers
     - Core domain models and services
     - Utility classes and helpers
     - Internal implementation details (lower priority)

2. **Analyze Code Structure:**
   - Review the code to understand:
     - Purpose and responsibility
     - Input parameters and their types
     - Return values and types
     - Possible exceptions or errors
     - Side effects or state changes
     - Usage patterns and examples
     - Performance characteristics
     - Thread safety considerations

3. **Write Documentation Comments:**

   **Ruby/YARD Example:**

   Use the Ruby YARD template: path (dev-handbook/templates/code-docs/ruby-yard.template.md)

   **JavaScript/JSDoc Example:**

   Use the JavaScript JSDoc template: path (dev-handbook/templates/code-docs/javascript-jsdoc.template.md)

4. **Documentation Standards:**

   **Required Elements:**
   - **Description**: Clear, concise explanation of what the code does
   - **Parameters**: All parameters with types and descriptions
   - **Return Value**: Type and description of what's returned
   - **Exceptions**: All possible exceptions/errors that can be thrown
   - **Examples**: At least one realistic usage example

   **Optional Elements:**
   - **Notes**: Important behaviors, constraints, or warnings
   - **See Also**: Links to related classes, methods, or docs
   - **Since**: Version when added (for public APIs)
   - **Deprecated**: Deprecation notices with migration path
   - **Todo**: Known limitations or future improvements

5. **Common Documentation Patterns:**

   **Class/Module Documentation:**

   ```ruby
   # Handles user authentication and session management
   #
   # This module provides methods for authenticating users,
   # managing sessions, and handling authentication tokens.
   # It supports multiple authentication strategies including
   # password-based and OAuth.
   #
   # @example Basic authentication
   #   include Authentication
   #   
   #   if authenticate_user(email, password)
   #     # User authenticated successfully
   #   end
   #
   # @see AuthenticationStrategy
   # @see SessionManager
   module Authentication
   ```

   **Configuration/Options Documentation:**

   ```ruby
   # @param options [Hash] Configuration options
   # @option options [Integer] :timeout (30) Request timeout in seconds
   # @option options [Integer] :retries (3) Number of retry attempts
   # @option options [Boolean] :ssl_verify (true) Whether to verify SSL
   # @option options [Logger] :logger (Rails.logger) Logger instance
   ```

   **Callback/Block Documentation:**

   ```ruby
   # @yield [item] Gives each item to the block
   # @yieldparam item [Item] The current item being processed
   # @yieldreturn [Boolean] Whether to include the item
   ```

6. **Generate and Review Documentation:**

   ```bash
   # Ruby/YARD
   bundle exec yard doc
   bundle exec yard server  # View at http://localhost:8808
   
   # JavaScript/JSDoc
   npx jsdoc -c jsdoc.json
   
   # Python/Sphinx
   sphinx-build -b html source build
   ```

   **Review Checklist:**
   - [ ] All public methods are documented
   - [ ] Parameter types are accurate
   - [ ] Examples are correct and runnable
   - [ ] Links are not broken
   - [ ] Formatting renders correctly
   - [ ] No spelling/grammar errors

7. **Common Issues and Fixes:**

   **Missing Types:**

   ```ruby
   # Bad - missing type information
   # @param user The user to process
   
   # Good - includes type
   # @param user [User] The user to process
   ```

   **Vague Descriptions:**

   ```ruby
   # Bad - too vague
   # Processes the data
   
   # Good - specific and helpful
   # Validates and transforms user input data into a normalized format
   # suitable for database storage
   ```

   **No Examples:**

   ```ruby
   # Bad - no usage example
   # @return [Hash] The result
   
   # Good - shows how to use
   # @return [Hash] The result containing :status and :data
   # @example
   #   result = process_data(input)
   #   puts result[:status]  # => :success
   #   puts result[:data]    # => { processed: true }
   ```

8. **Commit Documentation Updates:**

   ```bash
   git add -A
   git commit -m "docs(api): update documentation for PaymentService
   
   - Add comprehensive YARD documentation
   - Include usage examples
   - Document all exceptions
   - Add parameter type information"
   ```

## Success Criteria

- All public APIs have complete documentation comments
- Documentation includes all required elements (description, params, returns, examples)
- Generated documentation is accurate and renders correctly
- No broken links or formatting errors
- Examples are realistic and helpful
- Documentation follows consistent style and format

## Best Practices

**DO:**

- Write documentation as you code
- Include real-world examples
- Document edge cases and gotchas
- Keep descriptions concise but complete
- Update docs when code changes
- Use consistent terminology

**DON'T:**

- Leave TODOs in public API docs
- Include implementation details
- Copy-paste without reviewing
- Use ambiguous language
- Document obvious things
- Forget to document exceptions

## Documentation Tools by Language

- **Ruby**: YARD (`yard doc`)
- **JavaScript**: JSDoc (`jsdoc`)
- **TypeScript**: TypeDoc (`typedoc`)
- **Python**: Sphinx (`sphinx-build`)
- **Java**: Javadoc (`javadoc`)
- **C#**: XML Documentation (`///`)

## Common Patterns

### New Feature API Documentation

Document public interfaces when adding new features or capabilities to existing modules.

### Refactoring Documentation Updates

Update API documentation when refactoring changes method signatures or behavior.

### Legacy Code Documentation

Add comprehensive documentation to existing code that lacks proper API documentation.

### Documentation Generation Integration

Integrate API documentation generation into the build process for automatic updates.

## Usage Example
>
> "I've added new public methods to the PaymentService class. Help me create proper API documentation for these methods."

---

This workflow ensures comprehensive, consistent API documentation that helps developers understand and use your code effectively.

<templates>
    <template path="dev-handbook/templates/code-docs/ruby-yard.template.md">
# Processes payment transactions using the configured gateway
#
# This service handles payment processing including validation,
# gateway communication, and error handling. It supports multiple
# payment methods and implements retry logic for transient failures.
#
# @example Process a credit card payment
#   payment_service = PaymentService.new
#   result = payment_service.process(
#     amount: 99.99,
#     currency: 'USD',
#     payment_method: credit_card
#   )
#
# @example Handle payment errors
#   begin
#     result = payment_service.process(payment_data)
#   rescue PaymentService::InvalidAmount => e
#     Rails.logger.error("Invalid amount: #{e.message}")
#   end
#
# @param amount [BigDecimal] The payment amount (must be positive)
# @param currency [String] ISO 4217 currency code (e.g., 'USD', 'EUR')
# @param payment_method [PaymentMethod] The payment method to use
# @param options [Hash] Additional options
# @option options [Boolean] :capture (true) Whether to capture immediately
# @option options [String] :idempotency_key Unique key for idempotent requests
#
# @return [PaymentResult] The result object containing transaction details
#
# @raise [InvalidAmount] if amount is negative or zero
# @raise [UnsupportedCurrency] if currency is not supported
# @raise [GatewayError] if gateway communication fails
#
# @note This method is thread-safe
# @note Transactions are automatically logged for audit purposes
#
# @see PaymentResult
# @see PaymentMethod
# @see https://docs.example.com/payments
#
# @since 2.1.0
def process(amount:, currency:, payment_method:, **options)
  # Implementation
end
    </template>

    <template path="dev-handbook/templates/code-docs/javascript-jsdoc.template.md"># JavaScript JSDoc Documentation Template

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
</template>

</templates>
