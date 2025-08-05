# Ruby Style Guide

This document outlines the Ruby style conventions used in the Coding Agent Tools project.

## Overview

This project follows [StandardRB](https://github.com/standardrb/standard) as its base style guide, with some project-specific exceptions defined in `.rubocop.yml`.

## Key Style Decisions

### Base Configuration

- **Ruby Version**: 3.1+ (minimum supported version)
- **Style Foundation**: StandardRB v1.50.0
- **RuboCop Integration**: Inherits from StandardRB with project-specific overrides

### Project-Specific Conventions

#### Frozen String Literals
All Ruby files must include the frozen string literal comment:
```ruby
# frozen_string_literal: true
```

#### String Literals
- Use single quotes for strings without interpolation
- Use double quotes for strings with interpolation

#### Method Length
- Maximum 20 lines per method (StandardRB default is 10)
- CLI commands and complex business logic may exceed this in justified cases

#### Class Length
- Maximum 250 lines for CLI commands and organisms
- Standard classes should aim for 100 lines or less

#### Metrics Relaxations
- **ABC Size**: Max 25 for organisms and CLI (StandardRB: 15)
- **Cyclomatic Complexity**: Max 10 for complex logic (StandardRB: 6)
- **Perceived Complexity**: Max 10 for complex logic (StandardRB: 7)

### Code Organization

#### ATOM Architecture
The codebase follows the ATOM pattern:
- **Atoms**: Single-responsibility, no dependencies within the gem
- **Molecules**: Compose atoms, minimal dependencies
- **Organisms**: Complex business logic, may compose molecules
- **Ecosystems**: Complete workflows composing organisms

### Style Exceptions

#### Disabled Cops
The following cops are disabled for project-specific reasons:

- **Style/TernaryParentheses**: Parentheses can improve clarity
- **Style/EmptyElse**: Explicit else branches can be clearer
- **Style/ConditionalAssignment**: Can hurt readability
- **Style/SafeNavigation**: Not always clearer than explicit nil checks
- **Style/HashExcept**: Ruby 3+ feature, not always more readable
- **Lint/FloatComparison**: Sometimes necessary in calculations

#### Layout Preferences
- **Line Length**: 120 characters max
- **Indentation**: 2 spaces (Ruby standard)
- **Multi-line method chains**: Indented style
- **Case statements**: `when` aligned with `end`

### Testing Conventions

- RSpec is used for all tests
- Test files may have longer methods and blocks
- Unused variables in tests are acceptable for setup clarity

## Running Style Checks

```bash
# Run RuboCop with auto-correction for safe cops
bundle exec rubocop -a

# Run RuboCop with auto-correction for all cops (use with caution)
bundle exec rubocop -A

# Run RuboCop without corrections
bundle exec rubocop
```

## CI Integration

RuboCop runs automatically in CI for all pull requests. The build will fail if there are any offenses that aren't explicitly configured as exceptions in `.rubocop.yml`.

## Making Style Changes

1. Discuss significant style changes with the team first
2. Update `.rubocop.yml` with clear comments explaining exceptions
3. Run auto-corrections in a separate commit for easier review
4. Update this style guide to reflect any new conventions

## Style Evolution

This style guide is a living document. As the project evolves and Ruby introduces new features, we'll update our conventions to maintain a balance between consistency, readability, and modern Ruby idioms.