---
id: v.0.9.0+task.145
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Enhance ace-review with Unified Subject Definition and Composable Subject Presets

## Behavioral Specification

### User Experience
- **Input**: Users provide review scope via unified `--subject` flag (e.g., `--subject pr:48`, `--subject files:GLOB`, `--subject diff:REF`) or via reusable `--subject-preset` names
- **Process**: System parses subject definition, resolves it to concrete files/diffs, and combines with review style presets to execute comprehensive code review
- **Output**: Code review results scoped to the specified subject, with clear indication of what was reviewed

### Expected Behavior

Users should be able to define review scope using a unified, composable approach that separates "what to review" (subject) from "how to review" (review style). This enables:

1. **Unified Subject Definition**: All subject types use consistent `type:value` format
   - Pull requests: `--subject pr:48`
   - File patterns: `--subject files:ace-git-worktree/**/*`
   - Git diffs: `--subject diff:origin..HEAD`
   - Task contexts: `--subject task:v.0.9.0+task.123`

2. **Subject Presets**: Reusable scope definitions stored as configuration
   - Users can define common review scopes as presets
   - Presets support complex patterns and exclusions
   - Presets follow configuration cascade (global, user, project)

3. **Composable Reviews**: Mix and match review style with subject scope
   - `ace-review --preset code-quality --subject-preset feature-branch`
   - `ace-review --preset security --subject pr:48`
   - Clear separation of concerns improves determinism

### Interface Contract

```bash
# Unified subject definition (existing --subject flag enhanced)
ace-review --subject pr:48
ace-review --subject files:ace-review/**/*.rb
ace-review --subject diff:origin/main..HEAD
ace-review --subject task:v.0.9.0+task.145

# Subject presets (new capability)
ace-review --subject-preset my-feature-scope
ace-review --subject-preset current-branch

# Composing subject with review style presets
ace-review --preset code-quality --subject-preset feature-files
ace-review --preset security --subject pr:48

# Subject preset configuration location
# .ace/review/subject-presets/my-scope.yml
type: files
pattern: "src/**/*.rb"
exclude:
  - "**/*_test.rb"
  - "**/spec/**"
```

**Error Handling:**
- Invalid subject format: "Error: Subject must be in format 'type:value' (e.g., pr:48, files:GLOB)"
- Unknown subject preset: "Error: Subject preset 'my-scope' not found. Available: [list]"
- Malformed preset file: "Error: Subject preset 'my-scope' has invalid configuration: [details]"
- Empty scope resolution: "Warning: Subject resolved to 0 files. Nothing to review."

**Edge Cases:**
- Subject preset conflicts with --subject flag: --subject-preset takes precedence, warn user
- Multiple presets specified: Use last one specified, warn about others
- Subject resolves to non-existent files: Warn and skip missing files
- Subject type not supported yet: Clear error message with supported types

### Success Criteria

- [ ] **Unified Subject Parsing**: All subject types (pr, files, diff, task) parse through single `--subject` interface with consistent `type:value` format
- [ ] **Subject Preset Loading**: Subject presets load from configuration cascade (.ace/review/subject-presets/) and resolve to concrete file lists
- [ ] **Composable Reviews**: Users can combine `--preset` (review style) with `--subject-preset` (scope) in single command
- [ ] **Backward Compatibility**: Existing `--subject` usage continues to work without changes
- [ ] **Clear Error Messages**: Invalid subjects and missing presets produce helpful, actionable error messages
- [ ] **Documentation**: Usage documentation includes subject preset examples and composition patterns

### Validation Questions

- [ ] **Subject Type Coverage**: Should we support additional subject types beyond pr, files, diff, task? (e.g., commit ranges, directory paths)
- [ ] **Preset Naming**: Is "subject-preset" the best term, or should we use "scope-preset" or "target-preset"?
- [ ] **Precedence Rules**: When both --subject and --subject-preset are provided, which takes precedence?
- [ ] **Preset Composition**: Should subject presets support extending/composing other subject presets?
- [ ] **Integration Points**: How should subject resolution integrate with ace-search for pattern matching and ace-git-commit for context?

## Objective

Enable deterministic, composable code reviews by clearly separating review scope (what to review) from review style (how to review). This improves both human developer workflows and AI agent execution by providing reusable, well-defined review scopes that can be combined with review style presets.

## Scope of Work

- **User Experience Scope**:
  - CLI interface for unified subject definition
  - Subject preset creation and usage workflow
  - Composing subject presets with review style presets
  - Configuration cascade integration

- **System Behavior Scope**:
  - Parsing `type:value` subject definitions
  - Resolving subjects to concrete files/diffs
  - Loading and applying subject presets
  - Merging subject and review style configurations

- **Interface Scope**:
  - `--subject <type:value>` flag enhancement
  - `--subject-preset <name>` flag addition
  - Subject preset configuration format
  - Error messages and validation

### Deliverables

#### Behavioral Specifications
- Unified subject definition format specification
- Subject preset configuration schema
- Composition rules for mixing presets
- Interface contract for CLI flags

#### Validation Artifacts
- Success criteria validation methods
- User acceptance criteria for subject resolution
- Behavioral test scenarios for all subject types

## Out of Scope

- ❌ **Implementation Details**: Specific parser implementation, file structure organization, class hierarchy
- ❌ **Technology Decisions**: Choice of YAML vs JSON for presets, specific gems to use
- ❌ **Performance Optimization**: Caching strategies, parallel file resolution
- ❌ **Future Enhancements**: AI-suggested presets, preset templates, preset sharing

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/done/20251128-124510-review-enhance/add-unified-subject-definition-and-composable-presets.s.md`
- Related: ace-review current subject handling
- Related: ace-support-core configuration cascade
- Related: ace-search file pattern matching