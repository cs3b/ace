---
id: v.0.3.0+task.96
status: pending
priority: high
estimate: 5h
dependencies: []
---

# Fix Code-Review Session Directory Path Format

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

Fix the code-review session directory path format to put timestamps at the beginning for better chronological sorting, and integrate with nav-path command for consistent path generation. Currently paths like `docs-handbook-workflows-20250705-173751` should become `20250705-173751-docs-handbook-workflows` and use nav-path for standardized path generation.

## Scope of Work

- Change SessionNameBuilder to put timestamp first in directory names
- Add code-review session path generation to nav-path command
- Update SessionManager to use nav-path for session directory creation
- Ensure backward compatibility with existing session directory structure
- Test new format with various code-review scenarios

### Deliverables

#### Create

- dev-tools/lib/coding_agent_tools/cli/commands/nav/code_review_new.rb (nav-path subcommand)
- .coding-agent/path.yml configuration for code-review sessions

#### Modify

- dev-tools/lib/coding_agent_tools/atoms/code/session_name_builder.rb
- dev-tools/lib/coding_agent_tools/organisms/code/session_manager.rb
- dev-tools/lib/coding_agent_tools/molecules/path_resolver.rb
- dev-tools/lib/coding_agent_tools/cli.rb (register nav commands)

#### Delete

- None expected

## Phases

1. Audit current code-review session directory creation flow
2. Design new timestamp-first format and nav-path integration
3. Implement SessionNameBuilder changes
4. Add nav-path code-review-new subcommand
5. Update SessionManager to use nav-path
6. Test and validate new format

## Implementation Plan

### Planning Steps

- [ ] Analyze current session directory creation flow from code-review command to SessionNameBuilder
  > TEST: Current Flow Understanding
  > Type: Pre-condition Check
  > Assert: Session creation components and their interactions are documented
  > Command: nav-path file session_name_builder
- [ ] Design new directory name format: {timestamp}-{focus}-{target} instead of {focus}-{target}-{timestamp}
- [ ] Plan nav-path integration with code-review-new subcommand similar to task-new and reflection-new

### Execution Steps

- [ ] Update SessionNameBuilder.build method to use timestamp-first format
  > TEST: Name Format Change
  > Type: Unit Validation
  > Assert: SessionNameBuilder generates names with timestamp first
  > Command: ruby -r ./lib/coding_agent_tools -e "puts CodingAgentTools::Atoms::Code::SessionNameBuilder.new.build('docs', 'handbook', '20250705-173751')"
- [ ] Add code_review_new path type to .coding-agent/path.yml configuration
- [ ] Create nav-path code-review-new subcommand that generates session paths using configured patterns
- [ ] Update PathResolver to handle code_review_new path type
- [ ] Modify SessionManager.create_session to use nav-path for directory path generation instead of internal logic
  > TEST: Nav-Path Integration
  > Type: Integration Validation
  > Assert: SessionManager uses nav-path for session directory creation
  > Command: nav-path code-review-new --focus docs --target handbook
- [ ] Update CLI command registration to include nav-path code-review-new
- [ ] Test new format with various focus and target combinations

## Acceptance Criteria

- [ ] AC 1: Code-review session directories use format {timestamp}-{focus}-{target} for chronological sorting
- [ ] AC 2: nav-path code-review-new command generates correct session directory paths
- [ ] AC 3: SessionManager uses nav-path for consistent path generation across the project
- [ ] AC 4: New format maintains all existing functionality (session creation, file organization)
- [ ] AC 5: Path generation is consistent with task-new and reflection-new patterns

## Out of Scope

- ❌ Migrating existing session directories to new format
- ❌ Changing session content structure or metadata
- ❌ Modifying code-review command interface or workflow
- ❌ Performance optimization of session creation process

## References

```
Current format: docs-handbook-workflows-20250705-173751
Target format: 20250705-173751-docs-handbook-workflows
Current path: dev-taskflow/current/v.0.3.0-workflows/code_review/docs-handbook-workflows-20250705-173751
Target path: dev-taskflow/current/v.0.3.0-workflows/code_review/20250705-173751-docs-handbook-workflows

Components to modify:
- SessionNameBuilder: Change directory name format
- SessionManager: Use nav-path instead of direct path building
- PathResolver: Add code_review_new path type
- CLI: Register nav-path code-review-new subcommand
```