---
id: v.0.3.0+task.117
status: done
priority: medium
estimate: 4h
dependencies: [v.0.3.0+task.116]
---

# Audit and standardize dry library usage across all executables

## 0. Directory Audit ✅

_Command run:_

```bash
ls -la .ace/tools/exe/ | sed 's/^/    /'
```

_Result excerpt:_

```
    total xxxx
    drwxr-xr-x  x user  group   xxx date .
    drwxr-xr-x  x user  group   xxx date ..
    -rwxr-xr-x  x user  group   xxx date coding_agent_tools
    -rwxr-xr-x  x user  group   xxx date create-path
    -rwxr-xr-x  x user  group   xxx date git-commit
    -rwxr-xr-x  x user  group   xxx date other-executables...
```

## Objective

Conduct a comprehensive audit of all executables in the .ace/tools/exe/ directory to identify commands that don't use the dry library pattern and standardize them. This addresses the code review feedback about ensuring consistency across all command implementations.

## Scope of Work

- Audit all executables for dry library usage
- Identify commands using manual argument parsing
- Standardize non-compliant executables to use dry library pattern
- Ensure consistent error handling and structure
- Document the standard pattern for future commands

### Deliverables

#### Create

- Audit report documenting current state and changes needed
- Standard executable template for future commands

#### Modify

- All non-compliant executables to use dry library pattern
- Documentation with standard patterns

#### Delete

- None

## Phases

1. Comprehensive audit of all executables
2. Identify non-compliant patterns
3. Standardize all executables
4. Create standard template

## Implementation Plan

### Planning Steps

- [x] Create comprehensive list of all executables
  > TEST: Executable Inventory
  > Type: Discovery
  > Assert: All executables in exe/ directory are catalogued
  > Command: cd .ace/tools && ls -1 exe/ | grep -v '\.' | head -20
- [x] Analyze each executable for dry library usage
  > TEST: Pattern Analysis
  > Type: Code Review
  > Assert: Usage patterns for each executable are documented
  > Command: cd .ace/tools && for f in exe/*; do echo "=== $f ==="; head -10 "$f"; done
- [x] Identify which executables need updates
- [x] Plan standardization approach

### Execution Steps

- [x] Step 1: Complete executable audit
  > TEST: Audit Completion
  > Type: Documentation
  > Assert: Audit report shows current state of all executables
  > Command: cd .ace/tools && find exe/ -type f -executable | wc -l
- [x] Step 2: Identify non-dry library executables
  > TEST: Non-Compliant Identification
  > Type: Pattern Detection
  > Assert: Executables not using dry library are identified
  > Command: cd .ace/tools && grep -l "ARGV" exe/nav-*
- [x] Step 3: Refactor identified executables to use dry pattern
  > TEST: Standardization Progress
  > Type: Refactoring Validation
  > Assert: All executables use consistent dry library pattern
  > Command: cd .ace/tools && grep -l "ARGV" exe/nav-* || echo "All nav executables standardized"
- [x] Step 4: Ensure all commands are properly registered
  > TEST: Command Registration
  > Type: Integration Validation
  > Assert: All commands are registered in the CLI system
  > Command: cd .ace/tools && grep -n "register.*command" lib/coding_agent_tools/cli.rb
- [x] Step 5: Test all standardized executables
  > TEST: Execution Validation
  > Type: Functional Testing
  > Assert: All executables work correctly with dry library
  > Command: cd .ace/tools && for f in exe/nav-*; do echo "Testing $f"; timeout 5 bundle exec "$f" --help >/dev/null 2>&1 && echo "OK" || echo "ISSUE"; done
- [x] Step 6: Create standard executable template
  > TEST: Template Creation
  > Type: Documentation
  > Assert: Standard template is available for future commands
  > Command: cd .ace/tools && test -f docs/executable-template.rb && echo "Template exists"

## Acceptance Criteria

- [x] AC 1: All executables use dry library pattern consistently
- [x] AC 2: No executables use manual argument parsing
- [x] AC 3: Error handling is consistent across all executables
- [x] AC 4: All commands are properly registered in CLI system
- [x] AC 5: Standard executable template is created
- [x] AC 6: Documentation is updated with patterns
- [x] AC 7: All executables pass basic functionality tests
- [x] AC 8: Audit report documents all changes made

## Out of Scope

- ❌ Changing command-line interfaces of existing commands
- ❌ Adding new functionality to commands
- ❌ Performance optimization
- ❌ Complete rewrite of command logic

## Standard Executable Pattern

```ruby
#!/usr/bin/env ruby
# Frozen string literal for performance
# frozen_string_literal: true

# Use absolute path resolution to support execution from any directory
lib_path = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)

require "coding_agent_tools/cli"

begin
  Dry::CLI.new(CodingAgentTools::Cli::Commands).call
rescue Dry::CLI::Error => e
  warn "Error: #{e.message}"
  exit 1
rescue => e
  warn "Unexpected error: #{e.message}"
  exit 1
end
```

## Audit Categories

### 1. Dry Library Compliant
- Commands that already use dry library pattern
- Should be validated for consistency

### 2. Manual Parsing
- Commands that use ARGV directly
- Commands that use OptionParser or similar
- Need full refactoring

### 3. Custom Patterns
- Commands that use non-standard patterns
- May need partial refactoring

### 4. Legacy Scripts
- Scripts that may not be proper CLI commands
- May need different treatment

## References

- Code review feedback: Check for other commands that don't use dry library
- Reference pattern: .ace/tools/exe/git-commit
- Dry-cli documentation
- Project CLI architecture in lib/coding_agent_tools/cli.rb
- ATOM architecture patterns for consistency