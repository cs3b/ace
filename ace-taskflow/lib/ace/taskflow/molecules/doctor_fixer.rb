# frozen_string_literal: true

require "fileutils"
require "ace/support/markdown"
require_relative "../atoms/safe_yaml_parser"
require_relative "../configuration"

module Ace
  module Taskflow
    module Molecules
      # Handles auto-fixing of common taskflow issues
      class DoctorFixer
        attr_reader :dry_run, :fixed_count, :skipped_count

        def initialize(dry_run: false)
          @dry_run = dry_run
          @fixed_count = 0
          @skipped_count = 0
          @fixes_applied = []
        end

        # Fix issues detected by doctor
        # @param issues [Array<Hash>] Issues to fix
        # @return [Hash] Fix results
        def fix_issues(issues)
          fixable_issues = issues.select { |issue| can_fix?(issue) }

          fixable_issues.each do |issue|
            fix_issue(issue)
          end

          {
            fixed: @fixed_count,
            skipped: @skipped_count,
            fixes_applied: @fixes_applied,
            dry_run: @dry_run
          }
        end

        # Fix a single issue
        # @param issue [Hash] Issue to fix
        # @return [Boolean] Whether fix was successful
        def fix_issue(issue)
          # Get configured done directory name for dynamic patterns
          done_dir = Regexp.escape(Ace::Taskflow.configuration.done_dir)

          case issue[:message]
          when /Missing closing '---' delimiter/
            fix_missing_delimiter(issue[:location])
          when /marked as done but not in #{done_dir}\/ directory/
            fix_task_location(issue[:location], :move_to_done)
          when /in #{done_dir}\/ directory but status is/
            fix_task_status(issue[:location], "done")
          when /Missing recommended field: (\w+)/
            fix_missing_field(issue[:location], $1)
          when /Missing default (\w+)/
            fix_missing_default(issue[:location], $1)
          when /Stale backup file/
            fix_stale_backup_file(issue[:location])
          when /Empty directory/
            fix_empty_directory(issue[:location])
          when /invalid nesting, should be in ideas/
            fix_idea_invalid_nesting(issue[:location])
          else
            @skipped_count += 1
            false
          end
        end

        private

        def can_fix?(issue)
          return false unless issue[:location]

          # Get configured done directory name for dynamic patterns
          done_dir = Regexp.escape(Ace::Taskflow.configuration.done_dir)

          # List of auto-fixable patterns
          fixable_patterns = [
            /Missing closing '---' delimiter/,
            /marked as done but not in #{done_dir}\/ directory/,
            /in #{done_dir}\/ directory but status is/,
            /Missing recommended field:/,
            /Missing default/,
            /Stale backup file/,
            /Empty directory/,
            /invalid nesting, should be in ideas/
          ]

          fixable_patterns.any? { |pattern| issue[:message].match?(pattern) }
        end

        def fix_missing_delimiter(file_path)
          return false unless File.exist?(file_path)

          content = File.read(file_path)
          fixed_content = Atoms::SafeYamlParser.fix_frontmatter(content)

          if content != fixed_content
            if @dry_run
              log_fix(file_path, "Would add missing closing '---' delimiter")
              @fixed_count += 1
            else
              Ace::Support::Markdown::Organisms::SafeFileWriter.write(
                file_path,
                fixed_content,
                backup: true,
                validate: true
              )
              log_fix(file_path, "Added missing closing '---' delimiter")
              @fixed_count += 1
            end
            true
          else
            @skipped_count += 1
            false
          end
        end

        def fix_task_location(file_path, action)
          return false unless File.exist?(file_path)

          case action
          when :move_to_done
            move_task_to_done(file_path)
          when :move_from_done
            move_task_from_done(file_path)
          else
            @skipped_count += 1
            false
          end
        end

        def move_task_to_done(file_path)
          # Determine target path
          dir_path = File.dirname(file_path)

          # Get archive directory name from configuration
          archive_dir_name = Ace::Taskflow.configuration.done_dir

          # Check if already in archive
          return false if dir_path.include?("/#{archive_dir_name}/")

          # Find parent t/ directory
          t_dir = find_parent_t_directory(dir_path)
          return false unless t_dir

          # Create archive directory if needed
          done_dir = File.join(t_dir, archive_dir_name)
          FileUtils.mkdir_p(done_dir) unless @dry_run

          # Get task folder name
          task_folder = File.basename(dir_path)
          target_folder = File.join(done_dir, task_folder)

          # Move entire task folder
          if @dry_run
            log_fix(dir_path, "Would move task folder to: #{target_folder}")
          else
            FileUtils.mkdir_p(target_folder)
            FileUtils.mv(Dir.glob(File.join(dir_path, "*")), target_folder)
            FileUtils.rmdir(dir_path) if Dir.empty?(dir_path)
            log_fix(dir_path, "Moved task folder to #{archive_dir_name}: #{target_folder}")
          end

          @fixed_count += 1
          true
        end

        def move_task_from_done(file_path)
          # Determine target path
          dir_path = File.dirname(file_path)

          # Check if in archive directory
          archive_dir_name = Ace::Taskflow.configuration.done_dir
          return false unless dir_path.include?("/#{archive_dir_name}/")

          # Find parent t/ directory
          archive_dir = find_parent_archive_directory(dir_path)
          return false unless archive_dir

          t_dir = File.dirname(archive_dir)

          # Get task folder name
          task_folder = File.basename(dir_path)
          target_folder = File.join(t_dir, task_folder)

          # Move entire task folder
          if @dry_run
            log_fix(dir_path, "Would move task folder from done to: #{target_folder}")
          else
            FileUtils.mkdir_p(target_folder)
            FileUtils.mv(Dir.glob(File.join(dir_path, "*")), target_folder)
            FileUtils.rmdir(dir_path) if Dir.empty?(dir_path)
            log_fix(dir_path, "Moved task folder from done: #{target_folder}")
          end

          @fixed_count += 1
          true
        end

        def fix_task_status(file_path, new_status)
          return false unless File.exist?(file_path)

          begin
            editor = Ace::Support::Markdown::Organisms::DocumentEditor.new(file_path)
            editor.update_frontmatter("status" => new_status)

            if @dry_run
              log_fix(file_path, "Would update status to '#{new_status}'")
            else
              editor.save!(backup: true, validate: true)
              log_fix(file_path, "Updated status to '#{new_status}'")
            end

            @fixed_count += 1
            true
          rescue StandardError => e
            @skipped_count += 1
            false
          end
        end

        def fix_missing_field(file_path, field_name)
          return false unless File.exist?(file_path)

          begin
            editor = Ace::Support::Markdown::Organisms::DocumentEditor.new(file_path)
            default_value = get_default_value(field_name)
            editor.update_frontmatter(field_name => default_value)

            if @dry_run
              log_fix(file_path, "Would add missing field '#{field_name}' with default value")
            else
              editor.save!(backup: true, validate: true)
              log_fix(file_path, "Added missing field '#{field_name}' with default value")
            end

            @fixed_count += 1
            true
          rescue StandardError => e
            @skipped_count += 1
            false
          end
        end

        def fix_missing_default(file_path, item_name)
          # Similar to fix_missing_field but for other defaults
          fix_missing_field(file_path, item_name)
        end


        def fix_stale_backup_file(file_path)
          return false unless file_path && File.exist?(file_path)

          if @dry_run
            log_fix(file_path, "Would delete stale backup file")
          else
            File.delete(file_path)
            log_fix(file_path, "Deleted stale backup file")
          end

          @fixed_count += 1
          true
        end

        def fix_empty_directory(dir_path)
          return false unless dir_path && Dir.exist?(dir_path)

          # Safety: only remove if truly empty (no files recursively)
          files = Dir.glob(File.join(dir_path, "**", "*")).select { |f| File.file?(f) }
          unless files.empty?
            @skipped_count += 1
            return false
          end

          if @dry_run
            log_fix(dir_path, "Would delete empty directory")
          else
            FileUtils.rm_rf(dir_path)
            log_fix(dir_path, "Deleted empty directory")
          end

          @fixed_count += 1
          true
        end

        def fix_idea_invalid_nesting(file_path)
          return false unless file_path && File.exist?(file_path)

          # Move idea from scope/_archive/ to ideas/_archive/
          # Normalize: work with the idea's parent folder
          idea_folder = File.dirname(file_path)
          idea_name = File.basename(idea_folder)

          # Find the ideas/ ancestor directory dynamically
          # Path structure: .../ideas/{scope}/{archive}/idea-folder/file.md
          ideas_dir = find_ideas_ancestor(idea_folder)
          return false unless ideas_dir

          # Target: ideas/_archive/idea-folder
          archive_dir_name = Ace::Taskflow.configuration.done_dir
          target_archive = File.join(ideas_dir, archive_dir_name)
          target_path = File.join(target_archive, idea_name)

          if @dry_run
            log_fix(idea_folder, "Would move from invalid nesting to #{target_archive}/")
          else
            FileUtils.mkdir_p(target_archive) unless File.directory?(target_archive)

            if File.exist?(target_path) || Dir.exist?(target_path)
              @skipped_count += 1
              return false
            end

            FileUtils.mv(idea_folder, target_path)
            log_fix(idea_folder, "Moved from invalid nesting to #{archive_dir_name}/")
          end

          @fixed_count += 1
          true
        end

        # Walk up from path to find the nearest ideas/ directory ancestor
        def find_ideas_ancestor(path)
          current = File.expand_path(path)

          while current != "/" && current != File.expand_path("~")
            return current if File.basename(current) == "ideas"

            parent = File.dirname(current)
            break if parent == current
            current = parent
          end

          nil
        end

        def get_default_value(field_name)
          # Default values for common fields
          defaults = {
            "status" => "pending",
            "priority" => "medium",
            "estimate" => "TBD",
            "dependencies" => []
          }

          defaults[field_name] || ""
        end

        def find_parent_t_directory(path)
          current = File.expand_path(path)

          while current != "/" && current != File.expand_path("~")
            basename = File.basename(current)
            return current if basename == "t"

            parent = File.dirname(current)
            break if parent == current
            current = parent
          end

          nil
        end

        def find_parent_archive_directory(path)
          current = File.expand_path(path)
          archive_dir_name = Ace::Taskflow.configuration.done_dir

          while current != "/" && current != File.expand_path("~")
            basename = File.basename(current)
            return current if basename == archive_dir_name && File.basename(File.dirname(current)) == "t"

            parent = File.dirname(current)
            break if parent == current
            current = parent
          end

          nil
        end

        def apply_fix(file_path, new_content, description)
          if @dry_run
            log_fix(file_path, "Would apply: #{description}")
          else
            # Use SafeFileWriter for all file writes
            Ace::Support::Markdown::Organisms::SafeFileWriter.write(
              file_path,
              new_content,
              backup: true,
              validate: false # Don't validate for non-markdown operations
            )

            log_fix(file_path, description)
          end

          @fixed_count += 1
        end

        def log_fix(file_path, description)
          @fixes_applied << {
            file: file_path,
            description: description,
            timestamp: Time.now
          }
        end
      end
    end
  end
end