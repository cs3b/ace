---
id: v.0.5.0+task.058
status: done
priority: high
estimate: 1.5h
dependencies: []
---

# Fix template processing errors in integrate command

## Behavioral Context

**Issue**: The `coding-agent-tools integrate claude --init-project` command was failing with "no implicit conversion of Symbol into Integer" error during ERB template processing.

**Key Behavioral Requirements**:
- ERB templates must receive correctly formatted variables
- Template processing should handle both Hash and Array data structures appropriately
- Command should complete successfully without type conversion errors

## Objective

Fixed the template processing error in the integrate command by creating template-specific variable setup methods that provide the correct data structure format expected by each ERB template.

## Scope of Work

- Identified root cause of Symbol to Integer conversion error
- Created template-specific variable setup methods
- Fixed variable binding for what-do-we-build.md template
- Ensured all templates receive properly formatted data

### Deliverables

#### Modify

- .ace/tools/lib/coding_agent_tools/cli/commands/integrate.rb

## Implementation Summary

### What Was Done

- **Problem Identification**: ERB template for what-do-we-build.md expected @tech_stack as an Array but was receiving a Hash
- **Investigation**: Traced error to template variable binding in process_template method
- **Solution**: Created set_template_variables_for_what_do_we_build method that:
  - Converts tech_stack Hash to Array format
  - Maintains compatibility with template expectations
  - Provides fallback for missing data
- **Validation**: Tested that integrate command completes successfully without errors

### Technical Details

Added new method to handle template-specific variables:

```ruby
def set_template_variables_for_what_do_we_build(template_vars)
  # Convert tech_stack hash to array format expected by template
  @tech_stack = if template_vars[:tech_stack].is_a?(Hash)
    template_vars[:tech_stack].map { |key, value| 
      { name: key.to_s.capitalize, description: value }
    }
  else
    template_vars[:tech_stack] || []
  end
  
  # Set other template variables
  @project_name = template_vars[:project_name]
  @project_description = template_vars[:project_description]
  # ... other variables
end
```

Modified process_template to use template-specific setup:

```ruby
def process_template(template_path, output_path, template_vars = {})
  case output_path.basename.to_s
  when "what-do-we-build.md"
    set_template_variables_for_what_do_we_build(template_vars)
  else
    # Default variable setup
    template_vars.each { |key, value| instance_variable_set("@#{key}", value) }
  end
  
  # Process ERB template
  template = ERB.new(File.read(template_path))
  result = template.result(binding)
  # ...
end
```

### Testing/Validation

```bash
# Command now completes successfully
coding-agent-tools integrate claude --init-project

# Verified template processed correctly
cat docs/what-do-we-build.md
```

**Results**: Template processing error resolved, command executes successfully

## References

- Error message: "no implicit conversion of Symbol into Integer (TypeError)"
- User feedback: "ok, the .ace/taskflow issue is solved, but the second issue persist"
- Related to overall integrate command improvements in v.0.5.0