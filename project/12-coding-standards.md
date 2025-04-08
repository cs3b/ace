# Coding Standards for AI Ruby Agent SDK

## Core Principles

1. **Outside-In Development**
   - Start with the user-facing DSL and work inwards
   - Each layer should have clear boundaries and interfaces
   - Test-drive the implementation from the outside

2. **Ruby Idioms**
   - Follow Ruby community conventions and patterns
   - Use blocks and yield for configuration when appropriate
   - Leverage metaprogramming judiciously

3. **Modular Architecture**
   - Each component should have a single responsibility
   - Use composition over inheritance
   - Keep interfaces small and focused

## Implementation Approach

### 1. DSL First
- Define the user-facing DSL as the first step
- Create examples showing ideal usage
- Test the DSL readability and ergonomics

### 2. Core Components
- Implement core abstractions:
  - Agent registry
  - Tool registry
  - File-based communication
  - Prompt templating

### 3. Testing Strategy
- Write acceptance tests first
- Follow with unit tests
- Use integration tests for file operations

## Code Organization

### Directory Structure
```
lib/
  aira/
    agent.rb         # Core agent class
    dsl.rb          # DSL implementation
    registry.rb     # Agent registry
    tools/          # Tool implementations
    environment.rb  # File system operations
    prompts/        # Prompt templates
```

### File Naming
- Use snake_case for file names
- Match file names to class/module names
- Group related functionality in directories

## Documentation

- Document public APIs thoroughly
- Include usage examples
- Maintain YARD-compatible documentation

## Quality Checks

- Run Rubocop for style consistency
- Maintain high test coverage
- Use git pre-commit hooks for quality checks

## Development Workflow

1. Start with acceptance tests
2. Implement minimal DSL
3. Build core components
4. Add tools and extensions
5. Refactor and optimize