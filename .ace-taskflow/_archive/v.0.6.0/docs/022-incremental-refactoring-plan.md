# Incremental Refactoring Plan for ClaudeCommandsInstaller

## Overview

This plan outlines a safe, incremental approach to refactoring ClaudeCommandsInstaller to ATOM architecture while maintaining backward compatibility and minimizing risk.

## Refactoring Phases

### Phase 1: Extract Models (Low Risk)
Extract pure data structures without changing behavior.

**Steps:**
1. Create model classes in `lib/coding_agent_tools/models/`
2. Keep original hash structures in the main class
3. Add conversion methods to/from models
4. Run tests after each model extraction

**Order:**
1. `InstallationStats` - Simple counter object
2. `InstallationOptions` - Configuration object
3. `InstallationResult` - Result wrapper
4. `CommandMetadata` - Metadata structure
5. `FileOperation` - Operation descriptor

**Risk Mitigation:**
- Models are pure data with no behavior
- Original code continues to work with hashes
- Tests validate no behavior changes

### Phase 2: Extract Atoms (Low Risk)
Extract pure utility functions that have no dependencies.

**Steps:**
1. Create atom classes in `lib/coding_agent_tools/atoms/`
2. Extract utility methods as class methods
3. Update main class to delegate to atoms
4. Test each atom in isolation

**Order:**
1. `TimestampGenerator` - Extract timestamp formatting
2. `PathSanitizer` - Extract path validation logic

**Risk Mitigation:**
- Atoms are stateless pure functions
- Easy to test in isolation
- Can fall back to original methods if issues arise

### Phase 3: Extract Molecules (Medium Risk)
Extract focused operations that compose atoms and models.

**Steps:**
1. Create molecule classes with dependency injection
2. Extract method logic into molecule methods
3. Update main class to use molecules
4. Test molecules with mocked dependencies

**Order:**
1. `ProjectRootFinder` - Standalone operation
2. `CommandTemplateRenderer` - No dependencies
3. `StatisticsCollector` - Works with models
4. `SourceDirectoryValidator` - Path validation
5. `MetadataInjector` - YAML operations
6. `FileOperationExecutor` - File operations
7. `BackupCreator` - Backup logic

**Risk Mitigation:**
- Test each molecule thoroughly before integration
- Keep original methods as fallback during transition
- Use feature flags if needed for gradual rollout

### Phase 4: Extract Organisms (Medium Risk)
Extract business logic that orchestrates molecules.

**Steps:**
1. Create organism classes with injected dependencies
2. Move business logic from main class
3. Test organisms with integration tests
4. Ensure backward compatibility

**Order:**
1. `CommandDiscoverer` - Directory scanning logic
2. `AgentInstaller` - Agent installation logic
3. `WorkflowCommandGenerator` - Workflow processing
4. `CommandInstaller` - Command installation logic
5. `ClaudeCommandsOrchestrator` - Main orchestration

**Risk Mitigation:**
- Build organisms incrementally
- Test with real file system operations
- Maintain integration test coverage

### Phase 5: Refactor Main Class (Low Risk)
Transform the main class into a thin wrapper.

**Steps:**
1. Replace internal logic with orchestrator delegation
2. Maintain public API compatibility
3. Add factory for dependency setup
4. Update CLI integration

**Code Structure:**
```ruby
class ClaudeCommandsInstaller
  def initialize(project_root = nil, options = {})
    @orchestrator = build_orchestrator(project_root, options)
  end

  def run
    @orchestrator.run
  end

  private

  def build_orchestrator(project_root, options)
    # Build complete dependency graph
    # Return configured orchestrator
  end
end
```

### Phase 6: Comprehensive Testing (Low Risk)
Add complete test coverage for all components.

**Steps:**
1. Unit tests for each atom/molecule/organism
2. Integration tests for complete workflows
3. Performance benchmarks
4. Regression tests against original implementation

## Rollback Strategy

Each phase can be rolled back independently:

1. **Model Rollback**: Remove model usage, revert to hashes
2. **Atom Rollback**: Revert to inline utility methods
3. **Molecule Rollback**: Restore original method implementations
4. **Organism Rollback**: Revert to original business logic
5. **Main Class Rollback**: Git revert to previous version

## Testing Checkpoints

After each phase:
1. Run existing test suite
2. Run manual installation test
3. Compare output with original implementation
4. Check performance metrics

## Success Metrics

- All existing tests pass
- No performance regression
- Code coverage > 90%
- Clean separation of concerns
- Improved maintainability

## Timeline Estimate

- Phase 1 (Models): 30 minutes
- Phase 2 (Atoms): 30 minutes
- Phase 3 (Molecules): 2 hours
- Phase 4 (Organisms): 2 hours
- Phase 5 (Main Class): 30 minutes
- Phase 6 (Testing): 1 hour

Total: ~6 hours (matches task estimate)