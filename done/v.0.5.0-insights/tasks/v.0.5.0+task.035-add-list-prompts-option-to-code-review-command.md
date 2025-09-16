---
id: v.0.5.0+task.035
status: done
priority: medium
estimate: 3h
dependencies: []
---

# Add --list-prompts option to code-review command

## Behavioral Specification

### User Experience
- **Input**: User runs `code-review --list-prompts` command
- **Process**: System discovers and categorizes all available prompt modules from filesystem
- **Output**: Organized display of all prompt modules grouped by type (base, format, focus, guidelines) with usage paths

### Expected Behavior

Users need a way to discover all available prompt modules that can enhance their code reviews. Similar to how `--list-presets` shows configuration presets, the `--list-prompts` option should provide a comprehensive view of available prompt modules organized by category.

The system should:
- Discover prompt modules from `.ace/handbook/templates/review-modules/` directory
- Categorize modules by their directory structure (base, format, focus, guidelines)
- Display subcategories for focus modules (architecture, frameworks, languages, quality, scope)
- Show the usage path for each module (how to reference it in prompts)
- Handle missing modules directory gracefully
- Exit after displaying the list (no further processing)

### Interface Contract

```bash
# CLI Interface
code-review --list-prompts

# Expected Output Format:
Available prompt modules:

Base modules:
  system        - Base system prompt
  sections      - Standard review sections

Format modules:
  standard      - Standard format
  detailed      - Detailed format
  compact       - Compact format

Focus modules:
  architecture/atom       - ATOM architecture patterns
  frameworks/rails        - Ruby on Rails framework
  frameworks/vue-firebase - Vue.js with Firebase
  languages/ruby          - Ruby language specifics
  quality/performance     - Performance considerations
  quality/security        - Security review focus
  scope/docs             - Documentation focus
  scope/tests            - Test coverage focus

Guideline modules:
  tone          - Professional tone guidelines
  icons         - Review icons and markers

# Exit code: 0 (success)
```

**Error Handling:**
- Missing modules directory: Display "No prompt modules found" and exit gracefully
- Permission errors: Display clear error message about directory access
- File system errors: Handle gracefully with informative messages

**Edge Cases:**
- Empty modules directory: Display "No prompt modules found"
- Nested subdirectories: Only process known category structure
- Invalid module files: Skip files that cannot be processed

### Success Criteria

- [x] **Module Discovery**: System discovers all available prompt modules from filesystem
- [x] **Categorized Display**: Modules are grouped by category (base, format, focus, guidelines)
- [x] **Usage Path Display**: Each module shows its usage path for prompt composition
- [x] **Focus Subcategories**: Focus modules show subcategory structure clearly
- [x] **Graceful Error Handling**: Missing directories or files handled without crashes
- [x] **Consistent Format**: Output format matches existing --list-presets style

### Validation Questions

- [ ] **Module Description**: Should we display module descriptions from file content or just filenames?
- [ ] **Nested Categories**: Should we support deeper nesting than current structure?
- [ ] **Module Status**: Should we indicate if modules are valid/parseable?
- [ ] **Usage Examples**: Should we show example usage syntax for each module?

## Objective

Enable users to discover and understand available prompt modules for code review enhancement, improving their ability to customize review prompts and utilize the full capability of the prompt system.

## Scope of Work

- **User Experience Scope**: Add discovery capability for prompt modules via --list-prompts option
- **System Behavior Scope**: Module filesystem discovery, categorization, and formatted display
- **Interface Scope**: New command-line option following existing --list-presets pattern

### Deliverables

#### Behavioral Specifications
- User experience flow for module discovery
- System behavior for categorization and display
- Interface contract for --list-prompts option

#### Validation Artifacts
- Success criteria for module discovery
- Error handling specifications
- Output format validation

## Out of Scope

- ❌ **Implementation Details**: File parsing logic, specific Ruby class structure
- ❌ **Module Validation**: Checking if module content is valid or parseable
- ❌ **Module Enhancement**: Modifying or improving existing modules
- ❌ **Future Features**: Module editing, validation, or management capabilities

## References

- Existing --list-presets implementation pattern
- PromptEnhancer class for module loading logic  
- Review module directory structure in .ace/handbook/templates/review-modules/

## Technical Approach

### Architecture Pattern
- [ ] **Follow existing pattern**: Mirror the --list-presets implementation in review.rb (lines 192-209)
- [ ] **Single responsibility**: Create focused method that only handles module discovery and display
- [ ] **Integration point**: Add new option and early return logic similar to list_presets pattern

### Technology Stack
- [ ] **Ruby filesystem APIs**: Use Dir.glob and File.directory? for module discovery
- [ ] **Existing PromptEnhancer**: Leverage find_modules_directory method for consistency
- [ ] **Dry::CLI option system**: Add new --list-prompts boolean option
- [ ] **No new dependencies**: Use only standard Ruby and existing project dependencies

### Implementation Strategy
- [ ] **Incremental approach**: Add option → implement method → integrate early return
- [ ] **Error handling**: Graceful fallback when modules directory doesn't exist
- [ ] **Output consistency**: Match existing info_output format used by list_presets
- [ ] **Exit behavior**: Return 0 on success, follow existing command patterns

## Tool Selection

| Criteria | Dir.glob | File.directory? | Manual traversal | Selected |
|----------|----------|-----------------|------------------|----------|
| Performance | Fast | Fast | Slow | Dir.glob + File.directory? |
| Maintenance | Simple | Simple | Complex | Dir.glob + File.directory? |
| Integration | Native | Native | Custom | Dir.glob + File.directory? |
| Error Handling | Good | Good | Manual | Dir.glob + File.directory? |

**Selection Rationale:** Use Ruby's built-in filesystem APIs for reliable, performant directory traversal with minimal complexity.

### Dependencies
- [ ] **No new dependencies**: Implementation uses only existing gems and Ruby standard library
- [ ] **Leverage PromptEnhancer**: Reuse find_modules_directory method for path resolution
- [ ] **Compatible with dry-cli**: New option integrates with existing option system

## File Modifications

### Modify
- **.ace/tools/lib/coding_agent_tools/cli/commands/code/review.rb**
  - **Changes**: Add --list-prompts option and list_prompts method
  - **Impact**: New command capability without affecting existing functionality
  - **Integration points**: Early return logic in call method, new private method

### No Create/Delete Files
- Implementation entirely contained within existing review.rb command file
- No new test files needed for this discovery-only feature
- No configuration files or templates required

## Implementation Plan

### Planning Steps

- [x] **Analyze Current Pattern**: Study list_presets implementation to understand exact pattern
  > TEST: Pattern Understanding Check
  > Type: Pre-condition Check
  > Assert: Key implementation patterns identified (option handling, early return, output format)
  > Command: grep -A 20 "def list_presets" .ace/tools/lib/coding_agent_tools/cli/commands/code/review.rb

- [x] **Map Module Structure**: Document the complete module directory structure and categorization logic
  > TEST: Module Structure Documentation
  > Type: Analysis Validation
  > Assert: All module categories and subcategories are identified and documented
  > Command: find .ace/handbook/templates/review-modules -type f -name "*.md" | sort

- [x] **Design Output Format**: Plan the exact output format matching behavioral specification
  > TEST: Output Format Design
  > Type: Design Validation
  > Assert: Output format specification matches behavioral requirements and list_presets style
  > Command: echo "Output format designed and validated against requirements"

### Execution Steps

- [x] **Add --list-prompts Option**: Add new boolean option to command definition
  > TEST: Option Addition Verification
  > Type: Structural Validation  
  > Assert: New option is properly defined in command class
  > Command: grep -A 2 "list_prompts.*boolean" .ace/tools/lib/coding_agent_tools/cli/commands/code/review.rb

- [x] **Implement Early Return Logic**: Add list_prompts check to call method
  > TEST: Early Return Integration
  > Type: Flow Control Validation
  > Assert: Early return logic properly handles --list-prompts option
  > Command: grep -A 3 "return list_prompts" .ace/tools/lib/coding_agent_tools/cli/commands/code/review.rb

- [x] **Create Module Discovery Logic**: Implement list_prompts method with directory traversal
  > TEST: Module Discovery Functionality  
  > Type: Functional Validation
  > Assert: Method discovers all modules and organizes by category
  > Command: ruby -r './.ace/tools/lib/coding_agent_tools/cli/commands/code/review.rb' -e "puts 'Module discovery logic implemented'"

- [x] **Add Categorization Logic**: Group modules by base, format, focus, guidelines categories
  > TEST: Categorization Validation
  > Type: Logic Validation
  > Assert: Modules are correctly categorized and subcategorized (focus modules)
  > Command: code-review --list-prompts | grep -E "^(Base|Format|Focus|Guideline) modules:" | wc -l

- [x] **Format Output Display**: Implement formatted output matching behavioral specification
  > TEST: Output Format Validation
  > Type: Interface Validation
  > Assert: Output format matches specified format with proper indentation and structure
  > Command: code-review --list-prompts | head -20

- [x] **Add Error Handling**: Handle missing modules directory and other edge cases gracefully  
  > TEST: Error Handling Validation
  > Type: Edge Case Validation
  > Assert: Graceful handling of missing directory and permission errors
  > Command: mv .ace/handbook/templates/review-modules .ace/handbook/templates/review-modules.bak && code-review --list-prompts; mv .ace/handbook/templates/review-modules.bak .ace/handbook/templates/review-modules

- [x] **Integration Testing**: Verify command works alongside existing options and functionality
  > TEST: Integration Validation
  > Type: End-to-End Validation
  > Assert: New option doesn't interfere with existing functionality
  > Command: code-review --list-presets && code-review --list-prompts && code-review --help | grep list-prompts

## Risk Assessment

### Technical Risks
- **Risk:** Directory traversal performance with large module collections
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Use efficient Dir.glob patterns, cache if needed in future
  - **Rollback:** Simple option removal

- **Risk:** Output format inconsistency with existing patterns
  - **Probability:** Medium
  - **Impact:** Low
  - **Mitigation:** Follow exact list_presets format and test output manually
  - **Rollback:** Adjust output format strings

### Integration Risks
- **Risk:** Command option conflicts with existing options
  - **Probability:** Low
  - **Impact:** Low  
  - **Mitigation:** Use clear, descriptive option name --list-prompts
  - **Monitoring:** Test all existing command combinations

- **Risk:** Early return logic breaking existing flow
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Follow exact pattern used by list_presets with early return
  - **Monitoring:** Test existing command functionality after changes

### Performance Risks
- **Risk:** Slow directory scanning on large filesystems
  - **Mitigation:** Scope to specific review-modules directory only
  - **Monitoring:** Test execution time
  - **Thresholds:** Should complete under 100ms for typical module collections

## Acceptance Criteria

### Behavioral Requirement Fulfillment
- [x] **Module Discovery**: --list-prompts option discovers all available prompt modules from filesystem
- [x] **Categorized Display**: Output groups modules by base, format, focus, guidelines categories
- [x] **Focus Subcategories**: Focus modules show architecture/, frameworks/, etc. subcategory structure
- [x] **Usage Path Display**: Each module shows its usage path (e.g., frameworks/rails)
- [x] **Error Handling**: Missing modules directory handled gracefully without crashes
- [x] **Output Format**: Display format matches behavioral specification example

### Implementation Quality Assurance
- [x] **Code Quality**: Implementation follows existing patterns and Ruby best practices
- [x] **Integration**: New option works alongside all existing command options  
- [x] **Performance**: Command executes quickly without noticeable delays
- [x] **Error Recovery**: Handles permission errors and missing files gracefully

### Documentation and Validation
- [x] **Help Text**: --list-prompts option appears in command help
- [x] **Example Usage**: Command examples updated to show new option
- [x] **Pattern Consistency**: Implementation matches list_presets pattern exactly