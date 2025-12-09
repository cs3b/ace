---
id: v.0.9.0+task.153
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Replace ace-nav wfi:// with ace-context wfi:// in Claude Code commands and workflows

## Behavioral Specification

### User Experience
- **Input**: Claude Code agents and workflows currently use `ace-nav wfi://load-context` and similar patterns for loading context
- **Process**: Agents should seamlessly use `ace-context` command with wfi:// protocol support for better context loading behavior
- **Output**: Improved context loading experience with better default behaviors and protocol handling

### Expected Behavior

When agents and workflows need to load project context or workflow instructions, they should use `ace-context wfi://resource` instead of `ace-nav wfi://resource`. This provides:

- Better default behavior for context loading (read and present content directly)
- Consistent interface across commands and workflows
- Improved integration with related context enhancement features
- More intuitive agent experience when loading contextual information

This change affects:
- `.claude/commands/` - Claude Code slash commands
- Workflow instruction files (`.wf.md`) - Step-by-step process definitions
- Agent definitions - Agent context loading patterns
- CLAUDE.md - Project-level agent guidance

### Interface Contract

```bash
# Current pattern (to be replaced)
ace-nav wfi://load-context
ace-nav wfi://draft-task

# New pattern (target behavior)
ace-context wfi://load-context
ace-context wfi://draft-task

# Expected behavior:
# 1. ace-context resolves wfi:// protocol to workflow instruction file
# 2. Reads and presents the content directly (default behavior)
# 3. Provides better integration with context management features
```

**Error Handling:**
- Missing workflow file: Clear error message with available workflows
- Invalid protocol: Helpful message about supported protocols
- Read failures: Graceful fallback with actionable error information

**Edge Cases:**
- Backwards compatibility with existing ace-nav usage during transition
- Mixed usage patterns during migration period
- Documentation references that need updating

### Success Criteria

- [ ] **All slash commands updated**: `.claude/commands/` files use `ace-context wfi://` instead of `ace-nav wfi://`
- [ ] **All workflow instructions updated**: `.wf.md` files reference `ace-context` for context loading
- [ ] **CLAUDE.md updated**: Agent guidance reflects new `ace-context` usage patterns
- [ ] **Agent definitions updated**: If any agents reference wfi:// protocol loading, they use `ace-context`
- [ ] **Backwards compatibility verified**: Existing workflows continue to function during transition
- [ ] **Documentation consistency**: All references to context loading use consistent ace-context pattern

### Validation Questions

- [ ] **Scope Clarity**: Are there other locations beyond commands, workflows, and CLAUDE.md that use ace-nav wfi:// patterns?
- [ ] **Dependency Check**: Does this depend on the related idea (20251102-104953) about ace-context default behavior enhancements?
- [ ] **Migration Strategy**: Should we update all at once or support gradual migration?
- [ ] **Testing Coverage**: How do we verify that all context loading scenarios work correctly with ace-context?

## Objective

Improve the agent and workflow experience by standardizing on `ace-context` for context loading operations, leveraging its enhanced default behaviors and better integration with the context management system. This makes the interface more intuitive and consistent across all Claude Code integration points.

## Scope of Work

- **Command File Scope**: Update all `.claude/commands/` files that use ace-nav wfi:// patterns
- **Workflow Instruction Scope**: Update all `.wf.md` files that reference ace-nav for context loading
- **Documentation Scope**: Update CLAUDE.md and any agent definitions that demonstrate or use wfi:// protocol
- **Validation Scope**: Verify changes work correctly and maintain backwards compatibility

### Deliverables

#### Behavioral Specifications
- Updated command files with ace-context usage
- Updated workflow instructions with new patterns
- Updated documentation demonstrating proper usage

#### Validation Artifacts
- Manual testing of affected commands and workflows
- Verification checklist for all updated files
- Before/after comparison showing consistent pattern usage

## Out of Scope

- ❌ **Implementation Details**: How ace-context internally resolves protocols or loads files
- ❌ **New Features**: Adding new capabilities to ace-context or ace-nav
- ❌ **Other Protocols**: Changes to guide://, prompt://, or other protocol handlers
- ❌ **Deprecation**: Removing ace-nav or marking it as deprecated

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/done/20251102-105143-context-enhance/use-ace-context-in-workflows.s.md`
- Related idea: `20251102-104953-ace-context-the-default-behaviour-should-be-if-b.s.md` - ace-context default behavior enhancements
