---
id: v.0.5.0+task.059
status: done
priority: high
estimate: 1h
dependencies: []
---

# Make dev-taskflow setup flexible in integrate command

## Behavioral Context

**Issue**: The integrate command was attempting to clone dev-taskflow as a git submodule from a non-existent GitHub repository, causing the initialization to fail.

**Key Behavioral Requirements**:
- The command should always succeed in creating dev-taskflow structure
- When submodule setup fails, gracefully fall back to directory creation
- Support both submodule and directory-based dev-taskflow setups

## Objective

Modified the integrate command to handle dev-taskflow setup flexibly - attempting submodule setup first but gracefully falling back to directory creation when the repository doesn't exist.

## Scope of Work

- Modified check_and_setup_submodules method to handle dev-taskflow specially
- Implemented fallback strategy from submodule to directory creation
- Ensured dev-taskflow structure is always created successfully

### Deliverables

#### Modify

- dev-tools/lib/coding_agent_tools/cli/commands/integrate.rb

## Implementation Summary

### What Was Done

- **Problem Identification**: The integrate command was failing when trying to set up dev-taskflow as a submodule because the GitHub repository didn't exist
- **Investigation**: Found that the command was attempting to clone from a non-existent repository
- **Solution**: Modified check_and_setup_submodules to treat dev-taskflow specially:
  - First attempts submodule setup if .gitmodules entry exists
  - If submodule setup fails, creates as regular directory
  - Always ensures dev-taskflow structure exists
- **Validation**: Tested that the command now succeeds whether dev-taskflow is a submodule or directory

### Technical Details

Modified the `check_and_setup_submodules` method in integrate.rb:

```ruby
def check_and_setup_submodules
  # Special handling for dev-taskflow
  if submodule == "dev-taskflow"
    if File.exist?(".gitmodules") && File.read(".gitmodules").include?("dev-taskflow")
      # Try submodule setup
      system("git submodule update --init dev-taskflow", exception: false)
    end
    
    # If dev-taskflow doesn't exist after submodule attempt, create as directory
    unless File.exist?("dev-taskflow")
      log "Creating dev-taskflow as directory..."
      FileUtils.mkdir_p("dev-taskflow/backlog/ideas")
      FileUtils.mkdir_p("dev-taskflow/current")
      FileUtils.mkdir_p("dev-taskflow/done")
    end
  end
end
```

### Testing/Validation

```bash
# Tested the command with and without submodule
coding-agent-tools integrate claude --init-project
```

**Results**: Command now succeeds in both scenarios - creates dev-taskflow as directory when submodule setup fails

## References

- Related to task v.0.5.0+task.058 (template processing fix)
- Commits made during session implementation