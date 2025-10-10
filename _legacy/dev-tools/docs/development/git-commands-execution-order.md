# Git Commands Execution Order

## Overview

This document defines the execution order requirements for git commands across multiple repositories (main repository + submodules) to maintain repository consistency and avoid conflicts.

## Command Categories

### Sequential Execution Required

These commands require specific ordering to maintain repository integrity:

#### 1. Push Operations (Submodules First)

**Ordering**: Submodules → Main Repository

**Rationale**: 
- Submodules must be pushed before the main repository to ensure their refs exist
- Main repository references submodule commits that must be available remotely
- Prevents broken references when main repo is pulled by others

**Implementation**:
```ruby
# Both concurrent and sequential push use submodules-first ordering
def execute_push_sequential(command, options)
  # Execute submodules first
  submodule_result = coordinator.execute_across_repositories(command, options.merge(submodules_only: true))
  # Then execute main repository
  main_result = coordinator.execute_across_repositories(command, options.merge(main_only: true))
end
```

#### 2. Pull Operations (Main First)

**Ordering**: Main Repository → Submodules

**Rationale**:
- Main repository must pull first to get updated submodule refs
- Submodules then update to the specific commits referenced by main
- Prevents submodules from being in inconsistent states

**Implementation**:
```ruby
# Both concurrent and sequential pull use main-first ordering
def execute_pull_sequential(command, options)
  # Execute main repository first
  main_result = coordinator.execute_across_repositories(command, options.merge(main_only: true))
  # Then execute submodules
  submodule_result = coordinator.execute_across_repositories(command, options.merge(submodules_only: true))
end
```

#### 3. Commit Operations (Submodules First)

**Ordering**: Submodules → Main Repository

**Rationale**:
- Submodule changes must be committed before main repository commits that reference them
- Main repository commit includes updated submodule refs pointing to new commits
- Maintains consistency between main repo and its submodule references

**Implementation**:
```ruby
# Message-based commits use submodules-first ordering
def commit_with_message(message, options)
  submodule_result = coordinator.execute_across_repositories(commit_command, options.merge(submodules_only: true))
  main_result = coordinator.execute_across_repositories(commit_command, options.merge(main_only: true))
end

# LLM-based commits use execute_sequentially_with_submodules_first
def commit_with_llm_message(options)
  # ...generate messages for each repository...
  execute_sequentially_with_submodules_first(commands_by_repo, options)
end
```

### Concurrent Execution Safe

These commands are read-only and can execute in any order or concurrently:

#### 1. Status Operations

**Execution**: Concurrent safe, no ordering constraints

**Rationale**: Read-only operation that doesn't modify repository state

**Implementation**:
```ruby
def status(options = {})
  coordinator.execute_across_repositories("status", options.merge(capture_output: true))
end
```

#### 2. Log Operations

**Execution**: Concurrent safe, no ordering constraints

**Rationale**: Read-only operation that retrieves commit history

**Implementation**:
```ruby
def log(options = {})
  coordinator.execute_across_repositories(log_command, options.merge(capture_output: true))
end
```

#### 3. Diff Operations

**Execution**: Concurrent safe, no ordering constraints

**Rationale**: Read-only operation that shows differences

**Implementation**:
```ruby
def diff(options = {})
  coordinator.execute_across_repositories(diff_command, options.merge(capture_output: true))
end
```

#### 4. Fetch Operations

**Execution**: Concurrent safe, no ordering constraints

**Rationale**: Only updates remote tracking branches, doesn't affect working tree

**Implementation**:
```ruby
def fetch(options = {})
  coordinator.execute_across_repositories(fetch_command, options.merge(capture_output: true))
end
```

## Implementation Details

### MultiRepoCoordinator Options

The execution order is controlled through these options:

- `submodules_only: true` - Execute only on submodules
- `main_only: true` - Execute only on main repository  
- `repository: "name"` - Execute on specific repository only

### Error Handling

When operations fail in a sequence:

1. **Continue execution**: Later steps still execute even if earlier ones fail
2. **Combine results**: Results from all repositories are merged
3. **Report failures**: All errors are collected and reported
4. **Overall success**: Only true if all repositories succeed

Example from push operation:
```ruby
{
  success: submodule_result[:success] && main_result[:success],
  results: combined_results,
  errors: combined_errors,
  repositories_processed: (submodule_result[:repositories_processed] + main_result[:repositories_processed])
}
```

### Repository Discovery Order

Repositories are discovered in this order by `RepositoryScanner`:

1. Main repository (name: "main")
2. Submodules (discovered via `git submodule status`)
3. Dev directories (fallback: dev-* patterns)

**Note**: This natural discovery order (main-first) is **incorrect for push and commit operations**, which is why explicit ordering is implemented.

## Testing

Execution order is validated through integration tests in `spec/integration/git_execution_order_spec.rb`:

### Test Coverage

- ✅ Push operations (sequential and concurrent) use submodules-first
- ✅ Pull operations (sequential and concurrent) use main-first  
- ✅ Commit operations use submodules-first
- ✅ Read-only operations can execute concurrently
- ✅ Error handling preserves execution order and combines results

### Test Structure

Tests mock the `MultiRepoCoordinator.execute_across_repositories` method to track execution order:

```ruby
execution_order = []

allow_any_instance_of(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
  .to receive(:execute_across_repositories) do |coordinator, command, options|
    if options[:submodules_only]
      execution_order << :submodules
    elsif options[:main_only]
      execution_order << :main
    end
    # Return mock result...
  end

orchestrator.push(concurrent: false)
expect(execution_order).to eq([:submodules, :main])
```

## Future Considerations

### Performance Optimization

For read-only operations, consider true concurrent execution:

- Status, log, diff, fetch could run in parallel threads
- Would require updating MultiRepoCoordinator to support true concurrency
- Should measure performance impact before implementing

### Additional Commands

New git commands should be categorized:

- **Write operations**: Analyze dependencies and implement proper ordering
- **Read operations**: Can typically execute concurrently
- **Hybrid operations**: May need specific ordering based on behavior

### Repository Types

Current implementation assumes:
- One main repository
- Multiple submodules as git submodules

Future expansions might include:
- Multiple independent repositories
- Nested submodules
- Different dependency relationships

## Summary

| Operation | Ordering | Rationale |
|-----------|----------|-----------|
| Push | Submodules → Main | Ensure refs exist before main repo references them |
| Pull | Main → Submodules | Get updated refs before updating submodules |
| Commit | Submodules → Main | Commit changes before main repo references them |
| Status | Concurrent Safe | Read-only, no dependencies |
| Log | Concurrent Safe | Read-only, no dependencies |  
| Diff | Concurrent Safe | Read-only, no dependencies |
| Fetch | Concurrent Safe | Only updates tracking branches |

This execution order ensures repository consistency while maximizing performance for safe operations.