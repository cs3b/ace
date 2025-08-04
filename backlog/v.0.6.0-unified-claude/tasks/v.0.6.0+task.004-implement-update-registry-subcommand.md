---
id: v.0.6.0+task.004
status: pending
priority: high
estimate: 4h
dependencies: [v.0.6.0+task.001, v.0.6.0+task.002]
release: v.0.6.0-unified-claude
needs_review: true
---

# Implement update-registry subcommand

## Review Questions (Pending Human Input)

### [HIGH] Critical Implementation Questions
- [ ] Should the registry updater scan `.claude/commands/` or `dev-handbook/.integrations/claude/commands/`?
  - **Research conducted**: Found `.claude/commands/` contains 32 command files and commands.json
  - **Research conducted**: `dev-handbook/.integrations/claude/commands/` only has 6 files, no commands.json
  - **Current state**: Commands.json exists at `.claude/commands/commands.json`
  - **Suggested default**: Scan `.claude/commands/` which is the active location
  - **Why needs human input**: Task spec mentions dev-handbook path but actual files are elsewhere

- [ ] Should update-registry wait for task.001 directory structure creation or work with current flat structure?
  - **Research conducted**: No `_custom` or `_generated` directories exist yet
  - **Research conducted**: Task.001 is a dependency and will create these directories
  - **Suggested default**: Implement to support both flat and subdirectory structures
  - **Why needs human input**: Implementation approach depends on timing and coordination

### [MEDIUM] Enhancement Questions
- [ ] Should the command be `handbook claude update-registry` or `handbook update-registry`?
  - **Research conducted**: Current pattern is `handbook sync-templates` (no nested claude)
  - **Research conducted**: No existing claude subcommand namespace in CLI
  - **Suggested default**: `handbook update-registry` for consistency
  - **Why needs human input**: Architecture decision for Claude-specific commands

- [ ] What should happen if commands.json doesn't exist yet?
  - **Research conducted**: Current commands.json exists with 33 commands registered
  - **Suggested default**: Create new commands.json with proper structure
  - **Why needs human input**: Bootstrap behavior needs specification

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
  - **Research conducted**: Current format uses path as key with config object as value
  - **Example found**: `"/capture-idea": {}` or with config like `"workspace_restrictions"`
  - **Suggested default**: Preserve current format, add metadata only if needed
- [ ] **Sort Order**: Should commands be alphabetically sorted?
  - **Research conducted**: Current commands.json is alphabetically sorted by key
  - **Suggested default**: Maintain alphabetical sorting for consistency
- [ ] **Custom Fields**: Which non-standard fields should be preserved?
  - **Research conducted**: Found `workspace_restrictions`, `tools` fields in some entries
  - **Suggested default**: Preserve all existing fields during updates
- [ ] **Version Control**: Should registry include version information?
  - **Research conducted**: No version field in current commands.json
  - **Suggested default**: Add optional `version` and `generated_at` at root level

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
- Follow existing organism pattern (similar to TemplateSynchronizer)

### Technology Stack
- Ruby File/Dir for scanning
- JSON library for parsing/generation
- FileUtils for backup operations
- Dry::CLI for command structure (existing pattern)

## Tool Selection

| Tool/Library | Purpose | Rationale |
|--------------|---------|-----------|
| Dir.glob | Command file scanning | Pattern matching efficiency |
| JSON (Ruby) | Registry generation | Standard library, no deps |
| JSON::Validator | Schema validation | Ensure registry integrity |

## File Modifications

### Create
- `dev-tools/lib/coding_agent_tools/cli/commands/handbook/update_registry.rb` - Command implementation (or in claude/ subdirectory if namespace needed)
- `dev-tools/lib/coding_agent_tools/organisms/claude_registry_updater.rb` - Business logic
- `dev-tools/spec/coding_agent_tools/organisms/claude_registry_updater_spec.rb` - Tests
- `dev-tools/spec/coding_agent_tools/cli/commands/handbook/update_registry_spec.rb` - Command tests

### Modify
- `.claude/commands/commands.json` - Registry file (regenerated)
- `dev-tools/lib/coding_agent_tools/cli.rb` - Register new command (if claude namespace, update register_handbook_commands)

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
- **Path Discrepancy**: Task spec vs actual file locations
  - Mitigation: Make paths configurable with sensible defaults

## Implementation Plan

### Planning Steps

* [ ] Analyze current commands.json structure
* [ ] Define required metadata fields for each command
* [ ] Design backup rotation strategy
* [ ] Plan JSON validation approach

### Execution Steps

- [ ] Implement update-registry command class
  ```ruby
  # lib/coding_agent_tools/cli/commands/handbook/update_registry.rb (path TBD based on namespace decision)
  module CodingAgentTools
    module Cli  # Note: Cli not CLI based on existing pattern
      module Commands
        module Handbook
          # module Claude if nested namespace needed
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
          # Paths to be confirmed based on review questions
          @custom_dir = ".claude/commands/_custom"  # After task.001 creates these
          @generated_dir = ".claude/commands/_generated"  # After task.001 creates these
          @registry_path = ".claude/commands/commands.json"  # Current location
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