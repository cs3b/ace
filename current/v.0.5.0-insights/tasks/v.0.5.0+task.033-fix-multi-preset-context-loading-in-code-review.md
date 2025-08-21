---
id: v.0.5.0+task.033
status: draft
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
- [ ] **Load Order**: Does order of presets matter for context organization?
- [ ] **Error Behavior**: Should one bad preset stop all loading or continue?
- [ ] **Size Limits**: Any maximum context size we should enforce?

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

## References

- Testing session: Only one file loaded when three presets specified
- Context configuration: .coding-agent/context.yml preset definitions
- Related tool: context CLI command used internally by code-review