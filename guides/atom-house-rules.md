# ATOM Component Classification House Rules

## Overview

This guide provides practical rules and decision-making tools for correctly classifying components within the ATOM architecture used in the Coding Agent Tools project. Understanding these rules is crucial for maintaining code organization, ensuring proper separation of concerns, and preventing architectural drift.

The ATOM architecture organizes code into distinct layers based on complexity and responsibility:
- **Models**: Pure data carriers
- **Molecules**: Behavior-oriented helpers  
- **Organisms**: Complex business logic units
- **Atoms**: Basic utilities (foundation layer)
- **Ecosystems**: Cohesive groupings of organisms

## Why This Matters

Proper component classification ensures:
- **Maintainability**: Clear separation of concerns makes code easier to understand and modify
- **Reusability**: Components at the right abstraction level can be reused effectively
- **Testability**: Isolated responsibilities make unit testing straightforward
- **Architectural Consistency**: Prevents technical debt from accumulating due to misplaced code

## Quick Decision Flowchart

```
Start: I need to create a new class
    ↓
Is it ONLY data with no behavior?
    ↓ YES                           ↓ NO
Use Models/                    Does it perform I/O operations?
(Pure data structures)              ↓ YES                    ↓ NO
                              Does it orchestrate multiple    Is it a focused utility
                              components for business logic?  or helper function?
                                   ↓ YES          ↓ NO            ↓
                              Use Organisms/  Use Molecules/  Use Atoms/
                              (Business logic) (I/O helpers)  (Utilities)
```

## Component Classification Rules

### Models (`lib/coding_agent_tools/models/`)

**Purpose**: Pure data carriers with no external dependencies or side effects.

**Characteristics**:
- Typically implemented as `Struct` classes
- No I/O operations (no file access, no network calls, no database queries)  
- No external gem dependencies beyond Ruby standard library
- Focus solely on data representation and basic data manipulation
- Immutable when possible

**Good Examples**:
```ruby
# ✅ Good: Pure data structure
LlmModelInfo = Struct.new(:id, :name, :description, :default, keyword_init: true) do
  def default?
    default
  end
  
  def to_h
    {id: id, name: name, description: description, default: default}
  end
end
```

**Bad Examples**:
```ruby
# ❌ Bad: Contains I/O operations
class UserProfile < Struct.new(:name, :email)
  def save_to_file
    File.write("profile.json", to_json)  # I/O operation!
  end
end

# ❌ Bad: Has external dependencies
class ApiResponse < Struct.new(:data, :status)
  def parse_with_nokogiri
    Nokogiri::XML(data)  # External gem dependency!
  end
end
```

### Molecules (`lib/coding_agent_tools/molecules/`)

**Purpose**: Behavior-oriented helpers that encapsulate focused, reusable logic.

**Characteristics**:
- Single responsibility principle
- May perform I/O operations
- Compose atoms and other basic utilities
- Stateless or minimal state
- Can have external dependencies
- Focused on "how" to do something

**Good Examples**:
```ruby
# ✅ Good: Focused helper with specific responsibility
class HTTPRequestBuilder
  def initialize(timeout: 30)
    @timeout = timeout
  end
  
  def build_get_request(url, headers = {})
    # Focused logic for building HTTP requests
  end
end

# ✅ Good: Reusable wrapper functionality  
class ExecutableWrapper
  def initialize(command_path:, registration_method:)
    @command_path = command_path
    @registration_method = registration_method
  end
  
  def call
    setup_bundler
    execute_cli
  end
end
```

**Bad Examples**:
```ruby
# ❌ Bad: Too much business logic (should be Organism)
class OrderProcessor
  def process_order(order)
    validate_inventory(order)
    calculate_shipping(order)
    charge_payment(order)
    send_confirmation_email(order)
    update_analytics(order)
  end
end

# ❌ Bad: Pure data (should be Model)
class UserSettings
  attr_accessor :theme, :language, :notifications
  
  def initialize(theme:, language:, notifications:)
    @theme = theme
    @language = language  
    @notifications = notifications
  end
end
```

### Organisms (`lib/coding_agent_tools/organisms/`)

**Purpose**: Complex units that orchestrate molecules and atoms to achieve business goals.

**Characteristics**:
- Handle complete business use cases
- Orchestrate multiple components
- May maintain state across operations
- Focus on "what" business value to deliver
- Can be complex and feature-rich

**Good Examples**:
```ruby
# ✅ Good: Orchestrates multiple components for business purpose
class GeminiClient
  def initialize(api_key:)
    @request_builder = Molecules::HTTPRequestBuilder.new
    @response_parser = Molecules::APIResponseParser.new
    @credentials = Molecules::APICredentials.new(api_key)
  end
  
  def generate_text(prompt, **options)
    # Orchestrates request building, API calling, and response parsing
  end
  
  def list_models
    # Complete business operation
  end
end

# ✅ Good: Complex business logic coordination
class PromptProcessor  
  def process_prompt(template, context)
    # Coordinates template parsing, variable substitution, validation
  end
end
```

**Bad Examples**:
```ruby
# ❌ Bad: Simple utility (should be Molecule or Atom)
class StringFormatter
  def self.capitalize_first(text)
    text.capitalize
  end
end

# ❌ Bad: Pure data structure (should be Model)
class ConfigurationSettings
  attr_reader :api_endpoint, :timeout, :retry_count
  
  def initialize(api_endpoint:, timeout:, retry_count:)
    @api_endpoint = api_endpoint
    @timeout = timeout
    @retry_count = retry_count
  end
end
```

## Decision Checklist

When creating a new class, ask yourself:

### For Models:
- [ ] Does this class only hold data?
- [ ] Are there no I/O operations (file, network, database)?
- [ ] Are there no external gem dependencies?
- [ ] Could this be implemented as a Struct?
- [ ] Does it focus on "what" the data represents?

### For Molecules:  
- [ ] Does this class perform a specific, focused operation?
- [ ] Does it compose simpler components (atoms)?
- [ ] Is it reusable across different contexts?
- [ ] Does it encapsulate "how" to do something?
- [ ] Is the responsibility clear and single-focused?

### For Organisms:
- [ ] Does this class handle a complete business use case?
- [ ] Does it orchestrate multiple molecules/atoms?
- [ ] Is it complex enough to warrant the organism level?
- [ ] Does it focus on "what" business value to deliver?
- [ ] Would breaking it down lose important context?

## Common Mistakes and Solutions

### Mistake 1: Data Objects in Wrong Location

**Problem**: Placing pure data structures in `molecules/` or `organisms/`

**Example**: 
```ruby
# ❌ Wrong location: molecules/model.rb  
class Model < Struct.new(:id, :name)
  def to_s
    "#{id}: #{name}"
  end
end
```

**Solution**: Move to `models/` and rename appropriately
```ruby  
# ✅ Correct location: models/llm_model_info.rb
LlmModelInfo = Struct.new(:id, :name, :description, :default, keyword_init: true)
```

**Teaching Example**: The `LlmModelInfo` class was originally misplaced in `molecules/` but was correctly refactored to `models/` because it's a pure data structure with no I/O operations or external dependencies.

### Mistake 2: Business Logic in Molecules

**Problem**: Putting complex orchestration logic in molecules

**Example**:
```ruby
# ❌ Wrong: Complex business logic in molecule
class OrderHandler
  def process_complete_order(order)
    validate_order(order)
    reserve_inventory(order) 
    process_payment(order)
    ship_order(order)
    send_notifications(order)
  end
end
```

**Solution**: Move to organisms for complex business coordination
```ruby
# ✅ Correct: Business orchestration in organism  
class OrderProcessor
  def initialize
    @validator = Molecules::OrderValidator.new
    @inventory = Molecules::InventoryManager.new  
    @payment = Molecules::PaymentProcessor.new
  end
end
```

### Mistake 3: Simple Utilities in Organisms

**Problem**: Over-engineering simple utilities as organisms

**Example**:
```ruby
# ❌ Wrong: Simple utility as organism
class TextFormatter
  def format_currency(amount)
    "$#{amount.round(2)}"
  end
end
```

**Solution**: Use appropriate level (Atom or Molecule)
```ruby
# ✅ Correct: Simple utility as atom or molecule
module Atoms
  module TextFormatter
    def self.format_currency(amount)
      "$#{amount.round(2)}"
    end
  end
end
```

## Future Enforcement Mechanisms

To maintain these standards as the project grows, consider implementing:

### Automated Checks
- **RuboCop Rules**: Custom cops to detect misplaced components
- **CI Pipeline Checks**: Automated validation during pull requests
- **File Naming Conventions**: Enforce naming patterns that reflect component type

### Code Review Guidelines  
- **Classification Review**: Every new class should be reviewed for proper placement
- **Architecture Review**: Periodic reviews of component boundaries
- **Refactoring Guidelines**: Clear process for moving misplaced components

### Documentation Integration
- **ADR Updates**: Keep Architecture Decision Records synchronized
- **Cross-References**: Link to this guide from README and CONTRIBUTING files
- **Examples**: Maintain current examples as the codebase evolves

## Cross-References

- [Architecture Documentation](../../docs-project/architecture.md) - Overall system architecture
- [ADR-006: ATOM Architecture House Rules](../../docs-project/current/v.0.2.0-synapse/decisions/ADR-006-ATOM-Architecture-House-Rules.md) - Official architecture decisions
- [Coding Standards](./coding-standards.md) - General coding practices
- [Testing Guidelines](./testing.md) - Testing patterns for each component type

## Conclusion

Following these ATOM classification rules ensures our codebase remains maintainable, testable, and architecturally consistent. When in doubt, err on the side of simpler classification (Models before Molecules, Molecules before Organisms) and refactor up in complexity only when the additional abstraction provides clear value.

Remember: The goal is not perfect classification, but consistent and logical organization that serves the team's long-term productivity and code quality goals.