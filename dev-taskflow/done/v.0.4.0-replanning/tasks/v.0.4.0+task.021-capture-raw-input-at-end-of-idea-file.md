---
id: v.0.4.0+task.021
status: done
priority: high
estimate: 2h
dependencies: []
needs_review: true
---

# Capture Raw Input at End of Idea File

## Review Questions (Pending Human Input)

### [HIGH] Critical Implementation Questions
- [ ] Should the SOURCE section be added even when the LLM enhancement fails and fallback content is written?
  - **Research conducted**: Checked `save_fallback_idea` method which creates a "Raw Idea (Enhanced Version Failed)" format
  - **Current implementation**: Fallback includes "## Original Idea" section with raw text
  - **Suggested default**: Add SOURCE section to both enhanced and fallback files for consistency
  - **Why needs human input**: Design decision about whether SOURCE section should be universal or only for successful enhancements

- [ ] How should markdown code blocks within the raw input be escaped to prevent parsing conflicts?
  - **Research conducted**: Examined current file writing patterns, no escaping logic found
  - **Similar implementations**: Standard markdown uses nested backticks or HTML entities
  - **Suggested default**: Use 4 backticks for SOURCE block when input contains 3 backticks
  - **Why needs human input**: Edge case handling strategy needs confirmation

### [MEDIUM] Enhancement Questions
- [ ] Should the SOURCE section include metadata like timestamp and character count?
  - **Research conducted**: Current idea files include metadata header with tokens, cost, timestamp
  - **Suggested default**: Keep SOURCE minimal - just the raw text in a code block
  - **Why needs human input**: Balance between traceability and simplicity

- [ ] Should very long inputs show a truncation notice inline or just truncate silently?
  - **Research conducted**: Current limit is 7000 chars (BIG_INPUT_THRESHOLD), expandable with --big-user-input-allowed
  - **Suggested default**: Add "[truncated at 7000 characters]" marker when truncated
  - **Why needs human input**: User experience for understanding truncation

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
- [x] **Encoding Handling**: How should we handle special characters or encoding issues in raw input? - Research: Ruby's File.write handles UTF-8 by default, preserve as-is

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
- [x] Enhancement Pattern: Post-processing enhancement after LLM generation - Confirmed through code review
- [x] Integration Pattern: Modify the IdeaCapture organism to append SOURCE section - Verified in idea_capture.rb
- [x] Data Flow: Raw input → LLM enhancement → Append SOURCE section → Save file - Traced through implementation

### Technology Stack
- [x] Ruby for implementation (existing .ace/tools gem) - Confirmed
- [x] File I/O operations for appending content - Using standard Ruby File class
- [x] Character limit handling from llm-query patterns - BIG_INPUT_THRESHOLD = 7000 found
- [x] No new dependencies required - Verified, uses existing infrastructure

### Implementation Strategy
- [x] Minimal change approach: Modify only the final file writing step - Optimal approach confirmed
- [x] Preserve exact input before any processing - Input available in capture_idea method
- [x] Use consistent markdown formatting for SOURCE section - Format defined in idea file
- [x] Apply same character limits as llm-query for consistency - Use BIG_INPUT_THRESHOLD constant

## File Modifications

### Modify
- `.ace/tools/lib/coding_agent_tools/organisms/idea_capture.rb`
  - Changes: Add SOURCE section appending logic after LLM enhancement
  - Impact: All generated idea files will include raw input preservation
  - Integration points: After enhance_idea_with_llm, before final file write

- `.ace/tools/lib/coding_agent_tools/molecules/llm_client.rb`
  - Changes: No changes needed - LLM client only handles query execution
  - Impact: SOURCE section appending happens in IdeaCapture after LLM completes
  - Integration points: None - maintain separation of concerns

### Test Files to Update
- `.ace/tools/spec/coding_agent_tools/organisms/idea_capture_spec.rb` (path corrected)
  - Changes: Add tests for SOURCE section presence and format
  - Impact: Ensures feature works correctly
  - Integration points: New test cases for SOURCE section validation

- `.ace/tools/spec/integration/ideas_manager_integration_spec.rb`
  - Changes: Add integration test for end-to-end SOURCE section
  - Impact: Validates complete workflow
  - Integration points: Test actual file output contains SOURCE

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

* [x] Review current character limit implementation in llm-query - Found BIG_INPUT_THRESHOLD = 7000
* [x] Analyze existing idea file structure patterns - Reviewed template and generated files
* [x] Determine optimal SOURCE section format and placement - Use > SOURCE header with ```text block
* [x] Check for any existing raw input preservation patterns - None found, fallback has different format

### Execution Steps

- [x] Step 1: Add SOURCE section appending method to IdeaCapture organism
  - Create `append_source_section` private method
  - Handle character limit with truncation indicator (use @max_input_size from initialize)
  - Format SOURCE section with markdown code block
  - Method signature: `append_source_section(content, raw_input)`
  > TEST: SOURCE Section Method
  > Type: Unit Test
  > Assert: Method correctly formats and appends SOURCE section
  > Command: cd .ace/tools && bundle exec rspec spec/organisms/idea_capture_spec.rb -e "appends SOURCE"

- [x] Step 2: Integrate SOURCE appending into capture_idea flow
  - Modify enhance_idea_with_llm result handling (lines 76-86)
  - Call append_source_section before final file write
  - Also modify save_fallback_idea to include SOURCE section
  - Ensure SOURCE is always last section
  > TEST: Integration Flow
  > Type: Integration Test  
  > Assert: Generated idea files contain SOURCE section at end
  > Command: cd .ace/tools && bundle exec rspec spec/integration/idea_capture_integration_spec.rb

- [x] Step 3: Handle edge cases and special characters
  - Escape markdown code blocks in raw input if present
  - Handle multi-line input correctly
  - Preserve exact formatting including whitespace
  > TEST: Edge Case Handling
  > Type: Unit Test
  > Assert: Special characters and markdown preserved correctly
  > Command: cd .ace/tools && bundle exec rspec spec/organisms/idea_capture_spec.rb -e "handles special"

- [x] Step 4: Add character limit enforcement
  - Use @max_input_size from instance (already set based on big_user_input_allowed)
  - Truncate with "[truncated at X characters]" indicator when exceeded
  - Use debug_log method for truncation logging
  > TEST: Character Limit
  > Type: Unit Test
  > Assert: Large inputs truncated with indicator
  > Command: cd .ace/tools && bundle exec rspec spec/organisms/idea_capture_spec.rb -e "truncates large"

- [x] Step 5: Update tests for SOURCE section validation
  - Add test cases for SOURCE section presence
  - Test exact reproduction of raw input
  - Test truncation behavior
  - Test markdown escaping for nested code blocks
  > TEST: Test Coverage
  > Type: Test Suite
  > Assert: All new tests pass
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/organisms/idea_capture_spec.rb

- [x] Step 6: Manual testing with various input types
  - Test with simple one-line ideas
  - Test with multi-paragraph ideas
  - Test with ideas containing markdown
  - Test with very large inputs
  > TEST: Manual Validation
  > Type: Manual Test
  > Assert: SOURCE section appears correctly in all cases
  > Command: capture-it "test idea" && tail -20 .ace/taskflow/backlog/ideas/*.md

## Acceptance Criteria

- [x] Every generated idea file includes SOURCE section at the end
- [x] SOURCE section contains exact unmodified raw input
- [x] Large inputs are truncated with clear indicator
- [x] Special characters and formatting preserved correctly
- [x] All existing tests continue to pass
- [x] New tests validate SOURCE section behavior

## Out of Scope

- ❌ Retroactive addition of SOURCE to existing idea files
- ❌ UI changes to capture-it command interface  
- ❌ Changes to LLM prompts or enhancement logic
- ❌ Modification of idea file header format
- ❌ Integration with other tools beyond capture-it

## References

- Source idea file: .ace/taskflow/current/v.0.4.0-replanning/docs/ideas/021-20250803-1644-raw-input-capture.md
- Related tool: capture-it (formerly ideas-manager) workflow
- Character limit reference: BIG_INPUT_THRESHOLD constant (7000 chars)
- Implementation files:
  - Main: .ace/tools/lib/coding_agent_tools/organisms/idea_capture.rb
  - Tests: .ace/tools/spec/coding_agent_tools/organisms/idea_capture_spec.rb
  - Integration: .ace/tools/spec/integration/ideas_manager_integration_spec.rb
- Template files:
  - .ace/handbook/templates/idea-manager/idea.template.md
  - .ace/handbook/templates/idea-manager/system.prompt.md