# ADR-007: Zeitwerk for Autoloading

## Status

Accepted
Date: 2025-06-08

## Context

The project's codebase, initially small, relied on manual `require` statements or simple `require_relative` patterns for loading classes and modules. As the project grew in complexity and size, this manual approach became increasingly cumbersome, prone to errors (e.g., forgotten `require` statements, circular dependencies), and difficult to maintain. There was a clear need for a more robust, standardized, and automated autoloading mechanism to improve developer experience, reduce boilerplate, and align with modern Ruby and Rails development practices.

## Decision

We decided to adopt Zeitwerk as the primary autoloading mechanism for the project. Zeitwerk, known for its performance and strict adherence to file naming conventions, provides an efficient and convention-over-configuration solution for autoloading.

The specific implementation includes:
- Configuring Zeitwerk to manage the project's autoload paths.
- Utilizing Zeitwerk's inflector configuration to handle acronym-based class names (e.g., `CLI`, `HTTP`, `API`) correctly, ensuring that `CLI` is autoloaded from `cli.rb` and not `c_l_i.rb`.

```ruby
# Example (conceptual) Zeitwerk configuration
# This would typically be set up in a central initialization file.
loader = Zeitwerk::Loader.new
loader.push_dir("lib") # Assuming 'lib' is the root of our autoloadable code
loader.inflector.inflect(
  "CLI" => "CLI",
  "HTTP" => "HTTP",
  "API" => "API"
)
loader.setup
```

## Consequences

### Positive

- **Standardized Autoloading**: Provides a consistent and reliable way to load classes and modules without explicit `require` statements.
- **Rails/Ruby Community Alignment**: Adopting Zeitwerk aligns the project with common practices in the Ruby and Rails ecosystems, making it easier for developers familiar with these environments to contribute.
- **Improved Developer Experience**: Developers no longer need to manually manage `require` paths, leading to faster development cycles and fewer "missing constant" errors.
- **Performance**: Zeitwerk is highly optimized for performance, loading only what's needed, when it's needed.
- **Reduced Boilerplate**: Eliminates the need for numerous `require` statements, making files cleaner and more focused on business logic.

### Negative

- **Strict File Naming Conventions**: Requires strict adherence to Zeitwerk's file naming conventions (e.g., `MyModule::MyClass` must be in `my_module/my_class.rb`). While beneficial for consistency, it can be a learning curve for new contributors or require refactoring existing files.
- **Initial Setup Complexity**: Requires careful initial setup and configuration to ensure all autoload paths are correctly defined and inflections are handled.
- **Debugging Autoloading Issues**: While rare, issues related to incorrect file naming or path configuration can sometimes be tricky to debug.

### Neutral

- **Explicit Inflector Configuration**: The need to explicitly configure inflections for acronyms adds a small amount of initial setup, but this is a one-time cost for significant benefit.

## Alternatives Considered

### Manual Autoloading / Extensive `require_relative` Usage

- **Why rejected**: Becomes unmanageable and error-prone in larger codebases. Leads to fragmented `require` statements spread across many files.
- **Trade-offs**: Simple for very small projects, but scales poorly and hinders maintainability.

### Other Autoloading Gems (e.g., `ActiveSupport::Dependencies`)

- **Why rejected**: `ActiveSupport::Dependencies` is largely superseded by Zeitwerk in modern Rails and Ruby applications, and Zeitwerk is designed to be a standalone component.
- **Trade-offs**: Might offer similar functionality but Zeitwerk is the current standard and offers better performance and explicit design for autoloading.

## Related Decisions

- Project structure and directory layout
- Code style and convention guidelines

## References

- [Zeitwerk GitHub Repository](https://github.com/fxn/zeitwerk)
- [Zeitwerk Documentation](https://github.com/fxn/zeitwerk#zeitwerk)