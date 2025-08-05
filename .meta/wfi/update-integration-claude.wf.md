# Update Claude Integration Meta Workflow

## Goal

Maintain Claude Code integration using unified handbook CLI commands to ensure all workflows have corresponding Claude commands and the integration remains synchronized with the latest handbook updates.

## Prerequisites

- handbook CLI with Claude commands installed (v0.6.0+)
- Access to dev-handbook submodule
- Understanding of Claude command types (custom vs generated)
- Write access to project root (for .claude/ directory creation)
- Git repository for version control

## When to Use This Workflow

- After adding new workflow instructions
- When Claude commands are out of sync
- During major handbook version updates
- For periodic integration maintenance

## Process Steps

### 1. Check Current Status

First, understand the current state of your Claude integration:

```bash
# List all commands and their status
handbook claude list

# Validate coverage and consistency
handbook claude validate
```

Review the output to identify:
- Missing commands that need generation
- Outdated commands that need updates
- Duplicate commands that need resolution

### 2. Generate Missing Commands

For workflows without commands:

```bash
# Preview what would be generated
handbook claude generate-commands --dry-run

# Generate missing commands
handbook claude generate-commands
```

**Decision Tree: Custom vs Generated Commands**

Should this workflow have a custom command?

1. Does it require special tools or model selection?
   - YES → Create custom command with metadata
   - NO → Continue to next question

2. Does it have complex multi-step operations?
   - YES → Consider custom command for clarity
   - NO → Continue to next question

3. Is it a simple workflow reference?
   - YES → Use generated command
   - NO → Evaluate custom needs

Examples:
- `commit.md` → Custom (git operations, special formatting)
- `capture-idea.wf.md` → Generated (simple workflow reference)
- `load-project-context.md` → Custom (complex initialization)

### 3. Update Registry

Update the commands.json registry with any new or modified commands:

```bash
handbook claude update-registry
```

This command:
- Scans all command files in dev-handbook/.integrations/claude/
- Updates the central registry with metadata
- Validates JSON structure
- Reports any conflicts or issues

### 4. Install to Project

Install Claude commands to your project's .claude/ directory:

```bash
# Preview installation
handbook claude integrate --dry-run

# Perform installation (creates missing directories/files by default)
handbook claude integrate

# Force overwrite existing files if needed
handbook claude integrate --overwrite
```

The integration process:
- Creates .claude/commands/ and .claude/agents/ directories if missing
- Copies command files from dev-handbook to project
- Flattens directory structure for Claude Code compatibility
- Preserves custom commands while updating generated ones

### 5. Verify Installation

After installation, verify everything is working correctly:

```bash
# Run validation again to confirm
handbook claude validate

# Check installation summary
# The integrate command provides a summary showing:
# - Files created
# - Files updated
# - Files unchanged
# - Any errors encountered
```

Review the summary to ensure:
- All expected commands were installed
- No unintended overwrites occurred
- Directory structure is correct
- No errors or warnings present

## Troubleshooting

### Common Issues and Solutions

**Missing commands after generation**
- Check file permissions in dev-handbook/.integrations/claude/
- Verify template exists at correct location
- Ensure workflow files have .wf.md extension
- Run with --verbose flag for detailed output

**Validation failures**
- Review content hash mismatches (outdated commands)
- Check for naming conflicts between custom and generated
- Verify JSON registry syntax is valid
- Look for duplicate command definitions

**Installation errors**
- Ensure .claude/ directory exists and is writable
- Check if commands are being flattened correctly
- Verify no path conflicts during copy
- Run with --dry-run first to preview changes

**Command not working in Claude Code**
- Verify YAML front-matter syntax is correct
- Check that workflow path references are absolute
- Ensure @.claude/commands/commit.md reference exists
- Test with simpler command first

### Tool Specification Validation

The integration process validates that all tool specifications follow Claude's requirements:
- Tools must be simple names: `Bash`, `Read`, `Write`, `Edit`, `Grep`, `Glob`, `LS`, `TodoWrite`, `WebSearch`, `WebFetch`
- Do NOT use parentheses notation like `Bash(command)` - this is invalid
- Multiple tools are comma-separated: `Read, Write, Bash, Grep`

Common corrections:
- `Bash(git *)` → `Bash`
- `Bash(bundle exec *)` → `Bash`
- `Bash(task-manager *)` → `Bash`

### Diagnostic Commands

```bash
# Check current state
handbook claude list --verbose

# Validate with detailed output
handbook claude validate --format json

# Test specific workflow
handbook claude generate-commands --workflow capture-idea

# Check for invalid tool specifications
grep -r "Bash(" dev-handbook/.integrations/claude/
```

## Verification Checklist

### Pre-Integration Checks
- [ ] All workflows have commands (custom or generated)
- [ ] No validation errors reported
- [ ] Registry JSON is valid and complete
- [ ] Dry-run shows expected changes

### Post-Integration Verification
- [ ] Commands appear in .claude/commands/
- [ ] Agents appear in .claude/agents/ (if applicable)
- [ ] Review installation summary for changes/unchanged items
- [ ] Check for any errors or warnings in output
- [ ] Verify no unintended overwrites occurred

### Quality Checks
- [ ] YAML front-matter validates correctly
- [ ] Command descriptions are meaningful
- [ ] Tool restrictions are appropriate
- [ ] No invalid tool specifications with parentheses (e.g., no `Bash(command)`)
- [ ] Model preferences are set where needed

## Success Criteria

The workflow is successful when:
- All workflows have corresponding Claude commands
- Validation passes without errors
- Installation summary shows expected changes
- Registry accurately reflects current state
- No duplicate or conflicting commands exist
- Missing directories/files created automatically

## Common Patterns

### First-Time Setup
1. Run `handbook claude list` to see current state
2. Generate all missing commands
3. Review and customize as needed
4. Update registry
5. Install with `--dry-run` first
6. Perform actual installation

### Regular Maintenance
1. Validate current integration
2. Generate commands for new workflows
3. Update registry
4. Install changes (skip unchanged files by default)
5. Verify with validation

### Major Updates
1. Review all existing custom commands
2. Regenerate commands with new templates
3. Merge customizations carefully
4. Update registry comprehensively
5. Install with backup plan
6. Thorough verification

## Best Practices

**DO:**
- Run validation before and after changes
- Use --dry-run for preview
- Create custom commands for complex workflows
- Keep registry synchronized
- Document custom command rationale

**DON'T:**
- Skip validation steps
- Force overwrite without review
- Mix generated and custom content in same file
- Ignore warning messages
- Modify generated commands directly (create custom instead)

## Integration with Other Workflows

This workflow connects with:
- **New Workflow Creation**: Run after creating new .wf.md files
- **Handbook Updates**: Run after pulling handbook changes
- **Release Preparation**: Ensure Claude integration is current
- **Project Setup**: Part of initial project configuration

## Error Recovery

If integration fails:
1. Check error messages for specific issues
2. Restore from Git if needed
3. Fix identified problems
4. Re-run from appropriate step
5. Verify final state matches expectations

---

*This meta workflow ensures your Claude Code integration remains synchronized with the handbook's workflow instructions. Run it regularly to maintain optimal AI-assisted development experience.*