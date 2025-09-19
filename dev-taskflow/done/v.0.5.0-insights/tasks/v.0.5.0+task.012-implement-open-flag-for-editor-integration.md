---
id: v.0.5.0+task.012
status: completed
priority: medium
estimate: 4h
dependencies: ["v.0.5.0+task.006"]
---

# Implement --open flag for editor integration

## Summary

Add support for the --open flag in the search tool to allow direct opening of search results in the user's configured editor, improving developer workflow efficiency.

## Context

The search tool currently displays results in the terminal, requiring users to manually copy file paths and open them in their editor. This breaks the development flow and reduces productivity.

Adding an --open flag would allow users to immediately open search results in their preferred editor, creating a seamless search-to-edit workflow that significantly improves the developer experience.

## Behavioral Specification

### User Experience
- **Input**: User runs search command with --open flag
- **Process**: Search executes and automatically opens results in configured editor
- **Output**: Editor opens with relevant files, user can immediately start editing

### Expected Behavior

The --open flag should integrate with the user's development environment to provide seamless editor integration.

Specifically:
1. **Editor detection** should identify the user's preferred editor
2. **Multiple results** should be handled appropriately (prompt or open all)
3. **Editor configuration** should be customizable
4. **Error handling** should gracefully handle editor launch failures

### Interface Contract

```bash
# Open single result in editor
search "function_name" --open
# Expected: Editor opens with the matching file

# Open multiple results with confirmation
search "pattern" --open --multiple
# Expected: Prompt to select files or open all

# Configure editor preference
search config --editor code
# Expected: Sets VS Code as default editor

# Open with specific editor
search "pattern" --open --editor vim
# Expected: Opens in Vim regardless of default setting

# Open with line number positioning (if supported by editor)
search "pattern" --open --line
# Expected: Editor opens and positions cursor at match location
```

### Success Criteria

- [x] Implement --open flag in search CLI
- [x] Support common editors (VS Code, Vim, Emacs, Sublime, etc.)
- [x] Allow configuration of preferred editor
- [x] Handle multiple search results appropriately
- [x] Add documentation for the feature
- [x] Include line number positioning when possible
- [x] Provide graceful error handling for editor launch failures
- [x] Support editor-specific command line arguments

## Technical Details

### Editor Support Matrix

**Primary Editors (Phase 1)**
- VS Code: `code file` or `code file:line`
- Vim/Neovim: `vim +line file` or `nvim +line file`
- Emacs: `emacs +line file`
- Sublime Text: `subl file:line`

**Extended Editors (Phase 2)**
- Atom: `atom file:line`
- TextMate: `mate file -l line`
- IntelliJ IDEA: `idea file:line`
- Nano: `nano +line file`

### Configuration System

**Editor Detection Priority**
1. Command line --editor flag
2. User configuration file setting
3. Environment variables (EDITOR, VISUAL)
4. System default detection
5. Fallback to system default

**Configuration Storage**
```bash
# User config file location
~/.config/coding_agent/config.yml

# Configuration format
editor:
  default: "code"
  line_support: true
  args: ["--goto"]
```

### Multiple Results Handling

**Strategies**
- **Interactive mode**: Prompt user to select files
- **Batch mode**: Open all results (with confirmation)
- **Limit mode**: Open only first N results
- **Filter mode**: Allow pattern refinement before opening

## Implementation Approach

### Phase 1: Core Implementation
1. **Flag parsing**: Add --open flag to CLI parser
2. **Editor detection**: Implement editor discovery system  
3. **Single file handling**: Open individual files in editor
4. **Basic configuration**: Support editor preference setting

### Phase 2: Enhanced Features
1. **Multiple file handling**: Implement selection/batch opening
2. **Line positioning**: Add line number support for supported editors
3. **Advanced configuration**: Custom editor commands and arguments
4. **Error recovery**: Robust error handling and fallback options

### Phase 3: Polish and Documentation
1. **Performance optimization**: Efficient file handling for large result sets
2. **Cross-platform testing**: Ensure compatibility across operating systems
3. **User documentation**: Comprehensive usage examples and configuration guide
4. **Integration testing**: Validate with common development workflows

### Technical Architecture

**Components**
```
SearchCommand
├── OpenFlag (new)
├── EditorDetector (new)
├── EditorLauncher (new)
├── ConfigurationManager (enhanced)
└── ResultProcessor (enhanced)
```

**Editor Abstraction**
```ruby
class EditorLauncher
  def initialize(editor_type, config)
  def launch_file(file_path, line = nil)
  def launch_files(file_paths)
  def supports_line_numbers?
  def validate_availability
end
```

## Risk Assessment

### Technical Risks
- **Risk:** Editor command variations across platforms may cause failures
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Comprehensive editor command testing across platforms
  - **Fallback:** Default to system file opener if editor fails

- **Risk:** Large result sets may overwhelm editor or system
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Implement result limits and confirmation prompts
  - **Monitoring:** Track result set sizes and performance

### User Experience Risks
- **Risk:** Unexpected editor behavior may confuse users
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Clear documentation and predictable default behavior
  - **Testing:** Validate with multiple editors and user workflows

- **Risk:** Configuration complexity may deter adoption
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Sensible defaults and simple configuration options
  - **Documentation:** Clear setup guides for common editors

### Security Risks
- **Risk:** Command injection through editor arguments
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Strict input validation and command sanitization
  - **Auditing:** Security review of command construction

## Out of Scope

- ❌ **Custom Editor Development**: Creating or modifying existing editors
- ❌ **Advanced IDE Integration**: Deep integration with IDE-specific features
- ❌ **File Modification**: Automatically editing or modifying opened files
- ❌ **Version Control Integration**: Git blame or history integration in editors

## References

- Task v.0.5.0+task.006: Search tool simplification that provides foundation for this enhancement
- Common editor command-line interfaces and capabilities
- User workflow analysis for search-to-edit patterns
- Cross-platform editor availability and behavior studies