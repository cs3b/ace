---
id: v.0.6.0+task.006
status: done
priority: high
estimate: 4h
dependencies: [v.0.6.0+task.002, v.0.6.0+task.004]
release: v.0.6.0-unified-claude
needs_review: false
---

# Implement integrate subcommand for installation

## Review Questions (Resolved)

### [HIGH] Critical Implementation Questions (Resolved)
- [x] Should we refactor the existing ClaudeCommandsInstaller class or create a new ClaudeInstaller organism?
  - **Research conducted**: Found existing `CodingAgentTools::Integrations::ClaudeCommandsInstaller` class
  - **Current implementation**: Handles only commands, not agents; has hardcoded paths
  - **Suggested default**: Create new `ClaudeInstaller` organism for cleaner separation
  - **Human answer**: "we should follow the architecture, refactor whats possible, ensure that our system works as we describe in tasks"
  - **Decision**: Refactor existing ClaudeCommandsInstaller to support new requirements while maintaining compatibility

- [x] How should we handle the directory structure difference between source and target?
  - **Research conducted**: Source has `commands/_custom` and `commands/_generated` subdirs (per task.003 answers)
  - **Research conducted**: Target `.claude/commands/` is flat (no subdirectories)
  - **Current behavior**: ClaudeCommandsInstaller copies from single custom dir
  - **Suggested default**: Flatten both _custom and _generated into single commands/ dir
  - **Human answer**: "in claude commands and agents we have use flat structure - so the names in the .ace/handbook part needs to be unique"
  - **Decision**: Flatten _custom and _generated directories into single .claude/commands/ directory

### [MEDIUM] Enhancement Questions (Resolved)
- [x] Should file permissions be preserved during copy on Unix systems?
  - **Research conducted**: Ruby FileUtils always copies permissions regardless of preserve flag
  - **Web search findings**: Windows has issues with preserve flag for ownership/timestamps
  - **Suggested default**: Use simple FileUtils.cp (permissions copied, no ownership preserved)
  - **Human answer**: "yes"
  - **Decision**: Use FileUtils.cp which preserves file permissions by default

- [x] What should happen if source directories are missing?
  - **Research conducted**: Current installer checks for workflow-instructions but not all dirs
  - **Current behavior**: ClaudeCommandsInstaller returns empty array if dir missing
  - **Suggested default**: Warn for missing dirs but continue with available files
  - **Human answer**: "if source is missing (from .ace/handbook), then we should print error"
  - **Decision**: Print error and exit if source directories are missing

- [x] How should agent files be handled differently from commands?
  - **Research conducted**: Agents dir exists at `.ace/handbook/.integrations/claude/agents/`
  - **Current implementation**: ClaudeCommandsInstaller doesn't handle agents at all
  - **Suggested default**: Copy agents to `.claude/agents/` with same flattening logic
  - **Human answer**: "they should also be copied (same flattening logic)"
  - **Decision**: Copy agents to .claude/agents/ using same flattening approach

### [LOW] Future Enhancement Questions (Resolved)
- [x] Should we track installed version in a metadata file?
  - **Research conducted**: No version tracking found in current implementation
  - **Suggested default**: Add `.claude/.installed-version` with timestamp and source hash
  - **Human answer**: "we should have version as timestamp, when it was last time modified (in metadata, in both commands and agents definition)"
  - **Decision**: Add last_modified timestamp metadata to each command and agent file's YAML front-matter

- [x] Should symbolic links be used instead of copies for development mode?
  - **Research conducted**: No symlink usage found in current codebase
  - **Web search findings**: FileUtils supports symlinks but cross-platform issues exist
  - **Suggested default**: Always copy files (simpler, more portable)
  - **Human answer**: "no, user should explicitly update the agents / commands"
  - **Decision**: Always copy files, no symbolic links

## Behavioral Specification

### User Experience
- **Input**: Developer runs `handbook claude integrate` to install commands into .claude/
- **Process**: System copies all commands and agents to project's .claude/ directory
- **Output**: Confirmation of successful installation with statistics

### Expected Behavior
The system should copy all Claude commands from the .ace/handbook structure to the project's .claude/ directory, flattening the _custom and _generated structure. It should also copy agents and update the commands.json registry. The process should be idempotent, handle existing files gracefully, and provide clear feedback about what was installed.

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
handbook claude integrate --source .ace/handbook/.integrations/claude
# Output:
Installing from custom source: .ace/handbook/.integrations/claude
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

Provide a seamless installation experience that copies all Claude integration files from .ace/handbook to the project's .claude/ directory, making commands immediately available in Claude Code.

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
- Existing CodingAgentTools::Integrations::ClaudeCommandsInstaller class (legacy implementation)
- Task v.0.6.0+task.003 decisions on directory structure (_custom/_generated subdirs)

## Technical Approach

### Architecture Pattern
- Refactor existing ClaudeCommandsInstaller to support new requirements
- File copy orchestration with transaction-like behavior
- Backup management for safety
- Flattened directory structure for Claude compatibility (merge _custom and _generated)
- Add agent copying functionality to existing installer
- Add timestamp metadata to copied files' YAML front-matter

### Technology Stack
- Ruby FileUtils for file operations (cross-platform compatible)
- JSON for registry management
- Pathname for cross-platform path handling
- Dry::CLI for command structure

## Tool Selection

| Tool/Library | Purpose | Rationale |
|--------------|---------|-----------|
| FileUtils | File copying | Standard library, reliable |
| Pathname | Path manipulation | Cross-platform compatibility |
| Find | Directory traversal | Efficient file discovery |

## File Modifications

### Create
- `.ace/handbook/.integrations/claude/commands/_custom/` - Directory for custom commands (if not exists)
- `.ace/handbook/.integrations/claude/commands/_generated/` - Directory for generated commands (if not exists)
- `.ace/tools/spec/coding_agent_tools/integrations/claude_commands_installer_spec.rb` - New tests for enhanced functionality

### Modify
- `.ace/tools/lib/coding_agent_tools/cli/commands/handbook/claude/integrate.rb` - Update command to support new options
- `.ace/tools/lib/coding_agent_tools/integrations/claude_commands_installer.rb` - Refactor to support agents, subdirectories, metadata
- `.claude/commands/` - Destination directory (populated with flattened structure)
- `.claude/agents/` - Destination directory for agents (created and populated)
- `.claude/commands/commands.json` - Updated registry (maintained for backward compatibility)

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

* [x] Analyze current .claude directory structure requirements
  - **Completed**: Reviewed existing 32+ command files in `.claude/commands/`
  - **Finding**: Commands are flat, agents in separate directory
* [x] Study existing ClaudeCommandsInstaller implementation
  - **Completed**: Analyzed current implementation and patterns
  - **Finding**: Already has dry_run, verbose, Result struct pattern
* [x] Design backup rotation strategy
  - **Completed**: Implemented timestamp-based backup naming (`.backup.YYYYMMDD-HHMM`)
  - **Note**: Old backup cleanup left for future enhancement
* [x] Plan subdirectory handling for _custom and _generated
  - **Completed**: Scan both subdirectories in source
  - **Completed**: Flatten into target directories
  - **Completed**: Handle name conflicts (skip by default, force with --force)
* [x] Define metadata injection approach
  - **Completed**: Read existing YAML front-matter if present
  - **Completed**: Add/update last_modified timestamp
  - **Completed**: Preserve other metadata fields

### Execution Steps

- [x] Update integrate command class to support new options
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

- [x] Refactor ClaudeCommandsInstaller to support new requirements
  ```ruby
  # lib/coding_agent_tools/integrations/claude_commands_installer.rb
  # Refactor existing class to add:
  def copy_custom_commands
    # Update to handle both _custom and _generated subdirectories
    custom_dir = project_root / '.ace/handbook' / '.integrations' / 'claude' / 'commands' / '_custom'
    generated_dir = project_root / '.ace/handbook' / '.integrations' / 'claude' / 'commands' / '_generated'
    
    # Copy from both directories, flattening structure
    [custom_dir, generated_dir].each do |dir|
      next unless dir.exist?
      
      puts "Copying from #{dir.basename}..."
      dir.glob('*.md').each do |file|
        copy_command_with_metadata(file, project_root / '.claude' / 'commands' / file.basename)
      end
    end
  end

  def copy_agents
    agents_dir = project_root / '.ace/handbook' / '.integrations' / 'claude' / 'agents'
    target_dir = project_root / '.claude' / 'agents'
    
    return unless agents_dir.exist?
    
    ensure_directory_exists(target_dir)
    
    puts "Copying agents..."
    agents_dir.glob('*.md').each do |file|
      copy_file_with_metadata(file, target_dir / file.basename, 'agent')
    end
  end

  def copy_file_with_metadata(source, target, type = 'command')
    if target.exist? && !options[:force]
      puts "  ✗ Skipped: #{target.basename} (already exists)"
      stats[:skipped] += 1
      return
    end

    content = source.read
    
    # Add or update metadata
    content = inject_metadata(content, {
      'last_modified' => Time.now.strftime('%Y-%m-%d %H:%M:%S')
    })
    
    if options[:dry_run]
      puts "  ✓ Would create: #{target.basename} (with metadata)"
    else
      target.write(content)
      puts "  ✓ Created: #{target.basename}"
    end
    stats[:created] += 1
  end

  def inject_metadata(content, metadata)
    # Handle YAML front-matter injection/update
    if content =~ /\A---\n(.*?)\n---\n/m
      # Update existing front-matter
      yaml = YAML.safe_load($1) || {}
      yaml.merge!(metadata)
      new_frontmatter = YAML.dump(yaml).sub(/^---\n/, '')
      content.sub(/\A---\n.*?\n---\n/m, "---\n#{new_frontmatter}---\n")
    else
      # Add new front-matter
      "---\n#{YAML.dump(metadata).sub(/^---\n/, '')}---\n\n#{content}"
    end
  end
  ```
  > TEST: Metadata Injection
  > Type: Unit Test
  > Assert: Correctly adds/updates YAML front-matter
  > Command: bundle exec rspec -e "injects metadata"

- [x] Implement enhanced source validation
  ```ruby
  def validate_source!
    source_base = project_root / '.ace/handbook' / '.integrations' / 'claude'
    
    # Check for new structure with subdirectories
    commands_exist = (source_base / 'commands').exist?
    custom_exist = (source_base / 'commands' / '_custom').exist?
    generated_exist = (source_base / 'commands' / '_generated').exist?
    agents_exist = (source_base / 'agents').exist?
    
    # For now, accept current flat structure or new subdirectory structure
    if !commands_exist && !custom_exist && !generated_exist
      puts "Error: No command directories found at #{source_base}"
      exit 1
    end
    
    unless agents_exist
      puts "Warning: No agents directory found at #{source_base / 'agents'}"
    end
  end
  ```
  > TEST: Source Validation
  > Type: Unit Test
  > Assert: Validates required directories and exits on error
  > Command: bundle exec rspec -e "validates source structure"

- [x] Add backup option to existing installer
  ```ruby
  def create_backup
    target = project_root / '.claude'
    return unless target.exist? && options[:backup]
    
    timestamp = Time.now.strftime("%Y%m%d-%H%M")
    backup_path = project_root / ".claude.backup.#{timestamp}"
    
    if options[:dry_run]
      puts "Would create backup at: #{backup_path}" if options[:verbose]
    else
      FileUtils.cp_r(target, backup_path)
      puts "✓ Backed up existing .claude/ to #{backup_path}/"
    end
  end
  ```

- [x] Update the run method to include new functionality
  ```ruby
  def run
    puts "Installing Claude commands#{options[:dry_run] ? ' (DRY RUN)' : ''}..."
    puts "Project root: #{project_root}" if options[:verbose]
    puts

    # Validate source directories
    validate_source!
    
    # Create backup if requested
    create_backup if options[:backup]

    # Ensure directories exist
    ensure_directories_exist

    # Copy commands from new structure (_custom and _generated)
    copy_custom_commands
    
    # Copy agents
    copy_agents

    # Scan workflows and create generated commands (existing functionality)
    workflow_files = scan_workflows
    create_commands_from_workflows(workflow_files)

    # Update commands.json
    update_commands_json

    # Print summary
    print_enhanced_summary
    
    # Return result object
    Result.new(success: stats[:errors].empty?, exit_code: stats[:errors].empty? ? 0 : 1, stats: stats)
  rescue StandardError => e
    puts "Error: #{e.message}"
    puts e.backtrace if ENV['DEBUG'] || options[:verbose]
    stats[:errors] << e.message
    Result.new(success: false, exit_code: 1, stats: stats)
  end

  def print_enhanced_summary
    puts "="*50
    puts "Installation complete:"
    puts "  Commands:"
    puts "    #{stats[:custom_commands] || 0} custom commands"
    puts "    #{stats[:generated_commands] || 0} generated commands"
    puts "    #{stats[:workflow_commands] || 0} workflow commands"
    puts "  Agents:"
    puts "    #{stats[:agents] || 0} agents"
    puts "  Other:"
    puts "    #{stats[:updated]} files updated"
    puts "    #{stats[:skipped]} files skipped"
    
    if stats[:errors].any?
      puts
      puts "Errors encountered:"
      stats[:errors].each { |error| puts "  - #{error}" }
    end
    
    puts "="*50
    puts
    puts "Location: #{project_root / '.claude'}"
    puts "Run 'claude code' to use the new commands"
  end
  ```
  > TEST: Enhanced Installation
  > Type: Integration Test
  > Assert: Installs commands, agents with metadata
  > Command: bundle exec rspec -e "performs full installation"

- [x] Add comprehensive test coverage
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

- [x] Test idempotency
  > TEST: Idempotent Installation
  > Type: Integration Test
  > Assert: Multiple runs are safe
  > Command: handbook claude integrate && handbook claude integrate

## Acceptance Criteria

- [x] Copies all commands from both _custom and _generated directories
- [x] Flattens directory structure in .claude/commands/
- [x] Copies all agents to .claude/agents/
- [x] Adds last_modified timestamp to all copied files' YAML front-matter
- [x] Updates commands.json registry (for backward compatibility)
- [x] Creates backup when --backup flag is used
- [x] Respects --force flag for overwrites
- [x] Exits with error if source directories are missing
- [x] Provides clear installation summary with categorized counts
- [x] Maintains compatibility with existing ClaudeCommandsInstaller patterns

## Review Summary

**Date:** 2025-08-04
**Reviewer:** Claude (Automated Review)

**Questions Previously Generated:** 7 total (2 HIGH, 3 MEDIUM, 2 LOW)
**Questions Resolved:** All 7 questions have been answered by human input
**Critical Blockers:** None - all questions resolved

**Research Conducted:**
- ✅ Analyzed existing ClaudeCommandsInstaller class - already has dry_run, verbose, Result struct
- ✅ Verified existing CLI command at handbook/claude/integrate.rb
- ✅ Checked current .claude directory structure - flat commands/, separate agents/
- ✅ Reviewed task.003 decisions about _custom and _generated subdirectories
- ✅ Examined task.004 for metadata requirements (YAML front-matter with timestamps)
- ✅ Verified current implementation copies only from flat commands/ directory
- ✅ Confirmed agents directory exists but is not handled by current installer

**Content Updates Made:**
- Moved all Review Questions to "Resolved" section with human answers and decisions
- Updated Technical Approach to refactor existing installer instead of creating new organism
- Modified File Modifications to reflect refactoring approach
- Enhanced Implementation Plan with completed research steps
- Updated code examples to extend existing ClaudeCommandsInstaller functionality
- Added metadata injection logic for last_modified timestamps in YAML front-matter
- Added support for copying from _custom and _generated subdirectories
- Added agent copying functionality with same flattening approach
- Added error handling for missing source directories (exit on error)
- Enhanced summary output to show categorized counts
- Set needs_review flag to false as all questions are resolved

**Implementation Readiness:** Ready for implementation

**Recommended Next Steps:**
1. Create _custom and _generated subdirectories if they don't exist
2. Migrate existing custom commands to _custom/ subdirectory
3. Refactor ClaudeCommandsInstaller to support new directory structure
4. Add agent copying functionality with metadata injection
5. Implement backup option (--backup flag)
6. Add comprehensive error handling for missing directories
7. Update installation summary to show categorized counts
8. Test with various scenarios (missing dirs, existing files, metadata injection)
