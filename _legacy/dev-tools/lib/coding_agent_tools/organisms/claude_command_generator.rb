# frozen_string_literal: true

require "pathname"
require "fileutils"
require_relative "../atoms/claude/workflow_scanner"
require_relative "../atoms/claude/command_existence_checker"
require_relative "../atoms/claude/yaml_frontmatter_validator"
require_relative "../molecules/claude/command_metadata_inferrer"
require_relative "../molecules/command_template_renderer"

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
        @template_path = @project_root / "dev-handbook/.integrations/claude/templates/command.md.tmpl"
        @stats = {generated: 0, skipped: 0, errors: []}

        # Initialize atoms and molecules
        @metadata_inferrer = Molecules::Claude::CommandMetadataInferrer.new
        @template_renderer = Molecules::CommandTemplateRenderer.new
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
          # Check if we're in a submodule that has dev-handbook as a sibling
          if (current.parent / "dev-handbook").directory?
            return current.parent
          end
          # Check if dev-handbook is a direct subdirectory
          return current if (current / "dev-handbook").directory?
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
        # Use WorkflowScanner atom for all workflow discovery
        Atoms::Claude::WorkflowScanner.scan(@workflow_dir, specific)
      end

      def find_missing_commands(workflows, force = false)
        workflows.reject do |workflow|
          # Use CommandExistenceChecker to check for commands
          [@custom_dir, @generated_dir]

          custom_exists = Atoms::Claude::CommandExistenceChecker.exists?(workflow, [@custom_dir])
          generated_exists = Atoms::Claude::CommandExistenceChecker.exists?(workflow, [@generated_dir])

          # Skip custom commands always, but allow regeneration of generated commands with force
          custom_exists || (generated_exists && !force)
        end
      end

      def display_dry_run(missing, force = false)
        puts "Scanning workflow instructions..."
        # Use WorkflowScanner to count workflows
        all_workflows = Atoms::Claude::WorkflowScanner.scan(@workflow_dir)
        puts "Found #{all_workflows.size} workflow files"
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
        # Use WorkflowScanner to count all workflows
        all_workflows = Atoms::Claude::WorkflowScanner.scan(@workflow_dir)
        puts "Found #{all_workflows.size} workflow files"
        puts "Checking existing commands..."
        puts

        # Count skipped workflows (those not in the workflows list due to existing commands)
        @stats[:skipped] = all_workflows.size - workflows.size

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

            # Validate YAML front-matter using atom
            unless Atoms::Claude::YamlFrontmatterValidator.valid?(content)
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
        # Use CommandMetadataInferrer molecule
        metadata = @metadata_inferrer.infer(workflow_name)

        # Build YAML front-matter programmatically (safer than eval)
        yaml_lines = ["---"]
        yaml_lines << "description: #{metadata[:description]}"
        yaml_lines << "allowed-tools: #{metadata[:allowed_tools]}" if metadata[:allowed_tools]
        yaml_lines << "argument-hint: \"#{metadata[:argument_hint]}\"" if metadata[:argument_hint]
        yaml_lines << "model: #{metadata[:model]}" if metadata[:model]
        yaml_lines << "---"
        yaml_lines << ""

        # Use CommandTemplateRenderer to generate body
        body_content = @template_renderer.render(workflow_name)
        yaml_lines << body_content

        yaml_lines.join("\n")
      end

      def infer_metadata(workflow)
        metadata = {}

        # Generate description from workflow name - more sophisticated
        description = workflow.tr("-", " ")
        description = description.split.map(&:capitalize).join(" ")
        # Special case handling for common abbreviations
        description.gsub!(/\bApi\b/, "API")
        description.gsub!(/\bAdr\b/, "ADR")
        metadata[:description] = description

        # Comprehensive allowed-tools inference based on workflow type
        metadata[:allowed_tools] = case workflow
        # Git operations
        when /^git-/, /commit/, /rebase/, /merge/
          "Bash(git *), Read, Write"
        # Task management workflows
        when /^draft-task/, /^plan-task/, /^work-on-task/, /^review-task/, /^complete-task/
          "Read, Write, TodoWrite, Bash(task-manager *)"
        # Creation workflows
        when /^create-adr/, /^create-api-docs/, /^create-user-docs/, /^create-reflection-note/
          "Read, Write, Grep, Glob"
        when /^create-test-cases/
          "Read, Write, Bash(bundle exec rspec), Grep"
        # Testing and fixing workflows
        when /^test-/, /^validate-/
          "Bash, Read, Grep"
        when /^fix-tests/, /^fix-linting-issue/
          "Read, Write, Edit, Bash(bundle exec *), Grep"
        # Research and analysis workflows
        when /^research/, /analyze/
          "Read, Grep, Glob, WebSearch"
        # Synthesis workflows
        when /^synthesize-reflection-notes/
          "Read, Write, Grep, TodoWrite"
        # Project context loading
        when /^load-project-context/
          "Read, LS"
        # Release workflows
        when /^draft-release/, /^release/
          "Read, Write, Bash(task-manager release *), Grep"
        # Update workflows
        when /^update-blueprint/
          "Read, Write, Edit, Grep"
        # Capture workflows
        when /^capture-idea/
          "Write, TodoWrite"
        # Default fallback for any uncategorized workflows
        else
          "Read, Write, Edit, Grep"
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
