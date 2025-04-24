# Ruby Security Examples

This file provides Ruby-specific examples related to the main [Security Guide](../security.md).

*   **Dependency Scanning:** `bundler-audit`, GitHub Dependabot/Security Alerts
*   **Static Analysis (SAST):** `brakeman` (for Rails)
*   **Input Validation:** ActiveModel validations (Rails), custom validation logic.
*   **Secure Configuration:** Using environment variables, Rails credentials.

```ruby
# Example: Secure file path handling (avoiding directory traversal)
require 'pathname'

BASE_DIR = Pathname.new('/safe/base/path').realpath

def read_user_file(user_input)
  requested_path = BASE_DIR.join(user_input)

  # Basic check (more robust checks might be needed)
  unless requested_path.realpath.to_s.start_with?(BASE_DIR.to_s)
    raise ArgumentError, "Invalid file path: #{user_input}"
  end

  # Proceed with reading requested_path if valid
  File.read(requested_path)
end
```
