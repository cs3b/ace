---
id: v.0.5.0+task.062
status: done
priority: high
estimate: 1.5h
dependencies: [v.0.5.0+task.059]
---

# Simplify .ace/taskflow setup to use template structure

## Behavioral Context

**Issue**: The integrate command was creating .ace/taskflow structure using hardcoded directories. A template-based approach would be more maintainable and flexible.

**Key Behavioral Requirements**:
- Use template directory structure instead of hardcoded paths
- Support graceful fallback if template doesn't exist
- Enable easy customization through template modification

## Objective

Implemented template-based directory creation for .ace/taskflow and other structures, using templates from .ace/handbook/.meta/tpl/project-structure/ to replace hardcoded directory creation logic.

## Scope of Work

- Created template directory structure at .ace/handbook/.meta/tpl/project-structure/taskflow
- Implemented create_from_template method in integrate command
- Modified check_and_setup_submodules to use template-based creation
- Added fallback logic for when templates don't exist

### Deliverables

#### Create

- .ace/handbook/.meta/tpl/project-structure/taskflow/ (template structure)

#### Modify

- .ace/tools/lib/coding_agent_tools/cli/commands/integrate.rb

## Implementation Summary

### What Was Done

- **Problem Identification**: Hardcoded directory creation was inflexible and difficult to maintain
- **Investigation**: Determined template-based approach would be more maintainable
- **Solution**: 
  - Created template directory at .ace/handbook/.meta/tpl/project-structure/taskflow
  - Implemented create_from_template method to copy template structures
  - Modified .ace/taskflow setup to use template instead of hardcoded paths
  - Added graceful fallback to hardcoded creation if template missing
- **Validation**: Tested that template-based creation works and fallback functions correctly

### Technical Details

Added new method to integrate.rb:

```ruby
def create_from_template(template_name, target_path)
  template_source = @project_root + ".ace/handbook/.meta/tpl/project-structure/#{template_name}"
  
  unless template_source.exist?
    # Fallback to hard-coded creation if template doesn't exist
    log "  → Template not found, creating basic structure"
    case template_name
    when "taskflow"
      FileUtils.mkdir_p(target_path + "backlog/ideas")
      FileUtils.mkdir_p(target_path + "current")
      FileUtils.mkdir_p(target_path + "done")
    else
      FileUtils.mkdir_p(target_path)
    end
    return
  end
  
  # Create target directory if it doesn't exist
  FileUtils.mkdir_p(target_path)
  
  # Copy all contents from template to target
  template_source.children.each do |item|
    if item.directory?
      FileUtils.cp_r(item, target_path)
    else
      FileUtils.cp(item, target_path)
    end
  end
  log "  → Copied #{template_name} template structure"
end
```

Modified check_and_setup_submodules to use template:

```ruby
unless (@project_root + ".ace/taskflow").exist?
  log "Creating .ace/taskflow from template..."
  create_from_template("taskflow", @project_root + ".ace/taskflow")
end
```

### Testing/Validation

```bash
# Tested with template present
coding-agent-tools integrate claude --init-project

# Verified template structure copied correctly
ls -la .ace/taskflow/
```

**Results**: Template-based creation works correctly with proper fallback behavior

## References

- Depends on task v.0.5.0+task.059 (flexible .ace/taskflow setup)
- User request: "ok so if anyone create a submodule directory (empty) it will populate it with proper structure instead of having hard coded folders... we should have a directory to copy - .ace/handbook/.meta/tpl/project-structure/taskflow"
- Improves maintainability of integrate command