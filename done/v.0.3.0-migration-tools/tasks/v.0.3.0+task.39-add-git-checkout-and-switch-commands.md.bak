---
id: v.0.3.0+task.39
status: done
priority: medium
estimate: 5h
dependencies: [v.0.3.0+task.37]
---

# Add Git Checkout and Switch Commands

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-tools/exe | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-tools/exe
    ├── coding_agent_tools
    ├── git-add
    ├── git-commit
    ├── git-diff
    ├── git-fetch
    ├── git-log
    ├── git-pull
    ├── git-push
    ├── git-status
    ├── llm-gemini-query
    ├── llm-lmstudio-query
    └── llm-models
```

## Objective

Add git-checkout and git-switch commands to allow running the same git branch operations across all repositories in the multi-repository setup, following the existing patterns established by other git commands.

## Scope of Work

- Create git-checkout and git-switch executable scripts
- Implement command classes following existing git command patterns
- Add checkout/switch functionality to GitOrchestrator
- Support branch operations across all repositories
- Maintain consistency with existing git command interface

### Deliverables

#### Create

- dev-tools/exe/git-checkout
- dev-tools/exe/git-switch
- dev-tools/lib/coding_agent_tools/cli/commands/git/checkout.rb
- dev-tools/lib/coding_agent_tools/cli/commands/git/switch.rb

#### Modify

- dev-tools/lib/coding_agent_tools/organisms/git/git_orchestrator.rb

## Phases

1. Analyze existing git command patterns
2. Create executable scripts
3. Implement command classes
4. Add orchestrator methods
5. Test multi-repository operations

## Implementation Plan

### Planning Steps

- [x] Analyze existing git command implementation patterns
  > TEST: Pattern Analysis
  > Type: Code Analysis
  > Assert: Understand structure of git-status, git-add, etc. for consistent implementation
  > Command: Review existing git command files and identify common patterns

- [x] Review git checkout vs switch differences and options
  > TEST: Command Understanding
  > Type: Git Knowledge Check
  > Assert: Understand difference between checkout and switch commands and their options
  > Command: Research git checkout and switch command differences and common use cases

### Execution Steps

- [x] Create git-checkout executable script following existing patterns
  > TEST: Checkout Executable
  > Type: File Creation
  > Assert: git-checkout script exists and follows same structure as other git commands
  > Command: Verify git-checkout executable exists and has proper shebang and structure

- [x] Create git-switch executable script following existing patterns
  > TEST: Switch Executable
  > Type: File Creation
  > Assert: git-switch script exists and follows same structure as other git commands
  > Command: Verify git-switch executable exists and has proper shebang and structure

- [x] Implement Checkout command class with proper options and error handling
  > TEST: Checkout Command Class
  > Type: Class Implementation
  > Assert: Checkout command class supports common checkout options
  > Command: Test checkout command class instantiation and option parsing

- [x] Implement Switch command class with proper options and error handling
  > TEST: Switch Command Class
  > Type: Class Implementation
  > Assert: Switch command class supports common switch options
  > Command: Test switch command class instantiation and option parsing

- [x] Add checkout and switch methods to GitOrchestrator
  > TEST: Orchestrator Integration
  > Type: Method Implementation
  > Assert: GitOrchestrator has checkout and switch methods that work across repositories
  > Command: Test orchestrator methods execute across all repositories

- [x] Test checkout/switch operations across multiple repositories
  > TEST: Multi-Repository Operations
  > Type: Integration Test
  > Assert: Commands work across main and submodule repositories
  > Command: Test checkout/switch with different branch scenarios

## Acceptance Criteria

- [x] AC 1: git-checkout command works across all repositories
- [x] AC 2: git-switch command works across all repositories  
- [x] AC 3: Commands follow existing git command patterns and interface
- [x] AC 4: Proper error handling for failed operations in individual repositories
- [x] AC 5: Commands support common checkout/switch options

## Out of Scope

- ❌ Advanced git workflow features beyond basic checkout/switch
- ❌ Interactive branch selection menus
- ❌ Automatic conflict resolution
- ❌ Integration with git flow or other branching models

## References

```
Pattern source: dev-tools/exe/git-status, git-add, etc.
Implementation reference: dev-tools/lib/coding_agent_tools/cli/commands/git/status.rb
Orchestrator reference: dev-tools/lib/coding_agent_tools/organisms/git/git_orchestrator.rb
```