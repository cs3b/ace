---
id: v.0.3.0+task.112
status: done
priority: high
estimate: 8h
dependencies: []
---

# Add create-path command for file/directory creation with metadata

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-tools/lib/coding_agent_tools/cli | sed 's/^/    /'
```

_Result excerpt:_

```
dev-tools/lib/coding_agent_tools/cli/
├── code_lint_command.rb
├── code_review_command.rb
├── git_commands/
├── handbook_command.rb
├── llm_query_command.rb
├── nav_commands/
├── reflection_synthesize_command.rb
├── release_manager_command.rb
└── task_manager_command.rb
```

## Objective

Create a new `create-path` command that allows users to create files and directories with content, integrated with the same metadata capabilities as `task-new`. This command will delegate path generation to the existing nav-path Ruby classes (not via command line) and use templates configured in `.coding-agent/create-path.yml`. This keeps `nav-path` unchanged for its current navigation/preview functionality while providing a dedicated command for actual file/directory creation operations.

## Scope of Work

- Add new `create-path` CLI command to the dev-tools gem
- Delegate path generation to nav-path Ruby classes (PathResolver) directly
- Use template-based content from `.coding-agent/create-path.yml` configuration
- Support metadata attributes via command-line parameters
- Implement fail-by-default overwrite behavior with `--force` flag
- Maintain consistency with existing CLI command patterns
- Provide comprehensive help documentation

### Deliverables

#### Create

- `dev-tools/lib/coding_agent_tools/cli/create_path_command.rb`
- `dev-tools/exe/create-path`
- `.coding-agent/create-path.yml` - template configuration file
- Unit tests for the new command in `dev-tools/spec/cli/create_path_command_spec.rb`

#### Modify

- `dev-tools/lib/coding_agent_tools/cli.rb` (register new command)
- `dev-tools/coding_agent_tools.gemspec` (add new executable)
- `dev-tools/docs/tools.md` (document new command)

## Phases

1. Analyze existing nav-path and task-new implementations
2. Design create-path command interface and metadata integration
3. Implement core functionality
4. Add comprehensive testing
5. Update documentation

## Implementation Plan

### Planning Steps

- [x] Analyze current nav-path command implementation to understand existing patterns
  > TEST: Understanding Check
  > Type: Pre-condition Check  
  > Assert: nav-path command structure and patterns are identified
  > Command: Read dev-tools/lib/coding_agent_tools/cli/nav_commands/nav_path_command.rb
- [x] Analyze task-new metadata integration to understand metadata system
- [x] Research CLI patterns in existing commands for consistency
- [x] Study security infrastructure (SecurePathValidator, FileIoHandler) for safe file operations
- [x] Analyze PathResolver class for direct Ruby integration (no CLI calls)
- [x] Design `.coding-agent/create-path.yml` configuration structure for templates
- [x] Design command interface with flags (--force) and metadata attributes

### Execution Steps

- [x] Create create_path_command.rb with basic CLI structure following ATOM patterns
- [x] Integrate SecurePathValidator for all path validation
  > TEST: Security Validation
  > Type: Security Check
  > Assert: Path traversal attempts are blocked, forbidden patterns rejected
  > Command: rspec spec/cli/create_path_command_spec.rb -e "security"
- [x] Integrate with PathResolver Ruby class for path generation (no CLI calls)
  > TEST: Path Resolution
  > Type: Integration Check
  > Assert: Paths generated match nav-path output exactly
  > Command: rspec spec/cli/create_path_command_spec.rb -e "path resolution"
- [x] Implement file creation using FileIoHandler molecule
- [x] Implement fail-by-default behavior with --force flag for overwrites
- [x] Create `.coding-agent/create-path.yml` configuration loader
- [x] Implement template resolution from dev-handbook/templates/ based on config
- [x] Add metadata injection - non-flag parameters become template variables
  > TEST: Content Injection
  > Type: Functionality Check
  > Assert: Files created with correct content from various sources
  > Command: rspec spec/cli/create_path_command_spec.rb -e "content"
- [x] Implement directory creation functionality with recursive support
- [x] Let PathResolver handle multi-repo context (paths go where nav-path directs)
- [x] Create executable script in exe/ directory
- [x] Register command in main CLI module
- [x] Add comprehensive unit tests including security scenarios
- [x] Update gemspec with new executable
- [x] Update tools documentation with command usage and examples

## Acceptance Criteria

- [x] AC 1: create-path delegates to PathResolver Ruby class for all path generation
- [x] AC 2: Templates are loaded from `.coding-agent/create-path.yml` configuration
- [x] AC 3: Files created in exact location where nav-path would resolve them
- [x] AC 4: Overwrite fails by default, requires --force flag
- [x] AC 5: Non-flag parameters are treated as metadata for template variables
- [x] AC 6: Command follows existing CLI patterns and conventions
- [x] AC 7: Comprehensive test coverage (≥95%) for new functionality including security tests
- [x] AC 8: Documentation updated with usage examples and configuration

## Out of Scope

- ❌ Modifying existing nav-path command behavior
- ❌ Complex templating system beyond variable substitution
- ❌ Integration with external file management systems
- ❌ Advanced file permissions or ownership management
- ❌ Command-line path generation (must use PathResolver class)
- ❌ Custom repository selection (always use nav-path's decision)

## Implementation Example

```bash
# Create a new task using create-path
create-path task-new "implement-feature-x" priority:high estimate:4h

# This will:
# 1. Call PathResolver.resolve("task-new", "implement-feature-x") to get path
# 2. Load template from .coding-agent/create-path.yml mapping
# 3. Inject metadata (priority: high, estimate: 4h) into template
# 4. Create file at resolved path with populated content
```

## References

- Existing nav-path implementation: `dev-tools/lib/coding_agent_tools/cli/nav_commands/nav_path_command.rb`
- Task-new metadata system: Used by nav-path task-new functionality
- CLI patterns: Other commands in `dev-tools/lib/coding_agent_tools/cli/`
- Security infrastructure: `SecurePathValidator`, `FileIoHandler`, `FileOperationConfirmer`
- Multi-repo support: `RepositoryScanner`, `ProjectRootDetector`
- Path resolution: `PathResolver` molecule with `.coding-agent/path.yml` config
- Template configuration: `.coding-agent/create-path.yml` for template mappings
- Template storage: `dev-handbook/templates/` directory