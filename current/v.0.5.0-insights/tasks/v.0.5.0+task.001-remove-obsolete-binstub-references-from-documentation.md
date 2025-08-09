---
id: v.0.5.0+task.001
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Remove Obsolete Binstub References from Documentation

## Behavioral Specification

### User Experience
- **Input**: Developers and AI agents reading documentation and templates
- **Process**: Navigate documentation to understand how to use CLI tools correctly
- **Output**: Accurate guidance on accessing tools via dev-tools Ruby gem

### Expected Behavior
Users accessing documentation in dev-handbook and dev-tools will find accurate, up-to-date instructions for using CLI tools. All references to obsolete binstub patterns (bin/gc, bin/tn, bin/tnid, etc.) will be removed and replaced with correct tool access methods via the dev-tools/exe/ directory or installed gem commands.

### Interface Contract
```bash
# Obsolete patterns to remove:
bin/gc           # Should not appear in documentation
bin/tn           # Should not appear in documentation  
bin/tnid         # Should not appear in documentation
./bin/[tool]     # Should not appear in documentation

# Correct patterns to use:
dev-tools/exe/git-commit      # When working in submodule
dev-tools/exe/task-manager     # When working in submodule
git-commit                     # When gem is installed
task-manager                   # When gem is installed
```

**Error Handling:**
- Missing tool references: Documentation should guide users to install the gem or work within the submodule
- Path errors: Clear instructions on correct tool paths

**Edge Cases:**
- Historical references in ADRs: May be preserved with clear annotations
- Example outputs: May show old patterns if documenting migration

### Success Criteria
- [ ] **Behavioral Outcome 1**: All documentation correctly references tools via dev-tools/exe/ or gem commands
- [ ] **User Experience Goal 2**: Zero confusion about how to access CLI tools
- [ ] **System Performance 3**: Documentation audit shows no active binstub references

### Validation Questions
- [ ] **Requirement Clarity**: Should ADRs preserve historical binstub references with annotations?
- [ ] **Edge Case Handling**: How should we handle example outputs that show old tool invocations?
- [ ] **User Experience**: Should we add a migration guide for users familiar with old binstub patterns?
- [ ] **Success Definition**: What constitutes "complete" removal - 100% or with documented exceptions?

## Objective

Remove all obsolete binstub references from documentation to ensure users have accurate, up-to-date guidance on accessing CLI tools through the dev-tools Ruby gem.

## Scope of Work

- **User Experience Scope**: Documentation readers finding accurate tool usage instructions
- **System Behavior Scope**: All documentation files correctly referencing tool access methods
- **Interface Scope**: Clear guidance on dev-tools/exe/ paths and gem command usage

### Deliverables

#### Behavioral Specifications
- Comprehensive audit of binstub references across dev-handbook and dev-tools
- Updated documentation with correct tool access patterns
- Clear migration guidance for users familiar with old patterns

#### Validation Artifacts
- Audit report showing all files checked and updated
- Grep/search results confirming no remaining binstub references
- User acceptance that documentation is clear and accurate

## Out of Scope

- ❌ **Implementation Details**: Specific file structures or code organization decisions
- ❌ **Technology Decisions**: Tool selections or technical architecture choices
- ❌ **Performance Optimization**: Speed improvements to documentation access
- ❌ **Future Enhancements**: Additional documentation features beyond binstub removal

## References

- Related ideas-manager output: dev-taskflow/backlog/ideas/20250809-0840-tool-guide-updates.md
- Current tools documentation: docs/tools.md
- Dev-tools documentation: dev-tools/docs/tools.md