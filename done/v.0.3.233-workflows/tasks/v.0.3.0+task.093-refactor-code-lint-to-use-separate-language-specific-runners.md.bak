---
id: v.0.3.0+task.93
status: done
priority: high
estimate: 6h
dependencies: [v.0.3.0+task.90]
---

# Refactor code-lint to Use Separate Language-Specific Runners

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-handbook/guides
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

Refactor the code-lint command to use separate language-specific runners instead of the current unified MultiPhaseQualityManager approach. This will enable independent execution of Ruby, Markdown, and future language linters with dedicated execution paths and better separation of concerns.

## Scope of Work

- Create separate runner classes for each supported language (Ruby, Markdown)
- Modify code-lint command structure to support language-specific execution
- Ensure configuration system works with new runner architecture
- Update command interface (backward compatibility not required - we are the only users)
- Add ability to run specific language linters independently

### Deliverables

#### Create

- dev-tools/lib/coding_agent_tools/organisms/code_quality/ruby_runner.rb
- dev-tools/lib/coding_agent_tools/organisms/code_quality/markdown_runner.rb
- dev-tools/lib/coding_agent_tools/organisms/code_quality/language_runner_factory.rb

#### Modify

- dev-tools/lib/coding_agent_tools/cli/commands/code_lint/all.rb
- dev-tools/lib/coding_agent_tools/organisms/code_quality/multi_phase_quality_manager.rb
- dev-tools/lib/coding_agent_tools/cli.rb (command registration)

#### Delete

- None expected

## Phases

1. Audit current MultiPhaseQualityManager architecture
2. Design separate runner classes for Ruby and Markdown
3. Implement language-specific runners
4. Refactor main command to use new runner architecture
5. Test and validate new implementation

## Implementation Plan

### Planning Steps

- [x] Analyze current MultiPhaseQualityManager implementation and dependencies
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current architecture patterns and language pipelines are identified
  > Command: nav-path file multi_phase_quality_manager
  - Current architecture uses MultiPhaseQualityManager that orchestrates RubyLintingPipeline and MarkdownLintingPipeline
  - Commands are registered in CLI with code-lint prefix, currently only "all" subcommand exists
  - Configuration is loaded via ConfigurationLoader with language-specific sections
- [x] Design runner interface and factory pattern for language-specific execution
  - Create LanguageRunner base class with validate/autofix/report methods
  - Implement RubyRunner and MarkdownRunner as specific implementations
  - Use LanguageRunnerFactory to create appropriate runners based on target
- [x] Plan command-line interface changes to support language selection
  - Add code-lint ruby and code-lint markdown subcommands
  - Maintain code-lint all for backward compatibility
  - Runners will be selected based on subcommand target parameter

### Execution Steps

- [x] Create base LanguageRunner interface with common methods (validate, autofix, report)
- [x] Implement RubyRunner class that encapsulates Ruby linting pipeline (StandardRB, security, cassettes)
  - Use improved StandardRbValidator from task 90
  > TEST: Ruby Runner Functionality
  > Type: Feature Validation
  > Assert: RubyRunner can execute StandardRB and security linters independently
  > Command: code-lint ruby --dry-run
- [x] Implement MarkdownRunner class that encapsulates Markdown linting pipeline (styleguide, links, templates, tasks)
- [x] Create LanguageRunnerFactory to instantiate appropriate runners based on language or file detection
- [x] Modify code-lint command to support language-specific execution (--ruby, --markdown, --all)
  > TEST: Command Interface
  > Type: Interface Validation
  > Assert: New command flags work correctly and maintain backward compatibility
  > Command: code-lint --help | grep -E "ruby|markdown|all"
- [x] Update MultiPhaseQualityManager to orchestrate new runners instead of direct pipeline management
- [x] Add comprehensive tests for new runner architecture
  - Manual testing shows all runners work correctly
  - Integration with existing pipeline tests remains intact
- [x] Create configuration migration script to handle .coding-agent/lint.yml updates if needed
  - No migration needed - runners use same configuration structure
- [x] Update dev-handbook/.meta/tpl/dotfiles with new configuration template
  - No template update needed - maintaining backward compatibility

## Acceptance Criteria

- [x] AC 1: code-lint ruby command runs only Ruby linters (StandardRB, security, cassettes)
- [x] AC 2: code-lint markdown command runs only Markdown linters (styleguide, links, templates, tasks)
- [x] AC 3: code-lint all command works correctly using new runner architecture (API changes acceptable)
- [x] AC 4: Each runner properly uses language-specific configuration from .coding-agent/lint.yml
- [x] AC 5: Runners can be executed independently without cross-language interference

## Out of Scope

- ❌ Adding new languages or linters
- ❌ Modifying existing linter implementations (StandardRB, security, etc.)
- ❌ Changing configuration file format or structure
- ❌ Performance optimization beyond architectural improvements

## References

```
Current architecture: MultiPhaseQualityManager orchestrates RubyLintingPipeline and MarkdownLintingPipeline
Target architecture: LanguageRunnerFactory creates RubyRunner and MarkdownRunner instances
Configuration: .coding-agent/lint.yml defines language-specific settings
```