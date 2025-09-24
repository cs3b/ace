# Multi-Repository Detection and Path Resolution System

## Overview

This document outlines the multi-repository detection and intelligent path resolution system for the git module.

## Current Repository Structure

Based on `git submodule status`:
- **Main Repository**: `tools-meta-f-git` (root)
- **Submodules**:
  - `.ace/handbook` (heads/main)
  - `.ace/taskflow` (heads/main)
  - `.ace/tools` (v0.2.71-43-g944e187)

## Multi-Repository Detection Strategy

### 1. Repository Discovery

**Primary Method: Git Submodule Detection**
```ruby
# Get submodules from git
submodules = `git submodule status`.lines.map do |line|
  # Parse: " 2d7a31b769e93e9031e6c7561c2da6fc8845c87f .ace/handbook (heads/main)"
  path = line.strip.split(' ')[1]
  {
    name: File.basename(path),
    path: path,
    full_path: File.expand_path(path, project_root)
  }
end
```

**Fallback Method: Directory Scanning**
```ruby
# Scan for dev-* directories with .git
dev_dirs = Dir.glob(File.join(project_root, "dev-*")).select do |dir|
  File.directory?(dir) && (
    File.exist?(File.join(dir, ".git")) ||
    File.directory?(File.join(dir, ".git"))
  )
end
```

**Repository Registry**
```ruby
repositories = [
  { name: "main", path: ".", full_path: project_root },
  *submodules
]
```

### 2. Path Resolution Algorithm

**Input**: Array of file paths (e.g., `[".ace/handbook/file.md", "lib/file.rb", ".ace/taskflow/task.md"]`)

**Output**: Grouped commands by repository
```ruby
{
  "main" => ["lib/file.rb"],
  ".ace/handbook" => ["file.md"],
  ".ace/taskflow" => ["task.md"]
}
```

**Algorithm**:
1. Normalize all paths to absolute paths
2. For each path, determine which repository it belongs to
3. Convert absolute paths back to relative paths within each repository
4. Group by repository for batch operations

### 3. Path Dispatcher Implementation

```ruby
class PathDispatcher
  def initialize(project_root)
    @project_root = project_root
    @repositories = discover_repositories
  end

  def dispatch_paths(paths)
    grouped_paths = {}
    
    paths.each do |path|
      repo_info = resolve_path_to_repository(path)
      repo_name = repo_info[:repository]
      relative_path = repo_info[:relative_path]
      
      grouped_paths[repo_name] ||= []
      grouped_paths[repo_name] << relative_path
    end
    
    grouped_paths
  end

  private

  def resolve_path_to_repository(path)
    absolute_path = File.expand_path(path, Dir.pwd)
    
    # Check each repository to see if path falls within it
    @repositories.each do |repo|
      repo_path = repo[:full_path]
      if absolute_path.start_with?(repo_path + "/") || absolute_path == repo_path
        relative_path = Pathname.new(absolute_path).relative_path_from(Pathname.new(repo_path)).to_s
        return {
          repository: repo[:name],
          relative_path: relative_path,
          absolute_path: absolute_path
        }
      end
    end
    
    # Default to main repository if no match found
    relative_path = Pathname.new(absolute_path).relative_path_from(Pathname.new(@project_root)).to_s
    {
      repository: "main",
      relative_path: relative_path,
      absolute_path: absolute_path
    }
  end
end
```

## Path Resolution Examples

### Example 1: Mixed Repository Files
**Input**: `[".ace/handbook/guide.md", ".ace/taskflow/task.md", "lib/file.rb"]`

**Resolution**:
1. `.ace/handbook/guide.md` → `.ace/handbook` repo, `guide.md` (relative)
2. `.ace/taskflow/task.md` → `.ace/taskflow` repo, `task.md` (relative)
3. `lib/file.rb` → `main` repo, `lib/file.rb` (relative)

**Generated Commands**:
```bash
git -C .ace/handbook add guide.md
git -C .ace/taskflow add task.md
git add lib/file.rb
```

### Example 2: Absolute Paths
**Input**: `["/Users/user/tools-meta/.ace/tools/lib/file.rb"]`

**Resolution**:
1. Resolve to `.ace/tools` repository
2. Convert to relative path: `lib/file.rb`

**Generated Command**:
```bash
git -C .ace/tools add lib/file.rb
```

### Example 3: Directory-Agnostic Operation
**Current Directory**: `/Users/user/tools-meta/.ace/taskflow/current`
**Input**: `["../../../lib/file.rb", "task.md"]`

**Resolution**:
1. `../../../lib/file.rb` → Resolves to main repo, `lib/file.rb`
2. `task.md` → Resolves to .ace/taskflow repo, `current/task.md`

**Generated Commands**:
```bash
git add lib/file.rb
git -C .ace/taskflow add current/task.md
```

## Concurrent Execution Strategy

### 1. Thread-Based Execution
```ruby
class ConcurrentExecutor
  def execute_across_repositories(commands_by_repo)
    threads = []
    results = {}
    
    commands_by_repo.each do |repo_name, commands|
      threads << Thread.new do
        Thread.current[:repo] = repo_name
        results[repo_name] = execute_commands_for_repo(repo_name, commands)
      end
    end
    
    # Wait for all threads to complete
    threads.each(&:join)
    
    results
  end

  private

  def execute_commands_for_repo(repo_name, commands)
    commands.map do |command|
      if repo_name == "main"
        system(command)
      else
        system("git -C #{repo_name} #{command}")
      end
    end
  end
end
```

### 2. Fiber-Based Execution (Alternative)
```ruby
class FiberExecutor
  def execute_concurrently(commands_by_repo)
    fibers = []
    results = {}
    
    commands_by_repo.each do |repo_name, commands|
      fibers << Fiber.new do
        results[repo_name] = execute_commands_for_repo(repo_name, commands)
      end
    end
    
    # Resume all fibers
    fibers.each(&:resume)
    
    results
  end
end
```

## Error Handling and Validation

### 1. Path Validation
```ruby
def validate_path(path)
  expanded_path = File.expand_path(path)
  
  unless File.exist?(expanded_path)
    raise PathError, "Path does not exist: #{path}"
  end
  
  unless path_within_project?(expanded_path)
    raise PathError, "Path is outside project: #{path}"
  end
  
  true
end
```

### 2. Repository Validation
```ruby
def validate_repository(repo_name)
  repo = @repositories.find { |r| r[:name] == repo_name }
  
  unless repo
    raise RepositoryError, "Repository not found: #{repo_name}"
  end
  
  unless File.directory?(repo[:full_path])
    raise RepositoryError, "Repository directory does not exist: #{repo[:full_path]}"
  end
  
  true
end
```

## Integration with ProjectRootDetector

### 1. Root Detection
```ruby
def initialize
  @project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
  @repositories = discover_repositories
end
```

### 2. Directory-Agnostic Operations
- Use ProjectRootDetector for consistent root finding
- Support operations from any subdirectory
- Maintain relative path context within repositories

## Special Cases and Edge Conditions

### 1. Symbolic Links
- Resolve symbolic links to actual paths
- Ensure path resolution works correctly with symlinks
- Handle broken symbolic links gracefully

### 2. Nested Repositories
- Detect and handle nested git repositories
- Prevent conflicts between parent and child repos
- Maintain proper path resolution hierarchy

### 3. Missing Repositories
- Gracefully handle missing submodules
- Provide clear error messages
- Allow operations on available repositories only

### 4. Cross-Repository Operations
- Support operations that span multiple repositories
- Maintain atomicity where possible
- Provide rollback mechanisms for failed operations

## Performance Considerations

### 1. Caching
- Cache repository discovery results
- Cache path resolution for repeated operations
- Invalidate cache when repository structure changes

### 2. Lazy Loading
- Load repository information only when needed
- Defer expensive operations until required
- Optimize for common use cases

### 3. Batch Operations
- Group multiple operations per repository
- Minimize context switches between repositories
- Optimize git command execution

This multi-repository detection and path resolution system provides intelligent handling of file paths across the entire project structure while maintaining performance and reliability.