---

id: v.0.3.0+task.02
status: done
priority: high
estimate: 2h
dependencies: []
---

# Standardize Commit Command References

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 docs dev-handbook/workflow-instructions | sed 's/^/    /'
```

_Result excerpt:_

```
    docs
    ├── architecture.md
    ├── blueprint.md
    └── what-do-we-build.md
    dev-handbook/workflow-instructions
    ├── commit.wf.md
    ├── draft-release.wf.md
    └── ...
```

## Objective

Standardize all commit command references across documentation to use the consistent `bin/gc -i` format instead of the legacy `bin/git-commit-with-message`.

## Scope of Work

* Update blueprint.md to replace `bin/git-commit-with-message` with `bin/gc -i`
* Update commit.wf.md to use `bin/gc -i` for actual commands
* Search and update any remaining inconsistent references
* Verify bin/gc -i functionality

### Deliverables

#### Create

* None

#### Modify

* docs/blueprint.md
* dev-handbook/workflow-instructions/commit.wf.md

#### Delete

* None

## Phases

1. Audit current commit command usage
2. Update documentation files
3. Verify functionality

## Implementation Plan

### Planning Steps

* [x] Search for all occurrences of git-commit-with-message in the codebase
  > TEST: Command Usage Audit
  > Type: Pre-condition Check
  > Assert: All instances of old command are found
  > Command: grep -r "git-commit-with-message" . --exclude-dir=.git | wc -l
* [x] Verify that bin/gc supports the -i flag
* [x] Identify all files requiring updates

### Execution Steps

- [x] Update blueprint.md commit command references
  > TEST: Blueprint Updated
  > Type: Content Validation
  > Assert: No references to git-commit-with-message remain
  > Command: grep -c "git-commit-with-message" docs/blueprint.md || echo "0"
- [x] Update commit.wf.md to use bin/gc -i format
- [x] Search and update any other documentation files
- [x] Test bin/gc -i functionality with a sample intention
  > TEST: Command Functionality
  > Type: Integration Test
  > Assert: bin/gc -i accepts intention parameter
  > Command: bin/gc -i "test intention" --dry-run

## Acceptance Criteria

* [x] All references to bin/git-commit-with-message are replaced with bin/gc -i
* [x] Documentation is consistent across all files
* [x] bin/gc -i functionality is verified and working
* [x] No legacy command references remain in active documentation

## Out of Scope

* ❌ Modifying the actual bin/gc script functionality
* ❌ Creating new commit workflows
* ❌ Updating archived or historical documentation

## References

* Current inconsistent usage in docs/blueprint.md
* Workflow documentation: dev-handbook/workflow-instructions/commit.wf.md
* Related task from original plan: task.68
