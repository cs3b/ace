---
id: v.0.5.0+task.054
status: pending
priority: high
estimate: 4h
dependencies: []
---

# Make Claude Code hooks reusable and integrate in new installations

## Behavioral Specification

### User Experience
- **Input**: Developers run `coding-agent-tools integrate claude` command
- **Process**: Integration automatically sets up hooks that guide git workflow practices
- **Output**: Working hooks that enforce wrapper tools and suggest semantic commits

### Expected Behavior
When developers use Claude Code after integration:
1. Git commands are intercepted and wrapper tools are suggested
2. Using `git add` triggers helpful suggestions to use `git-commit --intention` or `--message` instead
3. Error messages provide clear examples and explanations
4. Hooks work immediately after integration without manual setup
5. Configuration can be customized through JSON files

### Interface Contract

```bash
# During integration
coding-agent-tools integrate claude
# Output: Hooks installed and configured in .claude/hooks/

# When developer tries native git
git add file.rb
# Hook response:
# Consider using semantic commits instead:
#   git-commit file.rb --intention "fix authentication"
#   git-commit file.rb --message "fix: resolve login timeout issue"

# When developer uses wrapper
git-commit --intention "add new feature"
# Hook allows and executes normally
```

**Error Handling:**
- Missing hooks directory: Create from templates
- Non-executable hooks: Automatically chmod +x
- Missing configuration: Use sensible defaults

**Edge Cases:**
- Existing hooks: Preserve with backup
- Custom settings.json: Merge configurations
- No Ruby available: Provide fallback message

### Success Criteria

- [ ] **Behavioral Outcome 1**: Hooks are automatically installed during integration
- [ ] **User Experience Goal 2**: Developers receive helpful git workflow guidance
- [ ] **System Performance 3**: Hooks execute in under 100ms for responsive feedback

### Validation Questions

- [ ] **Requirement Clarity**: Should hooks block commands or just suggest alternatives?
- [ ] **Edge Case Handling**: How to handle conflicts with existing git hooks?
- [ ] **User Experience**: Should suggestions be dismissible or always shown?
- [ ] **Success Definition**: What metrics indicate improved commit quality?

## Objective

Improve developer git workflow by providing intelligent hooks that guide toward semantic commits and proper tool usage, making the development process more consistent and meaningful across teams.

## Technical Approach

### Architecture Pattern
- Hook-based architecture using Claude Code's PreToolUse hooks
- Ruby scripts for cross-platform compatibility
- JSON configuration for easy customization
- Template-based distribution through dev-handbook

### Technology Stack
- Ruby for hook implementation (already used in existing hooks)
- JSON for configuration files
- Shell integration through Claude Code settings
- File system operations for integration

### Implementation Strategy
- Create template directory structure in dev-handbook
- Enhance existing hook with git-commit workflow suggestions
- Update integration command to copy and configure hooks
- Ensure executable permissions and proper paths

## Tool Selection

| Criteria | Ruby Hooks | Shell Hooks | Node.js Hooks | Selected |
|----------|------------|-------------|---------------|----------|
| Performance | Good | Excellent | Good | Ruby |
| Cross-platform | Excellent | Poor | Excellent | Ruby |
| Maintenance | Excellent | Good | Good | Ruby |
| Existing Code | Yes | No | No | Ruby |

**Selection Rationale:** Ruby is already used for existing hooks, provides good cross-platform support, and maintains consistency with current implementation.

## File Modifications

### Create
- dev-handbook/.meta/tpl/claude-hooks/enforce-wrapper-tools.rb
  - Purpose: Enhanced hook with git-commit workflow suggestions
  - Key components: Command detection, suggestion generation, configuration loading
  - Dependencies: Ruby runtime, JSON library

- dev-handbook/.meta/tpl/claude-hooks/wrapper-tools-config.json
  - Purpose: Configuration for hook behavior
  - Key components: Git command mappings, suggestion messages, feature flags
  - Dependencies: None (data file)

- dev-handbook/.meta/tpl/claude-hooks/settings.json
  - Purpose: Claude Code settings template
  - Key components: Hook registration, permissions, PreToolUse configuration
  - Dependencies: Claude Code

- dev-handbook/.meta/tpl/claude-hooks/README.md
  - Purpose: Documentation for hook system
  - Key components: Installation, configuration, customization guide
  - Dependencies: None (documentation)

### Modify
- dev-tools/lib/coding_agent_tools/cli/commands/integrate.rb
  - Changes: Add hooks copying logic with executable permissions
  - Impact: Hooks will be automatically installed during integration
  - Integration points: copy_files method, create_project_context_template pattern

- dev-tools/config/integration.yml
  - Changes: Update hooks source path to .meta/tpl/claude-hooks
  - Impact: Integration will find hooks in correct location
  - Integration points: Claude integration configuration section

## Risk Assessment

### Technical Risks
- **Risk:** Ruby not available on target system
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Check Ruby availability during integration, provide clear error message
  - **Rollback:** Skip hook installation with warning

- **Risk:** Conflicting existing hooks or settings
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Backup existing files, merge configurations carefully
  - **Rollback:** Restore from backup

### Integration Risks
- **Risk:** Hook permissions not set correctly
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Explicitly chmod +x during integration
  - **Monitoring:** Test hook execution after installation

## Implementation Plan

### Planning Steps

* [ ] Analyze current hook implementation patterns
* [ ] Research Claude Code hook API limitations
* [ ] Design configuration merge strategy for existing settings

### Execution Steps

- [ ] Create hooks template directory structure
  ```bash
  mkdir -p dev-handbook/.meta/tpl/claude-hooks
  ```

- [ ] Copy and enhance existing hook with git-commit suggestions
  > TEST: Hook Enhancement
  > Type: File Creation
  > Assert: enforce-wrapper-tools.rb exists with new git add detection
  > Command: grep -q "git add" dev-handbook/.meta/tpl/claude-hooks/enforce-wrapper-tools.rb

- [ ] Create enhanced wrapper-tools-config.json with commit workflow section
  > TEST: Config Enhancement
  > Type: Configuration Check
  > Assert: commit_workflow section exists in config
  > Command: jq '.commit_workflow' dev-handbook/.meta/tpl/claude-hooks/wrapper-tools-config.json

- [ ] Create settings.json template for Claude Code
  > TEST: Settings Template
  > Type: File Validation
  > Assert: PreToolUse hooks configured correctly
  > Command: jq '.hooks.PreToolUse' dev-handbook/.meta/tpl/claude-hooks/settings.json

- [ ] Create comprehensive README.md for hooks
  > TEST: Documentation
  > Type: File Check
  > Assert: README contains installation and configuration sections
  > Command: grep -E "(Installation|Configuration)" dev-handbook/.meta/tpl/claude-hooks/README.md

- [ ] Update integration.rb to copy hooks from new location
  > TEST: Integration Logic
  > Type: Code Update
  > Assert: Integration handles .meta/tpl/claude-hooks path
  > Command: grep -q "claude-hooks" dev-tools/lib/coding_agent_tools/cli/commands/integrate.rb

- [ ] Add executable permission logic during hook copy
  > TEST: Permission Logic
  > Type: Code Check
  > Assert: chmod +x applied to .rb files
  > Command: grep -q "chmod.*+x" dev-tools/lib/coding_agent_tools/cli/commands/integrate.rb

- [ ] Update integration.yml with correct hooks source path
  > TEST: Config Update
  > Type: Configuration
  > Assert: hooks source points to .meta/tpl/claude-hooks
  > Command: grep -q "claude-hooks" dev-tools/config/integration.yml

- [ ] Test full integration flow
  > TEST: Integration Test
  > Type: End-to-End
  > Assert: Hooks installed and executable in .claude/hooks
  > Command: coding-agent-tools integrate claude --dry-run --verbose | grep -q "hooks"

## Acceptance Criteria

- [ ] All hooks files created in dev-handbook/.meta/tpl/claude-hooks/
- [ ] Integration command successfully copies hooks to .claude/hooks/
- [ ] Hooks are executable after installation
- [ ] Git add command triggers helpful suggestions
- [ ] Wrapper commands work without interference
- [ ] Documentation clearly explains hook customization

## Out of Scope

- ❌ Supporting hook languages other than Ruby
- ❌ Creating GUI for hook configuration
- ❌ Implementing hooks for non-git commands
- ❌ Auto-updating hooks after installation

## References

- Existing hook implementation: `.claude/hooks/enforce-wrapper-tools.rb`
- Configuration: `.claude/hooks/wrapper-tools-config.json`
- Idea file: `dev-taskflow/backlog/ideas/20250824-0116-git-commit-instead.md`
- Current integration logic: `dev-tools/lib/coding_agent_tools/cli/commands/integrate.rb`