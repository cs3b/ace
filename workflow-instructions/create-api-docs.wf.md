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
    <template path="{current-project-path}/src/services/PaymentService.rb" template-path="dev-handbook/templates/code-docs/ruby-yard.template.md">
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
    
    <template path="{current-project-path}/src/services/PaymentService.js" template-path="dev-handbook/templates/code-docs/javascript-jsdoc.template.md">
/**
 * Processes payment transactions using the configured gateway
 * 
 * @description This service handles payment processing including validation,
 * gateway communication, and error handling. Supports multiple payment methods.
 *
 * @param {number} amount - The payment amount in cents
 * @param {string} currency - ISO 4217 currency code
 * @param {PaymentMethod} paymentMethod - Payment method object
 * @param {Object} [options={}] - Additional options
 * @param {boolean} [options.capture=true] - Whether to capture immediately
 * @param {string} [options.idempotencyKey] - Unique key for idempotent requests
 * 
 * @returns {Promise<PaymentResult>} Promise resolving to payment result
 * 
 * @throws {InvalidAmountError} Amount must be positive
 * @throws {UnsupportedCurrencyError} Currency not supported
 * @throws {GatewayError} Gateway communication failure
 * 
 * @example
 * // Process a payment
 * const result = await paymentService.process({
 *   amount: 9999,
 *   currency: 'USD',
 *   paymentMethod: creditCard
 * });
 * 
 * @example
 * // With error handling
 * try {
 *   const result = await paymentService.process(paymentData);
 * } catch (error) {
 *   if (error instanceof InvalidAmountError) {
 *     console.error('Invalid amount:', error.message);
 *   }
 * }
 * 
 * @since 2.1.0
 */
async process({ amount, currency, paymentMethod, options = {} }) {
  // Implementation
}
    </template>
</templates>
