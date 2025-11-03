# frozen_string_literal: true

require "open3"
require "ostruct"

# Helper module for mocking shell commands in tests
# Intercepts Open3.capture3 calls to ace-nav and ace-context
module ShellMockHelper
  # Store original method for restoration
  @@original_capture3 = nil
  @@shell_mocking_enabled = false

  # Enable shell command mocking globally
  def self.enable_shell_mocking!
    return if @@shell_mocking_enabled

    @@original_capture3 = Open3.method(:capture3)
    @@shell_mocking_enabled = true

    Open3.define_singleton_method(:capture3) do |cmd, *args, **kwargs, &block|
      case cmd
      when "ace-nav"
        ShellMockHelper.handle_ace_nav_mock(args, kwargs)
      when "ace-context"
        ShellMockHelper.handle_ace_context_mock(args, kwargs)
      when "git"
        ShellMockHelper.handle_git_mock(args, kwargs)
      else
        # Pass through to original method for other commands
        @@original_capture3.call(cmd, *args, **kwargs, &block)
      end
    end
  end

  # Disable shell command mocking (restore original)
  def self.disable_shell_mocking!
    return unless @@shell_mocking_enabled

    if @@original_capture3
      Open3.define_singleton_method(:capture3, @@original_capture3)
    end

    @@shell_mocking_enabled = false
    @@original_capture3 = nil
  end

  # Handle ace-nav command mocking
  def self.handle_ace_nav_mock(args, _kwargs)
    if args.include?("prompt://slug-generation") || args.first == "prompt://slug-generation"
      # Return mock slug generation prompt content
      prompt_content = <<~PROMPT
        ---
        description: LLM prompt for generating hierarchical task and idea slugs
        ---

        # Slug Generation Instructions

        Generate hierarchical slugs for organizing tasks and ideas.

        ## Folder Slugs (2-4 words)
        Format: `{system/area}-{goal/action}`

        ## File Slugs (3-5+ words)
        Format: `{specific-action-description}`

        ## Response Format
        Respond with ONLY valid JSON:
        ```json
        {
          "folder_slug": "system-goal",
          "file_slug": "specific-action-description"
        }
        ```
      PROMPT

      [prompt_content, "", OpenStruct.new(success?: true)]
    else
      # Other ace-nav commands return not found
      ["", "Resource not found", OpenStruct.new(success?: false, exitstatus: 1)]
    end
  end

  # Handle ace-context command mocking
  def self.handle_ace_context_mock(args, _kwargs)
    preset = args.first

    case preset
    when "project-base", "project"
      # Return mock project context
      context_content = <<~CONTEXT
        # Project Context

        ## Overview
        ACE Taskflow - Task and idea management system for AI-assisted development

        ## Components
        - ace-taskflow: Core task management
        - ace-context: Context loading
        - ace-nav: Resource navigation
        - ace-llm: LLM integration

        ## Architecture
        ATOM pattern: Atoms, Molecules, Organisms, Models
      CONTEXT

      [context_content, "", OpenStruct.new(success?: true)]
    else
      ["", "Preset not found", OpenStruct.new(success?: false, exitstatus: 1)]
    end
  end

  # Handle git command mocking
  def self.handle_git_mock(args, _kwargs)
    subcommand = args.first

    case subcommand
    when "rev-parse"
      # Check if in git repo
      if args.include?("--git-dir")
        [".git", "", OpenStruct.new(success?: true, exitstatus: 0)]
      else
        ["", "", OpenStruct.new(success?: true, exitstatus: 0)]
      end
    when "add"
      # Mock git add
      ["", "", OpenStruct.new(success?: true, exitstatus: 0)]
    when "commit"
      # Mock git commit
      commit_message = args[args.index("-m") + 1] if args.include?("-m")
      output = "[mock] 1 file changed, 1 insertion(+)\n create mode 100644 #{commit_message}"
      [output, "", OpenStruct.new(success?: true, exitstatus: 0)]
    when "status"
      # Mock git status - return clean status
      ["", "", OpenStruct.new(success?: true, exitstatus: 0)]
    when "init", "config"
      # Mock git init and config
      ["", "", OpenStruct.new(success?: true, exitstatus: 0)]
    else
      # Unknown git command - return success
      ["", "", OpenStruct.new(success?: true, exitstatus: 0)]
    end
  end
end

# Enable shell mocking automatically when module is loaded in tests
ShellMockHelper.enable_shell_mocking! if defined?(Minitest)
