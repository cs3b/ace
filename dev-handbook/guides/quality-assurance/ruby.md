# Ruby Quality Assurance Examples

This file provides Ruby-specific examples related to the main [Quality Assurance Guide](../quality-assurance.g.md).

* **Linters/Formatters:** `rubocop`, `standardrb`
* **Static Analysis:** `brakeman` (Security), `reek` (Code Smells)
* **Test Coverage:** `simplecov`
* **CI Configuration:** Examples for GitHub Actions, GitLab CI, etc. using Ruby setup actions.

**Example `.standard.yml` (StandardRB config):**

```yaml
fix: true               # default: false
parallel: true          # default: false
format: progress        # default: Standard::Formatter
ignore:
  - 'db/schema.rb'
  - 'vendor/**/*'
```

**Example `simplecov` setup (in `spec/spec_helper.rb` or `test/test_helper.rb`):**

```ruby
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/' # Ignore spec files themselves
  add_filter '/vendor/'
  # add_group 'Controllers', 'app/controllers'
  # minimum_coverage 90
end

# Rest of spec_helper/test_helper
```
