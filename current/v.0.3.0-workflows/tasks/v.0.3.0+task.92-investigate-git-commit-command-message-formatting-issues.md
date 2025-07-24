---
id: v.0.3.0+task.92
status: pending
priority: medium
estimate: 4h
dependencies: []
---

# Investigate git-commit Command Message Formatting Issues

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

Debug and fix the git-commit command error handling that displays improperly formatted error messages with escaped characters. While commits succeed, the error output shows shell escaping issues like `refactor\(git\):\ use\ direct\ Ruby\ calls\` instead of proper formatting, making debugging difficult.

## Scope of Work

- Investigate the git-commit command implementation in dev-tools
- Identify the source of shell character escaping in error messages
- Fix error message formatting to display properly
- Ensure error handling doesn't affect commit functionality

### Deliverables

#### Create

- None expected

#### Modify

- dev-tools/lib/coding_agent_tools/cli/git_commit.rb (likely)
- dev-tools/lib/coding_agent_tools/organisms/git_operations.rb (likely)
- Error handling and message formatting code

#### Delete

- None expected

## Phases

1. Audit git-commit implementation
2. Reproduce the error condition
3. Identify shell escaping issue
4. Fix error message formatting
5. Test fix doesn't break commit functionality

## Implementation Plan

### Planning Steps

- [ ] Examine the git-commit command implementation in dev-tools
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: git-commit command structure and error handling mechanisms are identified
  > Command: nav-path file git_commit
- [ ] Research how shell commands are executed and error messages are formatted
- [ ] Identify where the character escaping occurs in the error flow

### Execution Steps

- [ ] Locate the git-commit command source code in dev-tools
- [ ] Reproduce the error condition that generates escaped characters
  > TEST: Error Reproduction
  > Type: Issue Validation
  > Assert: The escaped character error can be consistently reproduced
  > Command: git-commit --intention "test commit with special chars (parentheses)"
- [ ] Trace the error handling flow from command execution to output
- [ ] Fix the shell escaping issue in error message formatting
  > TEST: Error Message Fix
  > Type: Fix Validation
  > Assert: Error messages display properly formatted without escaped characters
  > Command: git-commit --intention "test after fix (parentheses)" --dry-run
- [ ] Verify the fix doesn't break normal commit functionality
- [ ] Add test cases for proper error message formatting

## Acceptance Criteria

- [ ] AC 1: Error messages from git-commit display without shell character escaping
- [ ] AC 2: Normal commit functionality remains unaffected
- [ ] AC 3: Error handling preserves all necessary debugging information

## Out of Scope

- ❌ Changing the fundamental git-commit workflow
- ❌ Modifying commit message generation logic
- ❌ Adding new git-commit features

## References

```
Error example:
Error: [main] Error: Git command failed: git commit -m refactor\(git\):\ use\ direct\ Ruby\ calls\ for\ commit\ message\ generation'
```