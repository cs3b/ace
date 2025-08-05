# Claude Integration Developer Guide

This guide is for developers who want to understand, extend, or contribute to the Claude Code integration system in the Coding Agent Workflow Toolkit.

## Architecture Overview

The Claude integration is built as a modular system within the dev-tools Ruby gem:

```
dev-tools/
├── lib/
│   └── coding_agent_tools/
│       ├── cli/
│       │   └── handbook.rb          # Main CLI entry point
│       └── handbook/
│           └── claude_commands_installer.rb  # Core integration logic
└── spec/
    └── coding_agent_tools/
        └── handbook/
            └── claude_commands_installer_spec.rb
```

## Core Components

### ClaudeCommandsInstaller

The `ClaudeCommandsInstaller` class handles all Claude-related operations:

```ruby
module CodingAgentTools
  module Handbook
    class ClaudeCommandsInstaller
      # Main entry points
      def integrate(options = {})
      def list(options = {})
      def validate(options = {})
      def generate_commands(options = {})
      def update_registry(options = {})
    end
  end
end
```

### Command Registry

The system uses a JSON registry to track commands and agents:

```json
{
  "version": "1.0.0",
  "commands": {
    "command-name": {
      "path": "relative/path/to/command.md",
      "type": "custom|generated",
      "workflow": "optional/workflow/reference.md",
      "description": "Brief description"
    }
  },
  "agents": {
    "agent-name": {
      "path": "relative/path/to/agent.md",
      "description": "Agent purpose"
    }
  }
}
```

## Adding New Subcommands

### 1. Define the Command in CLI

Edit `lib/coding_agent_tools/cli/handbook.rb`:

```ruby
desc "claude SUBCOMMAND", "Claude Code integration commands"
subcommand "claude", Claude

class Claude < Thor
  desc "new-command", "Description of new command"
  option :custom_flag, type: :boolean, desc: "Custom flag description"
  def new_command
    installer = CodingAgentTools::Handbook::ClaudeCommandsInstaller.new
    result = installer.new_command(options)
    # Handle result
  end
end
```

### 2. Implement the Logic

Add method to `claude_commands_installer.rb`:

```ruby
def new_command(options = {})
  # Validate options
  validate_environment!
  
  # Perform operation
  result = perform_new_operation(options)
  
  # Return structured result
  {
    success: true,
    message: "Operation completed",
    data: result
  }
rescue StandardError => e
  {
    success: false,
    error: e.message
  }
end
```

### 3. Add Tests

Create tests in `claude_commands_installer_spec.rb`:

```ruby
RSpec.describe CodingAgentTools::Handbook::ClaudeCommandsInstaller do
  describe '#new_command' do
    it 'performs the new operation' do
      installer = described_class.new
      result = installer.new_command(dry_run: true)
      
      expect(result[:success]).to be true
      expect(result[:message]).to include('completed')
    end
  end
end
```

## Customizing Command Generation

### Template System

Command generation uses ERB templates located in:
- `dev-handbook/.integrations/claude/templates/workflow-command.md.tmpl`
- `dev-handbook/.integrations/claude/templates/agent-command.md.tmpl`

To customize generation:

1. **Modify Templates**: Edit the `.tmpl` files to change generated content
2. **Add Variables**: Extend the template context in `generate_command_content`:

```ruby
def generate_command_content(workflow_path)
  template = load_template('workflow-command.md.tmpl')
  
  # Add custom variables
  context = {
    workflow_path: workflow_path,
    title: extract_title(workflow_path),
    custom_var: compute_custom_value(workflow_path)
  }
  
  ERB.new(template).result_with_hash(context)
end
```

### Workflow Parsing

The system extracts information from workflow files:

```ruby
def parse_workflow(path)
  content = File.read(path)
  
  {
    title: extract_title(content),
    description: extract_description(content),
    steps: extract_steps(content),
    metadata: extract_frontmatter(content)
  }
end
```

## Extending Validation Rules

### Adding New Validation Checks

Extend the `validate` method:

```ruby
def validate(options = {})
  results = []
  
  # Existing validations
  results << validate_registry_structure
  results << validate_command_coverage
  results << validate_file_references
  
  # Add custom validation
  results << validate_custom_rule
  
  summarize_validation_results(results, options)
end

private

def validate_custom_rule
  issues = []
  
  # Implement custom logic
  registry['commands'].each do |name, data|
    if custom_condition_fails?(data)
      issues << "Command '#{name}' fails custom rule"
    end
  end
  
  {
    rule: 'custom_rule',
    passed: issues.empty?,
    issues: issues
  }
end
```

### Validation Severity Levels

```ruby
def categorize_issue(issue)
  case issue
  when /missing command/i
    :error
  when /outdated reference/i
    :warning
  when /style violation/i
    :info
  else
    :warning
  end
end
```

## Testing and Debugging

### Running Tests

```bash
# Run all tests
cd dev-tools
bundle exec rspec

# Run Claude-specific tests
bundle exec rspec spec/coding_agent_tools/handbook/claude_commands_installer_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec
```

### Debug Mode

Enable debug output:

```ruby
# In your code
def debug_log(message)
  return unless ENV['HANDBOOK_DEBUG']
  puts "[DEBUG] #{message}"
end

# Usage
debug_log("Processing command: #{command_name}")
```

### Interactive Debugging

```ruby
# Add binding for debugging
require 'debug'

def complex_method
  binding.break # Debugger will stop here
  perform_operation
end
```

## Performance Considerations

### Caching

The system implements caching for expensive operations:

```ruby
def workflow_files
  @workflow_files ||= begin
    pattern = File.join(handbook_root, 'workflow-instructions', '*.wf.md')
    Dir.glob(pattern).sort
  end
end
```

### Batch Operations

For better performance with multiple files:

```ruby
def process_commands_batch(commands)
  # Process in parallel if possible
  if defined?(Parallel)
    Parallel.map(commands) { |cmd| process_command(cmd) }
  else
    commands.map { |cmd| process_command(cmd) }
  end
end
```

## Error Handling Best Practices

### Structured Errors

```ruby
class ClaudeIntegrationError < StandardError
  attr_reader :code, :details
  
  def initialize(message, code: nil, details: {})
    super(message)
    @code = code
    @details = details
  end
end

# Usage
raise ClaudeIntegrationError.new(
  "Command generation failed",
  code: :generation_failed,
  details: { workflow: workflow_path, reason: 'Invalid format' }
)
```

### Error Recovery

```ruby
def safe_operation
  attempt = 0
  begin
    attempt += 1
    perform_risky_operation
  rescue NetworkError => e
    retry if attempt < 3
    raise ClaudeIntegrationError.new(
      "Network operation failed after #{attempt} attempts",
      code: :network_error,
      details: { original_error: e.message }
    )
  end
end
```

## Contributing Guidelines

### Code Style

- Follow Ruby style guide (RuboCop configuration)
- Use meaningful variable and method names
- Add comments for complex logic
- Keep methods focused and under 20 lines

### Documentation

- Update command help text when adding features
- Document new options in tools.md
- Add examples for new functionality
- Update this guide for architectural changes

### Pull Request Process

1. Create feature branch from main
2. Write tests for new functionality
3. Ensure all tests pass
4. Update documentation
5. Submit PR with clear description

## Future Enhancements

### Planned Features

1. **Command Dependencies**: Define relationships between commands
2. **Conditional Execution**: Run commands based on project state
3. **Command Composition**: Combine multiple commands
4. **Version Management**: Track command versions
5. **Analytics**: Usage tracking and insights

### Extension Points

The architecture supports these extension points:

- **Custom Validators**: Add project-specific validation rules
- **Template Engine**: Replace ERB with alternative templating
- **Storage Backend**: Support different registry formats
- **Command Sources**: Generate from sources beyond workflows
- **Integration Hooks**: Pre/post-processing for commands

## Resources

- [Main Integration Guide](../../../dev-handbook/.integrations/claude/README.md)
- [Ruby Gem Development](https://guides.rubygems.org/)
- [Thor CLI Framework](http://whatisthor.com/)
- [RSpec Testing](https://rspec.info/)

## Support

For development questions:
1. Check existing issues in GitHub
2. Review test cases for examples
3. Create detailed issue with reproduction steps
4. Tag with 'claude-integration' label