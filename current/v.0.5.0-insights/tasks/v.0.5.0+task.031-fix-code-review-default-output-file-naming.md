---
id: v.0.5.0+task.031
status: draft
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
- [ ] **Directory Location**: Confirm current directory vs session directory for default?
- [ ] **Model Name Format**: How to handle colons and slashes in model names for filenames?

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

## References

- Testing session: This issue was discovered during code-review command testing
- Related command: code-review CLI implementation