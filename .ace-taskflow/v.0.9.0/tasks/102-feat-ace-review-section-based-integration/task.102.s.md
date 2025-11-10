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

# Section-based instructions using ace-context
instructions:
  base: "prompt://base/system"
  context:
    sections:
      review_focus:
        title: "Files Under Review"
        description: "Code changes and files being reviewed"
        files:
          - "prompt://focus/languages/ruby"
          - "prompt://focus/architecture/atom"
          - "prompt://focus/scope/tests"
          - "prompt://focus/scope/docs"

      format_guidelines:
        title: "Format Guidelines"
        description: "Output formatting and structure guidelines"
        files:
          - "prompt://format/detailed"

      review_guidelines:
        title: "Review Guidelines"
        description: "Communication style and visual indicators"
        files:
          - "prompt://guidelines/tone"
          - "prompt://guidelines/icons"

      project_context:
        title: "Project Context"
        description: "Project information and background"
        presets:
          - "project"

# Legacy support (unchanged)
context: "project"

# Subject configuration (unchanged)
subject:
  diff:
    ranges:
      - "origin/main...HEAD"

  # Alternative: Use commands for custom git operations
  # commands:
  #   - "git diff origin/main...HEAD"
  #   - "git log origin/main..HEAD --oneline"

model: gpro
```

**Expected system.context.md Output**:
```markdown
---
context:
  embed_document_source: true
  sections:
    review_focus:
      title: "Files Under Review"
      description: "Code changes and files being reviewed"
      files:
        - "prompt://focus/languages/ruby"
        - "prompt://focus/architecture/atom"
        - "prompt://focus/scope/tests"
        - "prompt://focus/scope/docs"

    format_guidelines:
      title: "Format Guidelines"
      description: "Output formatting and structure guidelines"
      files:
        - "prompt://format/detailed"

    review_guidelines:
      title: "Review Guidelines"
      description: "Communication style and visual indicators"
      files:
        - "prompt://guidelines/tone"
        - "prompt://guidelines/icons"

    project_context:
      title: "Project Context"
      description: "Project information and background"
      presets:
        - "project"
---

[Base system prompt content from prompt://base/system]
```

**Expected system.prompt.md After ace-context Processing**:
```markdown
## Files Under Review

<review_focus>
<!-- Content from prompt://focus/languages/ruby -->
<!-- Content from prompt://focus/architecture/atom -->
<!-- Content from prompt://focus/scope/tests -->
<!-- Content from prompt://focus/scope/docs -->
</review_focus>

## Format Guidelines

<format_guidelines>
<!-- Content from prompt://format/detailed -->
</format_guidelines>

## Review Guidelines

<review_guidelines>
<!-- Content from prompt://guidelines/tone -->
<!-- Content from prompt://guidelines/icons -->
</review_guidelines>

## Project Context

<project_context>
<!-- Project context content from "project" preset -->
</project_context>
```

**User Prompt Generation**:
The user prompt will be generated separately from the subject configuration, containing the actual code diffs and context for review, following the existing ace-context patterns.

### Success Criteria

- [ ] ReviewManager updated to support `instructions.context.sections` configuration
- [ ] All existing ace-review presets updated to use `instructions` format with sections
- [ ] PresetManager enhanced to handle both legacy `system_prompt` and new `instructions` formats
- [ ] Backward compatibility maintained for all existing user presets
- [ ] Standard section patterns created for common review types (PR, code, security, docs)
- [ ] Comprehensive test coverage for instructions-based review functionality
- [ ] Documentation updated with instructions-based usage examples

### Validation Questions

- Does the `instructions.context.sections` approach improve review organization and clarity?
- Are the standard section patterns appropriate for common review scenarios?
- Is the migration path from `system_prompt` to `instructions` format smooth and automatic?
- Do users have sufficient flexibility to define custom sections through the instructions format?

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