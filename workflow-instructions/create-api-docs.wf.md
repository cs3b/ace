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

   Use the Ruby YARD template:

   **JavaScript/JSDoc Example:**

   Use the JavaScript JSDoc template:

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

<documents>
    <template path="dev-handbook/templates/code-docs/ruby-yard.template.md"># Ruby YARD Documentation Template

```ruby
# [Brief description of what this method/class does]
#
# [Detailed description including purpose, behavior, and context.
# Explain what the method/class does, why it's useful, and how it fits
# into the larger system.]
#
# @example [Example title]
#   [code example showing basic usage]
#
# @example [Another example title] 
#   [code example showing advanced usage or error handling]
#
# @param [parameter_name] [Type] [Description of parameter]
# @param [another_param] [Type] [Description with constraints/validation]
# @param [options] [Hash] [Description of options hash]
# @option options [Type] :option_name (default_value) [Description]
# @option options [Type] :another_option [Description]
#
# @return [ReturnType] [Description of what is returned]
#
# @raise [ExceptionClass] [Description of when this exception is raised]
# @raise [AnotherException] [Description of another exception condition]
#
# @note [Important note about usage, threading, performance, etc.]
# @note [Another important note]
#
# @see [RelatedClass]
# @see [RelatedMethod]
# @see [URL to external documentation]
#
# @since [version when this was added]
# @deprecated [version when deprecated] Use [alternative] instead
#
def method_name(parameter_name:, another_param:, **options)
  # Implementation
end
```

## YARD Tag Reference

### Basic Tags

- `@param` - Parameter documentation
- `@return` - Return value documentation  
- `@raise` - Exception documentation
- `@example` - Code examples
- `@note` - Important notes
- `@see` - Cross-references

### Metadata Tags

- `@since` - Version when added
- `@deprecated` - Deprecation notice
- `@author` - Author information
- `@version` - Version information

### Advanced Tags

- `@option` - Hash option documentation
- `@overload` - Method overloads
- `@yield` - Block documentation
- `@yieldparam` - Block parameter documentation
- `@yieldreturn` - Block return documentation

## Documentation Guidelines

1. **Start with a brief one-line summary**
2. **Follow with detailed description if needed**
3. **Provide realistic examples**
4. **Document all parameters and return values**
5. **Include exception conditions**
6. **Add notes for important behavior**
7. **Use cross-references for related code**
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

</documents>
