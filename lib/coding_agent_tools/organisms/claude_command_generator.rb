# frozen_string_literal: true

require 'pathname'
require 'fileutils'
require 'erb'

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
        @template_path = @project_root / "dev-handbook/.integrations/claude/templates/workflow-command.md.tmpl"
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
          # Fallback to hardcoded template if file doesn't exist
          <<~TEMPLATE
            read whole file and follow @dev-handbook/workflow-instructions/<%= workflow_name %>.wf.md

            read and run @dev-handbook/.integrations/claude/commands/commit.md
          TEMPLATE
        end
      end

      def render_template(template_content, workflow_name)
        # Use ERB for template rendering to match the existing .tmpl file
        ERB.new(template_content).result(binding)
      end
    end
  end
end