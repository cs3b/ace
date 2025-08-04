---
id: v.0.4.0+task.011
status: done
priority: high
estimate: 6h
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

## Technical Approach

### Architecture Pattern
- [ ] Follow existing git command pattern using ExecutableWrapper with ATOM architecture
- [ ] Integrate with GitOrchestrator and MultiRepoCoordinator for multi-repo operations
- [ ] Use dry-cli framework for command line interface consistent with other git tools

### Technology Stack
- [ ] Ruby >= 3.2 with existing CodingAgentTools gem architecture
- [ ] Leverage existing Molecules::Git::MultiRepoCoordinator for repository discovery
- [ ] Use Atoms::Git::GitCommandExecutor for individual git tag operations
- [ ] No new external dependencies required

### Implementation Strategy
- [ ] Create git-tag-all executable following existing git-* pattern
- [ ] Add TagCommand class in cli/commands/git/ directory
- [ ] Extend GitOrchestrator with tag operation support
- [ ] Add tag command registration to register_git_commands method

## Tool Selection

| Criteria | Git CLI | Custom Ruby | Shell Script | Selected |
|----------|---------|-------------|--------------|----------|
| Integration | Excellent | Good | Poor | Git CLI |
| Multi-repo | Good | Excellent | Fair | Git CLI |
| Argument passthrough | Excellent | Good | Good | Git CLI |
| Error handling | Good | Excellent | Fair | Git CLI |
| Consistency | Excellent | Excellent | Poor | Git CLI |

**Selection Rationale:** Use native git tag commands through GitCommandExecutor for maximum compatibility and argument passthrough, coordinated via MultiRepoCoordinator for multi-repository operations.

### Dependencies
- [ ] No new external dependencies required
- [ ] Extends existing CodingAgentTools::Organisms::Git::GitOrchestrator
- [ ] Uses existing multi-repository coordination infrastructure

## File Modifications

### Create
- dev-tools/exe/git-tag-all
  - Purpose: Executable wrapper following existing pattern
  - Key components: ExecutableWrapper configuration
  - Dependencies: coding_agent_tools/molecules/executable_wrapper

- dev-tools/lib/coding_agent_tools/cli/commands/git/tag.rb
  - Purpose: Main command implementation with argument parsing
  - Key components: Dry::CLI::Command subclass, option definitions, GitOrchestrator integration
  - Dependencies: dry/cli, git_orchestrator, project_root_detector

### Modify
- dev-tools/lib/coding_agent_tools/cli.rb
  - Changes: Add require for git/tag command in register_git_commands method
  - Impact: Registers new tag command in CLI system
  - Integration points: Follows existing pattern of other git command registrations

- dev-tools/lib/coding_agent_tools/organisms/git/git_orchestrator.rb
  - Changes: Add tag method for multi-repository tag operations
  - Impact: Extends GitOrchestrator with tagging capabilities
  - Integration points: Uses existing MultiRepoCoordinator infrastructure

### Delete
- None required

## Risk Assessment

### Technical Risks
- **Risk:** Submodules in detached HEAD state may cause tagging failures
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Add validation to check repository state before tagging
  - **Rollback:** Tags can be deleted using git tag -d across all repositories

- **Risk:** Partial tag application if some repositories fail
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Validate all repositories are clean before starting any operations
  - **Rollback:** Implement tag cleanup for already-processed repositories

### Integration Risks
- **Risk:** Argument parsing conflicts with git tag native options
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Use pass-through argument handling like existing git commands
  - **Monitoring:** Test with all common git tag option combinations

### Performance Risks
- **Risk:** Sequential tagging may be slow with many submodules
  - **Mitigation:** Use existing MultiRepoCoordinator which handles concurrent operations
  - **Monitoring:** Execution time for multi-repository operations
  - **Thresholds:** Should complete within 30 seconds for 4 repositories

## Implementation Plan

### Planning Steps

* [ ] Analyze git tag command options and argument patterns
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: All git tag options are documented and understood
  > Command: git tag --help

* [ ] Review existing GitOrchestrator patterns for multi-repo operations
  > TEST: Pattern Analysis
  > Type: Architecture Validation
  > Assert: Implementation approach aligns with existing git command patterns
  > Command: rg "def (status|commit|push)" dev-tools/lib/coding_agent_tools/organisms/git/git_orchestrator.rb

* [ ] Design tag operation flow with clean state validation

### Execution Steps

- [ ] Create git-tag-all executable wrapper
  > TEST: Executable Creation
  > Type: Action Validation
  > Assert: Executable exists and follows existing pattern
  > Command: test -x dev-tools/exe/git-tag-all && head -15 dev-tools/exe/git-tag-all

- [ ] Implement TagCommand class with argument parsing
  > TEST: Command Class Implementation
  > Type: Action Validation
  > Assert: TagCommand class exists and inherits from Dry::CLI::Command
  > Command: rg "class Tag.*Dry::CLI::Command" dev-tools/lib/coding_agent_tools/cli/commands/git/tag.rb

- [ ] Add tag method to GitOrchestrator with multi-repo coordination
  > TEST: GitOrchestrator Extension
  > Type: Action Validation
  > Assert: tag method exists in GitOrchestrator
  > Command: rg "def tag" dev-tools/lib/coding_agent_tools/organisms/git/git_orchestrator.rb

- [ ] Register tag command in CLI system
  > TEST: Command Registration
  > Type: Action Validation
  > Assert: Tag command is registered in git commands
  > Command: rg "git/tag" dev-tools/lib/coding_agent_tools/cli.rb

- [ ] Test tag creation across all repositories
  > TEST: Multi-Repository Tagging
  > Type: Integration Test
  > Assert: Tag appears in main repo and all submodules
  > Command: git-tag-all test-tag-$(date +%s) && git tag -l | grep test-tag && git-tag-all -d test-tag-$(date +%s)

- [ ] Test tag deletion across all repositories
  > TEST: Tag Deletion
  > Type: Integration Test
  > Assert: Tag is removed from all repositories
  > Command: git tag -l | grep -v test-tag

- [ ] Validate argument pass-through for annotated tags
  > TEST: Argument Pass-through
  > Type: Feature Validation
  > Assert: Annotated tags work with -a and -m options
  > Command: git-tag-all -a test-annotated-$(date +%s) -m "Test message" && git show test-annotated-$(date +%s)

## Acceptance Criteria

- [ ] git-tag-all executable exists and follows project patterns
- [ ] Tag creation works across main repository and all submodules
- [ ] Tag deletion works across all repositories
- [ ] All git tag arguments are passed through correctly
- [ ] Clean working directory validation prevents tagging dirty repositories
- [ ] Clear success/failure feedback for each repository processed

## References

- Source idea: dev-taskflow/backlog/ideas/20250731-0942-multi-repo-tag.md
- Existing git wrapper tools in dev-tools/exe/
- Multi-repository coordination patterns from docs/architecture.md
- GitOrchestrator: dev-tools/lib/coding_agent_tools/organisms/git/git_orchestrator.rb