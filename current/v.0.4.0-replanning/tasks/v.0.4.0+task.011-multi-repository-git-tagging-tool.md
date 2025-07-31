---
id: v.0.4.0+task.011
status: draft
priority: high
estimate: TBD
dependencies: 
---

# Multi-Repository Git Tagging Tool

## Behavioral Specification

### User Experience
- **Input**: User provides tag name and optional git tag arguments (e.g., `-a`, `-m`, `-f`)
- **Process**: Single command validates clean working directories across all repos, then applies tag consistently
- **Output**: Clear confirmation that tag was applied to main repository and all submodules, with per-repo feedback

### Expected Behavior
The system should provide a single command that orchestrates git tagging across the main repository and all its Git submodules simultaneously. The tool validates that all repositories have clean working directories before proceeding, then applies the specified tag with any provided arguments to each repository.

### Interface Contract
```bash
# Primary usage - create lightweight tag
git-tag-all v1.2.3

# Create annotated tag with message
git-tag-all -a v1.2.3 -m "Release version 1.2.3"

# Force tag (overwrite existing)
git-tag-all -f v1.2.3

# Delete tag from all repositories  
git-tag-all -d v1.2.3

# Pass through any git tag arguments
git-tag-all [git-tag-options] <tag-name>
```

### Success Criteria

- [ ] Tag applied consistently to main repository and all submodules
- [ ] Clean working directory validation before tagging operations
- [ ] Clear success/failure feedback for each repository processed
- [ ] All git tag arguments passed through correctly to underlying git commands
- [ ] Reversible operations (can delete tags from all repos easily)
- [ ] Automated operation without user prompts during execution

### Validation Questions

- [ ] How should the tool handle submodules in detached HEAD state?
- [ ] What level of error recovery is needed if tagging fails in some repos?
- [ ] Should the tool validate that the user has push permissions before tagging?

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-tools/exe | head -20
```

_Result excerpt:_

```
dev-tools/exe
├── git-add
├── git-commit
├── git-status
└── other git wrapper tools...
```

## Objective

Enable synchronized version control tagging across the entire toolkit ecosystem (main repository plus dev-handbook, dev-tools, and dev-taskflow submodules) through a single command interface that ensures consistent versioning and reduces manual coordination errors.

## Scope of Work

- CLI tool that discovers and operates on all Git submodules
- Clean working directory validation before tagging operations  
- Consistent tag application across multiple repositories
- Pass-through support for all git tag arguments and options

### Deliverables

#### Interface Contracts
- `git-tag-all` CLI command with git tag argument compatibility
- Multi-repository discovery and operation orchestration
- Clear success/failure reporting per repository

#### Behavioral Documentation
- User experience flows for common tagging scenarios
- Error handling and validation behaviors
- Integration with existing git wrapper tool patterns

## Out of Scope

- ❌ Network operations (fetching/pushing tags automatically)
- ❌ Integration with release-manager workflow automation
- ❌ Interactive prompts or confirmation dialogs
- ❌ Complex error recovery or rollback mechanisms

## References

- Source idea: dev-taskflow/backlog/ideas/20250731-0942-multi-repo-tag.md
- Existing git wrapper tools in dev-tools/exe/
- Multi-repository coordination patterns from docs/architecture.md