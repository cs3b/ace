#!/usr/bin/env ruby

require 'json'
require 'fileutils'

# List of actual git wrapper tools that exist
GIT_WRAPPER_TOOLS = %w[
  git-add
  git-checkout
  git-commit
  git-diff
  git-fetch
  git-log
  git-mv
  git-pull
  git-push
  git-restore
  git-rm
  git-status
  git-switch
  git-tag
].freeze

# Mapping of native git commands to wrapper tools
GIT_WRAPPER_MAPPING = {
  'git status'   => 'git-status',
  'git commit'   => 'git-commit',
  'git add'      => 'git-add',
  'git diff'     => 'git-diff',
  'git log'      => 'git-log',
  'git push'     => 'git-push',
  'git pull'     => 'git-pull',
  'git fetch'    => 'git-fetch',
  'git checkout' => 'git-checkout',
  'git switch'   => 'git-switch',
  'git restore'  => 'git-restore',
  'git tag'      => 'git-tag',
  'git mv'       => 'git-mv',
  'git rm'       => 'git-rm',
  'git branch'   => 'git branch (no wrapper available)',
  'git merge'    => 'git merge (no wrapper available)',
  'git rebase'   => 'git rebase (no wrapper available)',
  'git reset'    => 'git reset (no wrapper available)',
  'git stash'    => 'git stash (no wrapper available)',
  'git remote'   => 'git remote (no wrapper available)',
  'git clone'    => 'git clone (no wrapper available)',
  'git init'     => 'git init (no wrapper available)'
}.freeze

begin
  # Read JSON input from stdin
  input_json = $stdin.read
  input = JSON.parse(input_json)
  
  # Save JSON to tmp for debugging
  File.write('/tmp/git-hook-debug.json', JSON.pretty_generate(input))
  
  # Only process Bash tool calls
  exit 0 unless input['tool_name'] == 'Bash'
  
  # Get the command being executed
  command = input.dig('tool_input', 'command') || ''
  
  # First, check if this is already a git wrapper command
  # If the command starts with one of our wrapper tools, allow it
  wrapper_command = GIT_WRAPPER_TOOLS.find { |tool| command.start_with?(tool) }
  if wrapper_command
    # This is a wrapper tool, allow it
    exit 0
  end
  
  # Now check if it's a native git command (git followed by space and subcommand)
  # This should only match "git status", "git commit", etc., NOT "git-status", "git-commit"
  if command =~ /\bgit\s+(\w+)/
    git_subcommand = $1
    native_command = "git #{git_subcommand}"
    
    # Find the appropriate wrapper tool
    wrapper_tool = GIT_WRAPPER_MAPPING[native_command]
    
    # Build error message
    error_messages = []
    error_messages << "ERROR: Use git wrapper tools instead of native git commands."
    error_messages << ""
    error_messages << "You attempted to use: '#{native_command}'"
    
    if wrapper_tool && !wrapper_tool.include?('no wrapper')
      error_messages << "Please use: '#{wrapper_tool}' instead"
      error_messages << ""
      error_messages << "Example:"
      
      # Provide specific examples based on the command
      case git_subcommand
      when 'status'
        error_messages << "  git-status                    # Check status across all repos"
        error_messages << "  git-status --short            # Compact output"
      when 'commit'
        error_messages << "  git-commit --intention \"fix bug\"              # Commit all changes"
        error_messages << "  git-commit file.rb --intention \"update code\" # Commit specific files"
      when 'add'
        error_messages << "  git-add file1.md file2.rb    # Stage specific files"
        error_messages << "  git-add --all                # Stage all changes"
      when 'diff'
        error_messages << "  git-diff --stat              # Show summary of changes"
        error_messages << "  git-diff --staged            # Show staged changes"
      when 'log'
        error_messages << "  git-log --oneline -n 10      # Show recent commits"
      end
    else
      error_messages << "No wrapper tool available for '#{native_command}'"
      error_messages << "This command is not allowed in this context."
    end
    
    error_messages << ""
    error_messages << "Git wrapper tools provide:"
    error_messages << "• Multi-repository awareness"
    error_messages << "• Intelligent message generation"
    error_messages << "• Enhanced functionality"
    
    # Output error message to stderr and exit with code 2 to block the command
    $stderr.puts error_messages.join("\n")
    exit 2
  end
  
  # Allow all other commands to proceed
  exit 0
  
rescue JSON::ParserError => e
  $stderr.puts "Error parsing JSON input: #{e.message}"
  exit 1
rescue => e
  $stderr.puts "Unexpected error: #{e.message}"
  exit 1
end