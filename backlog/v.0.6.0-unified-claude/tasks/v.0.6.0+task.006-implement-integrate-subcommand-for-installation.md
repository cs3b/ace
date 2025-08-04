---
id: v.0.6.0+task.006
status: pending
priority: high
estimate: 4h
dependencies: [v.0.6.0+task.002, v.0.6.0+task.004]
release: v.0.6.0-unified-claude
---

# Implement integrate subcommand for installation

## Behavioral Specification

### User Experience
- **Input**: Developer runs `handbook claude integrate` to install commands into .claude/
- **Process**: System copies all commands and agents to project's .claude/ directory
- **Output**: Confirmation of successful installation with statistics

### Expected Behavior
The system should copy all Claude commands from the dev-handbook structure to the project's .claude/ directory, flattening the _custom and _generated structure. It should also copy agents and update the commands.json registry. The process should be idempotent, handle existing files gracefully, and provide clear feedback about what was installed.

### Interface Contract
```bash
# Full integration
handbook claude integrate
# Output:
Installing Claude commands...

Copying commands:
  ✓ Copied 6 custom commands
  ✓ Copied 19 generated commands
  ✓ Copied 2 agents
  ✓ Updated commands.json

Installation complete:
  Location: .claude/
  Commands: 25
  Agents: 2
  
Run 'claude code' to use the new commands

# Dry run
handbook claude integrate --dry-run
# Output:
Would install:
  Commands:
    - commit.md (custom)
    - draft-tasks.md (custom)
    - capture-idea.md (generated)
    [... list all ...]
  Agents:
    - feature-research.md
    - git-commit-manager.md
  
No changes made

# Integration with backup
handbook claude integrate --backup
# Output:
✓ Backed up existing .claude/ to .claude.backup.20250130-1545/
[Normal installation output]

# Force overwrite
handbook claude integrate --force
# Output:
⚠ Force mode: overwriting existing files
[Normal installation output]

# Integration from custom path
handbook claude integrate --source dev-handbook/.integrations/claude
# Output:
Installing from custom source: dev-handbook/.integrations/claude
[Normal installation output]
```

**Error Handling:**
- Missing source directories: Clear error about what's missing
- Permission denied: Error with sudo suggestion if appropriate
- Disk space issues: Error before starting copy
- Corrupted files: Skip with warning, continue

**Edge Cases:**
- No .claude directory: Create it automatically
- Existing files: Skip unless --force
- Symbolic links: Preserve or resolve based on flag
- Mixed permissions: Handle gracefully

### Success Criteria
- [ ] **Complete Installation**: All commands and agents copied
- [ ] **Registry Update**: commands.json properly updated
- [ ] **Idempotent**: Running twice is safe
- [ ] **Backup Support**: Can preserve existing setup
- [ ] **Clear Feedback**: User knows what was installed

### Validation Questions
- [ ] **File Permissions**: What permissions for installed files?
- [ ] **Symbolic Links**: Should we use symlinks or copies?
- [ ] **Partial Failure**: How to handle mid-install failures?
- [ ] **Version Tracking**: Should we track installed version?

## Objective

Provide a seamless installation experience that copies all Claude integration files from dev-handbook to the project's .claude/ directory, making commands immediately available in Claude Code.

## Scope of Work

- **User Experience Scope**: Installation workflow and feedback
- **System Behavior Scope**: File copying and registry management
- **Interface Scope**: CLI options and installation report

### Deliverables

#### Behavioral Specifications
- Installation process documentation
- File organization rules
- Backup strategy specification

#### Validation Artifacts
- Installation verification tests
- Idempotency tests
- Backup/restore tests

## Out of Scope
- ❌ **Implementation Details**: File copy methods, permission handling
- ❌ **Technology Decisions**: Copy vs symlink implementation
- ❌ **Performance Optimization**: Parallel copying, compression
- ❌ **Future Enhancements**: Incremental updates, versioning

## References

- Claude Code command structure requirements
- File system best practices
- Existing claude-integrate script behavior

## Technical Approach

### Architecture Pattern
- File copy orchestration with transaction-like behavior
- Backup management for safety
- Flattened directory structure for Claude compatibility

### Technology Stack
- Ruby FileUtils for file operations
- JSON for registry management
- Pathname for cross-platform path handling

## Tool Selection

| Tool/Library | Purpose | Rationale |
|--------------|---------|-----------|
| FileUtils | File copying | Standard library, reliable |
| Pathname | Path manipulation | Cross-platform compatibility |
| Find | Directory traversal | Efficient file discovery |

## File Modifications

### Create
- `dev-tools/lib/coding_agent_tools/cli/commands/handbook/claude/integrate.rb` - Command implementation
- `dev-tools/lib/coding_agent_tools/organisms/claude_installer.rb` - Installation logic
- `dev-tools/spec/coding_agent_tools/organisms/claude_installer_spec.rb` - Tests

### Modify
- `.claude/commands/` - Destination directory (populated)
- `.claude/commands/commands.json` - Updated registry

### Delete
- None required (unless --force used)

## Risk Assessment

### Technical Risks
- **Partial Installation**: Failure mid-copy could leave incomplete state
  - Mitigation: Implement rollback on failure
- **Permission Issues**: Different file permissions across systems
  - Mitigation: Preserve source permissions, handle errors gracefully

### Integration Risks
- **Overwriting User Customizations**: Users might have modified .claude files
  - Mitigation: Skip by default, require --force to overwrite
- **Path Resolution**: Different OS path separators
  - Mitigation: Use Pathname for cross-platform support

## Implementation Plan

### Planning Steps

* [ ] Analyze current .claude directory structure requirements
* [ ] Design backup rotation strategy
* [ ] Plan transaction-like installation with rollback
* [ ] Define file permission handling approach

### Execution Steps

- [ ] Implement integrate command class
  ```ruby
  # lib/coding_agent_tools/cli/commands/handbook/claude/integrate.rb
  module CodingAgentTools
    module CLI
      module Commands
        module Handbook
          module Claude
            class Integrate < Dry::CLI::Command
              desc "Install Claude commands into .claude/ directory"
              
              option :dry_run, type: :boolean, default: false, desc: "Show what would be done"
              option :backup, type: :boolean, default: false, desc: "Backup existing installation"
              option :force, type: :boolean, default: false, desc: "Overwrite existing files"
              option :source, type: :string, desc: "Custom source directory"
              
              def call(**options)
                installer = CodingAgentTools::Organisms::ClaudeInstaller.new
                installer.install(options)
              end
            end
          end
        end
      end
    end
  end
  ```

- [ ] Create installer organism
  ```ruby
  # lib/coding_agent_tools/organisms/claude_installer.rb
  module CodingAgentTools
    module Organisms
      class ClaudeInstaller
        def initialize
          @source_base = "dev-handbook/.integrations/claude"
          @target_base = ".claude"
        end
        
        def install(options)
          @source_base = options[:source] if options[:source]
          
          validate_source!
          create_backup if options[:backup]
          
          if options[:dry_run]
            display_dry_run
          else
            perform_installation(options[:force])
          end
        end
      end
    end
  end
  ```
  > TEST: Installer Initialization
  > Type: Unit Test
  > Assert: Installer sets correct paths
  > Command: bundle exec rspec -e "initializes with paths"

- [ ] Implement source validation
  ```ruby
  def validate_source!
    required_dirs = ["commands/_custom", "commands/_generated", "agents"]
    missing = required_dirs.reject do |dir|
      File.directory?(File.join(@source_base, dir))
    end
    
    if missing.any?
      raise "Missing required directories: #{missing.join(', ')}"
    end
  end
  ```
  > TEST: Source Validation
  > Type: Unit Test
  > Assert: Validates required directories exist
  > Command: bundle exec rspec -e "validates source structure"

- [ ] Implement backup functionality
  ```ruby
  def create_backup
    if File.directory?(@target_base)
      timestamp = Time.now.strftime("%Y%m%d-%H%M")
      backup_dir = "#{@target_base}.backup.#{timestamp}"
      
      FileUtils.cp_r(@target_base, backup_dir)
      puts "✓ Backed up existing .claude/ to #{backup_dir}/"
    end
  end
  ```

- [ ] Implement file copying with flattening
  ```ruby
  def perform_installation(force)
    ensure_target_directories
    
    stats = {
      custom_commands: 0,
      generated_commands: 0,
      agents: 0
    }
    
    # Copy custom commands (flatten structure)
    copy_commands("commands/_custom", stats[:custom_commands], force)
    
    # Copy generated commands (flatten structure)
    copy_commands("commands/_generated", stats[:generated_commands], force)
    
    # Copy agents
    copy_agents(stats[:agents], force)
    
    # Copy registry
    copy_registry(force)
    
    display_summary(stats)
  end
  
  def copy_commands(subdir, counter, force)
    source_dir = File.join(@source_base, subdir)
    target_dir = File.join(@target_base, "commands")
    
    Dir.glob(File.join(source_dir, "*.md")).each do |source|
      target = File.join(target_dir, File.basename(source))
      
      if File.exist?(target) && !force
        puts "⚠ Skipped: #{File.basename(source)} (already exists)"
      else
        FileUtils.cp(source, target)
        counter += 1
      end
    end
  end
  ```
  > TEST: File Copying
  > Type: Integration Test
  > Assert: Files copied to correct locations
  > Command: bundle exec rspec -e "copies files correctly"

- [ ] Add comprehensive test coverage
  ```ruby
  # spec/coding_agent_tools/organisms/claude_installer_spec.rb
  RSpec.describe CodingAgentTools::Organisms::ClaudeInstaller do
    describe "#install" do
      it "creates backup when requested" do
        # Test implementation
      end
      
      it "respects dry-run flag" do
        # Test implementation
      end
      
      it "handles force flag correctly" do
        # Test implementation
      end
    end
  end
  ```

- [ ] Test idempotency
  > TEST: Idempotent Installation
  > Type: Integration Test
  > Assert: Multiple runs are safe
  > Command: handbook claude integrate && handbook claude integrate

## Acceptance Criteria

- [ ] Copies all commands from both directories
- [ ] Flattens directory structure in .claude/commands/
- [ ] Copies all agents to .claude/agents/
- [ ] Updates commands.json registry
- [ ] Creates backup when requested
- [ ] Respects --force flag for overwrites
- [ ] Provides clear installation summary