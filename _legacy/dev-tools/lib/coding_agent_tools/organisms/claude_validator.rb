# frozen_string_literal: true

require "pathname"
require "json"
require "digest"
require "set"
require "stringio"

module CodingAgentTools
  module Organisms
    # Validates Claude command coverage and consistency
    class ClaudeValidator
      attr_reader :project_root, :validation_results

      def initialize(project_root = nil)
        @project_root = Pathname.new(project_root || find_project_root)
        @workflow_dir = @project_root / "dev-handbook" / "workflow-instructions"
        @custom_dir = @project_root / "dev-handbook" / ".integrations" / "claude" / "commands" / "_custom"
        @generated_dir = @project_root / "dev-handbook" / ".integrations" / "claude" / "commands" / "_generated"
        @claude_dir = @project_root / ".claude" / "commands"

        # Legacy paths for backward compatibility
        @legacy_custom_dir = @project_root / "dev-handbook" / ".integrations" / "claude" / "commands"

        @validation_results = {
          workflow_count: 0,
          command_count: 0,
          missing: [],
          outdated: [],
          duplicates: [],
          orphaned: [],
          valid: []
        }
      end

      def validate(options = {})
        if options[:workflow]
          validate_single_workflow(options[:workflow])
        elsif options[:check]
          run_specific_check(options[:check])
        else
          run_all_validations
        end

        ValidationResult.new(
          success: !has_issues?,
          data: @validation_results,
          format: options[:format] || "text"
        )
      end

      def has_issues?
        @validation_results[:missing].any? ||
          @validation_results[:outdated].any? ||
          @validation_results[:duplicates].any?
      end

      private

      def find_project_root
        # Reuse logic from ClaudeCommandsInstaller
        current = Pathname.pwd
        while current.parent != current
          return current if (current / ".claude" / "commands").directory?
          current = current.parent
        end
        Pathname.pwd
      end

      def run_all_validations
        # Count workflows and commands
        @validation_results[:workflow_count] = count_workflows
        @validation_results[:command_count] = count_commands

        # Run all checks
        @validation_results[:missing] = find_missing_commands
        @validation_results[:outdated] = find_outdated_commands
        @validation_results[:duplicates] = find_duplicate_commands
        @validation_results[:orphaned] = find_orphaned_commands
        @validation_results[:valid] = find_valid_commands
      end

      def run_specific_check(check)
        case check
        when "missing"
          @validation_results[:missing] = find_missing_commands
        when "outdated"
          @validation_results[:outdated] = find_outdated_commands
        when "duplicates"
          @validation_results[:duplicates] = find_duplicate_commands
        when "orphaned"
          @validation_results[:orphaned] = find_orphaned_commands
        else
          raise ArgumentError, "Unknown check type: #{check}"
        end
      end

      def validate_single_workflow(workflow_name)
        workflow_path = @workflow_dir / "#{workflow_name}.wf.md"
        unless workflow_path.exist?
          raise ArgumentError, "Workflow not found: #{workflow_name}"
        end

        # Check if command exists
        if command_exists?(workflow_name)
          command_path = find_command_path(workflow_name)

          # Check if outdated
          if is_command_outdated?(workflow_name, command_path)
            @validation_results[:outdated] << {
              workflow: workflow_name,
              reason: "Content mismatch"
            }
          else
            @validation_results[:valid] << workflow_name
          end
        else
          @validation_results[:missing] << workflow_name
        end
      end

      def count_workflows
        return 0 unless @workflow_dir.exist?
        @workflow_dir.glob("*.wf.md").count
      end

      def count_commands
        count = 0

        # Count in all possible locations
        [@custom_dir, @generated_dir, @legacy_custom_dir, @claude_dir].each do |dir|
          count += dir.glob("*.md").count if dir.exist?
        end

        count
      end

      def find_missing_commands
        return [] unless @workflow_dir.exist?

        workflows = @workflow_dir.glob("*.wf.md")
        missing = []

        workflows.each do |workflow_path|
          name = workflow_path.basename(".wf.md").to_s
          unless command_exists?(name)
            missing << name
          end
        end

        missing.sort
      end

      def find_outdated_commands
        outdated = []

        all_commands.each do |cmd_path|
          workflow_name = cmd_path.basename(".md").to_s
          workflow_path = @workflow_dir / "#{workflow_name}.wf.md"

          if workflow_path.exist? && is_command_outdated?(workflow_name, cmd_path)
            outdated << {
              command: cmd_path.basename.to_s,
              workflow_path: workflow_path.relative_path_from(@project_root).to_s,
              reason: "Content hash mismatch"
            }
          end
        end

        outdated
      end

      def find_duplicate_commands
        duplicates = []
        command_locations = Hash.new { |h, k| h[k] = [] }

        # Check all locations for commands
        [@custom_dir, @generated_dir, @legacy_custom_dir, @claude_dir].each do |dir|
          next unless dir.exist?

          dir.glob("*.md").each do |file|
            name = file.basename(".md").to_s
            command_locations[name] << dir.relative_path_from(@project_root).to_s
          end
        end

        # Find duplicates
        command_locations.each do |name, locations|
          if locations.size > 1
            duplicates << {
              name: name,
              locations: locations
            }
          end
        end

        duplicates
      end

      def find_orphaned_commands
        return [] unless @workflow_dir.exist?

        workflows = @workflow_dir.glob("*.wf.md").map { |p| p.basename(".wf.md").to_s }
        orphaned = []

        # Check .claude/commands directory
        if @claude_dir.exist?
          @claude_dir.glob("*.md").each do |cmd_path|
            cmd_name = cmd_path.basename(".md").to_s
            unless workflows.include?(cmd_name) || is_multi_task_command?(cmd_name)
              orphaned << {
                name: cmd_name,
                location: ".claude/commands/"
              }
            end
          end
        end

        orphaned
      end

      def find_valid_commands
        return [] unless @workflow_dir.exist?

        valid = []
        workflows = @workflow_dir.glob("*.wf.md")

        workflows.each do |workflow_path|
          name = workflow_path.basename(".wf.md").to_s
          if command_exists?(name)
            cmd_path = find_command_path(name)
            unless is_command_outdated?(name, cmd_path)
              valid << name
            end
          end
        end

        valid.sort
      end

      def command_exists?(name)
        # Check in all possible locations
        paths_to_check = [
          @custom_dir / "#{name}.md",
          @generated_dir / "#{name}.md",
          @legacy_custom_dir / "#{name}.md",
          @claude_dir / "#{name}.md"
        ]

        paths_to_check.any?(&:exist?)
      end

      def find_command_path(name)
        paths_to_check = [
          @custom_dir / "#{name}.md",
          @generated_dir / "#{name}.md",
          @legacy_custom_dir / "#{name}.md",
          @claude_dir / "#{name}.md"
        ]

        paths_to_check.find(&:exist?)
      end

      def is_command_outdated?(workflow_name, cmd_path)
        # Generate expected content
        expected_content = generate_command_content(workflow_name)
        actual_content = cmd_path.read

        # Compare content hashes
        expected_hash = Digest::SHA256.hexdigest(expected_content)
        actual_hash = Digest::SHA256.hexdigest(actual_content)

        expected_hash != actual_hash
      end

      def generate_command_content(workflow_name)
        # Check for custom templates
        case workflow_name
        when "commit"
          <<~CONTENT
            Read the entire file: @dev-handbook/workflow-instructions/commit.wf.md

            Follow the instructions exactly, including creating the git commit with the specific format shown.
          CONTENT
        when "load-project-context"
          <<~CONTENT
            Read the entire file: @dev-handbook/workflow-instructions/load-project-context.wf.md

            Load all the context documents listed in the workflow.
          CONTENT
        else
          # Default template
          <<~CONTENT
            read whole file and follow @dev-handbook/workflow-instructions/#{workflow_name}.wf.md

            read and run @.claude/commands/commit.md
          CONTENT
        end
      end

      def all_commands
        commands = []

        [@custom_dir, @generated_dir, @legacy_custom_dir, @claude_dir].each do |dir|
          commands.concat(dir.glob("*.md")) if dir.exist?
        end

        commands.uniq { |cmd| cmd.basename.to_s }
      end

      def is_multi_task_command?(name)
        # Commands that handle multiple tasks don't map 1:1 to workflows
        ["commit", "handbook-review", "load-project-context", "draft-tasks", "plan-tasks", "review-tasks", "work-on-tasks"].include?(name)
      end

      # Result class for formatting output
      class ValidationResult
        attr_reader :success, :data, :format

        def initialize(success:, data:, format: "text")
          @success = success
          @data = data
          @format = format
        end

        def to_s
          case format
          when "json"
            to_json
          else
            to_text
          end
        end

        def to_text
          report = StringIO.new

          report.puts "Validating Claude command coverage..."
          report.puts ""
          report.puts "Workflows found: #{data[:workflow_count]}"
          report.puts "Commands found: #{data[:command_count]}"
          report.puts ""

          if data[:missing].any?
            report.puts "✗ Missing commands:"
            data[:missing].each do |name|
              report.puts "  - #{name}.wf.md (no command found)"
            end
            report.puts ""
          end

          if data[:outdated].any?
            report.puts "⚠ Outdated commands (workflow modified after command):"
            data[:outdated].each do |info|
              report.puts "  - #{info[:command]} (#{info[:reason]})"
            end
            report.puts ""
          end

          if data[:duplicates].any?
            report.puts "⚠ Duplicate commands:"
            data[:duplicates].each do |info|
              report.puts "  - #{info[:name]} appears in: #{info[:locations].join(", ")}"
            end
            report.puts ""
          end

          if data[:orphaned].any?
            report.puts "ℹ Orphaned commands (no corresponding workflow):"
            data[:orphaned].each do |info|
              report.puts "  - #{info[:name]} in #{info[:location]}"
            end
            report.puts ""
          end

          if data[:valid].any?
            report.puts "✓ Valid commands: #{data[:valid].size}"
          end

          report.puts ""
          report.puts summary_line

          report.string
        end

        def to_json
          output = {
            success: success,
            validation_status: success ? "passed" : "failed",
            summary: {
              workflows_found: data[:workflow_count],
              commands_found: data[:command_count],
              missing_count: data[:missing].size,
              outdated_count: data[:outdated].size,
              duplicate_count: data[:duplicates].size,
              orphaned_count: data[:orphaned].size,
              valid_count: data[:valid].size
            },
            details: {
              missing: data[:missing],
              outdated: data[:outdated],
              duplicates: data[:duplicates],
              orphaned: data[:orphaned],
              valid: data[:valid]
            },
            message: summary_line
          }

          JSON.pretty_generate(output)
        end

        private

        def summary_line
          issues = []
          issues << "#{data[:missing].size} missing" if data[:missing].any?
          issues << "#{data[:outdated].size} outdated" if data[:outdated].any?
          issues << "#{data[:duplicates].size} duplicate" if data[:duplicates].any?

          if issues.empty?
            "Summary: All commands are valid and up to date"
          else
            "Summary: #{issues.join(", ")}"
          end
        end
      end
    end
  end
end
