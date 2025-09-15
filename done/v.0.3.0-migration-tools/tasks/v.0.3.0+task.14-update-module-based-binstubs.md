---

id: v.0.3.0+task.14
status: done
priority: medium
estimate: 2h
dependencies: [v.0.3.0+task.13]
---

# Update Module-Based Command Binstubs

## 0. Directory Audit ✅

_Command run:_

```bash
ls -la .ace/tools/config/binstub-aliases.yml && grep -A 5 "llm-" .ace/tools/config/binstub-aliases.yml | head -10
```

_Result excerpt:_

```
    .ace/tools/config/binstub-aliases.yml exists
    Example binstub configuration format for reference
```

## Objective

Update binstub configuration to include shortcuts for the new nav module commands implemented in Task 13, specifically adding np (nav-path) and nt (nav-tree) shortcuts to the binstub-aliases.yml configuration.

## Scope of Work

* Add np (nav-path) shortcut to .ace/tools/config/binstub-aliases.yml
* Add nt (nav-tree) shortcut to .ace/tools/config/binstub-aliases.yml  
* Configure proper execution context and argument passing for nav commands
* Test binstub generation and functionality
* Ensure nav command shortcuts work correctly

### Deliverables

#### Create

* None

#### Modify

* .ace/tools/config/binstub-aliases.yml

#### Delete

* None

## Phases

1. Add nav command entries to binstub-aliases.yml
2. Test binstub generation 
3. Verify nav shortcuts work correctly

## Implementation Plan

### Planning Steps

* [x] Review current binstub-aliases.yml configuration structure
  > TEST: Binstub Config Review
  > Type: Pre-condition Check
  > Assert: Binstub configuration format understood
  > Command: head -20 .ace/tools/config/binstub-aliases.yml
* [x] Verify nav command availability in CLI
  > TEST: Nav Commands Available
  > Type: Pre-condition Check
  > Assert: Nav commands are registered in CLI
  > Command: cd .ace/tools && bundle exec exe/coding_agent_tools nav --help
* [x] Plan nav shortcut configuration

### Execution Steps

- [x] Add np shortcut for nav-path to binstub-aliases.yml
  > TEST: Nav Path Binstub Config
  > Type: Configuration Test
  > Assert: np shortcut is properly configured
  > Command: grep -A 5 "np:" .ace/tools/config/binstub-aliases.yml
- [x] Add nt shortcut for nav-tree to binstub-aliases.yml  
  > TEST: Nav Tree Binstub Config
  > Type: Configuration Test
  > Assert: nt shortcut is properly configured
  > Command: grep -A 5 "nt:" .ace/tools/config/binstub-aliases.yml
- [x] Test binstub installation with new nav shortcuts
  > TEST: Binstub Installation
  > Type: Integration Test
  > Assert: Binstubs install correctly with nav shortcuts
  > Command: cd .ace/tools && bundle exec exe/coding_agent_tools install-binstubs /tmp/test-binstubs && test -f /tmp/test-binstubs/np && test -f /tmp/test-binstubs/nt
- [x] Verify nav shortcuts execute correctly
  > TEST: Nav Shortcuts Execution
  > Type: Integration Test
  > Assert: np and nt shortcuts work correctly
  > Command: /tmp/test-binstubs/np --help && /tmp/test-binstubs/nt --help

## Acceptance Criteria

* [x] np shortcut is added to binstub-aliases.yml for nav-path command
* [x] nt shortcut is added to binstub-aliases.yml for nav-tree command
* [x] Both shortcuts have proper configuration (description, executable, args_processing)
* [x] Binstub installation includes the new nav shortcuts
* [x] np and nt shortcuts execute nav commands correctly
* [x] Arguments are properly passed through to nav subcommands
* [x] Generated binstubs follow existing patterns and conventions

## Out of Scope

* ❌ Updating existing bin/ scripts (bin/tree, bin/gl remain unchanged)
* ❌ Implementing git or code module commands (handled in other tasks)
* ❌ Adding functionality beyond nav command shortcuts
* ❌ Modifying existing binstub behavior patterns

## References

* Dependency: v.0.3.0+task.13 (nav module CLI commands implementation)
* Binstub configuration: .ace/tools/config/binstub-aliases.yml
* Binstub installer: lib/coding_agent_tools/cli/commands/install_binstubs.rb
* Nav module commands: nav path, nav tree (from Task 13)