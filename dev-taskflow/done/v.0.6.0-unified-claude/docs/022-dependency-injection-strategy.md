# Dependency Injection Strategy for ClaudeCommandsInstaller Refactoring

## Overview

This document outlines the dependency injection strategy for refactoring the ClaudeCommandsInstaller to follow ATOM architecture principles. The strategy focuses on explicit dependency injection via constructors to improve testability and maintainability.

## Core Principles

1. **Constructor Injection**: All dependencies are injected through constructors
2. **Explicit Dependencies**: No hidden dependencies or global state
3. **Interface Segregation**: Components depend on narrow interfaces, not concrete implementations
4. **Testability First**: Each component can be tested in isolation with mocked dependencies
5. **Single Responsibility**: Each component has one clear responsibility

## Component Dependency Structure

### Models (No Dependencies)
Pure data structures with no external dependencies:
- `InstallationStats` - Simple value object
- `InstallationOptions` - Configuration value object
- `InstallationResult` - Result value object
- `CommandMetadata` - Metadata value object
- `FileOperation` - Operation descriptor

### Atoms (No Internal Dependencies)
- `TimestampGenerator` - Pure function for timestamp formatting
- `PathSanitizer` - Pure functions for path validation/normalization
- `YamlFrontmatterParser` - Already exists, pure YAML parsing
- `DirectoryCreator` - Already exists, filesystem operations

### Molecules (Depend on Atoms/Models)

```ruby
class ProjectRootFinder
  def initialize(path_sanitizer: Atoms::PathSanitizer.new)
    @path_sanitizer = path_sanitizer
  end
end

class SourceDirectoryValidator
  def initialize(path_sanitizer: Atoms::PathSanitizer.new)
    @path_sanitizer = path_sanitizer
  end
end

class BackupCreator
  def initialize(
    timestamp_generator: Atoms::TimestampGenerator.new,
    directory_creator: Atoms::Code::DirectoryCreator.new
  )
    @timestamp_generator = timestamp_generator
    @directory_creator = directory_creator
  end
end

class MetadataInjector
  def initialize(yaml_parser: Atoms::TaskflowManagement::YamlFrontmatterParser)
    @yaml_parser = yaml_parser
  end
end

class FileOperationExecutor
  def initialize(directory_creator: Atoms::Code::DirectoryCreator.new)
    @directory_creator = directory_creator
  end
end

class CommandTemplateRenderer
  # No dependencies - pure template logic
end

class StatisticsCollector
  # No dependencies - operates on InstallationStats model
end
```

### Organisms (Depend on Molecules/Atoms/Models)

```ruby
class CommandDiscoverer
  def initialize(source_validator: Molecules::SourceDirectoryValidator.new)
    @source_validator = source_validator
  end
end

class CommandInstaller
  def initialize(
    file_executor: Molecules::FileOperationExecutor.new,
    metadata_injector: Molecules::MetadataInjector.new,
    stats_collector: Molecules::StatisticsCollector.new
  )
    @file_executor = file_executor
    @metadata_injector = metadata_injector
    @stats_collector = stats_collector
  end
end

class AgentInstaller
  def initialize(
    file_executor: Molecules::FileOperationExecutor.new,
    metadata_injector: Molecules::MetadataInjector.new,
    stats_collector: Molecules::StatisticsCollector.new
  )
    @file_executor = file_executor
    @metadata_injector = metadata_injector
    @stats_collector = stats_collector
  end
end

class WorkflowCommandGenerator
  def initialize(
    template_renderer: Molecules::CommandTemplateRenderer.new,
    file_executor: Molecules::FileOperationExecutor.new,
    stats_collector: Molecules::StatisticsCollector.new
  )
    @template_renderer = template_renderer
    @file_executor = file_executor
    @stats_collector = stats_collector
  end
end

class ClaudeCommandsOrchestrator
  def initialize(
    project_root_finder: Molecules::ProjectRootFinder.new,
    source_validator: Molecules::SourceDirectoryValidator.new,
    backup_creator: Molecules::BackupCreator.new,
    command_discoverer: Organisms::CommandDiscoverer.new,
    command_installer: Organisms::CommandInstaller.new,
    agent_installer: Organisms::AgentInstaller.new,
    workflow_generator: Organisms::WorkflowCommandGenerator.new,
    stats_collector: Molecules::StatisticsCollector.new
  )
    @project_root_finder = project_root_finder
    @source_validator = source_validator
    @backup_creator = backup_creator
    @command_discoverer = command_discoverer
    @command_installer = command_installer
    @agent_installer = agent_installer
    @workflow_generator = workflow_generator
    @stats_collector = stats_collector
  end
end
```

## Testing Strategy

### Unit Testing
Each component can be tested in isolation:

```ruby
# Example: Testing BackupCreator
RSpec.describe Molecules::BackupCreator do
  let(:timestamp_generator) { instance_double(Atoms::TimestampGenerator) }
  let(:directory_creator) { instance_double(Atoms::Code::DirectoryCreator) }
  let(:backup_creator) { described_class.new(
    timestamp_generator: timestamp_generator,
    directory_creator: directory_creator
  ) }

  it "creates backup with timestamp" do
    allow(timestamp_generator).to receive(:generate).and_return("20250805-123456")
    allow(directory_creator).to receive(:create).and_return({success: true})
    
    result = backup_creator.create_backup("/path/to/.claude")
    expect(result[:path]).to eq("/path/to/.claude.backup.20250805-123456")
  end
end
```

### Integration Testing
The orchestrator can be tested with real components or selective mocking:

```ruby
RSpec.describe Organisms::ClaudeCommandsOrchestrator do
  # Can use real components for integration tests
  let(:orchestrator) { described_class.new }
  
  # Or mock specific components for focused testing
  let(:command_installer) { instance_double(Organisms::CommandInstaller) }
  let(:orchestrator) { described_class.new(command_installer: command_installer) }
end
```

## Factory Pattern (Optional)

For complex dependency graphs, we can introduce a factory:

```ruby
class ClaudeCommandsFactory
  def self.build_orchestrator(options = {})
    # Build complete dependency graph
    path_sanitizer = Atoms::PathSanitizer.new
    timestamp_generator = Atoms::TimestampGenerator.new
    directory_creator = Atoms::Code::DirectoryCreator.new
    yaml_parser = Atoms::TaskflowManagement::YamlFrontmatterParser
    
    # Build molecules
    project_root_finder = Molecules::ProjectRootFinder.new(path_sanitizer: path_sanitizer)
    # ... build other molecules
    
    # Build organisms
    # ... build organisms
    
    # Return orchestrator
    ClaudeCommandsOrchestrator.new(
      project_root_finder: project_root_finder,
      # ... other dependencies
    )
  end
end
```

## Benefits

1. **Testability**: Each component can be tested with mocked dependencies
2. **Flexibility**: Easy to swap implementations for different behaviors
3. **Clarity**: Dependencies are explicit and visible
4. **Maintainability**: Changes to one component don't ripple through the system
5. **Reusability**: Components can be reused in different contexts