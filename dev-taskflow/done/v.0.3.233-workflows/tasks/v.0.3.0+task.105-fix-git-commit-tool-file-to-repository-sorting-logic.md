---
id: v.0.3.0+task.105
status: done
priority: medium
estimate: 6h
dependencies: []
---

# Fix Git-Commit Tool File-to-Repository Sorting Logic

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

Fix the critical file-to-repository sorting bug in the git-commit tool that incorrectly assigns files to wrong repositories when given mixed file paths from main repo and submodules. Currently, the tool tries to add main repository files (like `.coding-agent/path.yml`) to submodule repositories (like .ace/tools), causing commit failures.

This issue prevents reliable use of git-commit with mixed repository file lists, forcing users to commit files separately by repository or use workarounds like the `--intention` only approach.

## Scope of Work

- Locate and analyze the current file sorting/repository assignment logic in git-commit tool
- Identify the root cause of incorrect file-to-repository mapping
- Fix the repository detection algorithm to correctly handle:
  - Main repository files (files without submodule prefixes)
  - Submodule files (files with `.ace/tools/`, `.ace/taskflow/`, `.ace/handbook/` prefixes)
  - Mixed file lists across multiple repositories
- Add comprehensive tests to prevent regression
- Ensure the fix maintains backward compatibility with existing workflows

### Deliverables

#### Create

- Test cases for mixed repository file lists
- Documentation of the corrected file sorting algorithm

#### Modify

- git-commit tool implementation (file sorting logic)
- Existing tests that may be affected by the fix

#### Delete

- None expected

## Phases

1. Investigation - Locate and understand current implementation
2. Root Cause Analysis - Identify exactly where the sorting fails
3. Design Fix - Plan the corrected algorithm
4. Implementation - Apply the fix with proper error handling
5. Testing - Comprehensive test coverage for mixed repo scenarios
6. Validation - End-to-end testing with real use cases

## Implementation Plan

### Planning Steps

- [x] Locate git-commit tool source code and understand its architecture
  > TEST: Code Location Check
  > Type: Pre-condition Check
  > Assert: git-commit tool source files are identified and can be read
  > Command: find .ace/tools -name "*git*commit*" -type f | head -10
- [x] Analyze current file sorting and repository assignment logic
  > TEST: Logic Understanding Check
  > Type: Pre-condition Check  
  > Assert: Current file-to-repo mapping algorithm is documented and understood
  > Command: grep -r "repository.*file\|file.*repository" .ace/tools/lib --include="*git*" | head -5
- [x] Reproduce the bug with a minimal test case to understand failure mode
- [x] Research the correct algorithm for mapping file paths to their respective repositories

### Execution Steps

- [x] Implement corrected file-to-repository mapping logic that properly handles main repo vs submodule files
  > TEST: Mapping Logic Validation
  > Type: Unit Validation
  > Assert: New algorithm correctly identifies file repositories for test cases
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/atoms/git/path_resolver_spec.rb
- [x] Add comprehensive test coverage for mixed repository file lists
- [x] Update existing tests that may be affected by the algorithm change
- [x] Test the fix end-to-end with the original failing command that triggered this issue
  > TEST: Original Issue Resolution
  > Type: Integration Validation
  > Assert: git-commit successfully handles mixed repo files like the original failing case
  > Command: git-commit README.md .ace/tools/CHANGELOG.md --intention "test fix"
- [x] Validate that existing git-commit workflows continue to work correctly

## Acceptance Criteria

- [x] AC 1: git-commit correctly identifies main repository files (without submodule prefixes)
- [x] AC 2: git-commit correctly identifies submodule files (with .ace/tools/, .ace/taskflow/, .ace/handbook/ prefixes)  
- [x] AC 3: Mixed repository file lists are properly sorted and committed to their respective repositories
- [x] AC 4: The original failing command now works without errors
- [x] AC 5: All existing git-commit functionality remains unchanged (backward compatibility)
- [x] AC 6: Comprehensive test coverage prevents future regression of this issue
- [x] AC 7: Error messages are clear when file-to-repository mapping fails

## Out of Scope

- ❌ Complete rewrite of git-commit tool architecture
- ❌ Adding support for additional repository types beyond the current 4
- ❌ Performance optimization of git-commit (unless related to the bug)
- ❌ Changes to git-commit CLI interface or command syntax
- ❌ Migration of existing git repositories or commit history

## References

### Bug Context

**Original failing command:**
```bash
git-commit .coding-agent/path.yml .ace/tools/lib/coding_agent_tools/atoms/code/session_name_builder.rb .ace/tools/spec/coding_agent_tools/atoms/code/session_name_builder_spec.rb .ace/taskflow/current/v.0.3.0-workflows/tasks/v.0.3.0+task.96-fix-code-review-session-directory-path-format.md --intention "implement timestamp-first directory format for code-review sessions with nav-path integration"
```

**Error observed:**
```
git -C /Users/michalczyz/Projects/CodingAgent/handbook-meta/.ace/tools add .coding-agent/path.yml
```

**Root cause:** The tool incorrectly assigned `.coding-agent/path.yml` (main repo file) to the .ace/tools repository.

### Repository Structure Context

This project uses 4 repositories:
- **Main repo**: Files without prefixes (like `.coding-agent/path.yml`)
- **.ace/tools/**: Ruby gem submodule  
- **.ace/taskflow/**: Task management submodule
- **.ace/handbook/**: Documentation submodule

### Expected Behavior

Files should be grouped by repository:
- `.coding-agent/path.yml` → main repo
- `.ace/tools/lib/example.rb` → .ace/tools submodule
- `.ace/taskflow/tasks/example.md` → .ace/taskflow submodule
- `.ace/handbook/guides/example.md` → .ace/handbook submodule