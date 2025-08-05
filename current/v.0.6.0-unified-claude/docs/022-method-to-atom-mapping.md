# Method to ATOM Component Mapping for ClaudeCommandsInstaller

## Current Method Analysis

### Data Structures → Models
- `@stats` hash → `Models::InstallationStats`
- `@options` hash → `Models::InstallationOptions`
- `Result` struct → `Models::InstallationResult`
- Metadata hash in `inject_metadata` → `Models::CommandMetadata`
- File operation info → `Models::FileOperation`

### Utility Methods → Atoms
- `inject_metadata` → `Atoms::YamlFrontmatterParser` (already exists)
- Timestamp generation in `create_backup` → `Atoms::TimestampGenerator`
- Path validation/sanitization → `Atoms::PathSanitizer`
- `ensure_directory_exists` → `Atoms::Code::DirectoryCreator` (already exists)

### Focused Operations → Molecules
- `find_project_root` → `Molecules::ProjectRootFinder`
- `validate_source!` → `Molecules::SourceDirectoryValidator`
- `create_backup` → `Molecules::BackupCreator`
- `inject_metadata` → `Molecules::MetadataInjector`
- `copy_file_with_metadata` → `Molecules::FileOperationExecutor`
- `get_custom_template` → `Molecules::CommandTemplateRenderer`
- Statistics tracking → `Molecules::StatisticsCollector`

### Business Logic → Organisms
- `scan_workflows` + directory discovery → `Organisms::CommandDiscoverer`
- `copy_custom_commands` → `Organisms::CommandInstaller`
- `copy_agents` → `Organisms::AgentInstaller`
- `create_commands_from_workflows` + `create_command_file` → `Organisms::WorkflowCommandGenerator`
- `run` method orchestration → `Organisms::ClaudeCommandsOrchestrator`

## Dependency Flow

```
ClaudeCommandsInstaller (thin wrapper)
  └── Organisms::ClaudeCommandsOrchestrator
      ├── Models::InstallationOptions
      ├── Models::InstallationStats
      ├── Molecules::ProjectRootFinder
      │   └── Atoms::PathSanitizer
      ├── Molecules::SourceDirectoryValidator
      │   └── Atoms::PathSanitizer
      ├── Molecules::BackupCreator
      │   ├── Atoms::TimestampGenerator
      │   └── Atoms::Code::DirectoryCreator
      ├── Organisms::CommandDiscoverer
      │   └── Molecules::SourceDirectoryValidator
      ├── Organisms::CommandInstaller
      │   ├── Molecules::FileOperationExecutor
      │   └── Molecules::MetadataInjector
      │       └── Atoms::YamlFrontmatterParser
      ├── Organisms::AgentInstaller
      │   ├── Molecules::FileOperationExecutor
      │   └── Molecules::MetadataInjector
      ├── Organisms::WorkflowCommandGenerator
      │   ├── Molecules::CommandTemplateRenderer
      │   └── Molecules::FileOperationExecutor
      └── Molecules::StatisticsCollector
          └── Models::InstallationStats
```

## Notes

- The existing `Atoms::YamlFrontmatterParser` can be reused for metadata parsing
- The existing `Atoms::Code::DirectoryCreator` can be reused for directory creation
- Each component will have explicit dependencies injected via constructor
- The original class will become a thin CLI wrapper that delegates to the orchestrator