---
id: v.0.9.0+task.148
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Clarify distinction between Claude commands and CLI tools in documentation

## Behavioral Specification

### User Experience
- **Input**: Documentation users reading about ace-meta tools and commands
- **Process**: Users need to understand which commands to run from Claude agents vs. terminal
- **Output**: Clear, unambiguous documentation showing where each type of command should be executed

### Expected Behavior

Documentation should clearly distinguish between:
1. **Claude commands** (e.g., `/ace:fix-test`, `/ace:commit`) - Only run from within Claude agents/conversations
2. **CLI tools** (e.g., `ace-taskflow`, `ace-test`, `ace-context`) - Run from bash/fish terminal

Users should be able to:
- Quickly identify which environment a command belongs to
- Understand the purpose and context of each command type
- Avoid errors from running commands in wrong environments
- Find examples showing proper usage in correct context

### Interface Contract

**Documentation Requirements:**

```markdown
# Clear Visual Distinction
- Claude commands: Prefixed with `/` (slash commands)
  - Example: /ace:fix-test
  - Context: "Run from Claude agent conversation"

- CLI tools: No prefix, standard shell commands
  - Example: ace-taskflow task create
  - Context: "Run from terminal (bash/fish)"

# Consistent Labeling
Every command reference should include:
- Command type indicator (Agent Command vs CLI Tool)
- Execution environment (Claude conversation vs Terminal)
- Code block with appropriate context
```

**Documentation Locations:**
- CLAUDE.md files (project and user-level)
- README files in relevant packages
- Workflow instructions that reference commands
- Command guides and help documentation

**Error Handling:**
- Mixed or unclear contexts: Add explicit environment markers
- Ambiguous references: Include full command path/prefix
- Missing context: Add usage notes showing proper invocation

**Edge Cases:**
- Commands that might be called from both contexts: Explicitly document both usages
- Similar naming patterns: Use distinct formatting/styling
- New commands: Follow established conventions for environment clarity

### Success Criteria

- [ ] **Documentation Clarity**: All command references include explicit environment context (agent vs terminal)
- [ ] **Visual Distinction**: Claude commands clearly marked with `/` prefix, CLI tools shown as shell commands
- [ ] **User Understanding**: Documentation readers can identify command environment at a glance
- [ ] **Consistency**: All documentation files follow same convention for command type indication
- [ ] **Examples Included**: Command references show proper usage in correct context with examples

### Validation Questions

- [ ] **Requirement Clarity**: Which documentation files need updates? (CLAUDE.md, READMEs, guides, workflow instructions?)
- [ ] **Visual Conventions**: Should we use additional markers beyond `/` prefix? (badges, icons, formatting?)
- [ ] **Scope Coverage**: Do we need to audit all existing docs or focus on frequently accessed files?
- [ ] **User Guidance**: Should we add a "Command Reference Guide" explaining the distinction?
- [ ] **Tooling Support**: Should ace-nav or other tools help users discover command types?

## Objective

Eliminate user confusion about where to run commands by providing clear, consistent documentation that distinguishes between Claude agent commands (slash commands for agent conversations) and CLI tools (terminal commands). This improves developer experience and reduces errors from running commands in wrong environments.

## Scope of Work

**User Experience Scope**:
- Documentation readers learning ace-meta tools
- Developers executing commands in daily workflow
- Users troubleshooting command execution errors

**System Behavior Scope**:
- Documentation structure and formatting
- Command reference patterns
- Environment context indicators
- Usage examples and guides

**Interface Scope**:
- All CLAUDE.md files (project and user-level)
- README files in relevant packages
- Workflow instruction files
- Command help documentation

### Deliverables

#### Behavioral Specifications
- Documentation style guide for command types
- Environment context indicators (slash prefix, labels, examples)
- Consistent formatting patterns across all docs

#### Validation Artifacts
- Documentation audit results
- Updated files following new conventions
- User feedback on clarity improvements

## Out of Scope

- ❌ **Implementation Details**: Specific file editing tools or automation scripts
- ❌ **Technology Decisions**: Documentation generation tools or systems
- ❌ **Code Changes**: Modifications to actual commands or tools
- ❌ **Future Enhancements**: Interactive command discovery or IDE integrations

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/done/20251002-213245-clarify-distinction-between-claude-commands-and-cl/idea.s.md`
