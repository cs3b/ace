# frozen_string_literal: true

require "fileutils"
require_relative "../atoms/safe_yaml_parser"

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
          case issue[:message]
          when /Missing closing '---' delimiter/
            fix_missing_delimiter(issue[:location])
          when /marked as done but not in done\/ directory/
            fix_task_location(issue[:location], :move_to_done)
          when /in done\/ directory but status is/
            fix_task_status(issue[:location], "done")
          when /Missing recommended field: (\w+)/
            fix_missing_field(issue[:location], $1)
          when /Missing default (\w+)/
            fix_missing_default(issue[:location], $1)
          else
            @skipped_count += 1
            false
          end
        end

        private

        def can_fix?(issue)
          return false unless issue[:location]

          # List of auto-fixable patterns
          fixable_patterns = [
            /Missing closing '---' delimiter/,
            /marked as done but not in done\/ directory/,
            /in done\/ directory but status is/,
            /Missing recommended field:/,
            /Missing default/
          ]

          fixable_patterns.any? { |pattern| issue[:message].match?(pattern) }
        end

        def fix_missing_delimiter(file_path)
          return false unless File.exist?(file_path)

          content = File.read(file_path)
          fixed_content = Atoms::SafeYamlParser.fix_frontmatter(content)

          if content != fixed_content
            apply_fix(file_path, fixed_content, "Added missing closing '---' delimiter")
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

          # Check if already in done
          return false if dir_path.include?("/done/")

          # Find parent t/ directory
          t_dir = find_parent_t_directory(dir_path)
          return false unless t_dir

          # Create done directory if needed
          done_dir = File.join(t_dir, "done")
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
            log_fix(dir_path, "Moved task folder to done: #{target_folder}")
          end

          @fixed_count += 1
          true
        end

        def move_task_from_done(file_path)
          # Determine target path
          dir_path = File.dirname(file_path)

          # Check if in done
          return false unless dir_path.include?("/done/")

          # Find parent t/ directory
          done_dir = find_parent_done_directory(dir_path)
          return false unless done_dir

          t_dir = File.dirname(done_dir)

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

          content = File.read(file_path)
          result = Atoms::SafeYamlParser.parse_with_recovery(content)

          # Update status in frontmatter
          if result[:frontmatter].is_a?(Hash)
            result[:frontmatter]["status"] = new_status

            # Rebuild content with updated frontmatter
            new_content = rebuild_content_with_frontmatter(result[:frontmatter], result[:content])

            apply_fix(file_path, new_content, "Updated status to '#{new_status}'")
            true
          else
            @skipped_count += 1
            false
          end
        end

        def fix_missing_field(file_path, field_name)
          return false unless File.exist?(file_path)

          content = File.read(file_path)
          result = Atoms::SafeYamlParser.parse_with_recovery(content)

          # Add missing field with default value
          if result[:frontmatter].is_a?(Hash)
            default_value = get_default_value(field_name)
            result[:frontmatter][field_name] = default_value

            # Rebuild content with updated frontmatter
            new_content = rebuild_content_with_frontmatter(result[:frontmatter], result[:content])

            apply_fix(file_path, new_content, "Added missing field '#{field_name}' with default value")
            true
          else
            @skipped_count += 1
            false
          end
        end

        def fix_missing_default(file_path, item_name)
          # Similar to fix_missing_field but for other defaults
          fix_missing_field(file_path, item_name)
        end

        def rebuild_content_with_frontmatter(frontmatter, body_content)
          yaml_content = YAML.dump(frontmatter).strip

          # Remove the leading "---" that YAML.dump adds
          yaml_content = yaml_content.sub(/^---\n/, "")

          # Rebuild the content
          "---\n#{yaml_content}\n---\n#{body_content}"
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

        def find_parent_done_directory(path)
          current = File.expand_path(path)

          while current != "/" && current != File.expand_path("~")
            basename = File.basename(current)
            return current if basename == "done" && File.basename(File.dirname(current)) == "t"

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
            # Backup original file
            backup_path = "#{file_path}.doctor-backup"
            File.write(backup_path, File.read(file_path))

            # Write fixed content
            File.write(file_path, new_content)

            # Remove backup if successful
            File.delete(backup_path)

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