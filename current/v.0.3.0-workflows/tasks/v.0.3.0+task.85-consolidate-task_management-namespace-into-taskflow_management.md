---
id: v.0.3.0+task.85
status: pending
priority: high
estimate: 6h
dependencies: []
---

# Consolidate task_management namespace into taskflow_management

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 3 dev-tools/lib/coding_agent_tools | grep -E "(task_management|taskflow_management)" | sed 's/^/    /'
```

_Result excerpt:_

```
    │   ├── task_management
    │   └── taskflow_management
    │   ├── task_management
    │   └── taskflow_management
    │   ├── task_management
    │   └── taskflow_management
```

## Objective

Eliminate code duplication between the `task_management` and `taskflow_management` namespaces by consolidating everything into `taskflow_management`. This addresses a critical architectural issue identified in the code review where five identical files exist in both namespaces, violating the DRY principle and creating maintenance burden.

## Scope of Work

- Migrate unique components from task_management to taskflow_management namespace
- Update all references to use the consolidated taskflow_management namespace
- Remove all duplicate code and empty directories
- Ensure both task-manager and release-manager commands continue to work
- Update and consolidate test files

### Deliverables

#### Create

- dev-tools/lib/coding_agent_tools/molecules/taskflow_management/file_synchronizer.rb
- dev-tools/lib/coding_agent_tools/molecules/taskflow_management/xml_template_parser.rb
- dev-tools/lib/coding_agent_tools/organisms/taskflow_management/template_synchronizer.rb
- dev-tools/spec/coding_agent_tools/organisms/taskflow_management/template_synchronizer_spec.rb
- dev-tools/spec/coding_agent_tools/molecules/taskflow_management/file_synchronizer_spec.rb
- dev-tools/spec/coding_agent_tools/molecules/taskflow_management/xml_template_parser_spec.rb

#### Modify

- dev-tools/lib/coding_agent_tools/cli/commands/handbook/sync_templates.rb
- dev-tools/lib/coding_agent_tools/organisms.rb
- dev-tools/lib/coding_agent_tools/molecules.rb

#### Delete

- dev-tools/lib/coding_agent_tools/atoms/task_management/ (entire directory)
- dev-tools/lib/coding_agent_tools/molecules/task_management/ (entire directory)
- dev-tools/lib/coding_agent_tools/organisms/task_management/ (entire directory)
- dev-tools/spec/coding_agent_tools/atoms/task_management/ (entire directory)
- dev-tools/spec/coding_agent_tools/molecules/task_management/ (entire directory)
- dev-tools/spec/coding_agent_tools/organisms/task_management/ (entire directory)

## Phases

1. Audit current usage and dependencies
2. Migrate unique components to taskflow_management
3. Update all references and autoload configuration
4. Delete duplicate code
5. Run tests and verify functionality

## Implementation Plan

### Planning Steps

- [ ] Analyze current usage of both namespaces across the codebase
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: All references to both namespaces are identified
  > Command: cd dev-tools && grep -r "TaskManagement\|task_management" --include="*.rb" | grep -v spec
- [ ] Identify unique components in task_management namespace
- [ ] Create migration plan for unique components

### Execution Steps

- [ ] Step 1: Move unique molecules from task_management to taskflow_management
  - Move file_synchronizer.rb
  - Move xml_template_parser.rb
  - Update module declarations in moved files
- [ ] Step 2: Move unique organism (TemplateSynchronizer) to taskflow_management
  - Move template_synchronizer.rb
  - Update module declaration and require statements
- [ ] Step 3: Update CLI command to use TaskflowManagement namespace
  > TEST: Verify CLI Command Update
  > Type: Action Validation
  > Assert: handbook sync-templates command uses TaskflowManagement
  > Command: cd dev-tools && grep -A5 -B5 "TemplateSynchronizer" lib/coding_agent_tools/cli/commands/handbook/sync_templates.rb
- [ ] Step 4: Update autoload configuration
  - Add TemplateSynchronizer to TaskflowManagement in organisms.rb
  - Remove TaskManagement module references
- [ ] Step 5: Move and update test files for unique components
  - Move template_synchronizer_spec.rb
  - Move file_synchronizer_spec.rb and xml_template_parser_spec.rb if they exist
  - Update require paths and module references in tests
- [ ] Step 6: Delete all duplicate files and directories
  - Remove atoms/task_management/
  - Remove remaining molecules/task_management/
  - Remove remaining organisms/task_management/
  - Remove corresponding test directories
- [ ] Step 7: Run all tests to ensure nothing is broken
  > TEST: All Tests Pass
  > Type: Integration Test
  > Assert: All tests in dev-tools pass after consolidation
  > Command: cd dev-tools && bundle exec rspec
- [ ] Step 8: Test handbook sync-templates command
  > TEST: Template Sync Works
  > Type: Functional Test
  > Assert: handbook sync-templates runs without errors
  > Command: cd dev-tools && bundle exec exe/handbook sync-templates --dry-run

## Acceptance Criteria

- [ ] AC 1: All unique components from task_management are successfully migrated to taskflow_management
- [ ] AC 2: No duplicate code remains between the namespaces
- [ ] AC 3: task-manager commands (next, recent, all) continue to work correctly
- [ ] AC 4: release-manager commands continue to work correctly
- [ ] AC 5: handbook sync-templates command works with the new namespace
- [ ] AC 6: All tests pass after consolidation
- [ ] AC 7: No references to TaskManagement namespace remain in the codebase

## Out of Scope

- ❌ Refactoring the actual implementation of the components
- ❌ Adding new features or functionality
- ❌ Modifying the CLI interface or command structure
- ❌ Changing the ATOM architecture categorization

## References

- Code review report: dev-taskflow/current/v.0.3.0-workflows/code_review/code-dev-tools-lib-20250724-184702/cr-report-gpro.md
- ATOM architecture documentation
- DRY principle violations identified in review