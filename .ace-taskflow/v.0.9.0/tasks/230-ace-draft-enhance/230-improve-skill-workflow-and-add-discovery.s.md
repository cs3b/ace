---
id: v.0.9.0+task.230
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Improve ace-draft-task skill workflow and add skill discovery

## Behavioral Specification

### User Experience

- **Input**: Agent or user invokes skill for task creation or wants to discover available skills
- **Process**: Skill discoverable via intuitive naming; parent-child relationships established automatically
- **Output**: Tasks properly linked; skills discoverable via `ace-nav skill:///`

### Expected Behavior

**Current State Problems** (from retro `8olqpc-ace-draft-task-skill-issues`):
- Skill name confusion: `ace-create-task` (CLI pattern) vs `ace_draft-task` (actual skill name)
- No explicit step for `ace-taskflow task move --child-of` in draft-task workflow
- Manual edits to parent task files don't establish structural relationships
- No way to discover available skill names

**Desired State**:
1. **Skill Discovery**: `ace-nav skill:///` lists all available skills
2. **Updated Workflow**: draft-task.wf.md includes explicit parent-linking step
3. **Validation Step**: Workflow confirms parent relationship established
4. **Better Documentation**: Skill naming conventions documented

### Interface Contract

**Skill Discovery**:
```bash
# List all available skills
ace-nav skill:///
# Expected output:
# skill://ace_commit
# skill://ace_draft-task
# skill://ace_plan-task
# skill://ace_create-retro
# skill://ace_review-task
# ...

# Find specific skill
ace-nav skill:/// | grep -i task
```

**Updated draft-task Workflow** (step 6 addition):
```markdown
6. **Establish Parent-Child Relationship** (REQUIRED when creating subtasks)
   * Use: `ace-taskflow task move <id> --child-of <parent-id>`
   * This command:
     - Moves task file to parent's subdirectory
     - Updates task metadata with parent relationship
     - Maintains ace-taskflow's internal tracking
   * **DO NOT** manually edit parent task file (only adds text reference)
   * Verify with: `ace-taskflow task show <id>` (should show parent)
```

**Proper Subtask Creation Flow**:
```bash
# 1. Create draft task
ace-taskflow task create --title "Title" --status draft --estimate "TBD"

# 2. Establish parent relationship (if subtask)
ace-taskflow task move <id> --child-of <parent-id>

# 3. Populate with behavioral specification
# Edit task file at new location
```

**Error Handling**:
- Skill not found: Suggest checking `ace-nav skill:///` for available skills
- Parent task doesn't exist: Error message with valid parent suggestions
- Move command fails: Explain need for `--child-of` flag

**Edge Cases**:
- Skill name aliases: Support both `ace-draft-task` and `ace_draft-task` if feasible
- Orphaned tasks: Detect tasks without parent references that should have them
- Circular dependencies: Prevent task from being its own parent

### Success Criteria

- [ ] **Skill Discovery Works**: `ace-nav skill:///` lists all available skills
- [ ] **Workflow Updated**: draft-task.wf.md includes explicit parent-linking step
- [ ] **Documentation Added**: Skill naming convention documented (underscores vs hyphens)
- [ ] **Validation Step**: Workflow includes verification after parent linking
- [ ] **Retro Addressed**: All action items from retro `8olqpc-ace-draft-task-skill-issues` covered

### Validation Questions

- [ ] **Implementation Approach**: Should skill discovery be added to ace-nav or separate command?
- [ ] **Name Aliases**: Is supporting both `ace-draft-task` and `ace_draft-task` feasible/worthwhile?
- [ ] **Validation Enforcement**: Should draft-task workflow fail if parent relationship not established?
- [ ] **Documentation Location**: Where should skill naming conventions be documented?

## Objective

Improve ace-draft-task skill workflow based on retro learnings to prevent future issues with:
- Skill discoverability
- Parent-child task relationships
- Clear workflow instructions

## Scope of Work

- **User Experience Scope**:
  - Discoverable skill names via `ace-nav skill:///`
  - Clear workflow steps for establishing parent relationships
  - Validation that relationships are properly established

- **System Behavior Scope**:
  - ace-nav protocol source configuration for skills
  - Updated draft-task workflow with explicit parent-linking step
  - Documentation of skill naming conventions

- **Interface Scope**:
  - `ace-nav skill:///` protocol discovery
  - `ace-taskflow task move --child-of` command
  - Workflow instruction clarity

### Deliverables

#### Behavioral Specifications
- Skill discovery protocol configuration
- Updated draft-task.wf.md workflow
- Skill naming convention documentation

#### Validation Artifacts
- Test `ace-nav skill:///` returns skill list
- Verify workflow includes parent-linking step
- Confirm documentation accessible

## Out of Scope

- ❌ **Skill Implementation Changes**: Not modifying skill internals, only workflow and discovery
- ❌ **ace-taskflow Core Changes**: Not modifying ace-taskflow command behavior
- ❌ **Other Skills**: Changes specific to ace-draft-task, not all skills
- ❌ **CLI Tool Changes**: Not modifying ace-nav binary, only protocol sources

## References

- Retro: `.ace-taskflow/v.0.9.0/retros/8olqpc-ace-draft-task-skill-issues.md`
- Parent Task: v.0.9.0+task.218 (Docs Audit - Documentation Alignment)
- Related Workflow: `ace-taskflow/handbook/workflow-instructions/draft-task.wf.md`
- Reference Package: `ace-nav/` (for protocol source configuration)

## Retro Action Items Being Addressed

From retro `8olqpc-ace-draft-task-skill-issues`:

### Process Improvements
- [ ] Add skill discovery command: `ace-nav skill:///` to list all available skills
- [ ] Update draft-task workflow: Explicitly include `ace-taskflow task move --child-of <parent>` step
- [ ] Add validation step: After creating task, verify parent relationship with `ace-taskflow task show <id>`

### Start Doing
- [ ] Verify skill names before invocation: Use `ace-nav skill:///` or check `.claude/skills/` directory
- [ ] Document skill naming conventions: Clarify underscore vs. hyphen patterns
