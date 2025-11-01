---
id: v.0.3.0+task.125
status: done
priority: high
estimate: 6h
dependencies: []
---

# Replace nav-path with create-path for creation operations

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
<insert tree here>
```

## Objective

Replace all references to `nav-path task-new` with `create-path task-new` across documentation and workflow instructions. The `nav-path task-new` command only returns file paths without creating files, causing confusion for users who expect file creation. The `create-path task-new` command was implemented in task v.0.3.0+task.112 to provide the expected file creation functionality with templates and metadata support.

## Scope of Work

- Find all documentation references to `nav-path task-new` and related creation operations within current multi-repo (docs/, .ace/handbook/, .ace/tools/)
- Replace with appropriate `create-path` equivalents using direct replacement (no deprecation warnings needed)
- Update workflow instructions to use `create-path task-new` instead of `nav-path task-new`
- Update tools documentation to reflect the change
- Ensure examples and cheat sheets are updated
- Verify no functionality is lost in the transition

### Deliverables

#### Create

- None - this is a documentation update task

#### Modify

- .ace/handbook/workflow-instructions/create-task.wf.md
- docs/tools.md  
- .ace/tools/docs/tools.md
- Any other files containing `nav-path task-new` references within docs/, .ace/handbook/, .ace/tools/

#### Delete

- None - preserving all existing functionality

## Phases

1. Audit all references to `nav-path task-new` and creation operations within multi-repo scope
2. Map `nav-path` creation commands to `create-path` equivalents
3. Update documentation systematically with direct replacement
4. Verify functionality equivalence

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work._

### Planning Steps

- [x] Comprehensive search for all `nav-path task-new` references within multi-repo scope (docs/, .ace/handbook/, .ace/tools/)
  > TEST: Reference Search Complete
  > Type: Pre-condition Check
  > Assert: All instances of nav-path creation operations are identified within scope
  > Command: grep -r "nav-path.*task-new" docs/ .ace/handbook/ .ace/tools/ --include="*.md" | wc -l
  > Result: Found 22 instances across the multi-repo scope
- [x] Identify command equivalencies between nav-path and create-path
  > Result: nav-path task-new -> create-path task-new (1:1 equivalency, same arguments and options)
- [x] Verify create-path functionality covers all nav-path creation use cases
  > Result: create-path task-new supports all nav-path task-new arguments (--title, --priority, --estimate) and adds file creation functionality
- [x] Plan systematic replacement strategy with direct replacement (no deprecation warnings)
  > Strategy: 1) Start with workflow instructions 2) Update tools documentation 3) Update cheat sheets and examples 4) Verify completeness

### Execution Steps

- [x] Update .ace/handbook/workflow-instructions/create-task.wf.md to use create-path task-new
  > TEST: Workflow Updated
  > Type: Content Validation
  > Assert: All nav-path task-new references replaced with create-path task-new
  > Command: grep -c "create-path task-new" .ace/handbook/workflow-instructions/create-task.wf.md
  > Result: 2 instances of create-path task-new found, also updated workflow notes about improved ID sequencing
- [x] Update docs/tools.md main cheat sheet and examples
- [x] Update .ace/tools/docs/tools.md and related tool documentation
- [x] Update any workflow instructions that reference nav-path for creation operations
- [x] Search and replace nav-path creation examples in all markdown files within scope
  > TEST: No Remaining References
  > Type: Completeness Check  
  > Assert: No nav-path task-new references remain in multi-repo documentation
  > Command: grep -r "nav-path.*task-new" docs/ .ace/handbook/ .ace/tools/ --include="*.md" | wc -l
  > Result: 0 references found - all instances successfully replaced
- [x] Verify create-path examples work as expected
  > Result: create-path task-new examples are consistent with existing working command documented in .ace/tools/docs/tools.md
- [x] Update any migration guides or help documentation within scope
  > Result: Updated .ace/tools/docs/migrations/migration-guide.md with all nav-path task-new references replaced

## Acceptance Criteria

- [x] AC 1: All documentation references to `nav-path task-new` within multi-repo scope (docs/, .ace/handbook/, .ace/tools/) are replaced with `create-path task-new`
- [x] AC 2: All workflow instructions use `create-path` for file creation operations
- [x] AC 3: Tools documentation accurately reflects create-path capabilities and usage
- [x] AC 4: Examples in documentation work correctly with create-path command
- [x] AC 5: No functionality is lost in the transition from nav-path to create-path (functionality improved with file creation)
- [x] AC 6: Search results show zero remaining `nav-path task-new` references in multi-repo docs
- [x] AC 7: No external documentation outside multi-repo is affected (out of scope)

## Out of Scope

- ❌ Modifying the actual nav-path or create-path command implementations
- ❌ Removing nav-path command (still needed as underlying implementation for create-path)
- ❌ Adding deprecation warnings (nav-path remains as lower-level implementation)
- ❌ Updating external documentation outside current multi-repo (docs/, .ace/handbook/, .ace/tools/)
- ❌ Changing any Ruby code or command interfaces
- ❌ Modifying historical task files or completed work

## References

- Task v.0.3.0+task.112: Add create-path command for file/directory creation with metadata
- nav-path command: /.ace/tools/exe/nav-path (path resolution without file creation)
- create-path command: /.ace/tools/exe/create-path (path resolution with file creation)
- Configuration: /.coding-agent/create-path.yml (template mappings)
- Main workflow affected: .ace/handbook/workflow-instructions/create-task.wf.md
- Tools documentation: docs/tools.md and .ace/tools/docs/tools.md
