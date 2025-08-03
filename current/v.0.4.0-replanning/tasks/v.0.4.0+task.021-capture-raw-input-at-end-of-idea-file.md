---
id: v.0.4.0+task.021
status: pending
priority: high
estimate: 2h
dependencies: []
---

# Capture Raw Input at End of Idea File

## Behavioral Specification

### User Experience
- **Input**: User provides raw text or prompt to the ideas-manager tool for processing into a structured idea file
- **Process**: The system processes the input, generates structured content, and automatically appends the original raw input at the end of the file in a designated SOURCE section
- **Output**: A complete idea file with both structured content and preserved raw input for full traceability

### Expected Behavior
<!-- Describe WHAT the system should do from the user's perspective -->
The ideas-manager tool should automatically preserve the exact original user input at the end of every generated idea file. When a user submits a raw idea or prompt, the system will:

1. Process the input into a structured idea format as currently implemented
2. Append a clearly marked SOURCE section at the very end of the file
3. Include the exact, unmodified raw input within a markdown code block
4. Apply the same character limit as used for llm-query to prevent excessive file sizes

This ensures complete traceability from structured ideas back to their original source, supporting debugging, auditing, and understanding of the AI's interpretation process.

### Interface Contract
<!-- Define all external interfaces, APIs, and interaction points -->

```bash
# CLI Interface - No changes to existing interface
ideas-manager [OPTIONS] "Raw idea or prompt text"
# The SOURCE section is added automatically without user intervention

# Expected file structure output
[Structured idea content...]

> SOURCE

```text
[Exact raw input text preserved here]
```
```

**Error Handling:**
- Input exceeding character limit: Truncate with ellipsis and note indicating truncation
- Empty input: Skip SOURCE section creation
- Special characters or encoding issues: Preserve as-is with best-effort encoding

**Edge Cases:**
- Multi-line input: Preserve exactly including line breaks
- Input with markdown code blocks: Escape appropriately to prevent parsing conflicts
- Very large inputs: Apply same limit as llm-query (configurable)

### Success Criteria
<!-- Define measurable, observable criteria that indicate successful completion -->

- [ ] **Automatic Preservation**: Every idea file generated includes the SOURCE section with raw input
- [ ] **Exact Reproduction**: The preserved input matches the original character-for-character
- [ ] **Consistent Formatting**: SOURCE section always appears at the end with standardized format
- [ ] **Size Management**: Large inputs are handled gracefully with appropriate truncation

### Validation Questions
<!-- Questions to clarify requirements, resolve ambiguities, and validate understanding -->

- [x] **Section Naming**: Should the section be called "SOURCE" as suggested? - Yes, confirmed in idea file
- [x] **Format Choice**: Should raw input be in a text code block? - Yes, confirmed in idea file  
- [x] **Character Limit**: Should we use the same limit as llm-query? - Yes, confirmed in idea file
- [ ] **Encoding Handling**: How should we handle special characters or encoding issues in raw input?

## Objective

To ensure complete traceability and auditability by preserving the exact original user input that generated each idea file, enabling better debugging, understanding of AI interpretation, and maintaining a clear audit trail from requirements to implementation.

## Scope of Work
<!-- Define the behavioral scope - what user experiences and system behaviors are included -->

- **User Experience Scope**: Transparent preservation of raw input without requiring user action
- **System Behavior Scope**: Automatic appending of SOURCE section to all idea files
- **Interface Scope**: No changes to existing CLI interface - enhancement is internal

### Deliverables
<!-- Focus on behavioral and experiential deliverables, not implementation artifacts -->

#### Behavioral Specifications
- User experience flow for automatic raw input preservation
- System behavior for SOURCE section generation
- Interface contract maintaining backward compatibility

#### Validation Artifacts
- Test scenarios for various input types and sizes
- Validation methods for exact reproduction
- Edge case handling verification

## Out of Scope
<!-- Explicitly exclude implementation concerns to maintain behavioral focus -->

- ❌ **Implementation Details**: Specific code modifications or file structure changes
- ❌ **Technology Decisions**: Choice of parsing libraries or text processing methods
- ❌ **Performance Optimization**: Specific strategies for handling large inputs efficiently
- ❌ **UI Enhancement**: Changes to the command-line interface or additional flags
- ❌ **Historical Migration**: Retroactively adding SOURCE sections to existing idea files

## Technical Approach

### Architecture Pattern
- [ ] Enhancement Pattern: Post-processing enhancement after LLM generation
- [ ] Integration Pattern: Modify the IdeaCapture organism to append SOURCE section
- [ ] Data Flow: Raw input → LLM enhancement → Append SOURCE section → Save file

### Technology Stack
- [ ] Ruby for implementation (existing dev-tools gem)
- [ ] File I/O operations for appending content
- [ ] Character limit handling from llm-query patterns
- [ ] No new dependencies required

### Implementation Strategy
- [ ] Minimal change approach: Modify only the final file writing step
- [ ] Preserve exact input before any processing
- [ ] Use consistent markdown formatting for SOURCE section
- [ ] Apply same character limits as llm-query for consistency

## File Modifications

### Modify
- `dev-tools/lib/coding_agent_tools/organisms/idea_capture.rb`
  - Changes: Add SOURCE section appending logic after LLM enhancement
  - Impact: All generated idea files will include raw input preservation
  - Integration points: After enhance_idea_with_llm, before final file write

- `dev-tools/lib/coding_agent_tools/molecules/llm_client.rb`
  - Changes: Ensure SOURCE section is appended after successful enhancement
  - Impact: Preserves raw input even when LLM modifies content
  - Integration points: After execute_llm_query success

### Test Files to Update
- `dev-tools/spec/organisms/idea_capture_spec.rb`
  - Changes: Add tests for SOURCE section presence and format
  - Impact: Ensures feature works correctly
  - Integration points: New test cases for SOURCE section validation

## Risk Assessment

### Technical Risks
- **Risk:** LLM might already include a SOURCE-like section
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Append our SOURCE section regardless, as standardization is valuable
  - **Rollback:** Simple removal of appending logic

- **Risk:** Character limit truncation might cut off important raw input
  - **Probability:** Medium
  - **Impact:** Medium  
  - **Mitigation:** Add truncation indicator when limit exceeded
  - **Monitoring:** Check output files for truncation markers

### Integration Risks
- **Risk:** Breaking existing idea file parsing tools
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** SOURCE section at end won't affect header parsing
  - **Monitoring:** Test with existing task-manager tools

## Implementation Plan

### Planning Steps

* [ ] Review current character limit implementation in llm-query
* [ ] Analyze existing idea file structure patterns
* [ ] Determine optimal SOURCE section format and placement
* [ ] Check for any existing raw input preservation patterns

### Execution Steps

- [ ] Step 1: Add SOURCE section appending method to IdeaCapture organism
  - Create `append_source_section` private method
  - Handle character limit with truncation indicator
  - Format SOURCE section with markdown code block
  > TEST: SOURCE Section Method
  > Type: Unit Test
  > Assert: Method correctly formats and appends SOURCE section
  > Command: cd dev-tools && bundle exec rspec spec/organisms/idea_capture_spec.rb -e "appends SOURCE"

- [ ] Step 2: Integrate SOURCE appending into capture_idea flow
  - Call append_source_section after successful LLM enhancement
  - Also append SOURCE for fallback raw ideas
  - Ensure SOURCE is always last section
  > TEST: Integration Flow
  > Type: Integration Test  
  > Assert: Generated idea files contain SOURCE section at end
  > Command: cd dev-tools && bundle exec rspec spec/integration/idea_capture_integration_spec.rb

- [ ] Step 3: Handle edge cases and special characters
  - Escape markdown code blocks in raw input if present
  - Handle multi-line input correctly
  - Preserve exact formatting including whitespace
  > TEST: Edge Case Handling
  > Type: Unit Test
  > Assert: Special characters and markdown preserved correctly
  > Command: cd dev-tools && bundle exec rspec spec/organisms/idea_capture_spec.rb -e "handles special"

- [ ] Step 4: Add character limit enforcement
  - Get character limit from configuration or use default
  - Truncate with "[truncated]" indicator when exceeded
  - Log when truncation occurs for debugging
  > TEST: Character Limit
  > Type: Unit Test
  > Assert: Large inputs truncated with indicator
  > Command: cd dev-tools && bundle exec rspec spec/organisms/idea_capture_spec.rb -e "truncates large"

- [ ] Step 5: Update tests for SOURCE section validation
  - Add test cases for SOURCE section presence
  - Test exact reproduction of raw input
  - Test truncation behavior
  > TEST: Test Coverage
  > Type: Test Suite
  > Assert: All new tests pass
  > Command: cd dev-tools && bundle exec rspec

- [ ] Step 6: Manual testing with various input types
  - Test with simple one-line ideas
  - Test with multi-paragraph ideas
  - Test with ideas containing markdown
  - Test with very large inputs
  > TEST: Manual Validation
  > Type: Manual Test
  > Assert: SOURCE section appears correctly in all cases
  > Command: capture-it "test idea" && tail -20 dev-taskflow/backlog/ideas/*.md

## Acceptance Criteria

- [ ] Every generated idea file includes SOURCE section at the end
- [ ] SOURCE section contains exact unmodified raw input
- [ ] Large inputs are truncated with clear indicator
- [ ] Special characters and formatting preserved correctly
- [ ] All existing tests continue to pass
- [ ] New tests validate SOURCE section behavior

## Out of Scope

- ❌ Retroactive addition of SOURCE to existing idea files
- ❌ UI changes to capture-it command interface  
- ❌ Changes to LLM prompts or enhancement logic
- ❌ Modification of idea file header format
- ❌ Integration with other tools beyond capture-it

## References

- Source idea file: dev-taskflow/backlog/ideas/20250803-1644-raw-input-capture.md
- Related tool: capture-it (formerly ideas-manager) workflow
- Character limit reference: llm-query tool configuration
- Implementation files: dev-tools/lib/coding_agent_tools/organisms/idea_capture.rb