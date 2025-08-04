---
id: v.0.6.0+task.004
status: pending
priority: high
estimate: 4h
dependencies: [v.0.6.0+task.001, v.0.6.0+task.002]
release: v.0.6.0-unified-claude
---

# Implement update-registry subcommand

## Behavioral Specification

### User Experience
- **Input**: Developer runs `handbook claude update-registry` to sync commands.json
- **Process**: System scans all command files and rebuilds the registry
- **Output**: Updated commands.json with all current commands registered

### Expected Behavior
The system should scan both _custom and _generated directories for all .md command files, extract their metadata, and rebuild the commands.json registry file. The registry should maintain proper JSON structure, preserve any custom metadata, and ensure all commands are properly registered for Claude Code to discover them. The process should validate the JSON and report any issues.

### Interface Contract
```bash
# Update registry
handbook claude update-registry
# Output:
Scanning command directories...
Found commands:
  _custom/: 6 commands
  _generated/: 19 commands
  
Updating commands.json...
✓ Registry updated with 25 commands
✓ JSON validation passed

# Update with validation disabled
handbook claude update-registry --no-validate
# Output:
[Same scanning]
✓ Registry updated with 25 commands
⚠ JSON validation skipped

# Update with backup
handbook claude update-registry --backup
# Output:
✓ Backed up existing registry to commands.json.bak
[Rest of normal output]

# Dry run
handbook claude update-registry --dry-run
# Output:
Would update registry with:
  - commit (custom)
  - draft-tasks (custom)
  - capture-idea (generated)
  [... list all commands ...]
No changes made
```

**Error Handling:**
- Missing commands directory: Create it and report
- Corrupted JSON: Backup and regenerate
- Write permission denied: Clear error message
- Invalid command file: Skip with warning

**Edge Cases:**
- Empty directories: Create valid empty registry
- Duplicate command names: Report conflict
- Missing metadata in command: Use filename as fallback
- Very large registry: Handle gracefully

### Success Criteria
- [ ] **Directory Scanning**: All command files discovered
- [ ] **Registry Generation**: Valid JSON with all commands
- [ ] **Metadata Preservation**: Custom fields retained
- [ ] **Validation**: JSON structure validated
- [ ] **Backup Option**: Previous registry can be preserved

### Validation Questions
- [ ] **Metadata Format**: What fields should each command entry contain?
- [ ] **Sort Order**: Should commands be alphabetically sorted?
- [ ] **Custom Fields**: Which non-standard fields should be preserved?
- [ ] **Version Control**: Should registry include version information?

## Objective

Maintain an accurate, up-to-date registry of all Claude commands that enables proper command discovery and integration with Claude Code.

## Scope of Work

- **User Experience Scope**: Registry update workflow and validation
- **System Behavior Scope**: File scanning, JSON generation, and validation
- **Interface Scope**: CLI options and output format

### Deliverables

#### Behavioral Specifications
- Registry JSON schema documentation
- Command metadata specifications
- Validation rules documentation

#### Validation Artifacts
- JSON schema validation tests
- Registry integrity checks
- Backup/restore verification

## Out of Scope
- ❌ **Implementation Details**: JSON parsing libraries, file I/O methods
- ❌ **Technology Decisions**: Specific JSON schema validator
- ❌ **Performance Optimization**: Incremental updates, caching
- ❌ **Future Enhancements**: Registry versioning, command dependencies

## References

- Claude Code commands.json format
- JSON schema validation standards
- Existing registry structure

## Technical Approach

### Architecture Pattern
- Directory scanner for command discovery
- JSON builder with schema validation
- Backup management for safety

### Technology Stack
- Ruby File/Dir for scanning
- JSON library for parsing/generation
- FileUtils for backup operations

## Tool Selection

| Tool/Library | Purpose | Rationale |
|--------------|---------|-----------|
| Dir.glob | Command file scanning | Pattern matching efficiency |
| JSON (Ruby) | Registry generation | Standard library, no deps |
| JSON::Validator | Schema validation | Ensure registry integrity |

## File Modifications

### Create
- `dev-tools/lib/coding_agent_tools/cli/commands/handbook/claude/update_registry.rb` - Command implementation
- `dev-tools/lib/coding_agent_tools/organisms/claude_registry_updater.rb` - Business logic
- `dev-tools/spec/coding_agent_tools/organisms/claude_registry_updater_spec.rb` - Tests

### Modify
- `dev-handbook/.integrations/claude/commands/commands.json` - Registry file (regenerated)

### Delete
- None required

## Risk Assessment

### Technical Risks
- **JSON Corruption**: Invalid JSON could break Claude integration
  - Mitigation: Always validate before writing, keep backups
- **Large Registry Performance**: Many commands could slow parsing
  - Mitigation: Streaming JSON generation if needed

### Integration Risks
- **Command Name Conflicts**: Duplicate names across directories
  - Mitigation: Report conflicts, use directory prefix in registry
- **Missing Metadata**: Commands without proper headers
  - Mitigation: Extract from filename, provide defaults

## Implementation Plan

### Planning Steps

* [ ] Analyze current commands.json structure
* [ ] Define required metadata fields for each command
* [ ] Design backup rotation strategy
* [ ] Plan JSON validation approach

### Execution Steps

- [ ] Implement update-registry command class
  ```ruby
  # lib/coding_agent_tools/cli/commands/handbook/claude/update_registry.rb
  module CodingAgentTools
    module CLI
      module Commands
        module Handbook
          module Claude
            class UpdateRegistry < Dry::CLI::Command
              desc "Update Claude commands.json registry"
              
              option :validate, type: :boolean, default: true, desc: "Validate JSON after update"
              option :backup, type: :boolean, default: false, desc: "Backup existing registry"
              option :dry_run, type: :boolean, default: false, desc: "Show what would be done"
              
              def call(**options)
                updater = CodingAgentTools::Organisms::ClaudeRegistryUpdater.new
                updater.update(options)
              end
            end
          end
        end
      end
    end
  end
  ```

- [ ] Create registry updater organism
  ```ruby
  # lib/coding_agent_tools/organisms/claude_registry_updater.rb
  module CodingAgentTools
    module Organisms
      class ClaudeRegistryUpdater
        def initialize
          @custom_dir = "dev-handbook/.integrations/claude/commands/_custom"
          @generated_dir = "dev-handbook/.integrations/claude/commands/_generated"
          @registry_path = "dev-handbook/.integrations/claude/commands/commands.json"
        end
        
        def update(options)
          create_backup if options[:backup]
          commands = scan_commands
          
          if options[:dry_run]
            display_dry_run(commands)
          else
            write_registry(commands)
            validate_registry if options[:validate]
          end
        end
      end
    end
  end
  ```
  > TEST: Registry Update
  > Type: Integration Test
  > Assert: Registry file is updated correctly
  > Command: bundle exec rspec -e "updates registry"

- [ ] Implement command scanning
  ```ruby
  def scan_commands
    commands = {}
    
    # Scan custom commands
    Dir.glob(File.join(@custom_dir, "*.md")).each do |path|
      name = File.basename(path, ".md")
      commands[name] = extract_metadata(path, "custom")
    end
    
    # Scan generated commands
    Dir.glob(File.join(@generated_dir, "*.md")).each do |path|
      name = File.basename(path, ".md")
      commands[name] = extract_metadata(path, "generated")
    end
    
    commands
  end
  ```
  > TEST: Command Scanning
  > Type: Unit Test
  > Assert: Finds all commands in both directories
  > Command: bundle exec rspec -e "scans all command files"

- [ ] Implement metadata extraction
  ```ruby
  def extract_metadata(path, type)
    {
      "name" => File.basename(path, ".md"),
      "type" => type,
      "path" => path.sub("dev-handbook/.integrations/claude/", ""),
      "modified" => File.mtime(path).iso8601
    }
  end
  ```

- [ ] Implement registry writing with validation
  ```ruby
  def write_registry(commands)
    registry = {
      "version" => "1.0",
      "generated_at" => Time.now.iso8601,
      "commands" => commands
    }
    
    json = JSON.pretty_generate(registry)
    File.write(@registry_path, json)
    
    puts "✓ Registry updated with #{commands.size} commands"
  end
  
  def validate_registry
    # Basic JSON validation
    JSON.parse(File.read(@registry_path))
    puts "✓ JSON validation passed"
  rescue JSON::ParserError => e
    puts "✗ JSON validation failed: #{e.message}"
  end
  ```
  > TEST: JSON Validation
  > Type: Unit Test
  > Assert: Generated JSON is valid
  > Command: bundle exec rspec -e "generates valid JSON"

- [ ] Add comprehensive test coverage
  ```ruby
  # spec/coding_agent_tools/organisms/claude_registry_updater_spec.rb
  RSpec.describe CodingAgentTools::Organisms::ClaudeRegistryUpdater do
    describe "#scan_commands" do
      it "finds commands in both directories" do
        # Test implementation
      end
      
      it "handles empty directories" do
        # Test implementation
      end
    end
    
    describe "#update" do
      it "creates backup when requested" do
        # Test implementation
      end
      
      it "respects dry-run flag" do
        # Test implementation
      end
    end
  end
  ```

- [ ] Test idempotency and edge cases
  > TEST: Idempotent Updates
  > Type: Integration Test
  > Assert: Multiple runs produce same result
  > Command: handbook claude update-registry && handbook claude update-registry

## Acceptance Criteria

- [ ] Scans both _custom and _generated directories
- [ ] Generates valid JSON registry
- [ ] Preserves custom metadata fields
- [ ] Validates JSON when requested
- [ ] Creates backups when requested
- [ ] Handles empty directories gracefully
- [ ] Reports command counts accurately