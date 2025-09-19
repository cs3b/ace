# frozen_string_literal: true

require "pathname"
require "digest"
require_relative "../../atoms/claude/command_existence_checker"
require_relative "../../atoms/claude/workflow_scanner"
require_relative "../../molecules/command_template_renderer"
require_relative "command_inventory_builder"

module CodingAgentTools
  module Molecules
    module Claude
      # Validates Claude command coverage and consistency
      # This is a behavior-oriented helper that encapsulates validation logic
      class CommandValidator
        attr_reader :project_root

        def initialize(project_root)
          @project_root = Pathname.new(project_root)
          @workflow_dir = @project_root / "dev-handbook" / "workflow-instructions"
          @template_renderer = CommandTemplateRenderer.new
          @inventory_builder = CommandInventoryBuilder.new(project_root)
        end

        # Check command coverage
        # @return [Array<String>] Array of workflow names without commands
        def find_missing_commands
          inventory = @inventory_builder.build
          inventory[:commands]
            .select { |cmd| cmd[:type] == "missing" }
            .map { |cmd| cmd[:name] }
        end

        # Find outdated commands by comparing with expected content
        # @return [Array<Hash>] Array of hashes with command info and reasons
        def find_outdated_commands
          outdated = []
          inventory = @inventory_builder.build

          # Check each non-missing command
          inventory[:commands].reject { |cmd| cmd[:type] == "missing" }.each do |cmd|
            command_path = @project_root / cmd[:path]
            workflow_name = cmd[:name]

            if is_command_outdated?(workflow_name, command_path)
              outdated << {
                command: cmd[:name],
                path: cmd[:path],
                reason: "Content mismatch with expected template"
              }
            end
          end

          outdated
        end

        # Find duplicate commands across different locations
        # @return [Array<Hash>] Array of duplicates with locations
        def find_duplicate_commands
          duplicates = []
          command_locations = Hash.new { |h, k| h[k] = [] }

          # Get all search paths
          search_paths = @inventory_builder.command_search_paths
          search_paths << @project_root / "dev-handbook" / ".integrations" / "claude" / "commands" # Legacy path

          # Check all locations
          search_paths.uniq.each do |path|
            next unless path.exist?

            Dir.glob(File.join(path, "*.md")).each do |file|
              name = File.basename(file, ".md")
              command_locations[name] << path.relative_path_from(@project_root).to_s
            end
          end

          # Find duplicates
          command_locations.each do |name, locations|
            if locations.size > 1
              duplicates << {
                name: name,
                locations: locations.uniq
              }
            end
          end

          duplicates
        end

        # Find orphaned commands (commands without corresponding workflows)
        # @return [Array<Hash>] Array of orphaned commands
        def find_orphaned_commands
          orphaned = []

          # Get all workflows
          all_workflows = Atoms::Claude::WorkflowScanner.scan(@workflow_dir)

          # Get all commands from .claude directory
          claude_dir = @project_root / ".claude" / "commands"
          return orphaned unless claude_dir.exist?

          Dir.glob(File.join(claude_dir, "**", "*.md")).each do |cmd_path|
            cmd_name = File.basename(cmd_path, ".md")

            # Skip special commands that handle multiple workflows
            next if multi_task_command?(cmd_name)

            unless all_workflows.include?(cmd_name)
              orphaned << {
                name: cmd_name,
                location: Pathname.new(cmd_path).relative_path_from(@project_root).to_s
              }
            end
          end

          orphaned
        end

        # Validate a single workflow
        # @param workflow_name [String] Name of the workflow
        # @return [Hash] Validation result with :valid, :exists, :outdated
        def validate_single_workflow(workflow_name)
          workflow_path = @workflow_dir / "#{workflow_name}.wf.md"

          unless workflow_path.exist?
            return {valid: false, exists: false, reason: "Workflow not found"}
          end

          # Check if command exists
          search_paths = @inventory_builder.command_search_paths
          command_path = Atoms::Claude::CommandExistenceChecker.find(workflow_name, search_paths)

          unless command_path
            return {valid: false, exists: false, reason: "Command not found"}
          end

          # Check if outdated
          if is_command_outdated?(workflow_name, command_path)
            return {valid: false, exists: true, outdated: true, reason: "Content mismatch"}
          end

          {valid: true, exists: true, outdated: false}
        end

        private

        def is_command_outdated?(workflow_name, command_path)
          return false unless command_path.exist?

          # Generate expected content using template renderer
          expected_content = @template_renderer.render(workflow_name)
          actual_content = command_path.read

          # Compare normalized content (ignore whitespace differences)
          normalize_content(expected_content) != normalize_content(actual_content)
        end

        def normalize_content(content)
          # Normalize by removing extra whitespace and blank lines
          content.strip.gsub(/\s+/, " ").gsub(/\n\s*\n/, "\n")
        end

        def multi_task_command?(name)
          # Commands that handle multiple tasks don't map 1:1 to workflows
          ["commit", "handbook-review", "load-project-context", "draft-tasks", "plan-tasks", "review-tasks", "work-on-tasks"].include?(name)
        end
      end
    end
  end
end
