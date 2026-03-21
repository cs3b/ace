---
doc-type: template
title: Ruby YARD Documentation Template
purpose: Documentation for ace-docs/handbook/templates/code-docs/ruby-yard.template.md
ace-docs:
  last-updated: 2026-01-08
  last-checked: 2026-03-21
---

# Ruby YARD Documentation Template

```ruby
# [Brief description of what this method/class does]
#
# [Detailed description including purpose, behavior, and context.
# Explain what the method/class does, why it's useful, and how it fits
# into the larger system.]
#
# @example [Example title]
#   [code example showing basic usage]
#
# @example [Another example title] 
#   [code example showing advanced usage or error handling]
#
# @param [parameter_name] [Type] [Description of parameter]
# @param [another_param] [Type] [Description with constraints/validation]
# @param [options] [Hash] [Description of options hash]
# @option options [Type] :option_name (default_value) [Description]
# @option options [Type] :another_option [Description]
#
# @return [ReturnType] [Description of what is returned]
#
# @raise [ExceptionClass] [Description of when this exception is raised]
# @raise [AnotherException] [Description of another exception condition]
#
# @note [Important note about usage, threading, performance, etc.]
# @note [Another important note]
#
# @see [RelatedClass]
# @see [RelatedMethod]
# @see [URL to external documentation]
#
# @since [version when this was added]
# @deprecated [version when deprecated] Use [alternative] instead
#
def method_name(parameter_name:, another_param:, **options)
  # Implementation
end
```

## YARD Tag Reference

### Basic Tags

- `@param` - Parameter documentation
- `@return` - Return value documentation  
- `@raise` - Exception documentation
- `@example` - Code examples
- `@note` - Important notes
- `@see` - Cross-references

### Metadata Tags

- `@since` - Version when added
- `@deprecated` - Deprecation notice
- `@author` - Author information
- `@version` - Version information

### Advanced Tags

- `@option` - Hash option documentation
- `@overload` - Method overloads
- `@yield` - Block documentation
- `@yieldparam` - Block parameter documentation
- `@yieldreturn` - Block return documentation

## Documentation Guidelines

1. **Start with a brief one-line summary**
2. **Follow with detailed description if needed**
3. **Provide realistic examples**
4. **Document all parameters and return values**
5. **Include exception conditions**
6. **Add notes for important behavior**
7. **Use cross-references for related code**
