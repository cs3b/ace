# Claude Command Organization

This document explains how Claude commands are organized and managed within the Coding Agent Workflow Toolkit.

## Directory Structure

```
.integrations/claude/commands/
├── _custom/          # Hand-crafted commands
└── _generated/       # Auto-generated from workflows
```

## Command Categories

### _custom/ - Custom Commands

These are hand-crafted commands that provide specialized functionality beyond simple workflow execution. They cannot be auto-generated due to their complex behavior or special requirements.

#### Current Custom Commands

**commit.md**
- Intelligent git commit workflow
- Analyzes changes and generates conventional commit messages
- Handles staging, commit message formatting, and push operations
- Integrates with project commit conventions

**draft-tasks.md**
- Creates multiple task definitions from specifications
- Supports batch task creation
- Generates properly formatted task files
- Handles task dependencies and metadata

**load-project-context.md**
- Loads essential project documentation
- Provides context for other commands
- Includes architecture, blueprint, and objective docs
- Sets up environment for informed decision-making

**plan-tasks.md**
- Strategic task planning and breakdown
- Creates implementation plans
- Handles task prioritization
- Generates structured task hierarchies

**review-tasks.md**
- Comprehensive task review workflow
- Validates task completeness
- Checks implementation quality
- Ensures acceptance criteria are met

**work-on-tasks.md**
- Execute multiple tasks in sequence
- Handles task status updates
- Manages task dependencies
- Provides progress tracking

### _generated/ - Generated Commands

These commands are automatically generated from workflow instructions. They follow a consistent format and should not be manually edited.

#### Generation Process

1. **Source**: Workflow instruction files in `dev-handbook/workflow-instructions/*.wf.md`
2. **Template**: Uses `templates/workflow-command.md.tmpl`
3. **Generation**: Run `handbook claude generate-commands`
4. **Updates**: Regenerated when workflows change

#### Current Generated Commands

Commands are generated for all workflow instructions, including:

- capture-idea.md - Capture and document new ideas
- create-adr.md - Create Architecture Decision Records
- create-reflection-note.md - Document development reflections
- draft-release.md - Prepare release documentation
- draft-task.md - Create new task definitions
- fix-tests.md - Debug and fix failing tests
- review-code.md - Perform code reviews
- work-on-task.md - Execute single task implementation
- And many more...

## Command Format

### Metadata Structure

All commands (custom and generated) follow this metadata format:

```yaml
command: command-name
description: Brief description of what the command does
version: 1.0.0
workflow: optional-workflow-reference
agent: optional-agent-reference
parameters: optional-parameters-list
```

### Custom Command Structure

Custom commands typically include:

1. **Metadata block** - Command configuration
2. **Purpose section** - What the command accomplishes
3. **Context section** - When to use the command
4. **Instructions** - Detailed steps for execution
5. **Examples** - Usage scenarios
6. **Error handling** - Common issues and solutions

### Generated Command Structure

Generated commands follow a standard template:

1. **Metadata block** - Auto-generated configuration
2. **Workflow reference** - Link to source workflow
3. **Execution instructions** - Standard workflow execution
4. **Context loading** - Required project documentation

## Command Lifecycle

### Creation

**Custom Commands:**
1. Identify need for specialized behavior
2. Create markdown file in `_custom/`
3. Write command following the format
4. Test command in Claude
5. Update registry with `handbook claude update-registry`

**Generated Commands:**
1. Create or update workflow instruction
2. Run `handbook claude generate-commands`
3. Commands are automatically created/updated
4. Registry is updated automatically

### Maintenance

**Custom Commands:**
- Edit directly in `_custom/`
- Version control changes
- Test modifications
- Update registry if metadata changes

**Generated Commands:**
- Never edit directly
- Update source workflow instruction
- Regenerate with `handbook claude generate-commands`
- Changes are applied automatically

### Deprecation

**Removing Commands:**
1. Delete the command file
2. Run `handbook claude update-registry`
3. Run `handbook claude integrate` to remove from Claude

**Archiving Commands:**
1. Move to an `_archive/` directory (create if needed)
2. Update registry to exclude archived commands
3. Document reason for archival

## Best Practices

### Custom Command Guidelines

1. **Clear Purpose**: Each command should have a single, well-defined purpose
2. **Comprehensive Instructions**: Include all necessary steps
3. **Error Handling**: Anticipate and document common issues
4. **Examples**: Provide realistic usage examples
5. **Context Loading**: Specify required project documentation

### Naming Conventions

- Use kebab-case for command names
- Be descriptive but concise
- Use verbs for actions (create-, update-, fix-)
- Use nouns for resources (task, release, note)
- Maintain consistency with existing commands

### Documentation Standards

1. **Metadata**: Always include complete metadata
2. **Descriptions**: Write clear, action-oriented descriptions
3. **Instructions**: Use numbered or bulleted lists
4. **Code Blocks**: Use appropriate syntax highlighting
5. **Cross-References**: Link to related commands and docs

## Registry Management

The `registry.json` file tracks all commands and agents:

```json
{
  "version": "1.0.0",
  "commands": {
    "commit": {
      "path": "commands/_custom/commit.md",
      "type": "custom",
      "description": "Create git commits"
    },
    "work-on-task": {
      "path": "commands/_generated/work-on-task.md",
      "type": "generated",
      "workflow": "workflow-instructions/work-on-task.wf.md"
    }
  }
}
```

### Updating the Registry

```bash
# Automatic update
handbook claude update-registry

# With backup
handbook claude update-registry --backup

# Validate after update
handbook claude update-registry --validate
```

## Validation

Commands are validated for:

1. **Structure**: Proper markdown and metadata format
2. **Completeness**: All required sections present
3. **References**: Valid workflow and agent references
4. **Uniqueness**: No duplicate command names
5. **Coverage**: All workflows have commands

Run validation:
```bash
handbook claude validate
```

## Troubleshooting

### Common Issues

**Missing Commands:**
- Check if workflow exists
- Verify workflow format
- Run generation with `--verbose`

**Invalid Commands:**
- Validate markdown syntax
- Check metadata format
- Ensure unique command names

**Generation Failures:**
- Review workflow instruction format
- Check for template issues
- Enable debug output

### Debug Mode

Enable detailed output:
```bash
HANDBOOK_DEBUG=1 handbook claude generate-commands
```

## Future Enhancements

Planned improvements:

1. **Command Testing**: Automated testing framework
2. **Version History**: Track command changes over time
3. **Dependencies**: Define command dependencies
4. **Conditions**: Conditional command execution
5. **Composition**: Combine commands into workflows

## Related Documentation

- [Main Integration Guide](../README.md)
- [Workflow Instructions](../../../workflow-instructions/)
- [Command Templates](../templates/)
- [Developer Guide](../../../../dev-tools/docs/development/claude-integration.md)