---
id: v.0.9.0+task.181
status: draft
priority: medium
estimate: 2h
dependencies: []
---

# Standardize Project Name to Agentic Coding Environment

## Behavioral Specification

### User Experience
- **Input**: Execute search-and-replace across documentation files
- **Process**: Update all instances of "Agent Coding Environment" to "Agentic Coding Environment"
- **Output**: Consistent naming across all project documentation

### Expected Behavior
The project should consistently use "ACE (Agentic Coding Environment)" as the full name expansion across all documentation, templates, and user-facing content. The term "Agentic" more accurately reflects the project's focus on autonomous, agent-driven development capabilities.

This is a documentation-only change with no impact on CLI behavior, source code logic, or deterministic output formats.

### Interface Contract
```bash
# No CLI changes - documentation-only task
# All ace-* commands continue to work identically
# Only human-readable documentation changes
# Acronym "ACE" is preserved in all locations
```

**Error Handling:**
- If a file cannot be edited: Report and skip, continue with others
- If ambiguous phrasing found: Use "ACE (Agentic Coding Environment)" as standard

**Edge Cases:**
- Partial phrases like "Agent Coding Env": Replace with full "Agentic Coding Environment"
- Historical documents: Update for consistency (per user preference)
- Cache files: Clear/regenerate rather than manual edit

### Success Criteria
- [ ] All README.md files updated (root + all ace-* packages)
- [ ] All docs/*.md files updated (architecture, blueprint, what-do-we-build)
- [ ] Template files updated (idea_enhancement.system.md)
- [ ] .ace/README.md updated
- [ ] No functional/behavioral changes to any CLI tools
- [ ] Acronym "ACE" preserved in all locations
- [ ] Historical/archived documents updated for consistency

### Validation Questions
- [x] **Historical Documents**: User confirmed update ALL occurrences including historical docs
- [x] **Scope Confirmation**: Documentation-only, no source code changes needed

## Objective

Standardize the project's full name to "ACE (Agentic Coding Environment)" to:
- Provide a single, professional, and descriptive name
- Ensure AI agents consuming project context receive consistent input
- Align the project's name with its advanced agentic capabilities

## Scope of Work

- **User Experience Scope**: All human-readable documentation presenting the project name
- **System Behavior Scope**: No changes - CLI tools maintain identical behavior
- **Interface Scope**: Documentation files only

### Deliverables

#### Files to Update (~85 files across categories)

**Critical Documentation (8 files)**
- `/Users/mc/Ps/ace-meta/README.md`
- `/Users/mc/Ps/ace-meta/docs/what-do-we-build.md`
- `/Users/mc/Ps/ace-meta/docs/architecture.md`
- `/Users/mc/Ps/ace-meta/docs/blueprint.md`

**Package READMEs**
- `ace-context/README.md`
- `ace-integration-claude/README.md`
- `ace-handbook/README.md`
- `ace-search/README.md`
- `ace-support-mac-clipboard/README.md`
- Other ace-*/README.md files

**Configuration & Templates**
- `.ace/README.md`
- `ace-taskflow/templates/idea_enhancement.system.md`

**Historical/Archive Documents**
- v.0.7.0 migration docs
- Completed task files
- Idea files in backlog

**Cache Files**
- Clear `.cache/` directory (files regenerate automatically)

## Out of Scope

- Source code changes (no lib/ modifications)
- CLI output changes (deterministic output preserved)
- Manual cache file updates (auto-regenerated)
- Any functional/behavioral changes

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/8o6iro-ace-rename/idea.s.md`
- Related backlog idea: `.ace-taskflow/_backlog/ideas/ace-project-renaming/`
