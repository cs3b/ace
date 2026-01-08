# ACE Integration Claude Gem

Claude Code integration workflows and templates for ACE (Agentic Coding Environment). This package provides comprehensive tools for maintaining Claude Code integration in AI-assisted development workflows.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ace-integration-claude'
```

And then execute:
```bash
bundle install
```

Or install it yourself as:
```bash
gem install ace-integration-claude
```

## Usage

The ace-integration-claude gem provides Claude Code integration workflows accessible via the `wfi://` protocol using ace-nav:

### Integration Workflow

```bash
# Update Claude Code integration files and command templates
ace-nav wfi://update-integration-claude
```

### Workflow Description

**update-integration-claude**: Comprehensive workflow for maintaining Claude Code integration:
- Synchronizes command files from dev-handbook to project
- Updates Claude Code slash commands and agent symlinks
- Maintains integration templates and metadata
- Validates integration configuration

## Integration Assets

This package includes Claude Code integration templates and documentation:

### Templates (`integrations/claude/templates/`)
- Command templates for various development workflows
- Agent definition templates
- Integration metadata templates

### Documentation (`integrations/claude/`)
- **README.md**: Claude Code integration setup and usage
- **metadata-field-reference.md**: Field reference for integration configuration
- **install-prompts.md**: Guide for installing Claude Code prompts

### Custom Commands (`integrations/claude/commands/_custom/`)
- Custom command definitions for Claude Code
- User-specific integration commands

## Architecture

This is a **pure integration package** following the ACE gem patterns:

- **No CLI interface**: Integration workflows accessed via `wfi://` protocol through ace-nav
- **No Ruby dependencies**: Contains only workflow files and integration assets
- **Auto-discovery**: ace-nav automatically discovers workflows from installed gems
- **Worktree compatible**: Fully compatible with git worktree environments through proper project root detection
- **Asset packaging**: Integration templates and documentation bundled with workflows

## File Structure

```
ace-integration-claude/
├── lib/ace/integration/claude.rb     # Gem entry point
├── lib/ace/integration/claude/version.rb  # Version constant
├── handbook/workflow-instructions/    # Workflow files
│   └── update-integration-claude.wf.md
├── integrations/claude/               # Integration assets
│   ├── templates/                    # Command and agent templates
│   ├── commands/_custom/             # Custom command definitions
│   ├── README.md                     # Integration documentation
│   ├── metadata-field-reference.md  # Configuration reference
│   └── install-prompts.md           # Installation guide
├── README.md                         # This file
├── CHANGELOG.md                      # Version history
├── ace-integration-claude.gemspec    # Gem specification
└── Rakefile                          # Gem tasks
```

## Standards

Integration workflows follow ACE standards:
- **ADR-001**: Self-contained workflows with embedded templates
- **ADR-002**: XML template embedding architecture
- **Frontmatter**: Standardized metadata and parameters
- **Path conventions**: Project-root relative paths

## Development

After checking out the repo, run `bin/setup` to install dependencies.

To install this gem onto your local machine, run:
```bash
bundle exec rake install
```

## Integration Setup

For full Claude Code integration:

1. **Install the gem**: Add to your Gemfile and run `bundle install`
2. **Run integration workflow**: `ace-nav wfi://update-integration-claude`
3. **Configure Claude Code**: Set up prompts and commands as directed
4. **Validate integration**: Test workflows and commands work correctly

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cs3b/ace-meta.

## License

The gem is available as open source under the terms of the MIT License.

## ACE Integration

This gem is part of the ACE (Agentic Coding Environment) ecosystem. For more information:

- [ACE Documentation](https://github.com/cs3b/ace-meta)
- [ace-nav Protocol](https://github.com/cs3b/ace-meta)
- [Development Standards](https://github.com/cs3b/ace-meta/tree/main/docs)