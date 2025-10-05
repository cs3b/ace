---
id: v.0.9.0+task.051
status: draft
priority: high
estimate: 6-8h
dependencies: []
review_completed: 2025-10-03
reviewed_by: User
---

# Create ace-review package

## Review Questions (Resolved)

### ✅ [RESOLVED] Package Structure & Integration Strategy

**Original Priority**: HIGH

#### Should ace-taskflow-review be a separate gem or integrated into ace-taskflow core?

- **Decision**: Separate gem named `ace-review` with `ace-review code` command
- **Rationale**:
  - Reviews are a distinct concern from task management
  - Separate gem allows independent versioning and installation
  - Follows pattern of other standalone ace-* tools
  - Cleaner separation of concerns
  - Synthesis handled via workflow instructions (no CLI needed)
- **Implementation Notes**:
  - Create new gem: `ace-review`
  - CLI command: `ace-review code` only
  - Synthesis via workflow instructions (wfi://synthesize-reviews)
  - Follow ace-gems.g.md best practices
  - Leverage ace-core for configuration and utilities
  - **Prompt System**:
    - Directory structure: `.ace/review/prompts/` (base/, format/, focus/, guidelines/)
    - Prompt cascade: project → user → gem (built-in)
    - Migrate from `dev-handbook/templates/review-modules/`
  - **prompt:// Protocol**:
    - URI format for prompt references: `prompt://category/path`
    - File references: `./file.md` (relative to config) or `file.md` (from project root)
    - Resolution cascade for flexibility
  - **Focus Module System**:
    - Additive composition: Base + Format + Focus(1..n) + Guidelines
    - Built-in modules: architecture/atom, languages/ruby, quality/security, etc.
    - Multiple focus modules can be combined per preset
    - Custom team prompts in `.ace/review/prompts/focus/team/`
  - **Molecules to Implement**:
    - PromptResolver: Resolves prompt:// URIs with cascade lookup
    - PromptComposer: Composes final prompt from modules
- **Resolved by**: User
- **Date**: 2025-10-03

#### Where should code reviews be stored by default?

- **Decision**: `.ace-taskflow/<release>/reviews/` (top-level in release), configurable via config file or CLI argument
- **Rationale**:
  - Top-level in release provides clear visibility
  - Supports both configuration file and runtime override
  - Integrates with existing release structure
- **Implementation Notes**:
  - Default path: `.ace-taskflow/<current-release>/reviews/`
  - Config option in `.ace/review/code.yml`
  - CLI flag: `--output-dir` or similar for override
- **Resolved by**: User
- **Date**: 2025-10-03

### ✅ [RESOLVED] Migration Strategy

**Original Priority**: MEDIUM

#### Should existing dev-tools code-review implementation be migrated or wrapped?

- **Decision**: Full migration - copy and adjust files from dev-tools implementation
- **Rationale**:
  - New architecture leverages ace-core capabilities
  - Clean slate allows following ace-gems.g.md best practices
  - Most files can be copied and adjusted for new structure
  - Provides opportunity to improve implementation
- **Implementation Notes**:
  - Copy implementation from `dev-tools/lib/coding_agent_tools/`
  - Adapt to use ace-core utilities and configuration
  - Follow ATOM architecture pattern (atoms, molecules, organisms, models)
  - Update imports and dependencies to use ace-core
  - Maintain preset system and LLM integration
- **Resolved by**: User
- **Date**: 2025-10-03

#### How should we handle backward compatibility with existing code-review commands?

- **Decision**: No backward compatibility - direct replacement
- **Rationale**:
  - Clean break simplifies codebase
  - Clear migration path for users
  - Avoids maintaining duplicate functionality
- **Implementation Notes**:
  - Replace `code-review` with `ace-review code`
  - Remove `code-review-synthesize` CLI (use wfi://synthesize-reviews instead)
  - Update all workflow files to use new commands
  - Document migration in CHANGELOG and README
- **Resolved by**: User
- **Date**: 2025-10-03

### ✅ [RESOLVED] Feature Scope & Interface

**Original Priority**: MEDIUM

#### Should review commands support task-specific reviews out of the box?

- **Decision**: No - use preset system for flexibility (like current code-review)
- **Rationale**:
  - Preset system already provides flexible configuration
  - Can create presets for different review scenarios
  - Avoids complexity of task file integration
  - Users can customize reviews via presets
- **Implementation Notes**:
  - Maintain robust preset system from current implementation
  - Support preset customization and extension
  - Document how to create custom presets for specific needs
  - Focus on making preset system powerful and flexible
- **Resolved by**: User
- **Date**: 2025-10-03

#### What configuration should be exposed for review storage location?

- **Decision**: Main config at `.ace/review/code.yml` with separate preset files at `.ace/review/presets/preset-name.yml`
- **Rationale**:
  - Follows existing pattern from `.coding-agent/code-review.yml`
  - Separate preset files allow modular configuration
  - Users can add custom presets without modifying main config
  - Supports preset sharing and reuse
- **Implementation Notes**:
  - Main configuration file: `.ace/review/code.yml`
  - Preset directory: `.ace/review/presets/`
  - Individual presets: `.ace/review/presets/{preset-name}.yml`
  - Support same preset structure as current `.coding-agent/code-review.yml`
  - Load presets from both main config and preset directory
  - Preset directory files override main config presets if same name
  - **Example Configuration with Focus Modules**:
    ```yaml
    presets:
      security:
        prompt_composition:
          base: "prompt://base/system"
          format: "prompt://format/detailed"
          focus:
            - "prompt://focus/quality/security"
          guidelines:
            - "prompt://guidelines/tone"
            - "prompt://guidelines/icons"

      ruby-atom:
        prompt_composition:
          base: "prompt://base/system"
          format: "prompt://format/standard"
          focus:
            - "prompt://focus/architecture/atom"
            - "prompt://focus/languages/ruby"
          guidelines:
            - "prompt://guidelines/tone"
    ```
- **Resolved by**: User
- **Date**: 2025-10-03

## Behavioral Specification

### User Experience
- **Input**: User invokes `ace-review code` CLI command with preset configuration
- **Process**: System performs code review analysis using LLM providers
- **Output**: Structured review document with findings and suggestions

### Expected Behavior

Users experience automated code review via the `ace-review` CLI tool:

**Review Code** (`ace-review code`): Analyzes code for quality, patterns, and potential improvements
- Accepts file paths, directories, or commit references via presets
- Performs automated code analysis (structure, patterns, best practices)
- Identifies potential issues, improvements, and learning opportunities
- Generates structured review document with categorized findings
- Links findings to specific code locations
- Stores reviews in `.ace-taskflow/<release>/reviews/`

**Synthesize Reviews** (workflow only): Pattern analysis across multiple reviews
- No CLI command - use `wfi://synthesize-reviews` workflow instead
- Manual process: read 2-4 review files and combine into synthesis
- Identifies recurring patterns and systemic issues
- Handled by workflow instructions, not automated CLI

The tool integrates with .ace-taskflow structure, storing reviews organized by release, making review insights accessible for planning refactoring work and process improvements.

### Interface Contract

```bash
# Review code using presets (replaces code-review)
ace-review code [--preset <preset-name>] [--output-dir <path>]
# Executes: Code review using specified preset configuration
# Default preset: "pr" (pull request review)
# Output: Review document in .ace-taskflow/<release>/reviews/

# Configuration:
# - Main config: .ace/review/code.yml
# - Presets: .ace/review/presets/{preset-name}.yml
# - Default storage: .ace-taskflow/<current-release>/reviews/
# - Override via: --output-dir flag

# Note: Synthesis is done via workflow instructions
# Use: wfi://synthesize-reviews (no CLI command)
```

**Error Handling:**
- Invalid path or commit: Report error with helpful message
- Invalid preset: Report available presets
- Analysis failure: Provide partial results with error context

**Edge Cases:**
- Very large codebase: Provide progress updates, allow interruption
- No issues found: Acknowledge good code quality, suggest deeper analysis
- Conflicting recommendations: Highlight trade-offs, prioritize by impact

### Success Criteria

- [ ] **Automated Analysis**: System identifies common code quality issues and improvement opportunities
- [ ] **Actionable Feedback**: Reviews provide specific, implementable suggestions
- [ ] **Preset Flexibility**: Support for custom presets and configuration
- [ ] **Storage Integration**: Reviews properly stored in `.ace-taskflow/<release>/reviews/`
- [ ] **LLM Provider Support**: Works with multiple LLM providers via ace-llm

### Validation Questions

- [ ] **Review Scope**: What aspects should reviews cover (architecture, style, security, performance)?
- [ ] **Analysis Depth**: How deep should automated analysis go vs. human review guidance?
- [ ] **Storage Organization**: Should reviews be per-release, per-feature, or time-based?
- [ ] **Tool Integration**: Should system integrate with existing linters/analyzers or complement them?
- [ ] **Issue Prioritization**: What criteria determine which findings are most important?

## Objective

Create a dedicated review package (ace-review) that enables automated code review and pattern synthesis, supporting code quality improvement and architectural decision-making across releases.

## Scope of Work

### Package Structure
New package: **ace-review** (Ruby gem)
- Location: `dev-tools/ace-review/`
- CLI command: `ace-review code` only
- Architecture: Follow ATOM pattern (atoms, molecules, organisms, models)
- Configuration: `.ace/review/code.yml` + `.ace/review/presets/*.yml`
- Note: Synthesis handled via workflow instructions (no CLI)

### Implementation Source
1. **Migrate from dev-tools code-review**
   - Source: `dev-tools/lib/coding_agent_tools/code_review/`
   - Executable: `dev-tools/exe/code-review` (copy and adapt)
   - Ignore: `dev-tools/exe/code-review-synthesize` (not needed)
   - Copy and adapt to ace-review structure
   - Use ace-core utilities and configuration

2. **Configuration Migration**
   - Source: `.coding-agent/code-review.yml`
   - Target: `.ace/review/code.yml` (main config)
   - Target: `.ace/review/presets/*.yml` (individual presets)
   - Maintain preset structure and capabilities

### Interface Scope
- CLI command: `ace-review code` only
- Preset-based configuration system
- Code analysis and pattern detection
- Review document generation and management
- Release-based storage integration
- Configurable output locations
- Note: Synthesis done via `wfi://synthesize-reviews` workflow

### Deliverables

#### Gem Package
- `ace-review` gem following ace-gems.g.md best practices
- ATOM architecture (atoms, molecules, organisms, models)
- ace-core integration for configuration and utilities
- Executable: `ace-review` with `code` subcommand only

#### Configuration System
- Main config: `.ace/review/code.yml`
- Preset directory: `.ace/review/presets/`
- Example presets migrated from `.coding-agent/code-review.yml`
- Support for custom user presets

#### Prompt System
- Built-in prompts in gem: `lib/ace/review/prompts/`
  - `base/` - Core system prompts (system.md, sections.md)
  - `format/` - Output styles (standard.md, detailed.md, compact.md)
  - `focus/` - Review focus modules (architecture/atom, languages/ruby, quality/security, etc.)
  - `guidelines/` - Style guidelines (tone.md, icons.md)
- Prompt cascade for overrides: project (`.ace/review/prompts/`) → user (`~/.ace/review/prompts/`) → gem
- Migrate from `dev-handbook/templates/review-modules/`
- PromptResolver molecule: Resolves `prompt://` URIs and direct file paths
- PromptComposer molecule: Composes prompts from modules
- File reference support: `./file.md` (relative to config) or `file.md` (from project root)

#### CLI Interface
- `ace-review code [--preset <name>] [--output-dir <path>]`
- Preset-based review execution
- Configurable output locations
- No synthesize CLI (use workflow instructions instead)

#### Migration
- Update workflow files to use new commands
- Migrate existing presets to new structure
- Update documentation and examples
- CHANGELOG documenting breaking changes

## Out of Scope

- ❌ **Implementation Details**: Ruby class structure, AST parsing, pattern matching algorithms
- ❌ **Deep Static Analysis**: Compiler-level optimizations, complex security vulnerability detection
- ❌ **IDE Integration**: Editor plugins, inline suggestions, real-time feedback
- ❌ **Team Collaboration**: Review assignments, approval workflows, discussion threads

## References

- Source implementation: `dev-tools/lib/coding_agent_tools/code_review/`
- Current executables: `dev-tools/exe/code-review`, `dev-tools/exe/code-review-synthesize`
- Current config: `.coding-agent/code-review.yml`
- Gem development guide: `docs/ace-gems.g.md`
- Architecture guide: `docs/architecture.md`
- ace-core documentation: `dev-tools/ace-core/README.md`

---

## Review Completion Summary

**Date**: 2025-10-03
**Reviewed by**: User
**Questions Resolved**: 6 (2 HIGH, 4 MEDIUM)
**Implementation Readiness**: ✅ Ready for implementation

### Key Decisions Made

1. **Package Architecture**: Separate gem `ace-review` with standalone CLI
2. **Storage Location**: `.ace-taskflow/<release>/reviews/` with config/CLI override support
3. **Migration Strategy**: Full migration from dev-tools, leveraging ace-core
4. **Backward Compatibility**: None - direct command replacement
5. **Feature Scope**: Preset-based system (no task-specific reviews initially)
6. **Configuration**: Main config at `.ace/review/code.yml` + preset directory `.ace/review/presets/`

### Implementation Guidance

- Follow ace-gems.g.md best practices
- Use ATOM architecture pattern
- Leverage ace-core for configuration cascade and utilities
- Copy and adapt existing dev-tools implementation
- Maintain robust preset system for flexibility
- Default storage: `.ace-taskflow/<current-release>/reviews/`
- Support both config file and CLI argument overrides

### Updated Commands

| Old Command | New Command | Notes |
|------------|-------------|-------|
| `code-review` | `ace-review code` | Direct replacement |
| `code-review-synthesize` | `wfi://synthesize-reviews` | Workflow only, no CLI |

### Configuration Structure

```
.ace/
└── review/
    ├── code.yml              # Main configuration
    └── presets/              # Custom preset directory
        ├── pr.yml
        ├── security.yml
        └── custom.yml
```
