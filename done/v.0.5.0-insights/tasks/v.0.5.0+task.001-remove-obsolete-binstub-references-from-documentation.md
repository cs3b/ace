---
id: v.0.5.0+task.001
status: done
priority: high
estimate: 1h
dependencies: []
---

# Remove Obsolete Binstub References from Documentation

## Behavioral Specification

### User Experience
- **Input**: Developers and AI agents reading documentation and templates
- **Process**: Navigate documentation to understand how to use CLI tools correctly
- **Output**: Accurate guidance on accessing tools via .ace/tools Ruby gem

### Expected Behavior
Users accessing documentation in .ace/handbook and .ace/tools will find accurate, up-to-date instructions for using CLI tools. All references to obsolete binstub patterns (bin/gc, bin/tn, bin/tnid, etc.) will be removed and replaced with correct tool access methods via the .ace/tools/exe/ directory or installed gem commands.

### Interface Contract
```bash
# Obsolete patterns to remove:
bin/gc           # Should not appear in documentation
bin/tn           # Should not appear in documentation  
bin/tnid         # Should not appear in documentation
./bin/[tool]     # Should not appear in documentation

# Correct patterns to use:
.ace/tools/exe/git-commit      # When working in submodule
.ace/tools/exe/task-manager     # When working in submodule
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
- [ ] **Behavioral Outcome 1**: All documentation correctly references tools via .ace/tools/exe/ or gem commands
- [ ] **User Experience Goal 2**: Zero confusion about how to access CLI tools
- [ ] **System Performance 3**: Documentation audit shows no active binstub references

### Validation Questions
- [ ] **Requirement Clarity**: Should ADRs preserve historical binstub references with annotations?
- [ ] **Edge Case Handling**: How should we handle example outputs that show old tool invocations?
- [ ] **User Experience**: Should we add a migration guide for users familiar with old binstub patterns?
- [ ] **Success Definition**: What constitutes "complete" removal - 100% or with documented exceptions?

## Objective

Remove all obsolete binstub references from documentation to ensure users have accurate, up-to-date guidance on accessing CLI tools through the .ace/tools Ruby gem.

## Scope of Work

- **User Experience Scope**: Documentation readers finding accurate tool usage instructions
- **System Behavior Scope**: All documentation files correctly referencing tool access methods
- **Interface Scope**: Clear guidance on .ace/tools/exe/ paths and gem command usage

### Deliverables

#### Behavioral Specifications
- Comprehensive audit of binstub references across .ace/handbook and .ace/tools
- Updated documentation with correct tool access patterns
- Clear migration guidance for users familiar with old patterns

#### Validation Artifacts
- Audit report showing all files checked and updated
- Grep/search results confirming no remaining binstub references
- User acceptance that documentation is clear and accurate

## Technical Approach

### Audit Results (CORRECTED)

Comprehensive search using ripgrep reveals **extensive binstub references still present**:
- **dev-handbook/**: **200+ references found** requiring updates
- **dev-tools/**: No binstub references found (already clean)
- **docs/**: No binstub references found (already clean)
- **dev-taskflow/**: Only historical references in done/ folders and idea files

### Current State Analysis

**The documentation requires significant cleanup**. Found references include:
- `bin/test`: 77 occurrences
- `bin/lint`: 24 occurrences
- `bin/tn`: 18 occurrences
- `bin/tnid`: 14 occurrences
- `bin/tr`, `bin/gc`, `bin/gs`, `bin/gl`, `bin/rc`: Multiple occurrences each

See `.ace/taskflow/current/v.0.5.0-insights/researches/binstub-audit-results.md` for complete audit.

## File Modifications

### Files Requiring Updates

#### High Priority - Workflow Instructions (10 files)
- .ace/handbook/workflow-instructions/work-on-task.wf.md
- .ace/handbook/workflow-instructions/initialize-project-structure.wf.md
- .ace/handbook/workflow-instructions/fix-tests.wf.md
- .ace/handbook/workflow-instructions/rebase-against.wf.md
- .ace/handbook/workflow-instructions/save-session-context.wf.md
- .ace/handbook/workflow-instructions/plan-task.wf.md
- .ace/handbook/workflow-instructions/draft-release.wf.md
- .ace/handbook/workflow-instructions/publish-release.wf.md
- .ace/handbook/workflow-instructions/improve-code-coverage.wf.md
- .ace/handbook/workflow-instructions/update-blueprint.wf.md

#### Critical - AI Agent Guide (1 file)
- .ace/handbook/guides/ai-agent-integration.g.md (Lines 31, 34, 37, 40-41, 44-45, 67-68)

#### Important - Development Guides (7 files)
- .ace/handbook/guides/project-management.g.md
- .ace/handbook/guides/version-control-system-git.g.md
- .ace/handbook/guides/task-definition.g.md
- .ace/handbook/guides/embedded-testing-guide.g.md
- .ace/handbook/guides/testing.g.md
- .ace/handbook/guides/release-publish.g.md
- .ace/handbook/guides/testing/test-maintenance.md

#### Templates (10+ files)
- .ace/handbook/templates/release-v.0.0.0/*.task.template.md (5 files)
- .ace/handbook/templates/project-docs/architecture.template.md
- .ace/handbook/templates/project-docs/blueprint.template.md
- .ace/handbook/templates/task-management/task.pending.template.md
- .ace/handbook/templates/binstubs/*.template.md

## Implementation Plan

### Planning Steps

* [x] **System Analysis**: Analyzed entire codebase for binstub references
  > TEST: Comprehensive Search
  > Type: Pre-condition Check
  > Assert: All repositories searched for binstub patterns
  > Command: rg "bin/(tn|gc|tnid|rc|tr|test|lint)" .ace/handbook --type md

* [x] **Current State Assessment**: Found 200+ references requiring updates
  > TEST: Documentation Audit
  > Type: Discovery Check
  > Assert: All binstub references identified and documented
  > Command: rg "bin/(tn|gc|tnid|rc|tr|test|lint|gs|gl|tal)" .ace/handbook --type md -n -o | wc -l

### Execution Steps

- [x] **Update Critical AI Agent Guide**: Fix .ace/handbook/guides/ai-agent-integration.g.md
  > TEST: AI Guide Validation
  > Type: Content Check
  > Assert: No binstub references remain in AI agent guide
  > Command: search "bin/(tn|gc|tnid)" --content -r .ace/handbook -g "ai-agent*.md"
  > Result: No results found ✅

- [x] **Update Workflow Instructions**: Fix all 26 workflow instruction files
  > TEST: Workflow Validation
  > Type: Content Check
  > Assert: All workflows use .ace/tools commands
  > Command: search "bin/(tn|gc|tnid)" --content -r .ace/handbook -g "**/workflow-instructions/*.md"
  > Result: No results found ✅

- [x] **Update Development Guides**: Fix 7 guide files
  > TEST: Guide Validation
  > Type: Content Check
  > Assert: All guides reference correct tool paths
  > Command: search "bin/(tn|gc|tnid)" --content -r .ace/handbook -g "**/*.g.md"
  > Result: No results found ✅

- [x] **Update Templates**: Fix all template files
  > TEST: Template Validation
  > Type: Content Check
  > Assert: Templates use correct tool references
  > Command: search "bin/(tn|gc|tnid)" --content -r .ace/handbook -g "**/*.template.md"
  > Result: No results found ✅

- [x] **Final Verification**: Confirm all references removed
  > TEST: Complete Cleanup Validation
  > Type: Final Check
  > Assert: Zero binstub references in .ace/handbook
  > Command: search "bin/(tn|gc|tnid|rc|tr|test|lint|gs|gl|tal)" --content -r .ace/handbook
  > Result: No results found ✅

## Risk Assessment

### Technical Risks
- **Risk:** Breaking existing workflows during mass replacement
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Careful review of each replacement, test workflows after changes
  - **Rollback:** Git revert if issues discovered

### Integration Risks
- **Risk:** Inconsistent replacement patterns
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Use consistent replacement mapping table
  - **Monitoring:** Run verification searches after each batch

## Acceptance Criteria

### Behavioral Requirement Fulfillment
- [x] **User Experience Delivery**: Documentation provides accurate tool access guidance
- [x] **Interface Contract Compliance**: All docs use .ace/tools commands (task-manager, release-manager, etc.)
- [x] **System Behavior Validation**: No confusing binstub references found

### Implementation Quality Assurance
- [x] **Audit Complete**: Comprehensive search of all repositories performed using new search tool
- [x] **Updates Complete**: All identified files updated with correct references
- [x] **Final Verification**: Zero binstub references in active documentation
- [x] **No Regressions**: Documentation structure and formatting preserved

## Out of Scope

- ❌ **Implementation Details**: Specific file structures or code organization decisions
- ❌ **Technology Decisions**: Tool selections or technical architecture choices
- ❌ **Performance Optimization**: Speed improvements to documentation access
- ❌ **Future Enhancements**: Additional documentation features beyond binstub removal

## References

- Related ideas-manager output: .ace/taskflow/backlog/ideas/20250809-0840-tool-guide-updates.md
- Current tools documentation: docs/tools.md (verified clean)
- Dev-tools documentation: .ace/tools/docs/tools.md (verified clean)

## Replacement Mapping Table

| Old Reference | New Reference (when in submodule) | New Reference (gem installed) |
|--------------|-----------------------------------|------------------------------|
| `bin/tn` | `.ace/tools/exe/task-manager next` | `task-manager next` |
| `bin/tnid` | `.ace/tools/exe/task-manager generate-id VERSION` | `task-manager generate-id VERSION` |
| `bin/tal` | `.ace/tools/exe/task-manager list` | `task-manager list` |
| `bin/tr` | `.ace/tools/exe/task-manager recent` | `task-manager recent` |
| `bin/gc` | `.ace/tools/exe/git-commit` | `git-commit` |
| `bin/gs` | `.ace/tools/exe/git-status` | `git-status` |
| `bin/gl` | `.ace/tools/exe/git-log` | `git-log` |
| `bin/rc` | `.ace/tools/exe/release-manager current` | `release-manager current` |
| `bin/test` | *Project-specific test command* | *Project-specific* |
| `bin/lint` | *Project-specific lint command* | *Project-specific* |

## Task Completion Summary

**✅ TASK COMPLETED** - All binstub references have been successfully removed from documentation.

### What Was Done
1. **Used new search tool** to comprehensively find all binstub references
2. **Updated 40+ files** across dev-handbook:
   - AI Agent Integration Guide
   - Project Management Guide  
   - Task Definition Guide
   - 26 Workflow Instruction files
   - 10+ Template files
3. **Replaced all references** with correct .ace/tools commands
4. **Verified cleanup** - Zero binstub references remain in active documentation

### Key Achievement
The new `search` tool proved invaluable for this task, enabling efficient discovery and verification of all references across the codebase. All documentation now correctly guides users to use .ace/tools commands that are available in PATH.