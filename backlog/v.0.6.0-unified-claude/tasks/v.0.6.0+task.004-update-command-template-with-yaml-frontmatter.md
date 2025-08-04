---
id: v.0.6.0+task.004
status: pending
priority: high
estimate: 4h
dependencies: [v.0.6.0+task.002, v.0.6.0+task.003]
release: v.0.6.0-unified-claude
needs_review: false
---

# Update command template with YAML front-matter

## Behavioral Specification

### User Experience
- **Input**: Developer uses `handbook claude generate-commands` to create Claude commands
- **Process**: System generates commands with proper YAML front-matter metadata
- **Output**: Claude-native command files with metadata for description, tools, and model preferences

### Expected Behavior
The command template should generate Claude Code-compatible markdown files with YAML front-matter containing metadata fields. Each generated command will include appropriate metadata based on the workflow type, making commands self-documenting and configurable. The template should be flexible enough to support different metadata for different command types.

### Interface Contract
```bash
# Generate commands with YAML front-matter
handbook claude generate-commands
# Output:
Generating commands with YAML metadata...
✓ Created: _generated/capture-idea.md (with description, allowed-tools)
✓ Created: _generated/fix-linting-issue-from.md (with description, model: sonnet)
✓ Created: _generated/rebase-against.md (with description, argument-hint)

# Example generated command file:
---
description: Capture and document a new idea as a task
allowed-tools: Read, Write, TodoWrite
argument-hint: "[idea-description]"
---

read whole file and follow @dev-handbook/workflow-instructions/capture-idea.wf.md

read and run @.claude/commands/commit.md
```

**Edge Cases:**
- Workflow with special characters in name: Sanitize for YAML
- Long workflow names: Truncate description appropriately
- Model-specific workflows: Add model field when needed

### Success Criteria
- [ ] **Template Creation**: Command template with YAML front-matter
- [ ] **Metadata Generation**: Appropriate metadata for each workflow type
- [ ] **YAML Validity**: Generated files have valid YAML syntax
- [ ] **Claude Compatibility**: Commands work in Claude Code
- [ ] **Template Flexibility**: Supports different metadata combinations

### Validation Questions
- [x] **YAML Format**: What fields should be included?
  - **Resolved**: description, allowed-tools, argument-hint, model (all optional)
- [x] **Description Generation**: How to create descriptions from workflow names?
  - **Resolved**: Convert kebab-case to sentence case, infer from workflow name
- [x] **Tool Restrictions**: Which workflows need tool restrictions?
  - **Resolved**: Add based on workflow type (e.g., commit workflows get git tools)

## Objective

Update the command generation template to produce Claude Code-native command files with YAML front-matter, eliminating the need for a separate registry file.

## Scope of Work

- **Template Scope**: Create flexible template with YAML front-matter
- **Generator Updates**: Modify generator to use new template format
- **Metadata Logic**: Smart metadata generation based on workflow type

### Deliverables

#### Template Artifacts
- Command template with YAML front-matter structure
- Metadata generation rules documentation
- Example generated commands

#### Generator Updates
- Modified generator using new template
- Metadata inference logic
- YAML validation

## Out of Scope
- ❌ **Registry Management**: No commands.json needed
- ❌ **Command Discovery**: Claude Code handles this automatically
- ❌ **Complex Metadata**: Advanced MCP configurations
- ❌ **Custom Prompts**: Focus on standard workflow reference pattern

## Technical Approach

### Template Structure
```markdown
---
description: <%= description %>
<% if allowed_tools %>allowed-tools: <%= allowed_tools %><% end %>
<% if argument_hint %>argument-hint: "<%= argument_hint %>"<% end %>
<% if model %>model: <%= model %><% end %>
---

read whole file and follow @dev-handbook/workflow-instructions/<%= workflow_name %>.wf.md

read and run @.claude/commands/commit.md
```

### Metadata Generation Rules
- **description**: Convert workflow name from kebab-case to readable sentence
- **allowed-tools**: Based on workflow type (git commands get Bash(git *), etc.)
- **argument-hint**: For workflows that take arguments (e.g., "[task-id]", "[branch-name]")
- **model**: Only for workflows needing specific models (e.g., complex analysis uses opus)

## Tool Selection

| Tool/Library | Purpose | Rationale |
|--------------|---------|-----------|
| YAML (Ruby) | Front-matter generation | Standard library support |
| String manipulation | Description generation | Built-in Ruby methods |
| Pattern matching | Workflow type detection | Determine metadata needs |

## File Modifications

### Create
- `dev-handbook/.integrations/claude/command.template.md` - Template with YAML front-matter

### Modify
- `dev-tools/lib/coding_agent_tools/organisms/claude_command_generator.rb` - Use new template
- `dev-tools/spec/coding_agent_tools/organisms/claude_command_generator_spec.rb` - Update tests

### Delete
- None required (no commands.json references to remove)

## Risk Assessment

### Technical Risks
- **YAML Syntax Errors**: Invalid YAML breaks Claude Code parsing
  - Mitigation: Validate YAML before writing, escape special characters
- **Metadata Inference Errors**: Wrong metadata for workflow type
  - Mitigation: Conservative defaults, clear rules

### Integration Risks
- **Claude Code Compatibility**: Format changes in future versions
  - Mitigation: Follow official documentation, test with Claude Code
- **Template Complexity**: Over-engineering metadata generation
  - Mitigation: Start simple, enhance based on usage

## Implementation Plan

### Planning Steps

* [ ] Define metadata inference rules for common workflow types
* [ ] Design template with conditional YAML fields
* [ ] Plan YAML validation approach
* [ ] Document metadata field meanings

### Execution Steps

- [ ] Create command template with YAML front-matter
  ```markdown
  # dev-handbook/.integrations/claude/command.template.md
  ---
  description: <%= description %>
  <% if allowed_tools %>allowed-tools: <%= allowed_tools %><% end %>
  <% if argument_hint %>argument-hint: "<%= argument_hint %>"<% end %>
  <% if model %>model: <%= model %><% end %>
  ---
  
  read whole file and follow @dev-handbook/workflow-instructions/<%= workflow_name %>.wf.md
  
  read and run @.claude/commands/commit.md
  ```

- [ ] Update generator to use template with metadata
  ```ruby
  # lib/coding_agent_tools/organisms/claude_command_generator.rb
  def generate_command_content(workflow)
    metadata = infer_metadata(workflow)
    
    # Use string interpolation as specified (not ERB)
    content = []
    content << "---"
    content << "description: #{metadata[:description]}"
    content << "allowed-tools: #{metadata[:allowed_tools]}" if metadata[:allowed_tools]
    content << "argument-hint: \"#{metadata[:argument_hint]}\"" if metadata[:argument_hint]
    content << "model: #{metadata[:model]}" if metadata[:model]
    content << "---"
    content << ""
    content << "read whole file and follow @dev-handbook/workflow-instructions/#{workflow}.wf.md"
    content << ""
    content << "read and run @.claude/commands/commit.md"
    
    content.join("\n")
  end
  ```

- [ ] Implement metadata inference logic
  ```ruby
  def infer_metadata(workflow)
    metadata = {}
    
    # Generate description from workflow name
    metadata[:description] = workflow.gsub('-', ' ').capitalize
    
    # Infer allowed-tools based on workflow type
    case workflow
    when /^git-/, /commit/, /rebase/, /merge/
      metadata[:allowed_tools] = "Bash(git *), Read, Write"
    when /^create-/, /^draft-/, /^plan-/
      metadata[:allowed_tools] = "Read, Write, TodoWrite"
    when /^test-/, /^validate-/
      metadata[:allowed_tools] = "Bash, Read"
    end
    
    # Add argument hints for parameterized workflows
    case workflow
    when /work-on-task/, /review-task/
      metadata[:argument_hint] = "[task-id]"
    when /rebase-against/, /merge-from/
      metadata[:argument_hint] = "[branch-name]"
    when /fix.*from/
      metadata[:argument_hint] = "[source-file]"
    end
    
    # Select model for complex workflows
    case workflow
    when /analyze/, /synthesize/, /research/
      metadata[:model] = "opus"
    end
    
    metadata
  end
  ```
  > TEST: Metadata Inference
  > Type: Unit Test
  > Assert: Correct metadata for different workflow types
  > Command: bundle exec rspec -e "infers metadata"

- [ ] Add YAML validation
  ```ruby
  def validate_yaml_frontmatter(content)
    # Extract YAML between --- markers
    yaml_match = content.match(/\A---\n(.*?)\n---/m)
    return false unless yaml_match
    
    begin
      YAML.safe_load(yaml_match[1])
      true
    rescue Psych::SyntaxError => e
      puts "Warning: Invalid YAML in generated command: #{e.message}"
      false
    end
  end
  ```

- [ ] Update generator tests
  ```ruby
  # spec/coding_agent_tools/organisms/claude_command_generator_spec.rb
  describe "#generate_command_content" do
    it "includes YAML front-matter" do
      content = generator.generate_command_content("capture-idea")
      expect(content).to start_with("---")
      expect(content).to include("description: Capture idea")
    end
    
    it "adds allowed-tools for git workflows" do
      content = generator.generate_command_content("git-commit")
      expect(content).to include("allowed-tools: Bash(git *)")
    end
    
    it "adds argument-hint for parameterized workflows" do
      content = generator.generate_command_content("work-on-task")
      expect(content).to include('argument-hint: "[task-id]"')
    end
    
    it "generates valid YAML" do
      content = generator.generate_command_content("test-workflow")
      expect(generator.validate_yaml_frontmatter(content)).to be true
    end
  end
  ```

- [ ] Test with Claude Code
  > TEST: Claude Code Compatibility
  > Type: Integration Test
  > Assert: Generated commands work in Claude Code
  > Command: Generate command, restart Claude Code, verify /help shows command

- [ ] Document metadata fields
  ```markdown
  # Metadata Field Reference
  
  ## description
  Short help text shown in Claude Code's /help output
  
  ## allowed-tools
  Restricts which tools the command can use (security feature)
  Format: Tool(pattern), Tool2, Tool3(specific:command)
  
  ## argument-hint
  Shown in autocomplete, helps users understand expected arguments
  Format: "[argument-name]" or "[arg1] [arg2]"
  
  ## model
  Forces specific model (sonnet, opus, haiku) for this command
  Default: User's selected model
  ```

## Acceptance Criteria

- [ ] Template includes YAML front-matter structure
- [ ] Generator produces valid YAML syntax
- [ ] Metadata is appropriately inferred from workflow names
- [ ] Generated commands work in Claude Code
- [ ] No references to commands.json remain
- [ ] Commands are self-documenting with descriptions
- [ ] Tool restrictions applied where appropriate