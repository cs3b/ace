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

**✅ DESIGN DECISIONS CONFIRMED**:
1. **Primary Goal**: Timestamp-first directory naming for better chronological sorting
2. **Integration Requirement**: Nav-path integration is essential for consistent path generation across the project
3. **Implementation Approach**: SessionManager will use nav-path Ruby classes directly for efficiency, with nav-path command also available

## Scope of Work

- Change SessionNameBuilder to put timestamp first in directory names: `{timestamp}-{focus}-{target}`
- Add code-review session path generation to nav-path command and configuration
- Update SessionManager to use nav-path Ruby classes directly for session directory creation
- Update all existing tests for SessionNameBuilder and SessionTimestampGenerator 
- Test new format with various code-review scenarios
- Maintain backward compatibility where reasonable (no migration required)

### Deliverables

#### Create

- dev-tools/lib/coding_agent_tools/cli/commands/nav/code_review_new.rb (nav-path subcommand)

#### Modify

- dev-tools/lib/coding_agent_tools/atoms/code/session_name_builder.rb (timestamp-first format)
- dev-tools/lib/coding_agent_tools/organisms/code/session_manager.rb (integrate nav-path Ruby classes)
- dev-tools/lib/coding_agent_tools/molecules/path_resolver.rb (add code_review_new path type)
- dev-tools/lib/coding_agent_tools/cli/commands/nav/path.rb (register code-review-new command)
- .coding-agent/path.yml (add code_review_new path pattern configuration)
- dev-tools/spec/coding_agent_tools/atoms/code/session_name_builder_spec.rb (update all tests)
- dev-tools/spec/coding_agent_tools/atoms/code/session_timestamp_generator_spec.rb (if needed)

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
  > Command: find dev-tools/lib -name "*session*" -type f | head -10
- [ ] Design new directory name format: {timestamp}-{focus}-{target} instead of {focus}-{target}-{timestamp}
- [ ] Plan nav-path integration approach using Ruby classes directly for SessionManager

### Execution Steps

**1. Add nav-path configuration and command support:**

- [ ] Add code_review_new path pattern to .coding-agent/path.yml configuration
  > TEST: Configuration Added
  > Type: Integration Validation
  > Assert: Configuration follows existing pattern structure for path generation
  > Command: grep -A 10 "code_review_new" .coding-agent/path.yml
- [ ] Create nav-path code-review-new subcommand in dev-tools/lib/coding_agent_tools/cli/commands/nav/code_review_new.rb
- [ ] Update PathResolver.resolve_path to handle code_review_new path type
- [ ] Update nav-path command registration to include code-review-new command
  > TEST: Nav-Path Command Available
  > Type: Integration Validation
  > Assert: nav-path code-review-new command is accessible and generates proper paths
  > Command: cd dev-tools && bundle exec exe/nav-path code-review-new "test session name"

**2. Update SessionNameBuilder for timestamp-first format:**

- [ ] Update SessionNameBuilder.build method to use timestamp-first format: {timestamp}-{focus}-{target}
  > TEST: Name Format Change
  > Type: Unit Validation
  > Assert: SessionNameBuilder generates names with timestamp first
  > Command: cd dev-tools && ruby -r ./lib/coding_agent_tools -e "puts CodingAgentTools::Atoms::Code::SessionNameBuilder.new.build('docs', 'handbook', '20250705-173751')"
- [ ] Update all SessionNameBuilder specs to expect new timestamp-first format
  > TEST: Spec Updates Complete
  > Type: Unit Validation
  > Assert: All tests pass with new naming format
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/atoms/code/session_name_builder_spec.rb

**3. Integrate SessionManager with nav-path Ruby classes:**

- [ ] Modify SessionManager.create_session to use PathResolver directly for directory path generation
  > TEST: Nav-Path Integration
  > Type: Integration Validation
  > Assert: SessionManager uses nav-path for session directory creation with proper format
  > Command: cd dev-tools && ruby -r ./lib/coding_agent_tools -e "require 'pry'; binding.pry" # Test session creation flow
- [ ] Test new format with various focus and target combinations to ensure sanitization works correctly

## Acceptance Criteria

- [ ] AC 1: Code-review session directories use format {timestamp}-{focus}-{target} for chronological sorting
- [ ] AC 2: nav-path code-review-new command generates correct session directory paths and is available via CLI
- [ ] AC 3: SessionManager uses PathResolver (nav-path Ruby classes) for consistent path generation across the project
- [ ] AC 4: All SessionNameBuilder tests pass with updated expectations for timestamp-first format
- [ ] AC 5: New format maintains all existing functionality (session creation, file organization, metadata)
- [ ] AC 6: Path generation follows same pattern structure as task-new and reflection-new in .coding-agent/path.yml
- [ ] AC 7: Integration testing confirms complete flow from code-review command to directory creation works correctly

## Design Decisions (Resolved)

**✅ ALL DESIGN QUESTIONS RESOLVED:**

1. **Scope Clarification**: ✅ **CONFIRMED** - Nav-path integration is essential and should be included in this task for consistent path generation across the project.

2. **Nav-Path Architecture**: ✅ **CONFIRMED** - Nav-path integration will work by passing session name and having nav-path figure out directory path, similar to task-new pattern but for dynamic session creation.

3. **Configuration Location**: ✅ **CONFIRMED** - Configuration goes in project root `.coding-agent/path.yml` (file already exists, just needs code_review_new pattern added).

4. **SessionManager Integration**: ✅ **CONFIRMED** - SessionManager will use nav-path Ruby classes directly for better performance, with nav-path command also available for CLI usage.

5. **Backward Compatibility**: ✅ **CONFIRMED** - No existing dependencies on current format, proceed with timestamp-first change without migration concerns.

## Out of Scope

- ❌ Migrating existing session directories to new format
- ❌ Changing session content structure or metadata
- ❌ Modifying code-review command interface or workflow
- ❌ Performance optimization of session creation process

## References

### Format Change Examples

```
Current format: docs-handbook-workflows-20250705-173751
Target format: 20250705-173751-docs-handbook-workflows
Current path: dev-taskflow/current/v.0.3.0-workflows/code_review/docs-handbook-workflows-20250705-173751
Target path: dev-taskflow/current/v.0.3.0-workflows/code_review/20250705-173751-docs-handbook-workflows
```

### Configuration Addition Required

Add to `.coding-agent/path.yml` in path_patterns section:

```yaml
# Code review session path generation  
code_review_new:
  template: "{release_path}/code_review/{timestamp}-{slug}"
  variables:
    release_path: "release-manager current --format json | jq -r '.data.path'" # Command to get current release path
    timestamp: "datetime:%Y%m%d-%H%M%S" # YYYYMMDD-HHMMSS format  
    slug: "user_input" # Derived from session name (focus-target format)
```

### Architecture Components

```
Components to modify:
- SessionNameBuilder: Change directory name format to timestamp-first
- SessionManager: Integrate PathResolver (nav-path Ruby classes) for path generation
- PathResolver: Add code_review_new path type support
- CLI: Register nav-path code-review-new subcommand
- Configuration: Add code_review_new pattern to .coding-agent/path.yml
```