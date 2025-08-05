# Claude Tools ATOM Design Specification

## Atoms (Indivisible Utilities)

### 1. WorkflowScanner
**Purpose**: Scan workflow directory for .wf.md files

```ruby
module CodingAgentTools
  module Atoms
    module Claude
      class WorkflowScanner
        # @param workflow_dir [Pathname] Directory to scan
        # @param pattern [String, nil] Optional glob pattern (e.g., "create-*")
        # @return [Array<String>] List of workflow names (without .wf.md extension)
        def self.scan(workflow_dir, pattern = nil)
          # Implementation
        end
      end
    end
  end
end
```

### 2. CommandExistenceChecker
**Purpose**: Check if a command file exists in various locations

```ruby
module CodingAgentTools
  module Atoms
    module Claude
      class CommandExistenceChecker
        # @param command_name [String] Name of the command (without .md)
        # @param search_paths [Array<Pathname>] Paths to search
        # @return [Pathname, nil] Path to command file if found
        def self.find(command_name, search_paths)
          # Implementation
        end

        # @param command_name [String] Name of the command
        # @param search_paths [Array<Pathname>] Paths to search
        # @return [Boolean] True if command exists
        def self.exists?(command_name, search_paths)
          # Implementation
        end
      end
    end
  end
end
```

### 3. YamlFrontmatterValidator
**Purpose**: Validate YAML frontmatter in generated commands

```ruby
module CodingAgentTools
  module Atoms
    module Claude
      class YamlFrontmatterValidator
        # @param content [String] File content with YAML frontmatter
        # @return [Boolean] True if valid YAML
        def self.valid?(content)
          # Implementation
        end

        # @param content [String] File content
        # @return [Hash, nil] Parsed YAML data or nil if invalid
        def self.parse(content)
          # Implementation
        end
      end
    end
  end
end
```

## Molecules (Behavior-Oriented Helpers)

### 1. CommandMetadataInferrer
**Purpose**: Infer metadata from workflow names

```ruby
module CodingAgentTools
  module Molecules
    module Claude
      class CommandMetadataInferrer
        # @param workflow_name [String] Name of the workflow
        # @return [Hash] Metadata with :description, :allowed_tools, :argument_hint, :model
        def infer(workflow_name)
          # Implementation
        end
      end
    end
  end
end
```

### 2. CommandTemplateRenderer
**Purpose**: Render command templates with metadata

```ruby
module CodingAgentTools
  module Molecules
    module Claude
      class CommandTemplateRenderer
        # @param workflow_name [String] Name of the workflow
        # @param metadata [Hash] Metadata for rendering
        # @param template_content [String, nil] Optional template content
        # @return [String] Rendered command content
        def render(workflow_name, metadata, template_content = nil)
          # Implementation
        end
      end
    end
  end
end
```

### 3. CommandInventoryBuilder
**Purpose**: Build unified inventory of commands from multiple sources

```ruby
module CodingAgentTools
  module Molecules
    module Claude
      class CommandInventoryBuilder
        def initialize(project_root)
          @project_root = project_root
          # Define search paths
        end

        # @return [Hash] Inventory with :commands array and counts
        def build
          # Implementation
        end

        # @param type [String] Filter by type (custom, generated, missing, all)
        # @return [Hash] Filtered inventory
        def filter_by_type(inventory, type)
          # Implementation
        end
      end
    end
  end
end
```

### 4. CommandValidator
**Purpose**: Validate command coverage and consistency

```ruby
module CodingAgentTools
  module Molecules
    module Claude
      class CommandValidator
        def initialize(project_root)
          @project_root = project_root
        end

        # @return [Array<String>] List of missing command names
        def find_missing_commands
          # Implementation
        end

        # @return [Array<Hash>] List of outdated commands with details
        def find_outdated_commands
          # Implementation
        end

        # @return [Array<Hash>] List of duplicate commands with locations
        def find_duplicate_commands
          # Implementation
        end

        # @return [Array<Hash>] List of orphaned commands
        def find_orphaned_commands
          # Implementation
        end
      end
    end
  end
end
```

## Models (Data Carriers)

### 1. ClaudeCommand
**Purpose**: Represent a Claude command with all its attributes

```ruby
module CodingAgentTools
  module Models
    ClaudeCommand = Struct.new(
      :name,           # String - Command name without extension
      :type,           # String - custom, generated, or missing
      :path,           # String - Relative path from project root
      :installed,      # Boolean - Whether installed in .claude/commands
      :valid,          # Boolean - Whether command is valid
      :size,           # Integer - File size in bytes (optional)
      :modified,       # Time - Last modification time (optional)
      :modified_iso,   # String - ISO format timestamp (optional)
      keyword_init: true
    )
  end
end
```

### 2. ClaudeValidationResult
**Purpose**: Carry validation results data

```ruby
module CodingAgentTools
  module Models
    ClaudeValidationResult = Struct.new(
      :workflow_count,  # Integer - Total workflows found
      :command_count,   # Integer - Total commands found
      :missing,         # Array<String> - Missing command names
      :outdated,        # Array<Hash> - Outdated commands with details
      :duplicates,      # Array<Hash> - Duplicate commands with locations
      :orphaned,        # Array<Hash> - Orphaned commands
      :valid,           # Array<String> - Valid command names
      keyword_init: true
    ) do
      def has_issues?
        missing.any? || outdated.any? || duplicates.any?
      end

      def summary_counts
        {
          missing_count: missing.size,
          outdated_count: outdated.size,
          duplicate_count: duplicates.size,
          orphaned_count: orphaned.size,
          valid_count: valid.size
        }
      end
    end
  end
end
```

## Refactored Organisms (Orchestration)

### ClaudeCommandGenerator
Will orchestrate:
- WorkflowScanner (atom) for finding workflows
- CommandExistenceChecker (atom) for checking existing commands
- CommandMetadataInferrer (molecule) for metadata generation
- CommandTemplateRenderer (molecule) for content generation
- YamlFrontmatterValidator (atom) for validation

### ClaudeCommandLister
Will orchestrate:
- CommandInventoryBuilder (molecule) for building inventory
- TableRenderer (existing atom) for output formatting

### ClaudeValidator
Will orchestrate:
- CommandValidator (molecule) for all validation checks
- ClaudeValidationResult (model) for results
- Output formatting for text/JSON

## Testing Strategy

### Unit Tests for Atoms
- Test pure functions with various inputs
- No mocking needed (no dependencies)
- Edge cases: empty dirs, missing files, invalid YAML

### Unit Tests for Molecules
- Mock atom dependencies
- Test behavior and composition
- Edge cases: complex workflows, edge case names

### Integration Tests for Organisms
- Test full workflows with real file system
- Use temporary directories for isolation
- Verify end-to-end functionality