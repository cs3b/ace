---
id: v.0.5.0+task.011
status: done
priority: low
estimate: 3h
dependencies: ["v.0.5.0+task.006"]
---

# Review and update multi-repository references

## Summary

Audit the codebase to find and update any remaining references to multi-repository functionality that should be removed or updated after the search tool simplification.

## Context

Following the search tool simplification work (task.006), the tool was streamlined to operate from a single project root instead of managing multiple repositories. However, there may be lingering references to the old multi-repository functionality in documentation, code comments, error messages, or configuration files.

These outdated references can confuse users and developers, and may indicate incomplete cleanup from the simplification effort. A comprehensive audit is needed to ensure consistency across the entire codebase.

## Behavioral Specification

### User Experience
- **Input**: User encounters documentation, error messages, or interface elements
- **Process**: All references accurately reflect current single-repository functionality
- **Output**: Consistent, up-to-date information that matches actual tool behavior

### Expected Behavior

All documentation, code comments, and user-facing messages should reflect the current simplified search tool architecture without references to obsolete multi-repository features.

Specifically:
1. **Documentation consistency** should reflect current tool capabilities
2. **Error messages** should reference correct functionality
3. **Code comments** should describe actual implementation
4. **Configuration examples** should show current usage patterns

### Interface Contract

```bash
# Old multi-repo references should be removed/updated:
# ❌ "Searching across repositories..."
# ❌ "Repository not found in registry..."
# ❌ "--repo flag to specify repository"

# Current single-project references should be accurate:
# ✅ "Searching project files..."
# ✅ "No files found matching pattern..."
# ✅ "--path flag to specify search directory"
```

### Success Criteria

- [x] Search for all multi-repo references in documentation
- [x] Update or remove outdated references in user-facing documentation
- [x] Review and update code comments to reflect current implementation
- [x] Verify no broken functionality due to outdated references
- [x] Update help text and error messages
- [x] Check configuration examples and templates
- [x] Ensure consistency across all documentation files
- [x] Validate that CLI help reflects current functionality

## Technical Details

### Search Strategy

**Documentation Files**
- `docs/**/*.md` - All documentation files
- `README.md` - Main project documentation
- `CHANGELOG.md` - Release notes and changes
- `*.md` files in root directory

**Code Files**
- `lib/**/*.rb` - Ruby implementation files
- `bin/*` - Executable scripts
- `spec/**/*.rb` - Test files
- Configuration files (YAML, JSON)

**Search Terms**
- "multi-repo", "multi repo", "multiple repositories"
- "repository registry", "repo registry"
- "cross-repo", "cross repo"
- "per-repository", "per repository" 
- "--repo", "repository flag"
- "repository selection", "repo selection"

### Reference Categories

**User Documentation**
- Feature descriptions mentioning multi-repo capability
- Usage examples with repository selection
- Configuration guides for repository management
- Troubleshooting guides for repository issues

**Code Comments**
- Implementation notes about repository handling
- Architecture comments about multi-repo design
- TODO items related to repository features
- Method documentation referencing repository parameters

**User Interface**
- Help text mentioning repository options
- Error messages about repository problems
- Command descriptions in CLI help
- Configuration option descriptions

**Tests and Examples**
- Test cases for repository functionality
- Example configurations with repository settings
- Mock data referencing multiple repositories
- Integration test scenarios

### Update Strategy

**Documentation Updates**
1. **Remove obsolete sections**: Delete content about multi-repo features
2. **Update examples**: Replace multi-repo examples with single-project ones
3. **Clarify scope**: Emphasize single-project, path-based searching
4. **Fix broken links**: Update any cross-references to removed content

**Code Updates**
1. **Comment cleanup**: Update comments to reflect current implementation
2. **Help text**: Update CLI help and error messages
3. **Configuration**: Remove obsolete configuration options
4. **Test cleanup**: Remove tests for non-existent functionality

## Implementation Approach

### Phase 1: Discovery and Cataloging
1. **Automated search**: Use grep/ripgrep to find all multi-repo references
2. **Manual review**: Examine search results to categorize by type and importance
3. **Impact assessment**: Determine which references need updating vs removal
4. **Priority classification**: Identify user-facing vs internal references

### Phase 2: Documentation Updates
1. **User documentation**: Update guides, READMEs, and help files
2. **API documentation**: Update method and class documentation
3. **Examples**: Replace obsolete examples with current usage patterns
4. **Cross-reference validation**: Ensure all links and references remain valid

### Phase 3: Code and Configuration Updates
1. **Code comments**: Update implementation comments and TODOs
2. **Error messages**: Update user-facing error and help text
3. **Configuration**: Remove obsolete configuration options
4. **Test cleanup**: Remove or update tests for removed functionality

### Phase 4: Validation and Testing
1. **Link checking**: Verify all documentation links work correctly
2. **Help text validation**: Test that CLI help matches actual functionality
3. **User testing**: Validate that documentation matches user experience
4. **Regression testing**: Ensure no functionality was broken by changes

## Risk Assessment

### Technical Risks
- **Risk:** Removing references may break documentation cross-references
  - **Probability:** Medium
  - **Impact:** Low
  - **Mitigation:** Careful link validation and cross-reference checking
  - **Testing:** Automated link checking in CI/CD pipeline

- **Risk:** May accidentally remove references to legitimate current functionality
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Manual review of all changes before implementation
  - **Validation:** Test functionality mentioned in updated documentation

### Process Risks
- **Risk:** Scope creep into actual feature changes rather than documentation cleanup
  - **Probability:** Medium
  - **Impact:** Low
  - **Mitigation:** Strict focus on reference updates, not implementation changes
  - **Monitoring:** Regular scope review during implementation

- **Risk:** Missing subtle references due to varied terminology
  - **Probability:** Medium
  - **Impact:** Low
  - **Mitigation:** Use comprehensive search terms and manual validation
  - **Iteration:** Multiple search passes with different term variations

## Out of Scope

- ❌ **New Feature Development**: Adding new capabilities to replace removed multi-repo features
- ❌ **Architecture Changes**: Modifying tool implementation beyond reference cleanup
- ❌ **Performance Optimization**: Improving tool performance as part of cleanup
- ❌ **User Interface Redesign**: Major changes to CLI interface or output format

## References

- Task v.0.5.0+task.006: Search tool simplification that removed multi-repository functionality
- Current search tool implementation and architecture
- Documentation structure and cross-reference patterns
- User feedback on documentation accuracy and clarity