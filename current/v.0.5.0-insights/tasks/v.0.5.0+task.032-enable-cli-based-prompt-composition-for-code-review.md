---
id: v.0.5.0+task.032
status: draft
priority: high
estimate: 4h
dependencies: []
---

# Enable CLI-based prompt composition for code-review

## Behavioral Specification

### User Experience
- **Input**: User provides `--prompt-base`, `--prompt-format`, `--prompt-focus`, and/or `--prompt-guidelines` CLI options
- **Process**: System composes a custom prompt from the specified modular components
- **Output**: Code review uses the composed prompt built from CLI-specified modules

### Expected Behavior
When users specify prompt composition options via CLI flags, the system should build a custom prompt by loading and combining the specified modules. This allows users to customize their review focus without creating presets, providing flexibility for one-off reviews with specific requirements. CLI options should override any preset prompt_composition settings.

### Interface Contract
```bash
# CLI Interface
code-review \
  --prompt-base system \
  --prompt-format detailed \
  --prompt-focus "languages/ruby,architecture/atom" \
  --prompt-guidelines "tone,icons" \
  --auto-execute
# Expected: Prompt composed from system base, detailed format, ruby+atom focus, tone+icons guidelines

code-review \
  --preset pr \
  --prompt-focus "quality/security" \
  --auto-execute  
# Expected: Uses PR preset but overrides/adds security focus module

# Verify composition in dry-run
code-review \
  --prompt-base system \
  --prompt-format compact \
  --dry-run
# Expected output: Shows "System prompt: (composed from modules)" not "(default review prompt)"
```

**Error Handling:**
- Module not found: Clear error message listing available modules
- Invalid path: Show valid module paths and structure
- Conflicting options: CLI options take precedence over preset

**Edge Cases:**
- Partial composition: Some CLI options provided, some from preset
- Empty modules: Handle missing module files gracefully
- Multiple focus/guidelines: Parse comma-separated lists correctly

### Success Criteria
- [ ] **Module Loading**: Specified modules are loaded and combined into prompt
- [ ] **CLI Override**: CLI options override preset prompt_composition settings
- [ ] **Visible Composition**: Dry-run shows prompt is composed, not default
- [ ] **Module Combination**: Multiple focus/guideline modules combine correctly

### Validation Questions
- [ ] **Precedence Rules**: Confirm CLI always overrides preset settings?
- [ ] **Partial Override**: If only some CLI options provided, merge with preset?
- [ ] **Module Validation**: Should we validate module paths before execution?
- [ ] **Error Reporting**: How detailed should module loading errors be?

## Objective

Enable flexible, on-demand prompt customization through CLI options, reducing the need for preset proliferation and supporting exploratory review sessions with custom focus areas.

## Scope of Work

- **User Experience Scope**: CLI-driven prompt module composition
- **System Behavior Scope**: Dynamic prompt building from modular components
- **Interface Scope**: Four CLI options for prompt customization

### Deliverables

#### Behavioral Specifications
- CLI option processing for prompt modules
- Module loading and combination logic
- Override precedence rules

#### Validation Artifacts
- Test cases for CLI option parsing
- Module composition verification
- Preset override behavior tests

## Out of Scope

- ❌ **Implementation Details**: Specific code structure for module loading
- ❌ **Technology Decisions**: Parser library or composition framework
- ❌ **Performance Optimization**: Module caching strategies
- ❌ **Future Enhancements**: Additional module types or composition rules

## References

- Testing session: Issue discovered when CLI prompt options were ignored
- Related modules: dev-handbook/templates/review-modules/
- Related task: Task 029 (composable prompt system implementation)