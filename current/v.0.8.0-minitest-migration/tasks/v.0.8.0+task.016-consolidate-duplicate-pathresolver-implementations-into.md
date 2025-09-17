---
id: v.0.8.0+task.016
status: pending
priority: high
estimate: 6h
dependencies: []
---

# Consolidate duplicate PathResolver implementations into single ATOM

## Behavioral Specification

### User Experience
- **Input**: Developers using path resolution functionality across ace_tools codebase
- **Process**: Seamless path resolution with consistent behavior across all components
- **Output**: Single, reliable PathResolver Atom providing unified path resolution functionality

### Expected Behavior

The system should provide a single, centralized PathResolver Atom that handles all path resolution needs across the ace_tools codebase. This eliminates the current maintenance burden of four duplicate implementations and ensures consistent behavior. All higher-level components (Molecules, Organisms) should use the same foundational path resolution logic, following proper ATOM architecture principles.

### Interface Contract

```ruby
# Primary PathResolver Atom Interface
AceTools::Atoms::PathResolver.resolve(path, options = {})
# Returns: Resolved path string
# Options: { base_path: String, validate: Boolean, normalize: Boolean }

# Legacy compatibility methods (during transition)
AceTools::Atoms::PathResolver.normalize_path(path)
AceTools::Atoms::PathResolver.validate_path(path)
AceTools::Atoms::PathResolver.resolve_relative_path(path, base_path = nil)

# Error handling:
# - InvalidPathError: When path validation fails
# - PathResolutionError: When path cannot be resolved
# - FileNotFoundError: When resolved path doesn't exist (if validation requested)
```

**Error Handling:**
- Invalid path formats: Raise InvalidPathError with descriptive message
- Unresolvable paths: Raise PathResolutionError with context
- Missing files (when validation enabled): Raise FileNotFoundError

**Edge Cases:**
- Relative paths without base_path: Use current working directory
- Symbolic links: Follow links to final destination
- Path normalization: Handle '../' and './' consistently

### Success Criteria

- [ ] **Single Source of Truth**: Only one PathResolver implementation exists in the codebase
- [ ] **Behavioral Consistency**: All path resolution behaves identically across components
- [ ] **ATOM Architecture Compliance**: PathResolver is properly positioned as foundational Atom
- [ ] **Zero Regression**: All existing functionality preserved during consolidation
- [ ] **Maintenance Efficiency**: Single location for path resolution bug fixes and enhancements

### Validation Questions

- [ ] **Complex Heuristics**: Should overly complex path resolution logic be simplified or moved to separate PathHeuristics Molecule?
- [ ] **Performance Impact**: What are the performance implications of consolidating all path resolution through single Atom?
- [ ] **Backward Compatibility**: How long should legacy method names be maintained during transition?
- [ ] **Error Handling**: Should error handling be standardized across all path operations?

## Objective

Consolidate four duplicate PathResolver implementations into a single, robust Atom that provides consistent path resolution functionality across the entire ace_tools codebase. This eliminates maintenance burden, ensures behavioral consistency, and enforces proper ATOM architecture compliance with path resolution as a foundational capability.

## Scope of Work

- **Analysis**: Review all four PathResolver implementations to understand functionality differences
- **Consolidation**: Create unified PathResolver Atom with comprehensive functionality from all implementations
- **Migration**: Update all call sites to use the consolidated implementation
- **Cleanup**: Remove redundant PathResolver files and update architecture compliance
- **Validation**: Ensure no behavioral regressions and proper ATOM architecture adherence

### Deliverables

#### Create
- `lib/ace_tools/atoms/path_resolver.rb` - Single, comprehensive PathResolver Atom

#### Modify
- All files that reference the removed PathResolver implementations
- Update require statements and class references throughout codebase
- Test files that reference duplicate implementations

#### Delete
- `lib/ace_tools/atoms/code_quality/path_resolver.rb` - Duplicate implementation
- `lib/ace_tools/atoms/git/path_resolver.rb` - Duplicate implementation
- `lib/ace_tools/molecules/path/path_resolver.rb` - Misplaced Molecule (should be Atom)
- `lib/ace_tools/molecules/path_resolver.rb` - Duplicate implementation

## Phases

1. **Analysis Phase**: Audit all four PathResolver implementations and identify differences
2. **Design Phase**: Create unified PathResolver Atom design with comprehensive functionality
3. **Implementation Phase**: Create consolidated PathResolver and update call sites
4. **Migration Phase**: Remove duplicate implementations and verify no regressions
5. **Validation Phase**: Ensure ATOM architecture compliance and behavioral consistency

## Technical Approach

### Architecture Pattern
- **ATOM Architecture**: PathResolver positioned as foundational Atom (not Molecule)
- **Single Responsibility**: One class handling all path resolution concerns
- **Composition over Inheritance**: Unified interface with optional behavior flags
- **Integration**: Foundation layer for all higher-level path operations

### Technology Stack
- **Ruby Standard Library**: File, Pathname, Dir for core path operations
- **No External Dependencies**: Keep PathResolver lightweight and self-contained
- **Ruby 3.0+ Features**: Leverage modern Ruby capabilities for clean implementation
- **Existing Patterns**: Follow established ace_tools coding conventions

### Implementation Strategy
- **Analysis-First**: Understand all four implementations before consolidation
- **Incremental Migration**: Update call sites gradually to prevent breakage
- **Backward Compatibility**: Maintain legacy method names during transition period
- **Test-Driven**: Ensure comprehensive test coverage for consolidated implementation

## Tool Selection

| Criteria | Ruby Stdlib | External Gems | Custom Utils | Selected |
|----------|-------------|---------------|--------------|----------|
| Performance | Good | Variable | Optimized | Ruby Stdlib |
| Integration | Excellent | Complex | Simple | Ruby Stdlib |
| Maintenance | Low | High | Medium | Ruby Stdlib |
| Security | High | Variable | High | Ruby Stdlib |
| Learning Curve | Low | Variable | Low | Ruby Stdlib |

**Selection Rationale:** Use Ruby standard library (File, Pathname, Dir) for maximum compatibility and minimal dependencies. This ensures the PathResolver Atom remains lightweight and doesn't introduce external dependency risks.

### Dependencies
- **No New Dependencies**: Consolidation uses only Ruby standard library
- **Ruby Version**: Compatible with Ruby 3.0+ (current project requirement)
- **Internal Dependencies**: May reference other ace_tools Atoms if needed

## File Modifications

### Create
- `lib/ace_tools/atoms/path_resolver.rb`
  - Purpose: Single, comprehensive PathResolver Atom implementation
  - Key components: Unified interface, path normalization, validation, relative resolution
  - Dependencies: Ruby standard library (File, Pathname, Dir)

### Modify
- **All files requiring removed PathResolvers** (identified via grep search)
  - Changes: Update require statements to point to unified PathResolver
  - Impact: Behavioral consistency across all path resolution operations
  - Integration points: Maintain existing method signatures during transition

- **Test files** for PathResolver functionality
  - Changes: Consolidate tests into single comprehensive test suite
  - Impact: Better test coverage and unified test approach
  - Integration points: Verify all existing functionality preserved

### Delete
- `lib/ace_tools/atoms/code_quality/path_resolver.rb`
  - Reason: Duplicate implementation with basic functionality subset
  - Dependencies: Code quality tools that import this implementation
  - Migration strategy: Update imports to use unified PathResolver

- `lib/ace_tools/atoms/git/path_resolver.rb`
  - Reason: Contains overly complex heuristics that should be simplified
  - Dependencies: Git-related tools and operations
  - Migration strategy: Migrate useful functionality to unified implementation

- `lib/ace_tools/molecules/path/path_resolver.rb`
  - Reason: Architectural violation - should be Atom, not Molecule
  - Dependencies: Path-related operations that expect Molecule interface
  - Migration strategy: Move to proper Atom layer location

- `lib/ace_tools/molecules/path_resolver.rb`
  - Reason: Duplicate general implementation, violates ATOM architecture
  - Dependencies: General path operations throughout codebase
  - Migration strategy: Update all imports to use unified Atom implementation

## Implementation Plan

<!-- This section details the specific steps required to implement the behavioral requirements -->
<!-- Clear distinction between planning/analysis activities and concrete implementation work -->

### Planning Steps

* [ ] **Comprehensive Code Analysis**: Identify all four PathResolver implementations and their differences
  > TEST: Implementation Discovery
  > Type: Code Analysis
  > Assert: All PathResolver files identified with functionality mapping
  > Command: find .ace/tools -name "*path_resolver*" -type f | wc -l # Should find 4 files

* [ ] **Call Site Analysis**: Find all files that import/use the duplicate PathResolvers
  > TEST: Usage Mapping Complete
  > Type: Dependency Analysis
  > Assert: All import statements and usage patterns documented
  > Command: grep -r "path_resolver" .ace/tools --include="*.rb" | wc -l # Document count

* [ ] **Functionality Comparison**: Analyze differences between the four implementations
  > TEST: Feature Matrix Complete
  > Type: Functional Analysis
  > Assert: All unique functionality identified and categorized
  > Command: diff -u path_resolver_1.rb path_resolver_2.rb # Compare implementations

* [ ] **Unified Interface Design**: Design consolidated PathResolver API
  > TEST: Interface Design Validation
  > Type: API Design Review
  > Assert: Unified interface covers all existing functionality
  > Command: ruby -c lib/ace_tools/atoms/path_resolver.rb # Syntax validation

* [ ] **Migration Strategy Planning**: Plan step-by-step migration approach
  > TEST: Migration Plan Validation
  > Type: Strategy Review
  > Assert: Migration plan minimizes risk of breaking changes
  > Command: echo "Migration plan documented and validated"

### Execution Steps

- [ ] **Create Unified PathResolver Atom**: Implement consolidated path resolution functionality
  > TEST: PathResolver Creation
  > Type: File Creation Validation
  > Assert: PathResolver Atom exists with all required methods
  > Command: test -f lib/ace_tools/atoms/path_resolver.rb && ruby -c lib/ace_tools/atoms/path_resolver.rb

- [ ] **Implement Core Path Resolution**: Add primary path resolution methods with unified interface
  > TEST: Core Methods Functional
  > Type: Unit Test Validation
  > Assert: resolve(), normalize_path(), validate_path() methods work correctly
  > Command: ruby -e "require_relative 'lib/ace_tools/atoms/path_resolver'; puts AceTools::Atoms::PathResolver.resolve('.')"

- [ ] **Add Backward Compatibility Methods**: Implement legacy method signatures for smooth transition
  > TEST: Legacy Interface Compatibility
  > Type: Compatibility Validation
  > Assert: All legacy method calls continue to work
  > Command: ruby -e "require_relative 'lib/ace_tools/atoms/path_resolver'; AceTools::Atoms::PathResolver.resolve_relative_path('.')"

- [ ] **Update Import Statements**: Replace all require statements to point to unified PathResolver
  > TEST: Import Updates Complete
  > Type: Import Validation
  > Assert: No broken imports, all files load correctly
  > Command: find .ace/tools -name "*.rb" -exec ruby -c {} \; | grep -c "Syntax OK"

- [ ] **Remove Duplicate Implementations**: Delete the four redundant PathResolver files
  > TEST: Duplicate Removal Verification
  > Type: Cleanup Validation
  > Assert: Only unified PathResolver remains in codebase
  > Command: find .ace/tools -name "*path_resolver*" -type f | wc -l # Should be 1

- [ ] **Run Comprehensive Test Suite**: Verify no regressions in path resolution functionality
  > TEST: Full Regression Testing
  > Type: End-to-End Validation
  > Assert: All existing path resolution functionality preserved
  > Command: cd .ace/tools && ruby -Ilib -e "Dir['test/**/*path*test*.rb'].each { |f| require_relative f }"

## Risk Assessment

### Technical Risks
- **Risk:** Behavioral differences between implementations cause regressions
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Thorough analysis of all four implementations before consolidation
  - **Rollback:** Git revert to restore original implementations if critical failures detected

- **Risk:** Complex path resolution heuristics break edge cases
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Comprehensive test suite covering all edge cases from original implementations
  - **Rollback:** Revert to individual implementations and re-plan simplification

### Integration Risks
- **Risk:** Import statement updates miss some files causing broken dependencies
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Systematic grep-based search for all path_resolver imports
  - **Monitoring:** Ruby syntax checks on all files after import updates

- **Risk:** ATOM architecture violation if PathResolver becomes too complex
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Keep PathResolver focused on core path operations, extract complex logic to separate Molecules
  - **Monitoring:** Code review for single responsibility adherence

### Performance Risks
- **Risk:** Unified implementation slower than specialized implementations
  - **Mitigation:** Benchmark path resolution performance before and after consolidation
  - **Monitoring:** Path resolution execution time in critical code paths
  - **Thresholds:** No more than 10% performance degradation acceptable

## Acceptance Criteria

<!-- Define conditions that signify successful implementation of behavioral requirements -->
<!-- These should directly map to success criteria from the behavioral specification -->
<!-- Focus on verifying that behavioral requirements are met, not just implementation completed -->

### Behavioral Requirement Fulfillment
- [ ] **Single Source of Truth**: Only one PathResolver implementation exists in ace_tools codebase
- [ ] **Behavioral Consistency**: All path resolution operations behave identically across components
- [ ] **ATOM Architecture Compliance**: PathResolver properly positioned as foundational Atom, not Molecule

### Implementation Quality Assurance
- [ ] **Zero Regression**: All existing path resolution functionality preserved and working
- [ ] **Test Coverage**: Comprehensive tests cover all consolidated functionality
- [ ] **Code Quality**: PathResolver Atom follows ace_tools coding standards and ATOM principles
- [ ] **Performance Maintained**: No significant performance degradation from consolidation

### Documentation and Validation
- [ ] **Architecture Documentation**: PathResolver's role as foundational Atom clearly documented
- [ ] **Migration Documentation**: All import changes and removed files properly documented
- [ ] **API Documentation**: Unified interface clearly documented with examples

## Out of Scope

- ❌ **Performance Optimization**: Focus on consolidation, not performance improvements
- ❌ **New Path Features**: No new path resolution capabilities beyond existing functionality
- ❌ **Complex Path Heuristics**: Simplify overly complex logic, don't enhance it
- ❌ **External Dependencies**: Keep implementation using only Ruby standard library
- ❌ **Legacy Method Removal**: Maintain backward compatibility during initial consolidation

## References

- **Source**: Comprehensive gpro code review (541,058 tokens, 332 Ruby files analyzed)
- **Architecture Analysis**: ATOM architecture compliance assessment
- **Code Review Findings**: Identified as "significant maintenance burden" requiring immediate consolidation
- **Files Identified**:
  - `lib/ace_tools/atoms/code_quality/path_resolver.rb`
  - `lib/ace_tools/atoms/git/path_resolver.rb`
  - `lib/ace_tools/molecules/path/path_resolver.rb`
  - `lib/ace_tools/molecules/path_resolver.rb`
- **Impact Assessment**: Critical blocking issue for ATOM architecture compliance