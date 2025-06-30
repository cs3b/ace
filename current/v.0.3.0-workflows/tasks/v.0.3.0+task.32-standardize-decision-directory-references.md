---
id: v.0.3.0+task.32
status: pending
priority: low
estimate: 4h
dependencies: []
---

# Standardize Decision Directory References

## 0. Directory Audit ✅

_Command run:_

```bash
find . -name "*.md" -type f | xargs grep -l "dev-taskflow/decisions" | wc -l | sed 's/^/    /'
```

_Result excerpt:_

```
    38 files contain dev-taskflow/decisions references
```

## Objective

Standardize all decision directory references across the codebase to use `docs/decisions/` for permanent Architecture Decision Records (ADRs). Currently, many files reference `dev-taskflow/decisions` or `current/*/decisions`, which conflicts with the principle that `docs/` contains permanent project context while `dev-taskflow/` contains point-in-time information.

## Scope of Work

* Find all references to dev-taskflow/decisions or current/*/decisions
* Update references to use docs/decisions/ for permanent ADRs
* Document the distinction in architecture.md
* Ensure consistent understanding of permanent vs temporal documentation

### Deliverables

#### Create

* None - this is a standardization task

#### Modify

* docs/architecture.md (add clarification about docs/ vs dev-taskflow/)
* All files containing incorrect decision directory references
* Any workflow instructions referencing the wrong path

#### Delete

* None

## Phases

1. Comprehensive search for all decision references
2. Categorize references by type
3. Update all references systematically
4. Document the standard

## Implementation Plan

### Planning Steps

* [ ] Search for all variations of decision directory references
  > TEST: All References Found
  > Type: Pre-condition Check
  > Assert: Complete list of files with decision references compiled
  > Command: bin/test --check-all-references-found
* [ ] Categorize which references should point to docs/decisions/
* [ ] Identify any legitimate dev-taskflow decision references

### Execution Steps

* [ ] Update docs/architecture.md to clarify docs/ vs dev-taskflow/ distinction
  > TEST: Architecture Clarification Added
  > Type: Content Check
  > Assert: Clear explanation of permanent vs point-in-time docs
  > Command: bin/test --check-architecture-clarification
* [ ] Update all workflow files to reference docs/decisions/ for ADRs
* [ ] Update any guide files with incorrect references
* [ ] Fix references in task files and other documentation
  > TEST: All References Standardized
  > Type: Path Validation
  > Assert: ADR references point to docs/decisions/
  > Command: bin/test --check-standardized-paths
* [ ] Ensure no broken links result from the changes

## Acceptance Criteria

* [ ] All permanent ADR references use docs/decisions/ path
* [ ] Architecture.md clearly documents the distinction
* [ ] No references to dev-taskflow/decisions for permanent ADRs
* [ ] Point-in-time decisions (if any) clearly marked as such
* [ ] All links remain functional after updates

## Out of Scope

* ❌ Moving actual decision files
* ❌ Creating new ADRs
* ❌ Changing decision content
* ❌ Restructuring the directory hierarchy

## References

* Current mixed references across 38 files
* docs/decisions/ as the permanent ADR location
* Architecture principles for permanent vs temporal documentation