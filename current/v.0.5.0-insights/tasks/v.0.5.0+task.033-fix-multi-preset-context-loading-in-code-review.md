---
id: v.0.5.0+task.033
status: pending
priority: high  
estimate: 3h
dependencies: []
---

# Fix multi-preset context loading in code-review

## Behavioral Specification

### User Experience
- **Input**: User specifies multiple presets in context YAML: `'presets: [project, dev-tools, dev-handbook]'`
- **Process**: System loads and combines context from all specified presets
- **Output**: Complete context includes files from all three presets, plus any additional files specified

### Expected Behavior
When users specify multiple context presets in YAML format, the system should load all files configured in each preset and combine them into a single context document. This allows comprehensive background information from multiple sources to inform the code review. Additionally, users should be able to specify both presets and individual files in the same context configuration.

### Interface Contract
```bash
# CLI Interface - Multiple presets
code-review \
  --context 'presets: [project, dev-tools, dev-handbook]' \
  --subject '...' \
  --auto-execute
# Expected: Context includes files from all three presets

# CLI Interface - Presets plus files
code-review \
  --context 'presets: [project, dev-tools]
files:
  - docs/custom-context.md
  - dev-taskflow/current/tasks/specific-task.md' \
  --subject '...' \
  --auto-execute
# Expected: Context includes preset files PLUS specified files

# Verification
ls -la {session-dir}/in-context.md
# Expected: File size reflects all preset contents (e.g., >50KB for 3 presets)

grep -c "<file path=" {session-dir}/in-context.md  
# Expected: Count matches total files from all presets
```

**Error Handling:**
- Invalid preset name: Clear error listing available presets
- Missing preset config: Skip with warning, load others
- Duplicate files: Include only once in context

**Edge Cases:**
- Empty preset: Skip without error
- Overlapping files: Deduplicate by path
- Mixed formats: Support both string and array syntax

### Success Criteria
- [ ] **All Presets Load**: Each specified preset's files appear in context
- [ ] **File Combination**: Both preset files and individual files included
- [ ] **Proper Sizing**: Context file size reflects all content loaded
- [ ] **No Duplication**: Each unique file appears only once

### Validation Questions
- [ ] **Preset Priority**: If presets have overlapping files, which version wins?
  - **Research conducted**: Context merger combines all contexts sequentially
  - **Implementation**: Last preset wins for duplicate files (standard merge behavior)
  - **Confirmed**: Follows existing merge patterns
- [ ] **Load Order**: Does order of presets matter for context organization?
  - **Research conducted**: Contexts are processed in order specified
  - **Implementation**: Order determines section sequence in output
  - **Confirmed**: Maintains user-specified order
- [ ] **Error Behavior**: Should one bad preset stop all loading or continue?
  - **Research conducted**: Lines 266-269 show skip with warning on error
  - **Implementation**: Continue loading others, warn about failures
  - **Confirmed**: Resilient loading strategy
- [ ] **Size Limits**: Any maximum context size we should enforce?
  - **Research conducted**: Default max_size is 1MB per file (line 34)
  - **Suggested default**: Keep per-file limit, no total limit
  - **Implementation**: Trust user judgment on total context size

## Objective

Ensure comprehensive context loading from multiple sources, enabling thorough code reviews with full project understanding across all specified presets and files.

## Scope of Work

- **User Experience Scope**: Multi-preset context configuration and loading
- **System Behavior Scope**: Combining context from multiple preset sources
- **Interface Scope**: YAML-based context specification with presets and files

### Deliverables

#### Behavioral Specifications
- Multi-preset loading behavior
- Context combination rules
- Deduplication logic

#### Validation Artifacts
- Test cases for multi-preset loading
- Context size verification tests
- File deduplication tests

## Out of Scope

- ❌ **Implementation Details**: Specific YAML parsing or file loading code
- ❌ **Technology Decisions**: Context tool implementation choices
- ❌ **Performance Optimization**: Context loading speed improvements
- ❌ **Future Enhancements**: Dynamic preset discovery or auto-loading

## Implementation Plan

### Root Cause Analysis

The context CLI command already supports multiple presets via comma-separated values (e.g., `--preset project,dev-tools`). The issue is in the ContextIntegrator class which doesn't recognize the `presets` key in YAML format and doesn't know how to convert it to the proper CLI format.

### Technical Approach

1. **Enhance ContextIntegrator.generate_context**:
   - Detect `presets` key in YAML/Hash input
   - Convert array of presets to comma-separated string
   - Pass to context command with --preset flag
   - Support mixed presets + files configuration

2. **Handle mixed configurations**:
   - When both presets and files specified
   - Load presets first via --preset
   - Load additional files via YAML
   - Merge results together

3. **Improve error handling**:
   - Continue on individual preset failures
   - Provide clear error messages
   - Log which presets loaded successfully

### Implementation Steps

1. **Update ContextIntegrator.generate_context** (lines 21-34):
   ```ruby
   def generate_context(context_config)
     return "" if context_config.nil? || context_config == "none"

     # If it's a string, treat it as a preset name
     if context_config.is_a?(String)
       execute_context_command("--preset", context_config)
     elsif context_config.is_a?(Hash)
       # Check for presets key
       if context_config["presets"] || context_config[:presets]
         presets = context_config["presets"] || context_config[:presets]
         preset_names = Array(presets).join(",")
         
         # Load preset content
         preset_content = execute_context_command("--preset", preset_names)
         
         # If there are additional files/commands, load them too
         additional_config = context_config.dup
         additional_config.delete("presets")
         additional_config.delete(:presets)
         
         if additional_config.any?
           yaml_content = YAML.dump(additional_config)
           additional_content = execute_context_command_with_yaml(yaml_content)
           # Merge both contents
           return [preset_content, additional_content].compact.join("\n\n")
         else
           return preset_content
         end
       else
         # Original behavior for non-preset configs
         yaml_content = YAML.dump(context_config)
         execute_context_command_with_yaml(yaml_content)
       end
     else
       ""
     end
   end
   ```

2. **Update ReviewPresetManager.resolve_context_config** (if needed):
   - Already handles String (preset name) correctly
   - Ensure Hash with presets key is preserved
   - Let ContextIntegrator handle the details

3. **Add validation for preset names**:
   ```ruby
   def validate_preset_names(presets)
     Array(presets).each do |preset|
       unless preset.is_a?(String) && preset.match?(/^[a-z0-9\-_]+$/i)
         raise ArgumentError, "Invalid preset name: #{preset}"
       end
     end
   end
   ```

### Tool Requirements

- Ruby code editor
- Access to context CLI command
- Test environment with multiple presets configured

### Risk Assessment

- **Low Risk**: Context CLI already supports multiple presets
- **Low Risk**: Changes isolated to ContextIntegrator
- **Medium Risk**: Breaking existing single-preset workflows
  - Mitigation: Preserve backward compatibility
  - Test both single and multi-preset modes

### Test Case Planning

#### Unit Tests
- Parse presets array from YAML
- Convert to comma-separated CLI format
- Handle mixed presets + files configuration
- Validate preset name format

#### Integration Tests
- Load multiple presets via YAML
- Verify all preset contents included
- Test preset + files combination
- Check deduplication of overlapping files

#### Edge Cases
- Empty presets array
- Invalid preset names
- Mix of valid and invalid presets
- Very large combined context
- Presets with no files configured

### Alternative Approach (if needed)

If modifying ContextIntegrator proves complex, an alternative is to handle this in ReviewPresetManager:

1. Expand presets array in YAML to multiple context tool calls
2. Execute each preset separately
3. Combine results before returning

This would be less efficient but safer for backward compatibility.

## References

- Testing session: Only one file loaded when three presets specified
- Context configuration: .coding-agent/context.yml preset definitions
- Related tool: context CLI command at dev-tools/lib/coding_agent_tools/cli/commands/context.rb:255-285
- ContextIntegrator: dev-tools/lib/coding_agent_tools/molecules/code/context_integrator.rb:21-34