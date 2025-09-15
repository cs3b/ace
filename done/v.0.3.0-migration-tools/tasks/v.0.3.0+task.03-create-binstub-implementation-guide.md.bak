---

id: v.0.3.0+task.03
status: done
priority: high
estimate: 3h
dependencies: []
---

# Create Shell Binstub Implementation Guide

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-handbook/guides
    ├── development
    ├── patterns
    └── ...
```

## Objective

Create a focused implementation guide for simple shell binstubs that delegate to `dev-tools/exe/` executables, ensuring proper directory context management and argument passing as specified in user requirements.

## Scope of Work

* Create dev-handbook/.meta/gds/shell-binstub-patterns.g.md
* Document shell script patterns used in this project
* Provide directory context management examples
* Include argument passing and delegation patterns
* Update development README

### Deliverables

#### Create

* dev-handbook/guides/development/shell-binstub-patterns.g.md

#### Modify

* dev-handbook/guides/development/README.md (add reference to new guide)

#### Delete

* None

## Phases

1. Analyze existing shell binstub patterns in bin/
2. Document directory context management requirements
3. Create shell script templates and examples
4. Include troubleshooting for common delegation issues

## Implementation Plan

### Planning Steps

* [x] Analyze existing shell binstub patterns in bin/ directory
  > TEST: Pattern Analysis Complete
  > Type: Pre-condition Check
  > Assert: Understanding of current shell binstub patterns documented
  > Command: ls -la bin/ | grep -E "test|gc|setup" | wc -l
* [x] Study directory context requirements for delegation
* [x] Map relationship between bin/ and dev-tools/exe/ executables

### Execution Steps

- [x] Create shell-binstub-patterns.g.md with focused structure
- [x] Document shell script template with directory context management
  > TEST: Shell Template Section Complete
  > Type: Content Validation
  > Assert: Shell script templates are present
  > Command: grep -c "#!/bin/sh" dev-handbook/.meta/gds/shell-binstub-patterns.g.md
- [x] Add argument passing and delegation examples
- [x] Document when to use directory context vs direct execution
- [x] Create troubleshooting section for common delegation issues
  > TEST: Troubleshooting Section
  > Type: Content Validation
  > Assert: Common delegation issues are documented
  > Command: grep -c "Troubleshooting" dev-handbook/.meta/gds/shell-binstub-patterns.g.md
- [x] Update development README to reference the new guide

## Acceptance Criteria

* [x] Guide focuses on shell script binstub patterns for this project
* [x] Clear examples of directory context management are provided
* [x] Argument passing to dev-tools/exe/ is documented
* [x] Troubleshooting section addresses common delegation issues
* [x] Development README references the new guide

## Out of Scope

* ❌ Implementing actual binstubs (this is documentation only)
* ❌ Covering languages beyond shell scripting
* ❌ Modifying existing binstub implementations
* ❌ General binstub patterns for other technologies (Ruby, Node.js, Python)

## References

* Target location: dev-handbook/.meta/gds/shell-binstub-patterns.g.md
* Current exe directory: dev-tools/exe/
* Existing patterns: bin/test, bin/gc, bin/setup
* User requirement: Simple bin/sh scripts with directory context and argument delegation