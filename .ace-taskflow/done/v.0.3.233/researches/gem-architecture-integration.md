# Gem Architecture Integration Design: ATOM Pattern for Task Management

## Overview

This document provides the detailed architectural design for integrating task management tools from `exe-old` into the `coding_agent_tools` Ruby gem using the ATOM (Atoms, Molecules, Organisms, Ecosystems) pattern.

## ATOM Architecture Deep Dive

### Layer 1: Atoms (Indivisible Components)

#### atoms/task_management/

**file_system_scanner.rb**

```ruby
module CodingAgentTools
  module Atoms
    module TaskManagement
      class FileSystemScanner
        # Scan directories for markdown files
        def self.scan_directory(path, pattern: "*.md")
          Dir.glob(File.join(path, "**", pattern))
        end
        
        # Check if file exists and is readable
        def self.file_accessible?(path)
          File.exist?(path) && File.readable?(path)
        end
      end
    end
  end
end
```

**yaml_frontmatter_parser.rb**

```ruby
module CodingAgentTools
  module Atoms
    module TaskManagement
      class YamlFrontmatterParser
        # Extract YAML frontmatter from markdown content
        def self.extract_frontmatter(content)
          return {} unless content.start_with?("---\n")
          
          parts = content.split(/^---\s*$/, 3)
          return {} if parts.length < 3
          
          YAML.safe_load(parts[1]) || {}
        rescue Psych::SyntaxError
          {}
        end
        
        # Extract content without frontmatter
        def self.extract_content(content)
          return content unless content.start_with?("---\n")
          
          parts = content.split(/^---\s*$/, 3)
          return content if parts.length < 3
          
          parts[2].strip
        end
      end
    end
  end
end
```

**task_id_parser.rb**

```ruby
module CodingAgentTools
  module Atoms
    module TaskManagement
      class TaskIdParser
        TASK_ID_REGEX = /^v\.\d+\.\d+\.\d+\+task\.(\d+)$/
        VERSION_REGEX = /^v\.\d+\.\d+\.\d+$/
        
        # Parse task sequential number from ID
        def self.parse_sequential_number(task_id)
          match = task_id.match(TASK_ID_REGEX)
          match ? match[1].to_i : Float::INFINITY
        end
        
        # Extract version from task ID
        def self.extract_version(task_id)
          match = task_id.match(/^(v\.\d+\.\d+\.\d+)/)
          match ? match[1] : nil
        end
        
        # Validate task ID format
        def self.valid_task_id?(task_id)
          !!(task_id =~ TASK_ID_REGEX)
        end
      end
    end
  end
end
```

**directory_navigator.rb**

```ruby
module CodingAgentTools
  module Atoms
    module TaskManagement
      class DirectoryNavigator
        # Find release directories
        def self.find_release_directories(base_path)
          Dir.glob(File.join(base_path, "v.*")).select { |path| File.directory?(path) }
        end
        
        # Check if directory follows release naming pattern
        def self.release_directory?(dir_name)
          !!(File.basename(dir_name) =~ /^v\.\d+\.\d+\.\d+/)
        end
        
        # Extract version from directory name
        def self.extract_version_from_directory(dir_name)
          match = File.basename(dir_name).match(/^(v\.\d+\.\d+\.\d+)/)
          match ? match[1] : nil
        end
      end
    end
  end
end
```

### Layer 2: Molecules (Simple Compositions)

#### molecules/task_management/

**task_file_loader.rb**

```ruby
module CodingAgentTools
  module Molecules
    module TaskManagement
      class TaskFileLoader
        include CodingAgentTools::Atoms::TaskManagement
        
        # Load and parse a single task file
        def self.load_task_file(file_path)
          return nil unless FileSystemScanner.file_accessible?(file_path)
          
          content = File.read(file_path)
          metadata = YamlFrontmatterParser.extract_frontmatter(content)
          body = YamlFrontmatterParser.extract_content(content)
          
          {
            path: file_path,
            metadata: metadata,
            content: body,
            id: metadata['id'],
            status: metadata['status'],
            priority: metadata['priority'],
            dependencies: metadata['dependencies'] || []
          }
        rescue => e
          # Log error but don't crash
          nil
        end
        
        # Load multiple task files from directory
        def self.load_task_files_from_directory(directory_path)
          task_files = FileSystemScanner.scan_directory(
            File.join(directory_path, "tasks")
          )
          
          task_files.map { |file| load_task_file(file) }.compact
        end
      end
    end
  end
end
```

**release_path_resolver.rb**

```ruby
module CodingAgentTools
  module Molecules
    module TaskManagement
      class ReleasePathResolver
        include CodingAgentTools::Atoms::TaskManagement
        
        # Find current release directory
        def self.find_current_release(base_path = ".ace/taskflow")
          current_path = File.join(base_path, "current")
          return nil unless File.directory?(current_path)
          
          release_dirs = DirectoryNavigator.find_release_directories(current_path)
          return nil if release_dirs.empty?
          
          # Return first found - should only be one current release
          release_dirs.first
        end
        
        # Get current release version
        def self.current_release_version(base_path = ".ace/taskflow")
          current_release = find_current_release(base_path)
          return nil unless current_release
          
          DirectoryNavigator.extract_version_from_directory(current_release)
        end
        
        # Get appropriate directory for new tasks
        def self.resolve_task_directory(base_path = ".ace/taskflow")
          current_release = find_current_release(base_path)
          
          if current_release
            File.join(current_release, "tasks")
          else
            File.join(base_path, "backlog", "tasks")
          end
        end
      end
    end
  end
end
```

**task_dependency_checker.rb**

```ruby
module CodingAgentTools
  module Molecules
    module TaskManagement
      class TaskDependencyChecker
        # Check if all dependencies are met for a task
        def self.dependencies_met?(task, all_tasks)
          return true if task[:dependencies].empty?
          
          dependency_statuses = task[:dependencies].map do |dep_id|
            dep_task = all_tasks.find { |t| t[:id] == dep_id }
            dep_task&.dig(:status) == 'done'
          end
          
          dependency_statuses.all?(true)
        end
        
        # Find tasks with unmet dependencies
        def self.find_blocked_tasks(tasks)
          tasks.select do |task|
            !dependencies_met?(task, tasks) && task[:status] != 'done'
          end
        end
        
        # Find actionable tasks (not done, dependencies met)
        def self.find_actionable_tasks(tasks)
          tasks.select do |task|
            task[:status] != 'done' && dependencies_met?(task, tasks)
          end
        end
      end
    end
  end
end
```

**task_id_generator.rb**

```ruby
module CodingAgentTools
  module Molecules
    module TaskManagement
      class TaskIdGenerator
        include CodingAgentTools::Atoms::TaskManagement
        
        # Generate next available task ID for version
        def self.next_task_id(version, base_path = ".ace/taskflow")
          existing_tasks = collect_existing_task_ids(version, base_path)
          max_number = existing_tasks.map { |id| TaskIdParser.parse_sequential_number(id) }
                                   .select { |num| num != Float::INFINITY }
                                   .max || 0
          
          "#{version}+task.#{max_number + 1}"
        end
        
        private
        
        def self.collect_existing_task_ids(version, base_path)
          task_ids = []
          
          # Check current releases
          current_path = File.join(base_path, "current")
          if File.directory?(current_path)
            DirectoryNavigator.find_release_directories(current_path).each do |release_dir|
              tasks = TaskFileLoader.load_task_files_from_directory(release_dir)
              task_ids.concat(tasks.map { |t| t[:id] }.compact)
            end
          end
          
          # Check backlog
          backlog_path = File.join(base_path, "backlog")
          if File.directory?(backlog_path)
            DirectoryNavigator.find_release_directories(backlog_path).each do |release_dir|
              tasks = TaskFileLoader.load_task_files_from_directory(release_dir)
              task_ids.concat(tasks.map { |t| t[:id] }.compact)
            end
          end
          
          # Filter by version
          task_ids.select { |id| TaskIdParser.extract_version(id) == version }
        end
      end
    end
  end
end
```

### Layer 3: Organisms (Business Logic)

#### organisms/task_management/

**task_manager.rb**

```ruby
module CodingAgentTools
  module Organisms
    module TaskManagement
      class TaskManager
        include CodingAgentTools::Molecules::TaskManagement
        include CodingAgentTools::Atoms::TaskManagement
        
        attr_reader :base_path
        
        def initialize(base_path = ".ace/taskflow")
          @base_path = base_path
        end
        
        # Find next actionable task
        def find_next_task
          tasks = load_all_current_tasks
          actionable_tasks = TaskDependencyChecker.find_actionable_tasks(tasks)
          
          # Sort by priority then by task number
          sorted_tasks = actionable_tasks.sort_by do |task|
            priority_weight = priority_to_weight(task[:priority])
            task_number = TaskIdParser.parse_sequential_number(task[:id] || "")
            [priority_weight, task_number]
          end
          
          sorted_tasks.first
        end
        
        # Find recent tasks
        def find_recent_tasks(since_seconds = 86400) # 1 day default
          tasks = load_all_current_tasks
          cutoff_time = Time.now - since_seconds
          
          # Filter by modification time and status
          recent_tasks = tasks.select do |task|
            next false unless task[:path]
            
            file_mtime = File.mtime(task[:path])
            file_mtime > cutoff_time && 
            ['done', 'in-progress'].include?(task[:status])
          end
          
          # Sort by modification time (newest first)
          recent_tasks.sort_by { |task| -File.mtime(task[:path]).to_i }
        end
        
        # Get all tasks
        def get_all_tasks
          load_all_tasks_from_all_releases
        end
        
        # Generate next task ID
        def generate_next_task_id(version)
          TaskIdGenerator.next_task_id(version, base_path)
        end
        
        private
        
        def load_all_current_tasks
          current_release = ReleasePathResolver.find_current_release(base_path)
          return [] unless current_release
          
          TaskFileLoader.load_task_files_from_directory(current_release)
        end
        
        def load_all_tasks_from_all_releases
          tasks = []
          
          # Load from current releases
          current_path = File.join(base_path, "current")
          if File.directory?(current_path)
            DirectoryNavigator.find_release_directories(current_path).each do |release_dir|
              tasks.concat(TaskFileLoader.load_task_files_from_directory(release_dir))
            end
          end
          
          # Load from backlog
          backlog_path = File.join(base_path, "backlog")
          if File.directory?(backlog_path)
            DirectoryNavigator.find_release_directories(backlog_path).each do |release_dir|
              tasks.concat(TaskFileLoader.load_task_files_from_directory(release_dir))
            end
          end
          
          tasks
        end
        
        def priority_to_weight(priority)
          case priority&.downcase
          when 'high', 'critical' then 0
          when 'medium' then 1
          when 'low' then 2
          else 3
          end
        end
      end
    end
  end
end
```

**release_manager.rb**

```ruby
module CodingAgentTools
  module Organisms
    module TaskManagement
      class ReleaseManager
        include CodingAgentTools::Molecules::TaskManagement
        
        attr_reader :base_path
        
        def initialize(base_path = ".ace/taskflow")
          @base_path = base_path
        end
        
        # Get current release information
        def current_release_info
          release_path = ReleasePathResolver.find_current_release(base_path)
          version = ReleasePathResolver.current_release_version(base_path)
          
          {
            path: release_path,
            version: version,
            exists: !release_path.nil?
          }
        end
        
        # Get appropriate directory for new tasks
        def task_directory_for_new_tasks
          ReleasePathResolver.resolve_task_directory(base_path)
        end
        
        # List all releases
        def list_all_releases
          releases = []
          
          # Current releases
          current_path = File.join(base_path, "current")
          if File.directory?(current_path)
            current_releases = DirectoryNavigator.find_release_directories(current_path)
            releases.concat(current_releases.map { |r| { path: r, type: 'current' } })
          end
          
          # Backlog releases
          backlog_path = File.join(base_path, "backlog")
          if File.directory?(backlog_path)
            backlog_releases = DirectoryNavigator.find_release_directories(backlog_path)
            releases.concat(backlog_releases.map { |r| { path: r, type: 'backlog' } })
          end
          
          releases
        end
      end
    end
  end
end
```

### Layer 4: CLI Command Integration

#### cli/commands/task/

**next.rb**

```ruby
module CodingAgentTools
  module Cli
    module Commands
      module Task
        class Next < Dry::CLI::Command
          desc "Find the next actionable task"
          
          def call(**)
            task_manager = CodingAgentTools::Organisms::TaskManagement::TaskManager.new
            next_task = task_manager.find_next_task
            
            if next_task
              puts "Next task to work on:"
              puts "  ID:    #{next_task[:id]}"
              puts "  Title: #{extract_title(next_task[:content])}"
              puts "  Path:  #{next_task[:path]}"
              puts "  Status: #{next_task[:status]}"
              
              dependencies = next_task[:dependencies]
              if dependencies && !dependencies.empty?
                puts "  Dependencies: #{dependencies.join(', ')}"
              end
            else
              puts "No actionable tasks found."
              exit 1
            end
          end
          
          private
          
          def extract_title(content)
            lines = content.split("\n")
            title_line = lines.find { |line| line.start_with?('# ') }
            title_line ? title_line.sub(/^# /, '') : "Untitled"
          end
        end
      end
    end
  end
end
```

**recent.rb**

```ruby
module CodingAgentTools
  module Cli
    module Commands
      module Task
        class Recent < Dry::CLI::Command
          desc "Show recently updated tasks"
          
          option :last, type: :string, desc: "Time period (e.g., '2.days', '4.hours')"
          
          def call(last: nil, **)
            seconds = parse_time_period(last || "1.day")
            task_manager = CodingAgentTools::Organisms::TaskManagement::TaskManager.new
            recent_tasks = task_manager.find_recent_tasks(seconds)
            
            if recent_tasks.empty?
              puts "No recent tasks found in the last #{format_time_period(seconds)}."
              return
            end
            
            puts "Recent tasks (last #{format_time_period(seconds)}):"
            puts
            
            recent_tasks.each do |task|
              mtime = File.mtime(task[:path])
              puts "#{task[:id]} - #{extract_title(task[:content])}"
              puts "  Status: #{task[:status]}"
              puts "  Updated: #{mtime.strftime('%Y-%m-%d %H:%M:%S')}"
              puts "  Path: #{task[:path]}"
              puts
            end
          end
          
          private
          
          def parse_time_period(period_str)
            case period_str
            when /^(\d+(?:\.\d+)?)\.?(hour|hours)$/
              $1.to_f * 3600
            when /^(\d+(?:\.\d+)?)\.?(day|days)$/
              $1.to_f * 86400
            when /^(\d+(?:\.\d+)?)\.?(min|minute|minutes)$/
              $1.to_f * 60
            else
              86400 # default 1 day
            end
          end
          
          def format_time_period(seconds)
            case seconds
            when 0...3600
              "#{(seconds / 60).round} minutes"
            when 3600...86400
              "#{(seconds / 3600).round} hours"
            else
              "#{(seconds / 86400).round} days"
            end
          end
          
          def extract_title(content)
            lines = content.split("\n")
            title_line = lines.find { |line| line.start_with?('# ') }
            title_line ? title_line.sub(/^# /, '') : "Untitled"
          end
        end
      end
    end
  end
end
```

## CLI Registration Integration

### Updated cli.rb

```ruby
# lib/coding_agent_tools/cli.rb - additions

def self.register_task_commands
  return if @task_commands_registered
  
  require_relative "cli/commands/task/next"
  require_relative "cli/commands/task/recent"
  require_relative "cli/commands/task/all"
  require_relative "cli/commands/task/generate_id"
  require_relative "cli/commands/task/current_release"
  
  register "task", aliases: [] do |prefix|
    prefix.register "next", Commands::Task::Next
    prefix.register "recent", Commands::Task::Recent
    prefix.register "all", Commands::Task::All
    prefix.register "generate-id", Commands::Task::GenerateId
    prefix.register "current-release", Commands::Task::CurrentRelease
  end
  
  @task_commands_registered = true
end

def self.register_project_commands
  return if @project_commands_registered
  
  require_relative "cli/commands/project/tree"
  require_relative "cli/commands/project/lint" 
  require_relative "cli/commands/project/git_log"
  require_relative "cli/commands/project/sync_templates"
  
  register "project", aliases: [] do |prefix|
    prefix.register "tree", Commands::Project::Tree
    prefix.register "lint", Commands::Project::Lint
    prefix.register "git-log", Commands::Project::GitLog
    prefix.register "sync-templates", Commands::Project::SyncTemplates
  end
  
  @project_commands_registered = true
end

# Ensure all commands are registered when CLI is used
def self.call(*args)
  register_llm_commands
  register_task_commands
  register_project_commands
  super
end
```

## Testing Strategy

### Unit Tests Structure

```
spec/
  coding_agent_tools/
    atoms/
      task_management/
        file_system_scanner_spec.rb
        yaml_frontmatter_parser_spec.rb
        task_id_parser_spec.rb
        directory_navigator_spec.rb
    molecules/
      task_management/
        task_file_loader_spec.rb
        release_path_resolver_spec.rb
        task_dependency_checker_spec.rb
        task_id_generator_spec.rb
    organisms/
      task_management/
        task_manager_spec.rb
        release_manager_spec.rb
    cli/
      commands/
        task/
          next_spec.rb
          recent_spec.rb
```

### Integration Test Approach

Create test fixtures that mirror the `.ace/taskflow` structure:

```
spec/fixtures/
  .ace/taskflow/
    current/
      v.0.1.0-test/
        tasks/
          v.0.1.0+task.1-sample-task.md
          v.0.1.0+task.2-dependent-task.md
    backlog/
      v.0.2.0-future/
        tasks/
          v.0.2.0+task.1-future-task.md
```

## Migration Benefits

### Code Quality Improvements

- **Testability**: ATOM pattern enables comprehensive unit testing
- **Maintainability**: Clear separation of concerns and responsibilities
- **Reusability**: Atoms and molecules can be reused across organisms
- **Consistency**: Standardized patterns across all task management functionality

### Performance Benefits

- **Caching**: Molecules can implement caching for frequently accessed data
- **Lazy Loading**: Organisms can load tasks on-demand
- **Optimization**: File system access can be optimized at the atom level

### Security Benefits

- **Input Validation**: Centralized validation in atoms prevents injection attacks
- **Path Security**: Secure path validation prevents directory traversal
- **Error Handling**: Consistent error handling patterns across all layers

## Dependencies

### New Gem Dependencies

- `yaml` (already available in Ruby stdlib)
- `time` (already available in Ruby stdlib)
- `pathname` (already available in Ruby stdlib)

### Testing Dependencies

- `rspec` (already in use)
- `tempfile` (for testing file operations)

## Conclusion

This architectural integration follows the established ATOM pattern, providing a clean, testable, and maintainable foundation for task management functionality within the `coding_agent_tools` gem. The design preserves existing interfaces while enabling future extensibility and improved code quality.

---

**Document Status**: Initial architectural design  
**Last Updated**: 2025-01-07  
**Next Review**: Upon implementation of Phase 1 components
