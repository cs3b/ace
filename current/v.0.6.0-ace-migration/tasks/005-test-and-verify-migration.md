---
id: v.0.6.0+task.005
status: pending
priority: high
estimate: 3h
dependencies: [v.0.6.0+task.004]
---

# Test and Verify Migration

## Objective

Thoroughly test the migrated codebase to ensure all functionality works correctly with the new structure and naming conventions.

## Scope of Work

- Run full Ruby test suite
- Test all CLI commands
- Verify gem installation
- Test workflow instructions
- Validate search functionality

### Deliverables

#### Create

- `codemods/verify.sh` - Comprehensive verification script
- `codemods/test_report.md` - Test execution report

#### Modify

- Fix any broken tests due to path/module changes

#### Delete

- None

## Implementation Plan

### Planning Steps

* [ ] Identify all test suites to run
* [ ] List all CLI commands to verify
* [ ] Plan installation testing approach

### Execution Steps

- [ ] Create comprehensive verification script:
  ```bash
  #!/bin/bash

  echo "=== Path Verification ==="
  search ".ace/tools/" --content --hidden || echo "✓ No .ace/tools references"
  search ".ace/handbook/" --content --hidden || echo "✓ No .ace/handbook references"
  search ".ace/taskflow/" --content --hidden || echo "✓ No .ace/taskflow references"

  echo "=== Module Verification ==="
  search "CodingAgentTools" --content || echo "✓ No CodingAgentTools references"
  search "coding_agent_tools" --content || echo "✓ No coding_agent_tools references"

  echo "=== Structure Verification ==="
  [ -d ".ace/tools/lib/ace_tools" ] && echo "✓ ace_tools directory exists"
  [ -f ".ace/tools/ace_tools.gemspec" ] && echo "✓ Gemspec renamed"
  ```
  > TEST: Verification Script
  > Type: Shell Test
  > Assert: Script runs without errors
  > Command: bash codemods/verify.sh

- [ ] Run Ruby test suite:
  ```bash
  cd .ace/tools
  bundle install
  bundle exec rspec
  ```
  > TEST: RSpec Suite
  > Type: Test Suite
  > Assert: All tests pass
  > Command: cd .ace/tools && bundle exec rspec --format documentation

- [ ] Test all CLI commands:
  - task-manager
  - release-manager
  - handbook
  - search
  - context
  - llm-query
  - git-* commands
  - code-review
  > TEST: CLI Commands
  > Type: Integration Test
  > Assert: Each command executes without errors
  > Command: for cmd in task-manager release-manager handbook; do $cmd --help; done

- [ ] Test gem build and installation:
  ```bash
  cd .ace/tools
  gem build ace_tools.gemspec
  gem install ./ace-tools-*.gem --local
  ```
  > TEST: Gem Installation
  > Type: Installation Test
  > Assert: Gem installs successfully
  > Command: gem list | grep ace-tools

- [ ] Verify workflow instructions work:
  - Test load-project-context workflow
  - Test draft-release workflow
  - Verify path references in workflows
  > TEST: Workflow Execution
  > Type: Workflow Test
  > Assert: Workflows reference correct paths
  > Command: grep -r "\.ace/" .ace/handbook/workflow-instructions/

## Acceptance Criteria

- [ ] All Ruby tests pass (maintain >80% coverage)
- [ ] All CLI commands function correctly
- [ ] Gem builds and installs successfully
- [ ] No references to old paths/modules remain
- [ ] Workflows execute with new structure

## Out of Scope

- ❌ Documentation writing (task 006)
- ❌ Migration guide creation (task 007)
- ❌ Release packaging (task 008)