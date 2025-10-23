---
id: v.0.9.0+task.084
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Enable file path arguments for /ace:load-context command

## Behavioral Specification

### User Experience
- **Input**: Users provide either a preset name (e.g., `project`) OR a file path (relative or absolute) when invoking `/ace:load-context`
- **Process**: Command automatically detects input type (preset vs file path vs protocol URL) and calls `ace-context` with appropriate arguments
- **Output**: Context is loaded successfully from the specified source, with clear error messages when file/preset not found

### Expected Behavior

The `/ace:load-context` slash command should accept flexible input arguments that match the capabilities already available in the `ace-context` CLI tool. Currently, `ace-context` supports:
- Preset names: `ace-context project`
- File paths: `ace-context /path/to/context.md`
- Protocol URLs: `ace-context wfi://workflow-name`

However, the `/ace:load-context` command currently hardcodes the `--preset` flag, limiting it to only accept preset names.

**Desired behavior:**
- Users can invoke `/ace:load-context` with any valid input that `ace-context` supports
- The command intelligently detects the input type without requiring explicit flags
- Task-specific context files can be loaded dynamically during workflows
- Custom context files from anywhere in the project can be used

### Interface Contract

```bash
# Slash command interface variations
/ace:load-context                    # Default: loads "project" preset
/ace:load-context project            # Named preset
/ace:load-context base               # Another preset
/ace:load-context .ace-taskflow/v.0.9.0/context/task-085.md  # Relative file path
/ace:load-context /Users/mc/Ps/ace-meta/.ace/context.yml    # Absolute file path
/ace:load-context wfi://some-workflow  # Protocol URL (if ace-context supports)
```

**Expected outputs:**
- Success: "Context saved (N lines, X KB), output file: /path/to/cache"
- File not found: "Error: Context file not found: /path/to/file.md"
- Preset not found: "Error: Preset 'name' not found. Use --list-presets to see available presets"

**Error Handling:**
- File path does not exist: Clear error message indicating file not found with full path
- Preset does not exist: Clear error message with suggestion to list available presets
- Invalid format: Error message indicating format issue (if file exists but is invalid)
- Permission denied: Error message about file access permissions

**Edge Cases:**
- Empty argument: Uses default "project" preset (existing behavior)
- Ambiguous input (could be preset or file): Preset takes precedence if both exist, or file path detection based on path separators (/, ., etc.)
- Relative paths: Resolved from current working directory

### Success Criteria

- [ ] **Flexible Input Acceptance**: `/ace:load-context` accepts preset names, file paths (relative/absolute), and protocol URLs
- [ ] **Automatic Detection**: Command correctly detects input type without requiring explicit flags like `--preset` or `--file`
- [ ] **Backward Compatibility**: Existing usage with preset names (e.g., `/ace:load-context project`) continues to work unchanged
- [ ] **Task-Specific Context Loading**: Can load custom context files like `.ace-taskflow/v.0.9.0/context/task-084.md` during workflow execution
- [ ] **Clear Error Messages**: Distinct error messages for "file not found" vs "preset not found" scenarios
- [ ] **Documentation Updated**: Command usage examples show both preset and file path usage

### Validation Questions

- [ ] **Detection Logic**: How should the command distinguish between a preset name and a file path? (e.g., presence of `/`, `.`, file extension?)
- [ ] **Precedence**: If both a preset named "test" and a file "test" exist, which should take precedence?
- [ ] **Protocol Support**: Should `/ace:load-context` support all protocols that `ace-context` supports (wfi://, guide://, etc.)?
- [ ] **Multiple Arguments**: Should the command support multiple inputs like `ace-context -p base -f custom.yml`?
- [ ] **Output Control**: Should users be able to specify output mode (stdio, cache, file path) via `/ace:load-context`?

## Objective

Enable the `/ace:load-context` slash command to leverage the full flexibility of the `ace-context` CLI tool by accepting file paths in addition to preset names. This allows workflows to load task-specific context files, custom context configurations, and any context source that `ace-context` supports, making context loading more dynamic and powerful during AI-assisted development sessions.

## Scope of Work

- **User Experience Scope**:
  - Slash command invocation with flexible arguments (preset or file path)
  - Clear feedback on what context was loaded from where
  - Helpful error messages when sources not found

- **System Behavior Scope**:
  - Input type detection (preset vs file path vs protocol)
  - Argument passing to `ace-context` without hardcoded flags
  - Error handling and user feedback

- **Interface Scope**:
  - `/ace:load-context` slash command interface
  - Integration with existing `ace-context` CLI capabilities
  - No changes to `ace-context` CLI itself (already supports this)

### Deliverables

#### Behavioral Specifications
- User experience flow for flexible context loading
- Input type detection behavior specification
- Error handling and feedback specifications

#### Validation Artifacts
- Success criteria validation through usage examples
- Test scenarios for preset vs file path detection
- Backward compatibility verification

## Out of Scope

- ❌ **Changes to ace-context CLI**: The CLI already supports file paths; only the slash command wrapper needs updating
- ❌ **New Context File Formats**: Not adding support for new formats beyond what ace-context already handles
- ❌ **Context Caching Changes**: Not modifying how context is cached or stored
- ❌ **Preset Management**: Not adding preset creation/editing capabilities

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/done/20251023-200025-ace-context-and-aceload-context-should-take-argu.md` (marked as done)
- `ace-context` CLI help output showing current file path support
- Existing `/ace:load-context` command implementation (inline in Claude Code prompts)
