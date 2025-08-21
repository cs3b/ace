# Composable Prompt System Guide

## Overview

The composable prompt system eliminates duplication across code review prompts by allowing modular composition of prompt components. This reduces the maintenance burden from 19+ separate prompt files to a set of reusable modules that can be mixed and matched.

## Architecture

### Module Organization

```
dev-handbook/templates/review-modules/
├── base/            # Core review instructions
│   ├── system.md    # Base system prompt
│   └── sections.md  # Standard section structure
├── format/          # Output formatting
│   ├── standard.md  # Standard format with icons
│   ├── detailed.md  # Expanded analysis sections
│   └── compact.md   # Minimal output for quick reviews
├── focus/           # Specific review areas
│   ├── architecture/
│   │   └── atom.md  # ATOM architecture patterns
│   ├── languages/
│   │   └── ruby.md  # Ruby-specific criteria
│   ├── frameworks/
│   │   ├── rails.md         # Rails framework
│   │   └── vue-firebase.md  # Vue.js with Firebase
│   ├── quality/
│   │   ├── security.md      # Security focus
│   │   └── performance.md   # Performance optimization
│   └── scope/
│       ├── tests.md  # Test file review
│       └── docs.md   # Documentation review
└── guidelines/      # Style and tone
    ├── tone.md      # Communication style
    └── icons.md     # Visual indicators

```

## Usage

### CLI Composition

Compose prompts directly from the command line:

```bash
# Basic composition
code-review \
  --prompt-base system \
  --prompt-format standard \
  --prompt-focus "architecture/atom,languages/ruby" \
  --prompt-guidelines "tone,icons"

# Add focus to existing preset
code-review --preset ruby-atom-modular --add-focus "quality/security"

# Custom composition with context
code-review \
  --prompt-base system \
  --prompt-format detailed \
  --prompt-focus "quality/performance" \
  --context project \
  --subject HEAD~1..HEAD
```

### Preset Configuration

Define reusable compositions in `.coding-agent/code-review.yml`:

```yaml
presets:
  ruby-atom-modular:
    description: "Ruby ATOM architecture review"
    prompt_composition:
      base: "system"
      format: "standard"
      focus:
        - "architecture/atom"
        - "languages/ruby"
      guidelines:
        - "tone"
        - "icons"
    context: "project"
    subject:
      commands:
        - git diff HEAD~1..HEAD
```

## Module Types

### Base Modules
- **system.md**: Core review principles and approach
- **sections.md**: Standard section structure for output

### Format Modules
- **standard**: Icons, severity grouping, approval checkboxes
- **detailed**: Deep analysis with metrics and assessments
- **compact**: Minimal output for quick reviews

### Focus Modules
- **Architecture**: ATOM, microservices, component-based
- **Languages**: Ruby, Python, JavaScript, TypeScript
- **Frameworks**: Rails, Vue.js, React, Django
- **Quality**: Security, performance, accessibility
- **Scope**: Tests, documentation, configuration

### Guidelines
- **tone**: Professional, constructive communication
- **icons**: Visual indicators and severity markers

## Migration from Monolithic Prompts

### Mapping Table

| Original Prompt | Composed Equivalent |
|---|---|
| `review-code/system.ruby.atom.prompt.md` | `ruby-atom-modular` preset |
| `review-code/system.vue.firebase.prompt.md` | `vue-firebase-modular` preset |
| `review-test/system.ruby.atom.prompt.md` | `ruby-atom-modular` + `scope/tests` focus |
| `review-docs/system.ruby.atom.prompt.md` | `ruby-atom-modular` + `scope/docs` focus |

### Backwards Compatibility

The system maintains full backwards compatibility:

```bash
# Old approach still works
code-review --system-prompt "dev-handbook/templates/review-code/system.ruby.atom.prompt.md"

# New modular approach
code-review --preset ruby-atom-modular
```

## Performance

- Module loading uses 15-minute cache for repeated reviews
- Assembly time < 100ms (comparable to monolithic loading)
- Reduced disk usage: ~60% less duplication

## Creating New Modules

### Adding a Focus Module

1. Create file in appropriate subdirectory:
   ```bash
   touch dev-handbook/templates/review-modules/focus/languages/python.md
   ```

2. Define focus-specific criteria:
   ```markdown
   # Python Language Focus
   
   ## Python-Specific Review Criteria
   
   ### Code Quality Standards
   - PEP 8 compliance
   - Type hints usage
   - Docstring conventions
   ```

3. Use in composition:
   ```bash
   code-review --prompt-focus "languages/python"
   ```

### Custom Format Module

1. Create format variation:
   ```bash
   touch dev-handbook/templates/review-modules/format/checklist.md
   ```

2. Define output structure:
   ```markdown
   # Checklist Format
   
   Output as actionable checklist:
   - [ ] Issue description with file:line
   - [ ] Next issue...
   ```

## Best Practices

1. **Module Granularity**: Keep modules focused on single concerns
2. **Composition Order**: base → sections → format → focus → guidelines
3. **Preset Naming**: Use descriptive names indicating stack/focus
4. **Documentation**: Document custom modules in this guide
5. **Testing**: Test compositions before adding to presets

## Troubleshooting

### Module Not Found
- Check module path and spelling
- Verify module exists in review-modules directory
- Use relative paths from category directory

### Composition Not Working
- Ensure base module is specified
- Check YAML syntax in preset configuration
- Use --debug flag to see composition details

### Performance Issues
- Module cache clears every 15 minutes
- Large compositions may take longer first time
- Consider using presets for repeated reviews