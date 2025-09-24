---
id: v.0.5.0+task.032
status: done
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
  - **Research conducted**: ReviewPresetManager.resolve_prompt_composition shows CLI override logic
  - **Implementation**: CLI options override preset values (lines 131-156)
  - **Confirmed**: CLI takes precedence as expected
- [ ] **Partial Override**: If only some CLI options provided, merge with preset?
  - **Research conducted**: Lines 128-159 show merge behavior
  - **Implementation**: Partial overrides work - unspecified options retain preset values
  - **Confirmed**: Merge strategy already implemented correctly
- [ ] **Module Validation**: Should we validate module paths before execution?
  - **Research conducted**: PromptEnhancer.compose_prompt handles missing modules
  - **Suggested default**: Validate during composition, show available modules on error
  - **Implementation**: Enhance error messages in compose_prompt method
- [ ] **Error Reporting**: How detailed should module loading errors be?
  - **Research conducted**: Current implementation returns default prompt on error
  - **Suggested default**: List available modules and show attempted path
  - **Implementation**: Add descriptive error handling in module loading

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

## Implementation Plan

### Root Cause Analysis

The CLI options for prompt composition (`--prompt-base`, `--prompt-format`, `--prompt-focus`, `--prompt-guidelines`) are already defined and parsed (lines 37-49 in review.rb), but they're not being passed through to the configuration. The issue is in the `merge_configurations` method (line 217) which only uses `preset_config[:prompt_composition]` and ignores the CLI options.

### Technical Approach

1. **Fix merge_configurations method**:
   - Pass CLI prompt options to ReviewPresetManager.resolve_prompt_composition
   - Build prompt_composition from CLI options even without preset
   - Ensure CLI options override preset composition settings

2. **Update configuration flow**:
   - In `load_preset_config`, pass prompt options to resolve_preset
   - In `merge_configurations`, handle prompt_composition properly
   - Support building composition without preset

3. **Enhance dry-run output**:
   - Show when prompt is composed from modules
   - Display module paths being used
   - Indicate CLI override when applicable

### Implementation Steps

1. **Update merge_configurations method** (around line 212-221):
   ```ruby
   def merge_configurations(preset_config, options)
     # Build prompt composition from CLI options
     prompt_options = {
       prompt_base: options[:prompt_base],
       prompt_format: options[:prompt_format],
       prompt_focus: options[:prompt_focus],
       add_focus: options[:add_focus],
       prompt_guidelines: options[:prompt_guidelines]
     }.compact
     
     # Use ReviewPresetManager to resolve composition
     manager = CodingAgentTools::Molecules::Code::ReviewPresetManager.new
     prompt_composition = manager.send(:resolve_prompt_composition, 
                                       preset_config[:prompt_composition], 
                                       prompt_options)
     
     {
       context: options[:context] || preset_config[:context],
       subject: options[:subject] || preset_config[:subject],
       system_prompt: options[:system_prompt] || preset_config[:system_prompt],
       prompt_composition: prompt_composition,
       model: options[:model] || preset_config[:model],
       output: options[:output]
     }
   end
   ```

2. **Fix non-preset configuration** (lines 202-209):
   ```ruby
   else
     # Build config from individual options
     prompt_options = {
       prompt_base: options[:prompt_base],
       prompt_format: options[:prompt_format],
       prompt_focus: options[:prompt_focus],
       prompt_guidelines: options[:prompt_guidelines]
     }.compact
     
     prompt_composition = prompt_options.empty? ? nil : 
                         manager.send(:resolve_prompt_composition, nil, prompt_options)
     
     {
       context: options[:context],
       subject: options[:subject],
       system_prompt: options[:system_prompt],
       prompt_composition: prompt_composition,
       model: options[:model] || manager.default_model || "google:gemini-2.0-flash-exp",
       output: options[:output]
     }
   end
   ```

3. **Update dry-run display** (lines 229-230):
   ```ruby
   info_output("\nSystem prompt:")
   if config[:prompt_composition]
     modules = []
     modules << "base: #{config[:prompt_composition]['base']}" if config[:prompt_composition]['base']
     modules << "format: #{config[:prompt_composition]['format']}" if config[:prompt_composition]['format']
     modules << "focus: #{config[:prompt_composition]['focus'].join(', ')}" if config[:prompt_composition]['focus']
     modules << "guidelines: #{config[:prompt_composition]['guidelines'].join(', ')}" if config[:prompt_composition]['guidelines']
     info_output("  (composed from modules: #{modules.join('; ')})")
   else
     info_output("  #{config[:system_prompt] || '(default review prompt)'}")
   end
   ```

### Tool Requirements

- Ruby code editor
- Access to ReviewPresetManager class
- Test environment for CLI validation

### Risk Assessment

- **Low Risk**: Changes are localized to configuration merging
- **Low Risk**: ReviewPresetManager already handles the logic correctly
- **Medium Risk**: Breaking existing preset-based workflows
  - Mitigation: Ensure preset_config is preserved when no CLI options
  - Test both preset and non-preset modes

### Test Case Planning

#### Unit Tests
- CLI options properly passed to configuration
- Prompt composition built from CLI options
- CLI options override preset composition
- Partial CLI options merge with preset

#### Integration Tests
- Full command with prompt composition flags
- Preset with CLI override
- Non-preset with CLI composition
- Dry-run shows composition details

#### Edge Cases
- Empty prompt options (should not create composition)
- Invalid module paths (error handling)
- Conflicting preset and CLI options (CLI wins)
- Add-focus with existing focus list

## References

- Testing session: Issue discovered when CLI prompt options were ignored
- Related modules: .ace/handbook/templates/review-modules/
- Related task: Task 029 (composable prompt system implementation)
- Key files:
  - .ace/tools/lib/coding_agent_tools/cli/commands/code/review.rb:212-221 (merge_configurations)
  - .ace/tools/lib/coding_agent_tools/molecules/code/review_preset_manager.rb:126-160 (resolve_prompt_composition)