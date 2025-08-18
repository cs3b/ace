# Rebase Against Workflow Instruction

## Goal

Rebase all repositories (main repository and submodules) against their respective origin/main branches while maintaining proper feature branch context, ensuring latest changes are incorporated while preserving feature work.

## Prerequisites

- Working git repository with submodules
- Feature branch exists in main repository and all submodules
- Origin remotes are properly configured for all repositories
- Repository has test capabilities (optional but recommended)
- Understanding of git rebase concepts and conflict resolution

## Project Context Loading

- Read and follow: `dev-handbook/workflow-instructions/load-project-context.wf.md`

## High-Level Execution Plan

### Planning Phase
- [ ] Verify current branch status across all repositories
- [ ] Confirm feature branch strategy
- [ ] Run pre-rebase tests if available
- [ ] Identify submodule structure and dependencies

### Execution Phase
- [ ] Fetch latest changes from origin for all repositories
- [ ] Rebase each submodule feature branch against origin/main
- [ ] Rebase main repository feature branch against origin/main
- [ ] Resolve any submodule conflicts during main repo rebase
- [ ] Run post-rebase tests to verify functionality
- [ ] Verify final branch status

## Process Steps

1. **Pre-Rebase Verification:**
   
   **Branch Status Check:**
   ```bash
   # Check main repository branch with project context
   git-status --verbose
   
   # Check each submodule branch with multi-repo support
   git-status --all-repos
   ```
   
   **Critical Verification Points:**
   - Confirm all repositories are on the intended feature branch (not main)
   - Ensure no uncommitted changes that could interfere with rebase
   - Verify .gitmodules file shows correct submodule structure
   
   **Common Branch Names to Verify:**
   - Feature branches: `wt/feature-name`, `feature/branch-name`
   - Release branches: `v.X.Y.Z+task.N`
   - Development branches: `develop`, `dev`

2. **Pre-Rebase Testing (Recommended):**
   
   **Run Tests in Repositories with Test Capabilities:**
   ```bash
   # Check for test scripts and run if available
   if [ -f "# Run project-specific test command" ]; then
       echo "Running pre-rebase tests..."
       # Run project-specific test command
   fi
   
   # For submodules with tests (example: dev-tools)
   cd dev-tools
   if [ -f "# Run project-specific test command" ]; then
       echo "Running pre-rebase tests in dev-tools..."
       # Run project-specific test command
   fi
   cd ..
   ```
   
   **Validation:**
   - Tests should pass before starting rebase
   - If tests fail, resolve issues before proceeding
   - Document any existing test failures for comparison

3. **Multi-Repository Fetch:**
   
   **Fetch Latest Changes:**
   ```bash
   # Enhanced multi-repository fetch with reporting
   git-fetch --all-repos --report
   
   # Alternative: Individual repository fetch with validation
   git-fetch --report
   ```
   
   **Expected Outcomes:**
   - All remote tracking branches updated
   - No merge conflicts during fetch (fetch only downloads, doesn't merge)
   - Partial success is normal if some repositories have no remote changes

4. **Submodule Rebase Sequence:**
   
   **CRITICAL: Maintain Feature Branch Context**
   
   **For Each Submodule:**
   ```bash
   # Navigate to submodule
   cd [submodule-name]
   
   # Verify current branch (should be feature branch)
   git branch
   
   # Ensure on correct feature branch
   git checkout [feature-branch-name]
   
   # Rebase feature branch against origin/main
   git rebase origin/main
   
   # Handle conflicts if they occur (see conflict resolution section)
   
   # Return to main repository
   cd ..
   ```
   
   **Example Submodule Sequence:**
   ```bash
   # Rebase dev-tools submodule
   cd dev-tools
   git checkout wt/v.0.3.0+task.19-git
   git rebase origin/main
   cd ..
   
   # Rebase dev-taskflow submodule  
   cd dev-taskflow
   git checkout wt/v.0.3.0+task.19-git
   git rebase origin/main
   cd ..
   
   # Rebase dev-handbook submodule
   cd dev-handbook
   git checkout wt/v.0.3.0+task.19-git
   git rebase origin/main
   cd ..
   ```

5. **Main Repository Rebase:**
   
   **Rebase Main Repository Feature Branch:**
   ```bash
   # Confirm on correct feature branch
   git checkout [feature-branch-name]
   
   # Rebase against origin/main
   git rebase origin/main
   ```
   
   **Expected Submodule Conflicts:**
   The main repository rebase will likely encounter submodule conflicts because:
   - Previous commits reference old submodule commit hashes
   - Submodules now point to new commits after their rebase
   
   **Handle Submodule Conflicts:**
   ```bash
   # For each submodule conflict, add the submodule
   git add [submodule-name]
   
   # Continue rebase
   git rebase --continue
   
   # Repeat for each conflict until rebase completes
   ```

6. **Conflict Resolution Process:**
   
   **Code Conflicts in Submodules:**
   ```bash
   # Check conflict status
   git status
   
   # Edit conflicted files to resolve conflicts
   # Remove conflict markers: <<<<<<< HEAD, =======, >>>>>>> 
   
   # Add resolved files
   git add [resolved-file]
   
   # Continue rebase
   git rebase --continue
   ```
   
   **Submodule Reference Conflicts:**
   ```bash
   # Add submodules to resolve reference conflicts
   git add [submodule-name]
   git rebase --continue
   ```
   
   **Emergency Abort:**
   ```bash
   # If rebase goes wrong, abort and return to pre-rebase state
   git rebase --abort
   ```

7. **Post-Rebase Testing:**
   
   **Run Tests in Repositories with Test Capabilities:**
   ```bash
   # Test main functionality in primary submodule
   cd dev-tools
   if [ -f "# Run project-specific test command" ]; then
       echo "Running post-rebase tests..."
       # Run project-specific test command
   fi
   cd ..
   ```
   
   **Expected Test Results:**
   - Most tests should pass (same as pre-rebase)
   - Some tests may fail due to merge conflicts or API changes
   - Document any new test failures for investigation

8. **Final Verification:**
   
   **Branch Status Verification:**
   ```bash
   # Verify all repositories with enhanced status
   git-status --verbose
   ```
   
   **Repository Status Check:**
   ```bash
   # Check for any uncommitted changes across all repos
   git-status --all-repos
   ```

## Conflict Resolution Patterns

### Common Code Conflicts

**CLI Command Registration Conflicts:**
```bash
# Example conflict in lib/coding_agent_tools/cli.rb
<<<<<<< HEAD
def self.register_reflection_commands
  # HEAD version
=======
def self.register_git_commands  
  # Incoming version
>>>>>>> commit-hash

# Resolution: Keep both methods
def self.register_reflection_commands
  # HEAD version
end

def self.register_git_commands
  # Incoming version  
end
```

**Security Enhancement Conflicts:**
- Often involves FileOperationConfirmer integration
- Choose the version with security enhancements
- Ensure dependency injection is complete

### Submodule Reference Conflicts

**Pattern:**
```bash
Failed to merge submodule [submodule-name]
CONFLICT (submodule): Merge conflict in [submodule-name]
```

**Resolution:**
```bash
# Always add the submodule after its successful rebase
git add [submodule-name]
git rebase --continue
```

## Technology-Specific Examples

### Ruby Projects with Bundler
```bash
# Pre-rebase dependency check
bundle check

# Post-rebase dependency update if needed
bundle install
```

### Node.js Projects
```bash
# Pre-rebase dependency check  
npm ci

# Post-rebase testing
npm test
```

### Python Projects
```bash
# Pre-rebase setup
pip install -r requirements.txt

# Post-rebase testing
pytest
```

### Rust Projects
```bash
# Pre-rebase build check
cargo check

# Post-rebase testing
cargo test
```

## Error Handling

**Fetch Failures:**
- **Symptoms:** git-fetch reports errors for specific repositories
- **Solution:** Fetch repositories individually; some may not have remotes configured

**Wrong Branch Error:**
- **Symptoms:** User corrects that submodules are on wrong branch
- **Solution:** Abort current rebase, checkout correct feature branches, restart process

**Test Failures After Rebase:**
- **Symptoms:** Tests that passed before rebase now fail
- **Solution:** Investigate merge conflicts, missing dependencies, or API changes

**Submodule Directory Not Found:**
- **Symptoms:** `cd submodule-name` fails
- **Solution:** Check current directory with `pwd`, ensure in correct repository root

**Missing operation_confirmer Method:**
- **Symptoms:** Test failures about undefined method `operation_confirmer`
- **Solution:** Add missing method definition and update test mocks

## Success Criteria

- All repositories are on their respective feature branches (not main)
- All feature branches have been rebased against their origin/main  
- No uncommitted changes remain in any repository
- Submodule references in main repository point to rebased commits
- Tests pass in repositories with test capabilities (with documented exceptions)
- Git status shows clean working trees across all repositories
- Main repository shows proper branch divergence from origin (ahead by rebase commits)

## Best Practices

**DO:**
- Verify branch status before starting any rebase operations
- Test before and after rebase to catch issues early
- Handle conflicts systematically, one repository at a time
- Document any test failures for investigation
- Use git-fetch for multi-repository operations when available

**DON'T:**
- Switch to main branches when the goal is to rebase feature branches
- Skip pre-rebase verification steps
- Proceed with rebase if repositories are in unexpected states
- Ignore test failures without investigation
- Mix different rebase strategies within the same session

## Usage Examples

**Standard Feature Branch Rebase:**
> "Rebase all submodules and main repo against origin/main"

**With Specific Branch Name:**
> "Rebase the wt/v.0.3.0+task.19-git branch against origin/main across all repositories"

**Recovery from Wrong Branch:**
> "I accidentally rebased main branches instead of feature branches, how do I fix this?"

## Common Patterns

### Multi-Repository Development
- Feature work spans multiple repositories
- Submodules track specific commits from main repository
- Rebase incorporates latest changes while preserving feature work

### Git Worktree Environments
- Main repository may be in a worktree directory
- Branch operations can be affected by worktree configuration
- Verify actual git directory location when troubleshooting

### Complex Merge Conflicts
- Sequential rebase conflicts are normal in main repository
- Each old commit that references submodules will conflict
- Systematic resolution (add submodules, continue) handles most cases

---

This workflow ensures proper multi-repository rebase operations while maintaining feature branch context and providing comprehensive error handling for common scenarios.