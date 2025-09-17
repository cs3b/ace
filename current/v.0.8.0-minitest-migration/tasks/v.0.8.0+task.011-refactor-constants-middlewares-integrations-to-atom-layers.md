---
id: v.0.8.0+task.011
status: done
priority: high
estimate: 6h
dependencies: [v.0.8.0+task.001]
---

# Refactor Constants/Middlewares/Integrations to ATOM Layers

## Objective

Clean up the codebase architecture by properly decomposing constants, middlewares, and integrations into the correct ATOM layers before migrating tests. This ensures clean architectural boundaries and prevents test migration confusion.

## Scope of Work

- Analyze current lib/ace_tools structure for misplaced components
- Move constants to appropriate atoms
- Decompose middlewares into molecules/organisms based on complexity
- Refactor integrations: move CLI parts to ecosystems, decompose rest to proper layers
- Update all require statements and dependencies
- Ensure ATOM boundaries are clean for test migration

### Deliverables

#### Analyze
- lib/ace_tools/constants/ - determine proper placement
- lib/ace_tools/middlewares/ - decompose by responsibility
- lib/ace_tools/integrations/ - separate CLI from other concerns

#### Refactor
- Move constants to atoms/ where they're used
- Decompose middlewares to molecules/organisms based on complexity
- Move CLI integrations to ecosystems/
- Move other integrations to appropriate layers

#### Update
- All require statements in affected files
- Module namespaces and dependencies
- Documentation and comments

## Phases

1. Analysis - Map current components to proper ATOM layers
2. Planning - Design refactoring strategy with minimal breaking changes
3. Execution - Move files and update references
4. Validation - Ensure everything still works

## Technical Approach

### Architecture Pattern
- [x] Follow ATOM architecture strictly: Atoms → Molecules → Organisms → Ecosystems
- [x] Constants belong in atoms where they're used
- [x] Middlewares decompose based on responsibility complexity
- [x] CLI integrations belong in ecosystems

### Migration Strategy
- [x] Incremental moves with git tracking
- [x] Update require statements immediately after moves
- [x] Test each move to prevent breakage
- [x] Maintain backward compatibility where possible

## Implementation Plan

### Planning Steps

* [x] **Component Analysis**: Analyze lib/ace_tools/constants/, middlewares/, integrations/
  > TEST: Analysis Complete
  > Type: File Inventory
  > Assert: All components categorized by proper ATOM layer
  > Command: find lib/ace_tools/{constants,middlewares,integrations} -name "*.rb" | wc -l

* [x] **Dependency Mapping**: Map require statements and usage patterns
  > TEST: Dependency Map
  > Type: Usage Analysis
  > Assert: All dependencies and usage patterns documented
  > Command: grep -r "require.*constants\|middlewares\|integrations" lib/

* [x] **Refactoring Strategy**: Plan minimal-breakage migration approach
* [x] **Testing Strategy**: Plan validation after each move

### Execution Steps

- [x] **Move Constants**: Relocate constants to appropriate atoms
  > TEST: Constants Moved
  > Type: File Structure Check
  > Assert: No lib/ace_tools/constants/ directory exists
  > Command: test ! -d lib/ace_tools/constants && echo "Constants moved"

- [x] **Decompose Middlewares**: Split middlewares by ATOM layer
  > TEST: Middlewares Decomposed
  > Type: File Structure Check
  > Assert: Middlewares properly distributed to molecules/organisms
  > Command: test ! -d lib/ace_tools/middlewares && echo "Middlewares decomposed"

- [x] **Refactor Integrations**: Move CLI to ecosystems, others to proper layers
  > TEST: Integrations Refactored
  > Type: File Structure Check
  > Assert: CLI integrations in ecosystems, others properly placed
  > Command: test ! -d lib/ace_tools/integrations && echo "Integrations refactored"

- [x] **Update Dependencies**: Fix all require statements and module references
  > TEST: Dependencies Updated
  > Type: Ruby Syntax Check
  > Assert: All files load without require errors
  > Command: cd .ace/tools && ruby -c lib/ace_tools.rb

- [x] **Validate Structure**: Ensure clean ATOM boundaries
  > TEST: Clean ATOM Structure
  > Type: Architecture Validation
  > Assert: Only atoms/, molecules/, organisms/, ecosystems/, models/, cli/ remain
  > Command: ls lib/ace_tools/ | grep -v -E "(atoms|molecules|organisms|ecosystems|models|cli|\.rb)" | wc -l

## File Modifications

### Delete
- lib/ace_tools/constants/ (after moving contents)
- lib/ace_tools/middlewares/ (after decomposing)
- lib/ace_tools/integrations/ (after refactoring)

### Move/Create
- Constants → lib/ace_tools/atoms/[domain]/
- Simple middlewares → lib/ace_tools/molecules/
- Complex middlewares → lib/ace_tools/organisms/
- CLI integrations → lib/ace_tools/ecosystems/
- Other integrations → appropriate layers

### Modify
- All files with require statements for moved components
- lib/ace_tools.rb - update autoload structure
- Module namespaces and class definitions

## Risk Assessment

### Technical Risks
- **Risk:** Breaking require dependencies during moves
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Test after each move, update requires immediately
  - **Rollback:** Git revert specific commits

### Integration Risks
- **Risk:** CLI commands stop working after refactoring
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Test CLI commands after each integration move
  - **Monitoring:** Run bin/test help after changes

## Acceptance Criteria

### Clean Architecture
- [x] **ATOM Boundaries**: Only proper ATOM directories remain in lib/ace_tools/
- [x] **No Orphaned Directories**: constants/, middlewares/, integrations/ removed
- [x] **Proper Placement**: All components in architecturally correct layers

### Functional Integrity
- [x] **Code Loads**: All Ruby files load without require errors
- [x] **CLI Works**: All CLI commands still function
- [x] **Tests Pass**: Existing tests (if any) still pass

### Ready for Test Migration
- [x] **Clear Structure**: Clean ATOM layers ready for systematic test migration
- [x] **No Confusion**: No architectural ambiguity for next tasks
- [x] **Documentation**: Changes documented for migration tasks

## Out of Scope

- ❌ Writing new tests (separate migration tasks)
- ❌ Major functionality changes
- ❌ Performance optimization beyond basic cleanup
- ❌ API changes (maintain backward compatibility)

## References

- ATOM Architecture documentation
- Current lib/ace_tools structure
- Existing require dependencies