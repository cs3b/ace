---
id: v.0.3.0+task.125
status: pending
priority: high
estimate: 6h
dependencies: []
---

# Replace nav-path with create-path for creation operations

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
<insert tree here>
```

## Objective

Replace all references to `nav-path task-new` with `create-path task-new` across documentation and workflow instructions. The `nav-path task-new` command only returns file paths without creating files, causing confusion for users who expect file creation. The `create-path task-new` command was implemented in task v.0.3.0+task.112 to provide the expected file creation functionality with templates and metadata support.

## Scope of Work

- Find all documentation references to `nav-path task-new` and related creation operations within current multi-repo (docs/, dev-handbook/, dev-tools/)
- Replace with appropriate `create-path` equivalents using direct replacement (no deprecation warnings needed)
- Update workflow instructions to use `create-path task-new` instead of `nav-path task-new`
- Update tools documentation to reflect the change
- Ensure examples and cheat sheets are updated
- Verify no functionality is lost in the transition

### Deliverables

#### Create

- None - this is a documentation update task

#### Modify

- dev-handbook/workflow-instructions/create-task.wf.md
- docs/tools.md  
- dev-tools/docs/tools.md
- Any other files containing `nav-path task-new` references within docs/, dev-handbook/, dev-tools/

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

- [ ] Comprehensive search for all `nav-path task-new` references within multi-repo scope (docs/, dev-handbook/, dev-tools/)
  > TEST: Reference Search Complete
  > Type: Pre-condition Check
  > Assert: All instances of nav-path creation operations are identified within scope
  > Command: grep -r "nav-path.*task-new" docs/ dev-handbook/ dev-tools/ --include="*.md" | wc -l
- [ ] Identify command equivalencies between nav-path and create-path
- [ ] Verify create-path functionality covers all nav-path creation use cases
- [ ] Plan systematic replacement strategy with direct replacement (no deprecation warnings)

### Execution Steps

- [ ] Update dev-handbook/workflow-instructions/create-task.wf.md to use create-path task-new
  > TEST: Workflow Updated
  > Type: Content Validation
  > Assert: All nav-path task-new references replaced with create-path task-new
  > Command: grep -c "create-path task-new" dev-handbook/workflow-instructions/create-task.wf.md
- [ ] Update docs/tools.md main cheat sheet and examples
- [ ] Update dev-tools/docs/tools.md and related tool documentation
- [ ] Update any workflow instructions that reference nav-path for creation operations
- [ ] Search and replace nav-path creation examples in all markdown files within scope
  > TEST: No Remaining References
  > Type: Completeness Check  
  > Assert: No nav-path task-new references remain in multi-repo documentation
  > Command: grep -r "nav-path.*task-new" docs/ dev-handbook/ dev-tools/ --include="*.md" | wc -l
- [ ] Verify create-path examples work as expected
- [ ] Update any migration guides or help documentation within scope

## Acceptance Criteria

- [ ] AC 1: All documentation references to `nav-path task-new` within multi-repo scope (docs/, dev-handbook/, dev-tools/) are replaced with `create-path task-new`
- [ ] AC 2: All workflow instructions use `create-path` for file creation operations
- [ ] AC 3: Tools documentation accurately reflects create-path capabilities and usage
- [ ] AC 4: Examples in documentation work correctly with create-path command
- [ ] AC 5: No functionality is lost in the transition from nav-path to create-path
- [ ] AC 6: Search results show zero remaining `nav-path task-new` references in multi-repo docs
- [ ] AC 7: No external documentation outside multi-repo is affected (out of scope)

## Out of Scope

- ❌ Modifying the actual nav-path or create-path command implementations
- ❌ Removing nav-path command (still needed as underlying implementation for create-path)
- ❌ Adding deprecation warnings (nav-path remains as lower-level implementation)
- ❌ Updating external documentation outside current multi-repo (docs/, dev-handbook/, dev-tools/)
- ❌ Changing any Ruby code or command interfaces
- ❌ Modifying historical task files or completed work

## References

- Task v.0.3.0+task.112: Add create-path command for file/directory creation with metadata
- nav-path command: /dev-tools/exe/nav-path (path resolution without file creation)
- create-path command: /dev-tools/exe/create-path (path resolution with file creation)
- Configuration: /.coding-agent/create-path.yml (template mappings)
- Main workflow affected: dev-handbook/workflow-instructions/create-task.wf.md
- Tools documentation: docs/tools.md and dev-tools/docs/tools.md
