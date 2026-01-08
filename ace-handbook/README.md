# ACE Handbook Gem

Handbook management workflows for ACE (Agentic Coding Environment). This pure workflow package contains standardized workflows for creating, managing, and maintaining development guides, workflow instructions, and agent definitions.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ace-handbook'
```

And then execute:
```bash
bundle install
```

Or install it yourself as:
```bash
gem install ace-handbook
```

## Usage

The ace-handbook gem provides workflow instructions accessible via the `wfi://` protocol using ace-nav:

### Workflow Access

All workflows are accessible through ace-nav:

```bash
# Guide Management
ace-nav wfi://manage-guides          # Create and update development guides
ace-nav wfi://review-guides          # Review guides for quality and consistency

# Workflow Management
ace-nav wfi://manage-workflow-instructions  # Create and validate workflow files
ace-nav wfi://review-workflows       # Review workflow instructions

# Agent Management
ace-nav wfi://manage-agents          # Create and update agent definitions

# Documentation Sync
ace-nav wfi://update-handbook-docs  # Update handbook README and structure
# Claude Code integration workflows are now in ace-integration-claude gem
```

### Workflow Descriptions

1. **manage-guides**: Create, update, and maintain development guides following standardized structure
2. **review-guides**: Review all development guides for compliance with standards and identify gaps
3. **manage-workflow-instructions**: Create and update workflow instruction files (.wf.md format)
4. **review-workflows**: Review workflow instructions for quality and standards compliance
5. **manage-agents**: Create and update agent definitions (.ag.md format) with standardized contracts
6. **update-handbook-docs**: Maintain accurate README documentation across handbook structure

Note: Claude Code integration workflows are now available in the **ace-integration-claude** gem.

## Architecture

This is a **pure workflow package** following the ACE gem patterns:

- **No CLI interface**: Workflows accessed via `wfi://` protocol through ace-nav
- **No Ruby dependencies**: Contains only markdown workflow files
- **Auto-discovery**: ace-nav automatically discovers workflows from installed gems
- **Worktree compatible**: Fully compatible with git worktree environments through proper project root detection
- **Template embedding**: All templates embedded per ADR-002 XML format

## File Structure

```
ace-handbook/
├── lib/ace/handbook.rb           # Gem entry point
├── lib/ace/handbook/version.rb   # Version constant
├── handbook/workflow-instructions/  # Workflow files
│   ├── manage-guides.wf.md
│   ├── review-guides.wf.md
│   ├── manage-workflow-instructions.wf.md
│   ├── review-workflows.wf.md
│   ├── manage-agents.wf.md
│   └── update-handbook-docs.wf.md
├── README.md                      # This file
├── CHANGELOG.md                   # Version history
├── ace-handbook.gemspec           # Gem specification
└── Rakefile                       # Gem tasks
```

## Standards

Workflows follow ACE standards:
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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cs3b/ace-meta.

## License

The gem is available as open source under the terms of the MIT License.

## ACE Integration

This gem is part of the ACE (Agentic Coding Environment) ecosystem. For more information:

- [ACE Documentation](https://github.com/cs3b/ace-meta)
- [ace-nav Protocol](https://github.com/cs3b/ace-meta)
- [Development Standards](https://github.com/cs3b/ace-meta/tree/main/docs)