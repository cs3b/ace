---
id: v.0.5.0+task.031
status: done
priority: medium
estimate: 2h
dependencies: []
---

# Fix code-review default output file naming

## Behavioral Specification

### User Experience
- **Input**: User runs `code-review` command without specifying `--output` flag
- **Process**: System automatically generates a default filename based on the model being used
- **Output**: Review report saved to `cr-{model-name}.md` in the current working directory

### Expected Behavior
When users execute the code-review command without an explicit output file, the system should automatically create a predictable, model-specific filename in the current directory. This eliminates the need for users to always specify --output and provides consistent naming that helps identify which model generated each review.

### Interface Contract
```bash
# CLI Interface
code-review --preset pr --auto-execute
# Expected output: Creates cr-google-gemini-2-0-flash-exp.md in current directory

code-review --model claude-3-opus --preset code --auto-execute  
# Expected output: Creates cr-claude-3-opus.md in current directory

# With explicit output (override default)
code-review --preset pr --output my-review.md --auto-execute
# Expected output: Creates my-review.md as specified
```

**Error Handling:**
- File exists: Append timestamp or counter to avoid overwriting
- No write permissions: Display clear error message with attempted path

**Edge Cases:**
- Model name with special characters: Sanitize for valid filename
- Very long model names: Truncate while maintaining uniqueness

### Success Criteria
- [ ] **Default Naming**: Reviews save to `cr-{model-name}.md` without --output flag
- [ ] **Current Directory**: Default files created in user's current working directory
- [ ] **Model Identification**: Filename clearly indicates which model was used
- [ ] **Override Works**: Explicit --output flag still takes precedence

### Validation Questions
- [ ] **Overwrite Behavior**: Should existing files be overwritten or should we append timestamps?
  - **Research conducted**: Checked existing code patterns in codebase
  - **Suggested default**: Overwrite existing files (consistent with explicit --output behavior)
  - **Implementation note**: Can add timestamp suffix later if needed
- [ ] **Directory Location**: Confirm current directory vs session directory for default?
  - **Research conducted**: Line 364 shows fallback uses session_dir when available
  - **Suggested default**: Current working directory (matches user expectation)
  - **Implementation note**: Keep session_dir fallback for non-auto-execute mode
- [ ] **Model Name Format**: How to handle colons and slashes in model names for filenames?
  - **Research conducted**: Line 315 already sanitizes: `.gsub(":", "-").gsub("/", "-")`
  - **Implementation**: Use existing sanitization pattern for consistency

## Objective

Improve user experience by providing sensible defaults for output file naming, reducing command complexity and making review outputs more predictable and organized.

## Scope of Work

- **User Experience Scope**: Default output file naming behavior for code-review command
- **System Behavior Scope**: Automatic filename generation based on model parameter
- **Interface Scope**: Maintaining backward compatibility with explicit --output flag

### Deliverables

#### Behavioral Specifications
- Default output file naming convention
- Filename sanitization rules for model names
- Current directory as default location

#### Validation Artifacts  
- Test cases for default naming behavior
- Edge case handling verification
- User acceptance criteria for filename predictability


## Out of Scope

- ❌ **Implementation Details**: Specific code structure or file organization
- ❌ **Technology Decisions**: Framework or library choices for implementation  
- ❌ **Performance Optimization**: Specific strategies for file I/O optimization
- ❌ **Future Enhancements**: Additional naming conventions or patterns

## Implementation Plan

### Technical Approach

1. **Modify auto_execute branch (lines 317-361)**:
   - Set default output_file when not provided: `config[:output] || "cr-#{model_name}.md"`
   - Apply before line 323 where output_file is first used
   - Ensure model_name is already sanitized (line 315)

2. **Update LLM executor call**:
   - Change condition from `if output_file` to always have output_file
   - Keep streaming behavior optional via new flag if needed
   - Maintain backward compatibility with explicit --output

3. **File location consistency**:
   - Default files go to current working directory
   - Use Dir.pwd for explicit path if needed
   - Keep session_dir logic for non-auto-execute mode

### Implementation Steps

1. **Update execute_review method**:
   ```ruby
   # After line 315 (model_name = ...)
   # Before line 317 (if options[:auto_execute])
   # Set default output file for auto-execute mode
   if options[:auto_execute] && !config[:output]
     config[:output] = "cr-#{model_name}.md"
   end
   ```

2. **Modify auto-execute block (lines 322-350)**:
   - Remove the `if output_file` condition
   - Always use file output mode
   - Update success messages to show output location

3. **Test scenarios**:
   - Test with various model names (google:gemini-2.0-flash-exp)
   - Test with explicit --output flag (should override default)
   - Test without --output flag (should create cr-{model}.md)
   - Test file overwrite behavior

### Tool Requirements

- Ruby code editor
- Test runner for validation
- Git for version control

### Risk Assessment

- **Low Risk**: Backward compatibility maintained with explicit --output
- **Low Risk**: Model name sanitization already exists
- **Medium Risk**: File overwrite could lose previous reviews
  - Mitigation: Document behavior clearly
  - Future enhancement: Add --no-overwrite flag if needed

### Test Case Planning

#### Unit Tests
- Default filename generation with various model names
- Sanitization of special characters in model names
- Override behavior with explicit --output

#### Integration Tests
- Full command execution with auto-execute and no output flag
- File creation in current directory
- Content written correctly to default file

#### Edge Cases
- Very long model names (truncation not needed based on research)
- Model names with multiple special characters
- Write permission errors in current directory

## References

- Testing session: This issue was discovered during code-review command testing
- Related command: code-review CLI implementation at .ace/tools/lib/coding_agent_tools/cli/commands/code/review.rb:314-364
- Model name sanitization: Line 315 in review.rb