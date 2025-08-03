---
id: v.0.4.0+task.021
status: draft
priority: high
estimate: TBD
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

## References

- Source idea file: dev-taskflow/backlog/ideas/20250803-1644-raw-input-capture.md
- Related tool: ideas-manager workflow
- Character limit reference: llm-query tool configuration