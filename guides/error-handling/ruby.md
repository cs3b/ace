# Ruby Error Handling Examples

This file provides Ruby-specific examples related to the main [Error Handling Guide](../error-handling.md).

*   **Mechanism:** `begin`/`rescue`/`ensure`/`raise`
*   **Standard Library:** StandardError hierarchy

```ruby
class CustomError < StandardError
  attr_reader :context

  def initialize(message = "Something went wrong", context = {})
    super(message)
    @context = context
  end
end

begin
  # Code that might raise an error
  raise CustomError.new("Failed operation", { data: 'example' }) if some_condition
rescue CustomError => e
  puts "Caught custom error: #{e.message}, Context: #{e.context}"
rescue StandardError => e
  puts "Caught other standard error: #{e.message}"
ensure
  # Cleanup code
  puts "Ensuring cleanup"
end
```
