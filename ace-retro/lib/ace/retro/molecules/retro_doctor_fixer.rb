# frozen_string_literal: true

require "fileutils"
require "ace/support/markdown"
require "ace/support/items"
require_relative "../atoms/retro_id_formatter"
require_relative "../atoms/retro_validation_rules"
require_relative "../atoms/retro_frontmatter_defaults"
require_relative "retro_loader"
require_relative "retro_mover"

module Ace
  module Retro
    module Molecules
      # Handles auto-fixing of common retro issues detected by doctor.
      # Supports dry_run mode to preview fixes without applying them.
      class RetroDoctorFixer
        attr_reader :dry_run, :fixed_count, :skipped_count

        def initialize(dry_run: false, root_dir: nil)
          @dry_run = dry_run
          @root_dir = root_dir
          @fixed_count = 0
          @skipped_count = 0
          @fixes_applied = []
        end

        # Fix a batch of issues
        # @param issues [Array<Hash>] Issues to fix
        # @return [Hash] Fix results summary
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

        # Fix a single issue by pattern matching its message
        # @param issue [Hash] Issue to fix
        # @return [Boolean] Whether fix was successful
        def fix_issue(issue)
          case issue[:message]
          when /Missing opening '---' delimiter/
            fix_missing_opening_delimiter(issue[:location])
          when /Missing closing '---' delimiter/
            fix_missing_closing_delimiter(issue[:location])
          when /Missing required field: id/
            fix_missing_id(issue[:location])
          when /Missing required field: status/,
               /Missing recommended field: status/
            fix_missing_status(issue[:location])
          when /Missing required field: title/,
               /Missing recommended field: title/
            fix_missing_title(issue[:location])
          when /Missing required field: type/
            fix_missing_type(issue[:location])
          when /Missing required field: created_at/
            fix_missing_created_at(issue[:location])
          when /Field 'tags' is not an array/
            fix_tags_not_array(issue[:location])
          when /Missing recommended field: tags/
            fix_missing_tags(issue[:location])
          when /terminal status.*not in _archive/
            fix_move_to_archive(issue[:location])
          when /in _archive\/ but status is/
            fix_archive_status(issue[:location])
          when /Invalid archive partition/
            fix_invalid_archive_partition(issue[:location])
          when /Stale backup file/
            fix_stale_backup(issue[:location])
          when /Empty directory/
            fix_empty_directory(issue[:location])
          else
            @skipped_count += 1
            false
          end
        end

        # Check if an issue can be auto-fixed
        # @param issue [Hash] Issue to check
        # @return [Boolean]
        def can_fix?(issue)
          return false unless issue[:location]

          FIXABLE_PATTERNS.any? { |pattern| issue[:message].match?(pattern) }
        end

        FIXABLE_PATTERNS = [
          /Missing opening '---' delimiter/,
          /Missing closing '---' delimiter/,
          /Missing required field: id/,
          /Missing required field: status/,
          /Missing required field: title/,
          /Missing required field: type/,
          /Missing required field: created_at/,
          /Missing recommended field: status/,
          /Missing recommended field: title/,
          /Missing recommended field: tags/,
          /Field 'tags' is not an array/,
          /terminal status.*not in _archive/,
          /in _archive\/ but status is/,
          /Invalid archive partition/,
          /Stale backup file/,
          /Empty directory/
        ].freeze

        private

        def fix_missing_closing_delimiter(file_path)
          return false unless File.exist?(file_path)

          content = File.read(file_path)
          lines = content.lines
          insert_idx = nil
          lines[1..].each_with_index do |line, i|
            if line.strip.empty? || line.start_with?("#")
              insert_idx = i + 1
              break
            end
          end
          insert_idx ||= lines.size

          fixed_lines = lines.dup
          fixed_lines.insert(insert_idx, "---\n")
          fixed_content = fixed_lines.join

          apply_file_fix(file_path, fixed_content, "Added missing closing '---' delimiter")
        end

        def fix_missing_opening_delimiter(file_path)
          return false unless File.exist?(file_path)

          content = File.read(file_path)
          dir_name = File.basename(File.dirname(file_path))
          id_match = dir_name.match(/^([0-9a-z]{6})/)
          id = id_match ? id_match[1] : nil

          title = extract_title_from_content(content) || extract_slug_title(dir_name)

          frontmatter = Atoms::RetroFrontmatterDefaults.build(
            id: id || Atoms::RetroIdFormatter.generate,
            title: title,
            status: "active",
            created_at: Time.now.utc
          )
          frontmatter["id"] = id if id

          yaml_block = Atoms::RetroFrontmatterDefaults.serialize(frontmatter)
          new_content = "#{yaml_block}\n#{content}"

          apply_file_fix(file_path, new_content, "Added opening '---' delimiter and frontmatter")
        end

        def fix_missing_id(file_path)
          return false unless File.exist?(file_path)

          dir_name = File.basename(File.dirname(file_path))
          id_match = dir_name.match(/^([0-9a-z]{6})/)
          unless id_match
            return (@skipped_count += 1
                    false)
          end

          id = id_match[1]
          update_frontmatter_field(file_path, "id", id, "Added missing 'id' field from folder name")
        end

        def fix_missing_status(file_path)
          update_frontmatter_field(file_path, "status", "active", "Added missing 'status' field with default 'active'")
        end

        def fix_missing_title(file_path)
          return false unless File.exist?(file_path)

          content = File.read(file_path)
          title = nil
          _fm, body = Ace::Support::Items::Atoms::FrontmatterParser.parse(content)
          if body
            h1_match = body.match(/^#\s+(.+)/)
            title = h1_match[1].strip if h1_match
          end

          unless title
            dir_name = File.basename(File.dirname(file_path))
            slug_match = dir_name.match(/^[0-9a-z]{6}-(.+)$/)
            title = slug_match ? slug_match[1].tr("-", " ").capitalize : "Untitled"
          end

          update_frontmatter_field(file_path, "title", title, "Added missing 'title' field: '#{title}'")
        end

        def fix_missing_type(file_path)
          update_frontmatter_field(file_path, "type", "standard", "Added missing 'type' field with default 'standard'")
        end

        def fix_missing_created_at(file_path)
          return false unless File.exist?(file_path)

          content = File.read(file_path)
          frontmatter, _body = Ace::Support::Items::Atoms::FrontmatterParser.parse(content)

          id = frontmatter&.dig("id")
          unless id
            match = File.basename(File.dirname(file_path)).match(/^([0-9a-z]{6})/)
            id = match[1] if match
          end

          created_at = if id && Atoms::RetroIdFormatter.valid?(id)
            Atoms::RetroIdFormatter.decode_time(id).strftime("%Y-%m-%d %H:%M:%S")
          else
            Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")
          end

          update_frontmatter_field(file_path, "created_at", created_at, "Added missing 'created_at' field")
        end

        def fix_tags_not_array(file_path)
          update_frontmatter_field(file_path, "tags", [], "Coerced 'tags' field to empty array")
        end

        def fix_missing_tags(file_path)
          update_frontmatter_field(file_path, "tags", [], "Added missing 'tags' field with empty array")
        end

        def fix_move_to_archive(file_path)
          return false unless file_path && @root_dir

          retro_dir = File.directory?(file_path) ? file_path : File.dirname(file_path)
          folder_name = File.basename(retro_dir)
          partition = Ace::Support::Items::Atoms::DatePartitionPath.compute(Time.now, levels: [:month])
          archive_dir = File.join(@root_dir, "_archive", partition)
          target = File.join(archive_dir, folder_name)

          if @dry_run
            log_fix(retro_dir, "Would move to _archive/#{partition}/")
            @fixed_count += 1
            return true
          end

          FileUtils.mkdir_p(archive_dir)
          if File.exist?(target)
            return (@skipped_count += 1
                    false)
          end

          FileUtils.mv(retro_dir, target)
          log_fix(retro_dir, "Moved to _archive/#{partition}/")
          @fixed_count += 1
          true
        rescue
          @skipped_count += 1
          false
        end

        def fix_archive_status(file_path)
          update_frontmatter_field(file_path, "status", "done", "Updated status to 'done' (in _archive/)")
        end

        def fix_invalid_archive_partition(partition_dir)
          return false unless partition_dir && Dir.exist?(partition_dir) && @root_dir

          loader = RetroLoader.new
          mover = RetroMover.new(@root_dir)
          moved = 0

          Dir.glob(File.join(partition_dir, "*")).each do |retro_path|
            next unless File.directory?(retro_path)

            retro = loader.load(retro_path, special_folder: "_archive")
            next unless retro

            if @dry_run
              partition = Ace::Support::Items::Atoms::DatePartitionPath.compute(retro.created_at || Time.now)
              log_fix(retro_path, "Would move to _archive/#{partition}/")
            else
              mover.move(retro, to: "archive", date: retro.created_at)
            end
            moved += 1
          end

          # Remove empty partition dir
          unless @dry_run
            remaining = Dir.glob(File.join(partition_dir, "*"))
            FileUtils.rmdir(partition_dir) if remaining.empty?
          end

          if moved > 0
            unless @dry_run
              log_fix(partition_dir, "Relocated #{moved} retro(s) to b36ts partition(s)")
            end
            @fixed_count += 1
            true
          else
            @skipped_count += 1
            false
          end
        rescue
          @skipped_count += 1
          false
        end

        def fix_stale_backup(file_path)
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

        def extract_title_from_content(content)
          h1_match = content.match(/^#\s+(.+)$/)
          h1_match ? h1_match[1].strip : nil
        end

        def extract_slug_title(dir_name)
          slug_match = dir_name.match(/^[0-9a-z]{6}-(.+)$/)
          slug = slug_match ? slug_match[1] : dir_name
          slug.tr("-", " ").capitalize
        end

        def update_frontmatter_field(file_path, field, value, description)
          return false unless file_path && File.exist?(file_path)

          if @dry_run
            log_fix(file_path, "Would: #{description}")
            @fixed_count += 1
            return true
          end

          editor = Ace::Support::Markdown::Organisms::DocumentEditor.new(file_path)
          editor.update_frontmatter(field => value)
          editor.save!(backup: true, validate_before: false)
          log_fix(file_path, description)
          @fixed_count += 1
          true
        rescue
          @skipped_count += 1
          false
        end

        def apply_file_fix(file_path, new_content, description)
          if @dry_run
            log_fix(file_path, "Would: #{description}")
          else
            Ace::Support::Markdown::Organisms::SafeFileWriter.write(
              file_path,
              new_content,
              backup: true
            )
            log_fix(file_path, description)
          end

          @fixed_count += 1
          true
        rescue
          @skipped_count += 1
          false
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
