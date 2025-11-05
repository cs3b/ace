---
id: v.0.9.0+task.102
status: draft
priority: high
estimate: 2-3 days
dependencies: [v.0.9.0+task.101]
---

# Integrate ace-review with section-based content organization

Update ace-review to use the new section-based content organization system from ace-context, enabling structured organization of review content into semantic sections (focus, style, diff, etc.) while maintaining full backward compatibility with existing review presets.

## Review Questions

### Integration Decisions Needed

#### [HIGH] Integration Architecture Decisions
- [ ] **Preset migration strategy**: How should existing ace-review presets be updated?
  - Auto-migration of existing `pr.yml`, `code.yml`, etc. to use sections
  - Backward compatibility for user custom presets
  - Default section definitions for common review types

- [ ] **ReviewManager integration**: How should ReviewManager handle sections?
  - Changes to `create_system_context_file` method
  - Section-based preset configuration handling
  - Integration with existing prompt composition system

#### [MEDIUM] Preset Design Decisions
- [ ] **Standard review sections**: What sections should be defined for common review types?
  - Pull request reviews: focus, style, diff, context sections
  - Code reviews: focus, performance, security sections
  - Documentation reviews: content, style, structure sections
  - Security reviews: vulnerability, compliance, best-practice sections

- [ ] **Custom section support**: How should users be able to define custom sections?
  - Section definition in preset files
  - Section inheritance and composition
  - Section template customization

#### [LOW] Enhancement Decisions
- [ ] **Review output enhancement**: How should section-based reviews be formatted?
  - Enhanced review report templates
  - Section-specific feedback formatting
  - Improved review presentation

## Behavioral Specification

### User Experience

**Input**: User runs `ace-review --preset pr` or other review commands
**Process**: ace-review creates section-based context configuration that ace-context processes into organized sections
**Output**: Structured review system with properly organized focus files, style guidelines, diffs, and context

### Expected Behavior

- Existing ace-review presets automatically use sections when available
- Pull request reviews organize content into focus, style, diff, and context sections
- Review system maintains all existing functionality with enhanced organization
- Users can define custom sections in their review presets
- Review process is more structured and easier to navigate

### Interface Contract

**Enhanced Preset Format**:
```yaml
# .ace/review/presets/pr.yml
description: "Pull request review - comprehensive code changes review"

# Section-based configuration
sections:
  focus:
    title: "Files Under Review"
    content_type: "diffs"
    priority: 1
    ranges:
      - "origin/main...HEAD"
    paths:
      - "src/**/*.js"
      - "tests/**/*.test.js"

  style:
    title: "Style Guidelines"
    content_type: "files"
    priority: 2
    files:
      - ".eslintrc.js"
      - "docs/CODING_STANDARDS.md"
      - "style-guide.md"

  diff:
    title: "Recent Changes"
    content_type: "diffs"
    priority: 3
    ranges:
      - "origin/main...HEAD"

  context:
    title: "Project Context"
    content_type: "commands"
    priority: 4
    commands:
      - "git log --oneline origin/main..HEAD"
      - "npm test"
      - "git status"

# Legacy support (auto-migrated)
context: "project"
subject:
  diff:
    ranges:
      - "origin/main...HEAD"

# Prompt composition (unchanged)
prompt_composition:
  base: "prompt://base/system"
  format: "prompt://format/standard"
  guidelines:
    - "prompt://guidelines/tone"
    - "prompt://guidelines/icons"
```

**Expected system.context.md Output**:
```markdown
---
context:
  sections:
    focus:
      title: "Files Under Review"
      content_type: "diffs"
      priority: 1
      ranges:
        - "origin/main...HEAD"
      paths:
        - "src/**/*.js"
        - "tests/**/*.test.js"
    style:
      title: "Style Guidelines"
      content_type: "files"
      priority: 2
      files:
        - ".eslintrc.js"
        - "docs/CODING_STANDARDS.md"
        - "style-guide.md"
    diff:
      title: "Recent Changes"
      content_type: "diffs"
      priority: 3
      ranges:
        - "origin/main...HEAD"
    context:
      title: "Project Context"
      content_type: "commands"
      priority: 4
      commands:
        - "git log --oneline origin/main..HEAD"
        - "npm test"
        - "git status"
  embed_document_source: true
---

[Base system prompt content from prompt://base/system]
```

**Expected system.prompt.md After ace-context Processing**:
```markdown
## Files Under Review
<focus>
  <file path="src/main.js" language="javascript">
    // Changed code content
  </file>
  <file path="tests/main.test.js" language="javascript">
    // Test changes
  </file>
</focus>

## Style Guidelines
<style>
  <file path=".eslintrc.js">
    // ESLint configuration
  </file>
  <file path="docs/CODING_STANDARDS.md">
    # Coding Standards
    <!-- Style guidelines content -->
  </file>
</style>

## Recent Changes
<diff>
  <output command="git diff origin/main...HEAD">
    // Git diff output
  </output>
</diff>

## Project Context
<context>
  <output command="git log --oneline origin/main..HEAD">
    // Recent commits
  </output>
  <output command="npm test">
    // Test results
  </output>
</context>
```

### Success Criteria

- [ ] ReviewManager updated to support section-based preset configuration
- [ ] All existing ace-review presets migrated to use sections where appropriate
- [ ] PresetManager enhanced to handle both legacy and section-based configurations
- [ ] Backward compatibility maintained for all existing user presets
- [ ] Standard section templates created for common review types (PR, code, security, docs)
- [ ] Comprehensive test coverage for section-based review functionality
- [ ] Documentation updated with section-based usage examples

### Validation Questions

- Does the section-based approach improve review organization and clarity?
- Are the standard section templates appropriate for common review scenarios?
- Is the migration path for existing presets smooth and automatic?
- Do users have sufficient flexibility to define custom sections?

## Planning Steps

1. **Dependency Analysis**
   - [ ] Analyze ace-context section implementation (task.099)
   - [ ] Review existing ace-review preset structure
   - [ ] Plan migration strategy for existing presets
   - [ ] Design section templates for common review types

2. **Integration Architecture**
   - [ ] Review ReviewManager integration points
   - [ ] Plan PresetManager enhancements
   - [ ] Design backward compatibility strategy
   - [ ] Plan testing approach

3. **Preset Design**
   - [ ] Design standard section templates
   - [ ] Plan custom section definition approach
   - [ ] Review and enhance existing presets
   - [ ] Document section best practices

## Execution Steps

### Phase 1: Core Integration
- [ ] Update ReviewManager to support section-based context configuration
- [ ] Enhance PresetManager to handle sections in preset files
- [ ] Update preset resolution to support both legacy and section formats
- [ ] Implement auto-migration for existing presets

### Phase 2: Preset Enhancement
- [ ] Update all built-in ace-review presets to use sections
- [ ] Create standard section templates for common review types
- [ ] Add custom section definition support
- [ ] Update preset documentation and examples

### Phase 3: Testing and Validation
- [ ] Test with all existing ace-review presets
- [ ] Validate backward compatibility with user custom presets
- [ ] Test section-based review generation
- [ ] Performance testing with large review sets

### Phase 4: Documentation and Polish
- [ ] Update ace-review documentation with section examples
- [ ] Create migration guide for existing users
- [ ] Add section best practices guide
- [ ] Final testing and validation