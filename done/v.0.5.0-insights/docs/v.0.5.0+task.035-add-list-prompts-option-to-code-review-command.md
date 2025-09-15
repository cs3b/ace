# Task: Add --list-prompts option to code-review command

## Overview

Implement a `--list-prompts` option for the code-review command that displays all available prompt modules from the filesystem, similar to the existing `--list-presets` functionality.

## Context

The code-review command currently has a `--list-presets` option that lists available review presets from `.coding-agent/code-review.yml`. We need to add a similar `--list-prompts` option that lists all available prompt modules from the filesystem.

### Current Implementation
- The `--list-presets` option is implemented in `.ace/tools/lib/coding_agent_tools/cli/commands/code/review.rb` (lines 57, 92, 192-209)
- Prompt modules are stored in `.ace/handbook/templates/review-modules/` directory
- The PromptEnhancer class (`.ace/tools/lib/coding_agent_tools/molecules/code/prompt_enhancer.rb`) handles loading these modules

### Module Structure Found
```
.ace/handbook/templates/review-modules/
├── base/
│   ├── system.md
│   └── sections.md
├── format/
│   ├── standard.md
│   ├── detailed.md
│   └── compact.md
├── focus/
│   ├── architecture/
│   │   └── atom.md
│   ├── frameworks/
│   │   ├── rails.md
│   │   └── vue-firebase.md
│   ├── languages/
│   │   └── ruby.md
│   ├── quality/
│   │   ├── performance.md
│   │   └── security.md
│   └── scope/
│       ├── docs.md
│       └── tests.md
└── guidelines/
    ├── icons.md
    └── tone.md
```

## Requirements

### 1. Add CLI Option
Add a new option `--list-prompts` to the code-review command (similar to `--list-presets` on line 57-58)

### 2. Implement list_prompts Method
Create a `list_prompts` method that:
- Discovers all available prompt modules from `.ace/handbook/templates/review-modules/`
- Groups modules by category (base, format, focus, guidelines)
- For focus modules, shows subcategories (architecture, frameworks, languages, quality, scope)
- Displays each module with its usage path

### 3. Expected Output Format
```
Available prompt modules:

Base modules:
  system        - Base system prompt
  sections      - Standard review sections

Format modules:
  standard      - Standard format
  detailed      - Detailed format
  compact       - Compact format

Focus modules:
  architecture/atom       - ATOM architecture patterns
  frameworks/rails        - Ruby on Rails framework
  frameworks/vue-firebase - Vue.js with Firebase
  languages/ruby          - Ruby language specifics
  quality/performance     - Performance considerations
  quality/security        - Security review focus
  scope/docs             - Documentation focus
  scope/tests            - Test coverage focus

Guideline modules:
  tone          - Professional tone guidelines
  icons         - Review icons and markers
```

## Implementation Notes

- Follow the pattern used by `list_presets` method (lines 192-209)
- Use the existing `find_modules_directory` method from PromptEnhancer (line 149-155)
- Handle the case when modules directory doesn't exist
- The option should be checked early in the `call` method, similar to line 92

## Testing Requirements

- Test that `--list-prompts` displays all available modules
- Test that it handles missing modules directory gracefully
- Verify the output format is clear and organized

## Files to Modify

1. **Primary**: `.ace/tools/lib/coding_agent_tools/cli/commands/code/review.rb`
   - Add `--list-prompts` option
   - Implement `list_prompts` method

2. **Possibly**: Add a PromptModuleLister molecule if the logic becomes complex

## Acceptance Criteria

- [ ] `--list-prompts` option is added to code-review command
- [ ] All available prompt modules are discovered and listed
- [ ] Output is grouped by category with clear formatting
- [ ] Focus modules show nested subcategories properly
- [ ] Handles missing modules directory gracefully
- [ ] Follows existing code patterns and style
- [ ] Tests are added for the new functionality

## Priority

Medium - This is a developer experience improvement that makes the code-review tool more discoverable and user-friendly.

## Status

Pending - Ready for implementation

## Dependencies

None - this is an isolated feature addition that leverages existing prompt module infrastructure.