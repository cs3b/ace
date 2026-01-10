---
id: v.0.9.0+task.199
status: pending
priority: medium
estimate: 3h
dependencies: []
---

# Migrate Claude Code integration from commands to skills

## Behavioral Specification

### User Experience
- **Input**: Existing `.claude/commands/` directory with 67 command files (old frontmatter format)
- **Process**: Rename directory, update references, modernize frontmatter to skills standard
- **Output**: `.claude/skills/` directory with hot-reload capability, modern frontmatter, and all references updated

### Expected Behavior

Claude Code v2.1.0+ unified "commands" and "skills" into a single mental model. The `.claude/skills/` directory provides:
- **Hot-reload**: Skills are immediately available without restarting Claude Code
- **Better discoverability**: Skills show in slash command menu by default
- **New frontmatter options**: `context: fork`, `agent`, `user-invocable: false`

After migration:
- All `/ace:*` slash commands continue to work
- Skills appear in autocomplete menu
- Changes to skill files are immediately reflected without restart
- ace-integration-claude generates to the new location

### Interface Contract

```bash
# Before migration
ls .claude/commands/           # 67 files
ls .claude/commands/ace/       # 51 nested files

# After migration
ls .claude/skills/             # All files preserved
ls .claude/skills/ace/         # Nested structure preserved

# Slash commands work identically
/ace:commit                    # Works
/ace:work-on-task 199          # Works
/meta-update-integration-claude # Works
```

**Error Handling:**
- Missing references: Update all `@.claude/commands/` to `@.claude/skills/`
- Documentation: Update all path references in docs

**Edge Cases:**
- Nested `ace/` subdirectory: Keep structure, update paths
- Custom commands in ace-integration-claude: Update template references

### Success Criteria

- [ ] **Directory renamed**: `.claude/commands/` → `.claude/skills/`
- [ ] **Internal references updated**: All `@.claude/commands/` → `@.claude/skills/`
- [ ] **Frontmatter modernized**: `allowed-tools` converted to YAML list format
- [ ] **Documentation updated**: CLAUDE.md, docs/architecture.md updated
- [ ] **ace-integration-claude updated**: Templates and workflows use new paths
- [ ] **Hot-reload works**: Edit a skill file, immediately available in Claude Code
- [ ] **Slash commands work**: `/ace:commit`, `/ace:work-on-task` execute correctly

### Validation Questions

- [x] **Subdirectory structure**: Keep nested `ace/` subdirectory (confirmed by user)
- [x] **Migration approach**: Rename + update references (confirmed)

## Objective

Align with Claude Code v2.1.0+ unified skills model for:
- Hot-reload capability (no restart needed for skill changes)
- Better discoverability in slash command menu
- Access to new frontmatter fields (`context: fork`, `agent`, etc.)

## Scope of Work

### Deliverables

#### Rename
- `.claude/commands/` → `.claude/skills/`

#### Modify
- All 67 skill files: modernize frontmatter (`allowed-tools` → YAML list)
- All skill files with `@.claude/commands/` references (~20 files)
- `CLAUDE.md` (lines 46-47)
- `docs/architecture.md` (line 133)
- `ace-integration-claude/integrations/claude/install-prompts.md`
- `ace-integration-claude/integrations/claude/metadata-field-reference.md`
- `ace-integration-claude/handbook/workflow-instructions/update-integration-claude.wf.md`
- `ace-integration-claude/integrations/claude/templates/command.md.tmpl`
- `ace-integration-claude/integrations/claude/commands/_custom/commit.md`

## Out of Scope

- Flattening the nested `ace/` subdirectory structure
- Renaming individual skill files
- Adding `context: fork` or `agent` fields (future enhancement)

## Implementation Plan

### Execution Steps

- [ ] **Step 1**: Rename directory
  ```bash
  mv .claude/commands .claude/skills
  ```

- [ ] **Step 2**: Modernize frontmatter in all skill files
  Convert `allowed-tools` from comma-separated to YAML list:
  ```yaml
  # Before
  allowed-tools: Read, Write, Edit, Bash

  # After
  allowed-tools:
    - Read
    - Write
    - Edit
    - Bash
  ```

- [ ] **Step 3**: Update internal skill references
  Find and replace in all `.claude/skills/**/*.md`:
  ```
  @.claude/commands/ → @.claude/skills/
  ```

- [ ] **Step 4**: Update root CLAUDE.md
  - Line 46: `@.claude/commands/ace/load-context.md` → `@.claude/skills/ace/load-context.md`
  - Line 47: `@.claude/commands/*` → `@.claude/skills/*`

- [ ] **Step 5**: Update docs/architecture.md
  - Line 133: `.claude/commands/` → `.claude/skills/`

- [ ] **Step 6**: Update ace-integration-claude package
  - `integrations/claude/install-prompts.md`: Update all path examples
  - `integrations/claude/metadata-field-reference.md`: Update reference
  - `handbook/workflow-instructions/update-integration-claude.wf.md`: Update directory paths
  - `integrations/claude/templates/command.md.tmpl`: Update commit reference
  - `integrations/claude/commands/_custom/commit.md`: Update example paths

- [ ] **Step 7**: Verify migration
  ```bash
  # Check directory exists
  ls .claude/skills/

  # Check no stale references remain
  grep -r "@.claude/commands" .claude/skills/ || echo "No stale refs"
  grep -r ".claude/commands" CLAUDE.md docs/ || echo "No stale refs"

  # Verify frontmatter format (should show YAML lists)
  head -10 .claude/skills/ace/commit.md
  ```

- [ ] **Step 8**: Test slash commands
  - `/ace:commit` - verify execution
  - `/ace:work-on-task` - verify execution

## Acceptance Criteria

- [ ] `.claude/skills/` directory exists with all 67 skill files
- [ ] All skill files use YAML list format for `allowed-tools`
- [ ] No references to `.claude/commands/` remain in skill files
- [ ] Documentation updated (CLAUDE.md, docs/architecture.md)
- [ ] ace-integration-claude templates generate to new location
- [ ] Slash commands work correctly after migration

## References

- [Claude Code CHANGELOG](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)
- [ClaudeLog Changelog](https://claudelog.com/claude-code-changelog/)
- Plan file: `/Users/mc/.claude/plans/shiny-booping-rivest.md`
