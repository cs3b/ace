---
id: v.0.3.0+task.128
status: pending
priority: high
estimate: 4h
dependencies: []
---

# audit-nav-path-usage-and-evaluate-create-path-extension

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

Replace nav-path creation operations with create-path equivalents using delegation pattern, while preserving nav-path for pure navigation. Strategy: nav-path file/task remain unchanged (pure navigation), but docs-new, reflection-new, code-review-new should be replaced with create-path using format like `create-path file:docs-new` where create-path delegates path resolution to nav-path then creates the file/directory.

## Scope of Work

- Find all nav-path creation usage: docs-new, reflection-new, code-review-new
- Replace with create-path delegation pattern:
  - `nav-path docs-new` → `create-path file:docs-new` (creates empty file at nav-path resolved location)
  - `nav-path reflection-new` → `create-path file:reflection-new` (creates empty file)
  - `nav-path code-review-new` → `create-path directory:code-review-new` (creates directory)
- Preserve nav-path file and nav-path task usage (pure navigation)
- Update documentation and workflow instructions with new patterns
- Verify create-path supports the delegation format (file:type, directory:type)

### Deliverables

#### Create

- None - this is a documentation update task

#### Modify

- Documentation files containing nav-path docs-new, reflection-new, code-review-new references
- Workflow instructions using creation nav-path operations
- Tools documentation with updated command patterns

#### Delete

- None - preserving all functionality with better command patterns

## Phases

1. Audit nav-path creation operations (docs-new, reflection-new, code-review-new)
2. Implement create-path delegation pattern replacements
3. Update all documentation with new command patterns
4. Verify delegation functionality works correctly

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work._

### Planning Steps

- [ ] Search for nav-path creation operations: docs-new, reflection-new, code-review-new
  > TEST: Creation Operations Found
  > Type: Data Collection Check
  > Assert: All creation nav-path operations identified
  > Command: grep -r "nav-path.*\(docs-new\|reflection-new\|code-review-new\)" docs/ dev-handbook/ dev-tools/ --include="*.md" | wc -l
- [ ] Verify create-path current types: task-new, file, directory, docs-new, template
- [ ] Determine if delegation format (file:type, directory:type) needs implementation or if direct types suffice
- [ ] Test delegation pattern examples to ensure functionality
- [ ] Confirm nav-path file and nav-path task usage should remain unchanged

### Execution Steps

- [ ] Replace nav-path docs-new references with create-path file:docs-new
  > TEST: docs-new Replacements Complete
  > Type: Content Validation
  > Assert: All docs-new references updated to create-path delegation
  > Command: grep -r "create-path file:docs-new" docs/ dev-handbook/ dev-tools/ --include="*.md" | wc -l
- [ ] Replace nav-path reflection-new references with create-path file:reflection-new
- [ ] Replace nav-path code-review-new references with create-path directory:code-review-new
- [ ] Verify nav-path file and nav-path task references remain unchanged
- [ ] Update workflow instructions with new delegation patterns
- [ ] Test that delegation format works: create-path file:docs-new, directory:code-review-new
  > TEST: Delegation Pattern Works
  > Type: Functionality Check
  > Assert: create-path delegation creates files/directories at nav-path resolved locations
  > Command: create-path file:docs-new --title "test" && ls -la

## Acceptance Criteria

- [ ] AC 1: All nav-path docs-new references replaced with create-path file:docs-new
- [ ] AC 2: All nav-path reflection-new references replaced with create-path file:reflection-new  
- [ ] AC 3: All nav-path code-review-new references replaced with create-path directory:code-review-new
- [ ] AC 4: nav-path file and nav-path task references preserved (pure navigation)
- [ ] AC 5: Delegation pattern verified to work correctly (path resolution + creation)
- [ ] AC 6: Documentation updated with new command patterns
- [ ] AC 7: No remaining nav-path creation operations in documentation

## Out of Scope

- ❌ Implementing any changes to nav-path or create-path commands (analysis only)
- ❌ Modifying existing documentation or workflow instructions
- ❌ Making final decisions about command consolidation (recommendations only)
- ❌ Updating external documentation outside multi-repo scope
- ❌ Analyzing task-new usage (covered in task 125)
- ❌ Changing any Ruby code or command interfaces

## References

- Task v.0.3.0+task.125: Replace nav-path with create-path for creation operations (task-new)
- Task v.0.3.0+task.112: Add create-path command implementation
- create-path command help: `create-path --help`
- nav-path command help: `nav-path --help`
- Configuration: /.coding-agent/create-path.yml
- Current create-path TYPE options: file, directory, docs-new, template
- Nav-path usage patterns in docs/, dev-handbook/, dev-tools/
