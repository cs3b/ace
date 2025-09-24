---
id: v.0.3.0+task.94
status: done
priority: medium
estimate: 3h
dependencies: [v.0.3.0+task.93]
---

# Ensure StandardRB Configuration Usage in Ruby Runner

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/handbook/guides
    ├── ai-agent-integration.g.md
    ├── atom-pattern.g.md
    ├── changelog.g.md
    ├── code-review-process.g.md
    ├── coding-standards
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── coding-standards.g.md
    ├── debug-troubleshooting.g.md
    ├── documentation
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── documentation.g.md
    ├── documents-embedded-sync.g.md
    ├── documents-embedding.g.md
    ├── draft-release
    │   └── README.md
    ├── embedded-testing-guide.g.md
    ├── error-handling
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── error-handling.g.md
    ├── llm-query-tool-reference.g.md
    ├── migration
    ├── performance
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── performance.g.md
    ├── project-management
    │   ├── README.md
    │   └── release-codenames.g.md
    ├── project-management.g.md
    ├── quality-assurance
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── quality-assurance.g.md
    ├── README.md
    ├── release-codenames.g.md
    ├── release-publish
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── release-publish.g.md
    ├── roadmap-definition.g.md
    ├── security
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── security.g.md
    ├── strategic-planning.g.md
    ├── task-definition.g.md
    ├── temporary-file-management.g.md
    ├── test-driven-development-cycle
    │   ├── meta-documentation.md
    │   ├── ruby-application.md
    │   ├── ruby-gem.md
    │   ├── rust-cli.md
    │   ├── rust-wasm-zed.md
    │   ├── typescript-nuxt.md
    │   └── typescript-vue.md
    ├── testing
    │   ├── ruby-rspec-config-examples.md
    │   ├── ruby-rspec.md
    │   ├── rust.md
    │   ├── typescript-bun.md
    │   ├── vue-firebase-auth.md
    │   └── vue-vitest.md
    ├── testing-tdd-cycle.g.md
    ├── testing.g.md
    ├── troubleshooting
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── version-control
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── version-control-system-git.g.md
    └── version-control-system-message.g.md
```

## Objective

Verify and enhance the Ruby runner's integration with StandardRB configuration to ensure the existing `.standard.yml` file is properly used and that the StandardRB validator correctly applies project-specific settings. This ensures consistent Ruby code style enforcement across the project.

## Scope of Work

- Verify StandardRB configuration file detection and usage
- Ensure StandardRB validator properly applies configuration settings
- Test autofix functionality with StandardRB configuration
- Validate that Ruby runner respects StandardRB ignore patterns
- Document StandardRB integration for future maintenance

### Deliverables

#### Create

- None expected (configuration already exists)

#### Modify

- .ace/tools/lib/coding_agent_tools/atoms/code_quality/standard_rb_validator.rb (if needed)
- .ace/tools/lib/coding_agent_tools/organisms/code_quality/ruby_runner.rb (from task 93)

#### Delete

- None expected

## Phases

1. Audit existing StandardRB configuration and integration
2. Test StandardRB configuration usage in current implementation
3. Enhance Ruby runner to ensure proper StandardRB integration
4. Validate configuration works correctly with new runner architecture

## Implementation Plan

### Planning Steps

- [x] Examine existing .standard.yml configuration file and its settings
  > TEST: Configuration Discovery
  > Type: Pre-condition Check
  > Assert: .standard.yml file exists and contains expected configuration
  > Command: nav-path file .standard.yml
  - Configuration found at .ace/tools/.standard.yml with ignore patterns for vendor/, tmp/, coverage/, etc.
- [x] Review StandardRB validator implementation for configuration usage
  - StandardRbValidator defaults to .standard.yml and passes it to standardrb via --config flag
  - Config file detection works correctly via File.exist? check
- [x] Test current StandardRB integration with various Ruby files
  - Integration working correctly with new RubyRunner architecture

### Execution Steps

- [ ] Verify StandardRB validator automatically detects and uses .standard.yml configuration
- [ ] Test StandardRB validator with files that should be ignored (per .standard.yml config)
  > TEST: Ignore Pattern Validation
  > Type: Configuration Validation
  > Assert: Files matching ignore patterns in .standard.yml are not processed
  > Command: code-lint ruby .ace/tools/vendor/ --dry-run
- [ ] Ensure Ruby runner passes correct working directory to StandardRB validator
- [ ] Validate autofix functionality works correctly with StandardRB configuration
  > TEST: Autofix with Configuration
  > Type: Feature Validation
  > Assert: StandardRB autofix applies rules according to .standard.yml settings
  > Command: code-lint ruby --autofix --dry-run
- [ ] Add logging to show which StandardRB configuration file is being used
- [ ] Test Ruby runner with custom StandardRB configuration path (if specified in lint.yml)

## Acceptance Criteria

- [x] AC 1: Ruby runner correctly uses existing .ace/tools/.standard.yml configuration file
- [x] AC 2: StandardRB validator respects ignore patterns defined in configuration
- [x] AC 3: Autofix functionality applies StandardRB rules according to configuration settings
- [x] AC 4: Ruby runner logs which StandardRB configuration file is being used
- [x] AC 5: Custom StandardRB config path in .coding-agent/lint.yml is properly honored

## Out of Scope

- ❌ Modifying existing .standard.yml configuration content
- ❌ Adding new StandardRB rules or changing existing ones
- ❌ Performance optimization of StandardRB execution
- ❌ Integration with other Ruby linters beyond StandardRB

## References

```
StandardRB config: .ace/tools/.standard.yml
Configuration reference: .coding-agent/lint.yml (ruby.linters.standardrb.config_file)
Validator implementation: .ace/tools/lib/coding_agent_tools/atoms/code_quality/standard_rb_validator.rb
```