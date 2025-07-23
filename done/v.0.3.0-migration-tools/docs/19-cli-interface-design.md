# CLI Command Interface Design

## Overview

This document outlines the CLI command interface design for the git module following dry-cli patterns and maintaining consistency with the existing task-manager implementation.

## Command Structure

### Base Command Structure
```
coding_agent_tools git <command> [options] [arguments]
```


### Command Hierarchy
```
git
├── commit      # Git commit with LLM integration
├── status      # Multi-repo status display
├── push        # Concurrent push operations
├── pull        # Concurrent pull operations
├── log         # Unified log display
├── diff        # Multi-repo diff operations
├── add         # Intelligent path grouping
├── mv          # Git move operations
├── rm          # Git remove operations
├── restore     # Git restore operations
└── fetch       # Git fetch operations
```

## Common Options Pattern

### Standard Options (Available on All Commands)
```ruby
option :debug, type: :boolean, default: false, aliases: ["d"],
  desc: "Enable debug output for verbose error information"

option :repository, type: :string, aliases: ["C"],
  desc: "Specify explicit repository context (e.g., 'dev-tools')"

option :help, type: :boolean, default: false, aliases: ["h"],
  desc: "Show help for this command"
```

### Multi-Repository Options
```ruby
option :all_repos, type: :boolean, default: true,
  desc: "Process all repositories (default: true)"

option :main_only, type: :boolean, default: false,
  desc: "Process main repository only"

option :submodules_only, type: :boolean, default: false,
  desc: "Process submodules only"
```

## Individual Command Specifications

### 1. Git Commit Command

```ruby
module CodingAgentTools
  module Cli
    module Commands
      module Git
        class Commit < Dry::CLI::Command
          desc "Commit changes across repositories with LLM-generated messages"

          option :intention, type: :string, aliases: ["i"],
            desc: "Intention context for commit message generation"

          option :local, type: :boolean, default: false, aliases: ["l"],
            desc: "Use local LLM model instead of cloud service"

          option :no_edit, type: :boolean, default: false, aliases: ["n"],
            desc: "Skip editor and commit directly with generated message"

          option :message, type: :string, aliases: ["m"],
            desc: "Use provided message instead of LLM generation"

          option :all, type: :boolean, default: false, aliases: ["a"],
            desc: "Stage all changes before committing"

          argument :files, type: :array, required: false,
            desc: "Specific files to commit (optional)"

          example [
            "",
            "--intention 'implement user authentication'",
            "--local --no-edit",
            "--message 'fix typo in documentation'",
            "--all --intention 'refactor database layer'",
            "dev-handbook/guide.md lib/auth.rb"
          ]

          def call(files: [], **options)
            # Implementation
          end
        end
      end
    end
  end
end
```

### 2. Git Status Command

```ruby
class Status < Dry::CLI::Command
  desc "Show status across all repositories with clear prefixes"

  option :porcelain, type: :boolean, default: false,
    desc: "Give the output in porcelain format"

  option :short, type: :boolean, default: false, aliases: ["s"],
    desc: "Give the output in short format"

  option :verbose, type: :boolean, default: false, aliases: ["v"],
    desc: "Show detailed status information"

  option :untracked_files, type: :string, default: "normal",
    desc: "Show untracked files (no|normal|all)"

  example [
    "",
    "--short",
    "--verbose",
    "--porcelain",
    "--repository dev-tools"
  ]

  def call(**options)
    # Implementation
  end
end
```

### 3. Git Push Command

```ruby
class Push < Dry::CLI::Command
  desc "Push changes to remote repositories concurrently"

  option :force, type: :boolean, default: false, aliases: ["f"],
    desc: "Force push (use with caution)"

  option :dry_run, type: :boolean, default: false,
    desc: "Show what would be pushed without actually pushing"

  option :set_upstream, type: :boolean, default: false, aliases: ["u"],
    desc: "Set upstream tracking for new branches"

  option :tags, type: :boolean, default: false,
    desc: "Push tags along with commits"

  argument :remote, type: :string, required: false,
    desc: "Remote name (default: origin)"

  argument :branch, type: :string, required: false,
    desc: "Branch name (default: current branch)"

  example [
    "",
    "--dry-run",
    "--force",
    "--set-upstream origin feature-branch",
    "--tags",
    "origin main"
  ]

  def call(remote: nil, branch: nil, **options)
    # Implementation
  end
end
```

### 4. Git Pull Command

```ruby
class Pull < Dry::CLI::Command
  desc "Pull changes from remote repositories concurrently"

  option :rebase, type: :boolean, default: false, aliases: ["r"],
    desc: "Rebase instead of merge"

  option :ff_only, type: :boolean, default: false,
    desc: "Only allow fast-forward merges"

  option :no_commit, type: :boolean, default: false,
    desc: "Don't commit automatic merge"

  option :strategy, type: :string,
    desc: "Merge strategy to use"

  argument :remote, type: :string, required: false,
    desc: "Remote name (default: origin)"

  argument :branch, type: :string, required: false,
    desc: "Branch name (default: current branch)"

  example [
    "",
    "--rebase",
    "--ff-only",
    "--no-commit",
    "upstream main"
  ]

  def call(remote: nil, branch: nil, **options)
    # Implementation
  end
end
```

### 5. Git Log Command

```ruby
class Log < Dry::CLI::Command
  desc "Show commit logs across repositories with unified timeline"

  option :oneline, type: :boolean, default: false,
    desc: "Show commits in oneline format"

  option :graph, type: :boolean, default: false,
    desc: "Show commit graph"

  option :since, type: :string,
    desc: "Show commits since date (e.g., '2 weeks ago')"

  option :until, type: :string,
    desc: "Show commits until date"

  option :author, type: :string,
    desc: "Show commits by specific author"

  option :grep, type: :string,
    desc: "Search commit messages"

  option :max_count, type: :integer, aliases: ["n"],
    desc: "Maximum number of commits to show"

  example [
    "",
    "--oneline -n 10",
    "--graph --since '1 week ago'",
    "--author 'John Doe'",
    "--grep 'fix bug'"
  ]

  def call(**options)
    # Implementation
  end
end
```

### 6. Git Add Command

```ruby
class Add < Dry::CLI::Command
  desc "Add files to staging area with intelligent path grouping"

  option :all, type: :boolean, default: false, aliases: ["A"],
    desc: "Add all changes (new, modified, deleted)"

  option :update, type: :boolean, default: false, aliases: ["u"],
    desc: "Add only modified and deleted files"

  option :patch, type: :boolean, default: false, aliases: ["p"],
    desc: "Interactively choose hunks to add"

  option :force, type: :boolean, default: false, aliases: ["f"],
    desc: "Allow adding ignored files"

  argument :files, type: :array, required: true,
    desc: "Files or directories to add"

  example [
    "file1.rb file2.rb",
    "--all",
    "--update",
    "dev-handbook/guide.md lib/auth.rb",
    "--patch lib/core.rb"
  ]

  def call(files:, **options)
    # Implementation
  end
end
```

## Error Handling Pattern

### Standard Error Handling
```ruby
def call(**options)
  # Implementation
rescue => e
  handle_error(e, options[:debug])
  1
end

private

def handle_error(error, debug_enabled)
  if debug_enabled
    error_output("Error: #{error.class.name}: #{error.message}")
    error_output("\nBacktrace:")
    error.backtrace.each { |line| error_output("  #{line}") }
  else
    error_output("Error: #{error.message}")
    error_output("Use --debug flag for more information")
  end
end

def error_output(message)
  warn message
end
```

### Git-Specific Error Handling
```ruby
def handle_git_error(error, repository = nil)
  prefix = repository ? "[#{repository}] " : ""

  case error
  when GitCommandError
    error_output("#{prefix}Git command failed: #{error.message}")
  when RepositoryNotFoundError
    error_output("#{prefix}Repository not found: #{error.repository}")
  when PathResolutionError
    error_output("#{prefix}Path resolution failed: #{error.path}")
  else
    error_output("#{prefix}Unexpected error: #{error.message}")
  end
end
```

## Help System Integration

### Command Help Pattern
```ruby
desc "Brief description of what the command does"

option :option_name, type: :type, desc: "Description of the option"

argument :arg_name, type: :type, required: boolean, desc: "Description of the argument"

example [
  "example usage 1",
  "example usage 2 --with-option",
  "example usage 3 with arguments"
]
```

### Help Output Format
```
USAGE
  coding_agent_tools git commit [options] [files...]

DESCRIPTION
  Commit changes across repositories with LLM-generated messages

OPTIONS
  --intention, -i VALUE    Intention context for commit message generation
  --local, -l              Use local LLM model instead of cloud service
  --no-edit, -n            Skip editor and commit directly with generated message
  --debug, -d              Enable debug output for verbose error information
  --repository, -C VALUE   Specify explicit repository context
  --help, -h               Show help for this command

ARGUMENTS
  files                    Specific files to commit (optional)

EXAMPLES
  coding_agent_tools git commit
  coding_agent_tools git commit --intention 'implement user authentication'
  coding_agent_tools git commit --local --no-edit
  coding_agent_tools git commit dev-handbook/guide.md lib/auth.rb
```

## Output Formatting

### Multi-Repository Output Format
```
[main] Status: clean working directory
[dev-tools] Status: modified files
  M lib/coding_agent_tools/cli/commands/git/commit.rb
  ?? spec/new_test.rb
[dev-handbook] Status: clean working directory
[dev-taskflow] Status: modified files
  M current/v.0.3.0-migration/tasks/task.md
```

### Progress Indication
```
Pushing repositories...
[1/4] main: Pushing to origin/main... ✓
[2/4] dev-tools: Pushing to origin/main... ✓
[3/4] dev-handbook: Pushing to origin/main... ✓
[4/4] dev-taskflow: Pushing to origin/main... ✓
All repositories pushed successfully.
```

## Consistency with Task Manager

### Option Naming
- Use consistent option names across commands
- Follow existing patterns from task manager
- Maintain aliases for common options

### Error Handling
- Use same error handling patterns
- Consistent error message format
- Debug mode implementation

### Help System
- Same help formatting and structure
- Consistent example patterns
- Clear descriptions and usage information

This CLI interface design provides a comprehensive, consistent, and user-friendly interface for git operations across multiple repositories while maintaining compatibility with existing patterns and conventions.
