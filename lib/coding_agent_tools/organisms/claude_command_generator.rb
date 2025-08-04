# frozen_string_literal: true

require 'pathname'
require 'fileutils'
require 'yaml'

module CodingAgentTools
  module Organisms
    # Generates Claude commands from workflow instructions
    class ClaudeCommandGenerator
      attr_reader :workflow_dir, :custom_dir, :generated_dir, :template_path, :stats

      def initialize(project_root = nil)
        @project_root = Pathname.new(project_root || find_project_root)
        @workflow_dir = @project_root / "dev-handbook/workflow-instructions"
        @custom_dir = @project_root / "dev-handbook/.integrations/claude/commands/_custom"
        @generated_dir = @project_root / "dev-handbook/.integrations/claude/commands/_generated"
        @template_path = @project_root / "dev-handbook/.integrations/claude/command.template.md"
        @stats = { generated: 0, skipped: 0, errors: [] }
      end

      def generate(options = {})
        ensure_directories_exist

        workflows = find_workflows(options[:workflow])
        missing = find_missing_commands(workflows, options[:force])

        if options[:dry_run]
          display_dry_run(missing, options[:force])
        else
          generate_commands(missing, options[:force])
        end

        Result.new(
          success: stats[:errors].empty?,
          stats: stats,
          missing_workflows: missing
        )
      end

      Result = Struct.new(:success, :stats, :missing_workflows, keyword_init: true)

      private

      def find_project_root
        current = Pathname.pwd
        while current.parent != current
          return current if (current / 'dev-handbook').directory?
          current = current.parent
        end
        Pathname.pwd
      end

      def ensure_directories_exist
        [@custom_dir, @generated_dir].each do |dir|
          FileUtils.mkdir_p(dir) unless dir.exist?
        end
      end

      def find_workflows(specific = nil)
        if specific
          # Support glob patterns
          if specific.include?('*')
            Dir.glob(File.join(@workflow_dir, "#{specific}.wf.md")).map do |path|
              File.basename(path, ".wf.md")
            end
          else
            path = @workflow_dir / "#{specific}.wf.md"
            return [] unless path.exist?
            [specific]
          end
        else
          Dir.glob(File.join(@workflow_dir, "*.wf.md")).map do |path|
            File.basename(path, ".wf.md")
          end
        end
      end

      def find_missing_commands(workflows, force = false)
        workflows.reject do |workflow|
          custom_exists = (@custom_dir / "#{workflow}.md").exist?
          generated_exists = (@generated_dir / "#{workflow}.md").exist?
          # Skip custom commands always, but allow regeneration of generated commands with force
          custom_exists || (generated_exists && !force)
        end
      end

      def display_dry_run(missing, force = false)
        puts "Scanning workflow instructions..."
        puts "Found #{Dir.glob(File.join(@workflow_dir, "*.wf.md")).size} workflow files"
        puts "Checking existing commands..."
        puts
        
        if missing.empty?
          puts "All workflows have corresponding commands."
        else
          puts "Missing commands for:"
          missing.each do |workflow|
            puts "  - #{workflow}.wf.md"
          end
          puts
          if force
            puts "Would regenerate (--force):"
          else
            puts "Would generate:"
          end
          missing.each do |workflow|
            puts "  - _generated/#{workflow}.md"
          end
        end
        
        @stats[:skipped] = missing.size
      end

      def generate_commands(workflows, force)
        puts "Scanning workflow instructions..."
        all_workflows = Dir.glob(File.join(@workflow_dir, "*.wf.md"))
        puts "Found #{all_workflows.size} workflow files"
        puts "Checking existing commands..."
        puts

        # Count skipped workflows (those not in the workflows list due to existing commands)
        total_workflows_checked = find_workflows.size
        @stats[:skipped] = total_workflows_checked - workflows.size

        if workflows.empty?
          puts "All workflows have corresponding commands."
          return
        end

        puts "Missing commands for:"
        workflows.each do |workflow|
          puts "  - #{workflow}.wf.md"
        end
        puts
        puts "Generating commands..."

        template_content = load_template

        workflows.each do |workflow|
          output_path = @generated_dir / "#{workflow}.md"

          begin
            content = render_template(template_content, workflow)
            
            # Validate YAML front-matter
            unless validate_yaml_frontmatter(content)
              puts "⚠ Warning: Invalid YAML front-matter for #{workflow}.md"
            end
            
            output_path.write(content)
            puts "✓ Created: _generated/#{workflow}.md"
            @stats[:generated] += 1
          rescue => e
            puts "✗ Error: #{workflow}.md - #{e.message}"
            @stats[:errors] << "#{workflow}: #{e.message}"
          end
        end

        puts
        puts "Summary: #{@stats[:generated]} commands generated"
      end

      def load_template
        if @template_path.exist?
          @template_path.read
        else
          # Return nil to indicate template is missing
          # The render_template method will handle this gracefully
          nil
        end
      end

      def render_template(template_content, workflow_name)
        metadata = infer_metadata(workflow_name)
        
        # Build YAML front-matter programmatically (safer than eval)
        yaml_lines = ["---"]
        yaml_lines << "description: #{metadata[:description]}"
        yaml_lines << "allowed-tools: #{metadata[:allowed_tools]}" if metadata[:allowed_tools]
        yaml_lines << "argument-hint: \"#{metadata[:argument_hint]}\"" if metadata[:argument_hint]
        yaml_lines << "model: #{metadata[:model]}" if metadata[:model]
        yaml_lines << "---"
        yaml_lines << ""
        
        # Add the workflow reference lines
        yaml_lines << "read whole file and follow @dev-handbook/workflow-instructions/#{workflow_name}.wf.md"
        yaml_lines << ""
        yaml_lines << "read and run @.claude/commands/commit.md"
        
        yaml_lines.join("\n")
      end

      def infer_metadata(workflow)
        metadata = {}

        # Generate description from workflow name - more sophisticated
        description = workflow.gsub('-', ' ')
        description = description.split.map(&:capitalize).join(' ')
        # Special case handling for common abbreviations
        description.gsub!(/\bApi\b/, 'API')
        description.gsub!(/\bAdr\b/, 'ADR')
        metadata[:description] = description

        # Comprehensive allowed-tools inference based on workflow type
        case workflow
        # Git operations
        when /^git-/, /commit/, /rebase/, /merge/
          metadata[:allowed_tools] = "Bash(git *), Read, Write"
        # Task management workflows
        when /^draft-task/, /^plan-task/, /^work-on-task/, /^review-task/, /^complete-task/
          metadata[:allowed_tools] = "Read, Write, TodoWrite, Bash(task-manager *)"
        # Creation workflows
        when /^create-adr/, /^create-api-docs/, /^create-user-docs/, /^create-reflection-note/
          metadata[:allowed_tools] = "Read, Write, Grep, Glob"
        when /^create-test-cases/
          metadata[:allowed_tools] = "Read, Write, Bash(bundle exec rspec), Grep"
        # Testing and fixing workflows
        when /^test-/, /^validate-/
          metadata[:allowed_tools] = "Bash, Read, Grep"
        when /^fix-tests/, /^fix-linting-issue/
          metadata[:allowed_tools] = "Read, Write, Edit, Bash(bundle exec *), Grep"
        # Research and analysis workflows
        when /^research/, /analyze/
          metadata[:allowed_tools] = "Read, Grep, Glob, WebSearch"
        # Synthesis workflows
        when /^synthesize-reflection-notes/
          metadata[:allowed_tools] = "Read, Write, Grep, TodoWrite"
        # Project context loading
        when /^load-project-context/
          metadata[:allowed_tools] = "Read, LS"
        # Release workflows
        when /^draft-release/, /^release/
          metadata[:allowed_tools] = "Read, Write, Bash(task-manager release *), Grep"
        # Update workflows
        when /^update-blueprint/
          metadata[:allowed_tools] = "Read, Write, Edit, Grep"
        # Capture workflows
        when /^capture-idea/
          metadata[:allowed_tools] = "Write, TodoWrite"
        # Default fallback for any uncategorized workflows
        else
          metadata[:allowed_tools] = "Read, Write, Edit, Grep"
        end

        # Add argument hints for parameterized workflows
        case workflow
        when /work-on-task/, /review-task/, /plan-task/, /complete-task/
          metadata[:argument_hint] = "[task-id]"
        when /rebase-against/, /merge-from/
          metadata[:argument_hint] = "[branch-name]"
        when /fix-linting-issue-from/
          metadata[:argument_hint] = "[linter-output-file]"
        when /draft-release/, /release/
          metadata[:argument_hint] = "[version]"
        when /capture-idea/
          metadata[:argument_hint] = "[idea-description]"
        when /create-adr/
          metadata[:argument_hint] = "[decision-title]"
        end

        # Select model for complex workflows
        case workflow
        when /analyze/, /synthesize/, /research/
          metadata[:model] = "opus"
        when /fix-tests/, /fix-linting/
          metadata[:model] = "sonnet"  # Fast iteration for fixes
        end

        metadata
      end

      def validate_yaml_frontmatter(content)
        # Extract YAML between --- markers
        yaml_match = content.match(/\A---\n(.*?)\n---/m)
        return false unless yaml_match

        begin
          YAML.safe_load(yaml_match[1])
          true
        rescue Psych::SyntaxError => e
          puts "Warning: Invalid YAML in generated command: #{e.message}"
          false
        end
      end
    end
  end
end