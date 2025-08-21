# v.0.5.0+task.029 - Implement composable prompt system for code review

## Behavioral Specification

### User Experience:
- **Input**: Users configure review prompts via YAML with composable modules (base prompt, report format, focus areas, guidelines)
- **Process**: System assembles complete prompts by combining selected modules, applying context tool for composition
- **Output**: Unified, context-aware prompt sent to LLM for code review

### Expected Behavior:
Users can compose custom review prompts by selecting and combining modular components:
- Select a base prompt template that defines the core review structure
- Choose report format (standard, detailed, compact)
- Add multiple focus modules (architecture patterns, languages, frameworks, quality aspects)
- Include guideline modules (tone, formatting, icons)
- System automatically assembles these into a coherent prompt
- Support both preset-based and ad-hoc composition

### Interface Contract:
```bash
# Use composed preset
code-review --preset ruby-atom-full

# Custom composition via config
code-review --preset custom-composition

# Override composition on the fly
code-review \
  --prompt-base review-base/system.prompt.md \
  --prompt-focus "architecture/atom.md,languages/ruby.md" \
  --prompt-report detailed

# Add focus to existing preset
code-review --preset pr --add-focus "quality/security.md"
```

### Success Criteria:
- Users can compose prompts from modular components via configuration
- System correctly assembles prompts from multiple sources
- Backwards compatibility maintained with existing system_prompt approach
- All 19 existing prompts can be expressed as compositions
- Reduced duplication across prompt files

## Technical Requirements

### Core Components:
1. **Prompt Module System**
   - Base prompt templates (system.prompt.md)
   - Focus area modules (architecture/, languages/, quality/)
   - Report format modules (detailed, standard, compact)
   - Guideline modules (tone, formatting, icons)

2. **Composition Engine**
   - YAML configuration parser
   - Module resolver and loader
   - Prompt assembly logic
   - Context tool integration

3. **Preset Management**
   - Predefined compositions for common use cases
   - Override mechanisms for customization
   - Migration path from existing system_prompt files

### Implementation Areas:
- Extend existing code-review command with composition options
- Create modular prompt file structure
- Implement composition logic in prompt loading
- Add preset configuration system
- Update existing prompts to use modular approach

## Dependencies
- [v.0.5.0+task.028] - code-review command foundations

## Metadata
- **Priority**: high
- **Status**: draft
- **Estimate**: 3-4 days
- **Created**: 2025-08-21
- **Release**: v.0.5.0-insights

# IMPLEMENTATION PLAN

## Analysis Summary

After analyzing the codebase, I found significant duplication across 19+ prompt files:

### Current Duplication Patterns:
1. **Format Structure**: Identical section lists and output formatting across ruby.atom vs vue.firebase prompts
2. **Focus Instructions**: Repetitive "code tests", "code docs", "code tests docs" blocks
3. **Review Guidelines**: Common tone, icon usage, and approval checkbox patterns
4. **Architecture Context**: Similar project standards and review depth guidelines

### Key Files Analysis:
- **Base System**: PromptEnhancer.rb has basic enhancement capability but no module composition
- **Configuration**: ReviewPresetManager.rb supports system_prompt but lacks composition features
- **CLI Interface**: Review.rb has preset support but no composable options
- **Templates**: 19+ .prompt.md files with 60-80% identical content

## Implementation Strategy

### Phase 1: Module Architecture (Day 1)

Create modular prompt directory structure:

```
dev-handbook/templates/review-modules/
├── base/
│   ├── system.md                    # Core review instruction
│   └── sections.md                  # Standard section structure
├── format/
│   ├── standard.md                  # Basic formatting rules
│   ├── detailed.md                  # Extended formatting with icons
│   └── compact.md                   # Minimal formatting
├── focus/
│   ├── architecture/
│   │   ├── atom.md                  # ATOM pattern specifics
│   │   └── component.md             # Component architecture
│   ├── languages/
│   │   ├── ruby.md                  # Ruby-specific guidelines
│   │   ├── vue.md                   # Vue.js specifics
│   │   └── typescript.md            # TypeScript patterns
│   ├── quality/
│   │   ├── security.md              # Security assessment focus
│   │   ├── performance.md           # Performance considerations
│   │   └── testing.md               # Test quality focus
│   └── scope/
│       ├── code.md                  # Code-only reviews
│       ├── docs.md                  # Documentation reviews
│       └── tests.md                 # Test-specific reviews
└── guidelines/
    ├── tone.md                      # Professional tone guidelines
    ├── icons.md                     # Icon usage patterns
    └── approval.md                  # Approval recommendation format
```

**Deliverables:**
- Create directory structure
- Extract common modules from existing prompts
- Define module composition format
- Create base system prompt template

### Phase 2: Composition Engine (Day 2)

Enhance PromptEnhancer with module assembly:

```ruby
class PromptEnhancer
  # New method for composable prompt assembly
  def compose_prompt(composition_config)
    # Load base prompt
    base = load_module(composition_config[:base])
    
    # Append format modules
    format_parts = load_modules(composition_config[:format])
    
    # Append focus modules
    focus_parts = load_modules(composition_config[:focus])
    
    # Append guideline modules
    guideline_parts = load_modules(composition_config[:guidelines])
    
    # Assemble with proper spacing and structure
    assemble_prompt(base, format_parts, focus_parts, guideline_parts)
  end
  
  private
  
  def load_module(module_path)
    # Load individual module from templates/review-modules/
  end
  
  def load_modules(module_list)
    # Load multiple modules and merge
  end
  
  def assemble_prompt(*parts)
    # Intelligent assembly with proper markdown structure
  end
end
```

**Deliverables:**
- Module loading infrastructure
- Prompt assembly logic
- Error handling for missing modules
- Unit tests for composition engine

### Phase 3: Configuration Integration (Day 2-3)

Extend ReviewPresetManager to support prompt composition:

```ruby
class ReviewPresetManager
  def resolve_preset(preset_name, overrides = {})
    preset = load_preset(preset_name)
    return nil unless preset

    resolved = {
      description: preset["description"],
      # NEW: Support both legacy and composition
      system_prompt: resolve_system_prompt(preset["system_prompt"], overrides[:system_prompt]),
      prompt_composition: resolve_composition(preset["prompt_composition"], overrides),
      context: resolve_context_config(preset["context"], overrides[:context]),
      subject: resolve_subject_config(preset["subject"], overrides[:subject]),
      model: overrides[:model] || preset["model"] || default_model,
      output_format: overrides[:output_format] || preset["output_format"] || default_output_format
    }

    resolved
  end
  
  private
  
  def resolve_composition(preset_composition, overrides)
    # Handle composition configuration with overrides
    # Support both preset-defined and CLI-override composition
  end
end
```

**Configuration Format:**

```yaml
presets:
  ruby-atom-full:
    description: "Full Ruby ATOM architecture review"
    prompt_composition:
      base: "base/system.md"
      format: ["format/detailed.md"]
      focus: 
        - "architecture/atom.md"
        - "languages/ruby.md"
        - "quality/security.md"
      guidelines: ["guidelines/tone.md", "guidelines/icons.md", "guidelines/approval.md"]
    context: "project"
    subject:
      commands:
        - git diff origin/main...HEAD
        
  vue-firebase-basic:
    description: "Vue.js Firebase component review"
    prompt_composition:
      base: "base/system.md"
      format: ["format/standard.md"]
      focus: 
        - "architecture/component.md"
        - "languages/vue.md"
      guidelines: ["guidelines/tone.md", "guidelines/approval.md"]
```

**Deliverables:**
- Composition configuration parser
- Preset configuration examples
- Backwards compatibility with system_prompt
- Integration tests

### Phase 4: CLI Enhancement (Day 3)

Add composition options to review command:

```ruby
class Review < Dry::CLI::Command
  # NEW OPTIONS
  option :prompt_base, type: :string,
    desc: "Base prompt module (e.g., base/system.md)"
  
  option :prompt_format, type: :string,
    desc: "Format modules (comma-separated)"
  
  option :prompt_focus, type: :string,
    desc: "Focus modules (comma-separated)"
  
  option :prompt_guidelines, type: :string,
    desc: "Guideline modules (comma-separated)"
  
  option :add_focus, type: :string,
    desc: "Add focus modules to existing preset"

  private
  
  def resolve_prompt_configuration(config, options)
    # Handle both legacy system_prompt and new composition
    if has_composition_options?(options) || config[:prompt_composition]
      build_composition_config(config, options)
    else
      # Fall back to legacy system_prompt approach
      config[:system_prompt]
    end
  end
  
  def build_composition_config(config, options)
    {
      base: options[:prompt_base] || config.dig(:prompt_composition, :base),
      format: parse_module_list(options[:prompt_format]) || config.dig(:prompt_composition, :format),
      focus: merge_focus_modules(config, options),
      guidelines: parse_module_list(options[:prompt_guidelines]) || config.dig(:prompt_composition, :guidelines)
    }
  end
  
  def merge_focus_modules(config, options)
    # Merge preset focus with CLI additions
    preset_focus = config.dig(:prompt_composition, :focus) || []
    cli_focus = parse_module_list(options[:prompt_focus]) || []
    add_focus = parse_module_list(options[:add_focus]) || []
    
    (preset_focus + cli_focus + add_focus).uniq
  end
end
```

**CLI Examples:**
```bash
# Use composed preset
code-review --preset ruby-atom-full

# Custom composition
code-review \
  --prompt-base base/system.md \
  --prompt-focus "architecture/atom.md,languages/ruby.md" \
  --prompt-format detailed.md

# Add focus to existing preset
code-review --preset pr --add-focus "quality/security.md"
```

**Deliverables:**
- CLI option parsing
- Composition configuration building
- Command examples and help text
- CLI integration tests

### Phase 5: Migration & Testing (Day 4)

**Migration Process:**
1. Transform existing 19 prompts into module compositions
2. Create equivalent preset configurations
3. Test backwards compatibility
4. Update documentation

**Migration Script Example:**
```ruby
# Extract modules from existing prompts
existing_prompts = [
  "system.ruby.atom.prompt.md",
  "system.vue.firebase.prompt.md",
  # ... all 19 prompts
]

existing_prompts.each do |prompt_file|
  content = File.read(prompt_file)
  
  # Extract common sections
  base_section = extract_base_instructions(content)
  format_section = extract_format_rules(content)
  focus_sections = extract_focus_areas(content)
  guideline_sections = extract_guidelines(content)
  
  # Generate module files
  save_modules(base_section, format_section, focus_sections, guideline_sections)
  
  # Generate equivalent composition config
  composition = generate_composition_config(prompt_file, focus_sections)
  save_composition_preset(composition)
end
```

**Test Strategy:**
```ruby
RSpec.describe "Composable Prompt System" do
  describe "Module Loading" do
    it "loads base modules correctly"
    it "handles missing modules gracefully"
    it "validates module format"
  end
  
  describe "Prompt Assembly" do
    it "assembles modules in correct order"
    it "handles spacing and formatting"
    it "merges overlapping sections"
  end
  
  describe "Configuration" do
    it "parses composition YAML correctly"
    it "resolves module paths"
    it "handles CLI overrides"
  end
  
  describe "Backwards Compatibility" do
    it "still supports system_prompt approach"
    it "migrates existing presets correctly"
    it "produces equivalent outputs"
  end
  
  describe "CLI Integration" do
    it "parses composition options"
    it "builds composition configs from CLI"
    it "merges preset and CLI options"
  end
end
```

**Deliverables:**
- Migration utility for existing prompts
- Comprehensive test suite
- Backwards compatibility verification
- Performance benchmarks

## Risk Assessment

### High Risk (🔴)
1. **Breaking Changes**: Existing users rely on system_prompt approach
   - *Mitigation*: Maintain full backwards compatibility, gradual migration
   
2. **Module Resolution Complexity**: Path resolution across different environments
   - *Mitigation*: Robust path resolution with fallbacks, clear error messages

### Medium Risk (🟡)
3. **Performance Impact**: Loading multiple module files per request
   - *Mitigation*: Module caching, benchmark against current system
   
4. **Configuration Complexity**: Users might find composition config complex
   - *Mitigation*: Provide rich examples, migration tools, preset library

### Low Risk (🟢)
5. **Module Conflicts**: Overlapping content between modules
   - *Mitigation*: Clear module boundaries, composition order rules
   
6. **Testing Complexity**: Multiple composition combinations to test
   - *Mitigation*: Automated test generation, property-based testing

## Success Metrics

### Functional Requirements
- [ ] All 19 existing prompts can be expressed as compositions
- [ ] System maintains backwards compatibility with system_prompt
- [ ] CLI supports composition options as specified
- [ ] Module loading works across all deployment environments

### Quality Requirements
- [ ] 90%+ test coverage for new composition system
- [ ] Performance within 10% of current system
- [ ] Zero breaking changes for existing users
- [ ] Clear error messages for configuration issues

### User Experience
- [ ] Composition reduces duplication by 60%+
- [ ] Preset creation time reduced by 50%
- [ ] CLI examples work as documented
- [ ] Migration path is seamless

## Next Steps

To proceed with implementation:

1. **Validate Plan**: Review this implementation plan with stakeholders
2. **Set Up Environment**: Ensure dev environment has all required dependencies
3. **Start Phase 1**: Begin with module architecture creation
4. **Iterate**: Complete each phase with testing before moving to next
5. **Document**: Maintain documentation throughout implementation

The implementation follows incremental development with each phase building on the previous one, ensuring we can validate functionality at each step and maintain backwards compatibility throughout.