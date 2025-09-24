---
id: v.0.5.0+task.054
status: done
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

- [x] **Behavioral Outcome 1**: Hooks are automatically installed during integration
- [x] **User Experience Goal 2**: Developers receive helpful git workflow guidance
- [x] **System Performance 3**: Hooks execute in under 100ms for responsive feedback

### Validation Questions

- [x] **Requirement Clarity**: Should hooks block commands or just suggest alternatives?
  - Answer: Git add shows suggestions only (non-blocking), other git commands are blocked with helpful alternatives
- [x] **Edge Case Handling**: How to handle conflicts with existing git hooks?
  - Answer: Integration preserves existing hooks unless --force is used, which creates backups first
- [x] **User Experience**: Should suggestions be dismissible or always shown?
  - Answer: Suggestions are shown each time but can be disabled via configuration
- [x] **Success Definition**: What metrics indicate improved commit quality?
  - Answer: Use of semantic commit types (feat, fix, docs, etc.) and intent-driven messages

## Objective

Improve developer git workflow by providing intelligent hooks that guide toward semantic commits and proper tool usage, making the development process more consistent and meaningful across teams.

## Technical Approach

### Architecture Pattern
- Hook-based architecture using Claude Code's PreToolUse hooks
- Ruby scripts for cross-platform compatibility
- JSON configuration for easy customization
- Template-based distribution through .ace/handbook

### Technology Stack
- Ruby for hook implementation (already used in existing hooks)
- JSON for configuration files
- Shell integration through Claude Code settings
- File system operations for integration

### Implementation Strategy
- Create template directory structure in .ace/handbook
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
- .ace/handbook/.meta/tpl/claude-hooks/enforce-wrapper-tools.rb
  - Purpose: Enhanced hook with git-commit workflow suggestions
  - Key components: Command detection, suggestion generation, configuration loading
  - Dependencies: Ruby runtime, JSON library

- .ace/handbook/.meta/tpl/claude-hooks/wrapper-tools-config.json
  - Purpose: Configuration for hook behavior
  - Key components: Git command mappings, suggestion messages, feature flags
  - Dependencies: None (data file)

- .ace/handbook/.meta/tpl/claude-hooks/settings.json
  - Purpose: Claude Code settings template
  - Key components: Hook registration, permissions, PreToolUse configuration
  - Dependencies: Claude Code

- .ace/handbook/.meta/tpl/claude-hooks/README.md
  - Purpose: Documentation for hook system
  - Key components: Installation, configuration, customization guide
  - Dependencies: None (documentation)

### Modify
- .ace/tools/lib/coding_agent_tools/cli/commands/integrate.rb
  - Changes: Add hooks copying logic with executable permissions
  - Impact: Hooks will be automatically installed during integration
  - Integration points: copy_files method, create_project_context_template pattern

- .ace/tools/config/integration.yml
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

* [x] Analyze current hook implementation patterns
* [x] Research Claude Code hook API limitations
* [x] Design configuration merge strategy for existing settings

### Execution Steps

- [x] Create hooks template directory structure
  ```bash
  mkdir -p .ace/handbook/.meta/tpl/claude-hooks
  ```

- [x] Copy and enhance existing hook with git-commit suggestions
  > TEST: Hook Enhancement
  > Type: File Creation
  > Assert: enforce-wrapper-tools.rb exists with new git add detection
  > Command: grep -q "git add" .ace/handbook/.meta/tpl/claude-hooks/enforce-wrapper-tools.rb

- [x] Create enhanced wrapper-tools-config.json with commit workflow section
  > TEST: Config Enhancement
  > Type: Configuration Check
  > Assert: commit_workflow section exists in config
  > Command: jq '.commit_workflow' .ace/handbook/.meta/tpl/claude-hooks/wrapper-tools-config.json

- [x] Create settings.json template for Claude Code
  > TEST: Settings Template
  > Type: File Validation
  > Assert: PreToolUse hooks configured correctly
  > Command: jq '.hooks.PreToolUse' .ace/handbook/.meta/tpl/claude-hooks/settings.json

- [x] Create comprehensive README.md for hooks
  > TEST: Documentation
  > Type: File Check
  > Assert: README contains installation and configuration sections
  > Command: grep -E "(Installation|Configuration)" .ace/handbook/.meta/tpl/claude-hooks/README.md

- [x] Update integration.rb to copy hooks from new location
  > TEST: Integration Logic
  > Type: Code Update
  > Assert: Integration handles .meta/tpl/claude-hooks path
  > Command: grep -q "claude-hooks" .ace/tools/lib/coding_agent_tools/cli/commands/integrate.rb

- [x] Add executable permission logic during hook copy
  > TEST: Permission Logic
  > Type: Code Check
  > Assert: chmod +x applied to .rb files
  > Command: grep -q "chmod.*+x" .ace/tools/lib/coding_agent_tools/cli/commands/integrate.rb

- [x] Update integration.yml with correct hooks source path
  > TEST: Config Update
  > Type: Configuration
  > Assert: hooks source points to .meta/tpl/claude-hooks
  > Command: grep -q "claude-hooks" .ace/tools/config/integration.yml

- [x] Test full integration flow
  > TEST: Integration Test
  > Type: End-to-End
  > Assert: Hooks installed and executable in .claude/hooks
  > Command: coding-agent-tools integrate claude --dry-run --verbose | grep -q "hooks"

## Acceptance Criteria

- [x] All hooks files created in .ace/handbook/.meta/tpl/claude-hooks/
- [x] Integration command successfully copies hooks to .claude/hooks/
- [x] Hooks are executable after installation
- [x] Git add command triggers helpful suggestions
- [x] Wrapper commands work without interference
- [x] Documentation clearly explains hook customization

## Out of Scope

- ❌ Supporting hook languages other than Ruby
- ❌ Creating GUI for hook configuration
- ❌ Implementing hooks for non-git commands
- ❌ Auto-updating hooks after installation

## References

- Existing hook implementation: `.claude/hooks/enforce-wrapper-tools.rb`
- Configuration: `.claude/hooks/wrapper-tools-config.json`
- Idea file: `.ace/taskflow/backlog/ideas/20250824-0116-git-commit-instead.md`
- Current integration logic: `.ace/tools/lib/coding_agent_tools/cli/commands/integrate.rb`