---
name: ruby
description: Ruby language review focus with idioms and best practices
last-updated: '2026-01-01'
---

# Ruby Language Focus

## Ruby-Specific Review Criteria

You are reviewing Ruby code with expertise in Ruby best practices and idioms.

### Ruby Gem Best Practices
- Proper gem structure and organization
- Semantic versioning compliance
- Dependency management and version constraints
- README and documentation standards

### Code Quality Standards
- **Style**: StandardRB compliance (note justified exceptions)
- **Idioms**: Ruby idioms and conventions
- **Performance**: Efficient use of Ruby features
- **Memory**: Proper object lifecycle management

### Testing with RSpec
- Target: 90%+ test coverage
- Test organization and naming conventions
- Proper use of RSpec features (contexts, let, before/after)
- Mock and stub usage appropriateness

### Ruby-Specific Checks
- Proper use of blocks, procs, and lambdas
- Metaprogramming appropriateness
- Module and class design
- Exception handling patterns
- String interpolation vs concatenation
- Symbol vs string usage
- Enumerable method selection
- Proper use of attr_accessor/reader/writer

### Ruby 3+ Features
Review for appropriate use of modern Ruby features:
- **Pattern Matching** (`case...in`): Prefer for complex destructuring, avoid for simple conditionals
- **Endless Methods** (`def method = expr`): Use for single-expression methods, keep readable
- **Numbered Block Parameters** (`_1`, `_2`): Use only for simple, short blocks
- **Hash Shorthand** (`{x:, y:}`): Use when variable name matches key name
- **Rightward Assignment** (`expr => var`): Use sparingly for destructuring results
- **Data Classes** (`Data.define`): Prefer over Struct for immutable value objects
- **Keyword Argument Forwarding** (`def foo(**) = bar(**)`)
- **Ractor**: Review thread-safety implications when used