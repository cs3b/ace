---
id: v.0.3.0+task.33
status: done
priority: high
estimate: 12h
dependencies: [v.0.3.0+task.07, v.0.3.0+task.08]
---

# Enhance task-manager with sorting and filtering capabilities

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 3 bin/ | grep -E "(task|tal|tn)" | sed 's/^/    /'
```

_Result excerpt:_

```
    ├── tal
    ├── tn
    └── tnid
```

## Objective

Add comprehensive sorting and filtering capabilities to the task-manager system to improve task organization and workflow management. This enhancement will change the default behavior for both `all` and `next` commands to use implementation order sorting, and allow users to sort tasks by multiple attributes and filter by any metadata with support for negation using `attribute:value` and `attribute:!value` syntax.

## Scope of Work

* Change default sorting for `all` and `next` commands to use implementation order
* Add `--sort` option with multi-attribute support and direction control
* Implement special "implementation order" sorting based on dependencies, task ID, and optional `sort` metadata attribute
* Add `--filter` option supporting any metadata attribute with positive (`attribute:value`) and negative (`attribute:!value`) syntax
* Maintain explicit sort/filter override capabilities
* Ensure backward compatibility with existing workflows

### Deliverables

#### Create

* Enhanced argument parsing for new options
* Sorting engine with dependency-aware implementation order
* Flexible filtering system with metadata support
* Updated command implementations

#### Modify

* bin/tal (task-manager all command)
* bin/tn (task-manager next command)
* Related task management scripts

#### Delete

* None

## Phases

1. Analysis of current task-manager implementation
2. Design sorting and filtering architecture
3. Implement sorting engine with implementation order logic
4. Implement filtering system with metadata support
5. Update command defaults and integration
6. Testing and validation

## Implementation Plan

### Planning Steps

* [x] Analyze current task-manager implementation to understand data structures and flow
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Task data structure, current sorting/filtering logic, and command flow are documented
  > Command: task-manager all --help && task-manager next --help
* [x] Research dependency resolution algorithms for implementation order sorting
* [x] Design flexible filtering system architecture supporting any metadata with `attribute:value` and `attribute:!value` syntax
* [x] Plan CLI argument parsing strategy for new options
* [x] Design implementation order algorithm considering dependencies, task ID, and optional `sort` metadata attribute

### Execution Steps

* [x] Implement argument parsing for `--sort` and `--filter` options
  > TEST: Verify Argument Parsing
  > Type: Action Validation
  > Assert: New options are correctly parsed and validated
  > Command: task-manager all --sort status,id:asc --filter status:pending --help
* [x] Create sorting engine with multi-attribute support
  > TEST: Verify Multi-Attribute Sorting
  > Type: Action Validation
  > Assert: Tasks are sorted correctly by multiple attributes with direction control
  > Command: task-manager all --sort priority:desc,id:asc --debug
* [x] Implement implementation order sorting logic
  > TEST: Verify Implementation Order Sorting
  > Type: Action Validation
  > Assert: Tasks are sorted by dependency order, then by sort metadata (if present), then by ID for same-level tasks
  > Command: task-manager all --sort implementation-order --debug
* [x] Build flexible filtering system with metadata support
  > TEST: Verify Metadata Filtering
  > Type: Action Validation
  > Assert: Filtering works for any metadata attribute including negation
  > Command: task-manager all --filter status:!done --filter priority:high --debug
* [x] Update `all` command with new default sorting (implementation order, all statuses)
  > TEST: Verify All Command Defaults
  > Type: Action Validation
  > Assert: task-manager all shows all tasks sorted by implementation order by default
  > Command: task-manager all
* [x] Update `next` command with new default sorting (implementation order, pending/in-progress only)
  > TEST: Verify Next Command Defaults
  > Type: Action Validation
  > Assert: task-manager next shows only pending/in-progress tasks in implementation order by default
  > Command: task-manager next
* [x] Add comprehensive error handling and validation
* [ ] Add JSON output format support for new sorting/filtering options
  > TEST: Verify JSON Output Format
  > Type: Action Validation
  > Assert: JSON output maintains consistent structure with new sort/filter metadata
  > Command: task-manager all --sort status --format json
* [x] Create test cases for all sorting and filtering combinations
* [x] Update documentation and help text
* [x] Add error handling for invalid sort/filter combinations
  > TEST: Verify Error Handling
  > Type: Action Validation
  > Assert: Clear error messages for invalid sort/filter syntax
  > Command: task-manager all --sort invalid-field --debug

## Acceptance Criteria

* [x] AC 1: `--sort` option supports multi-attribute sorting with direction control (e.g., `--sort status,id:asc`)
* [x] AC 2: Implementation order sorting considers task dependencies and IDs
* [x] AC 3: `--filter` option supports any metadata attribute with negation (e.g., `--filter status:!done`)
* [x] AC 4: `all` command defaults to implementation order sorting showing all statuses (considers dependencies, task ID, and optional sort metadata)
* [x] AC 5: `next` command defaults to implementation order sorting showing only pending/in-progress tasks
* [x] AC 6: All existing functionality remains backward compatible
* [ ] AC 7: JSON output format maintains consistency with new features
* [x] AC 8: Clear error messages for invalid sort/filter combinations
* [x] AC 9: Comprehensive test coverage for new features

## Out of Scope

* ❌ Advanced query language (keep simple attribute:value syntax)
* ❌ Task grouping or aggregation features
* ❌ Saved filters or sorting preferences
* ❌ Performance optimization for large task sets (focus on correctness first)
* ❌ GUI or web interface changes

## References

* Current task-manager implementation in bin/tal and bin/tn
* Task metadata structure and dependencies
* Existing sorting and filtering patterns in codebase