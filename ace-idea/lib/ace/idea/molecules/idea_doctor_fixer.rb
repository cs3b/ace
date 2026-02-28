# frozen_string_literal: true

require "fileutils"
require "ace/support/markdown"
require "ace/support/items"
require_relative "../atoms/idea_id_formatter"
require_relative "../atoms/idea_validation_rules"
require_relative "../atoms/idea_frontmatter_defaults"

module Ace
  module Idea
    module Molecules
      # Handles auto-fixing of common idea issues detected by doctor.
      # Supports dry_run mode to preview fixes without applying them.
      class IdeaDoctorFixer
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
          when /Field 'tags' is not an array/
            fix_tags_not_array(issue[:location])
          when /Missing recommended field: tags/
            fix_missing_tags(issue[:location])
          when /Missing recommended field: created_at/
            fix_missing_created_at(issue[:location])
          when /terminal status.*not in _archive/
            fix_move_to_archive(issue[:location])
          when /in _archive\/ but status is/
            fix_archive_status(issue[:location])
          when /in _maybe\/ with terminal status/
            fix_maybe_terminal(issue[:location])
          when /Stale backup file/
            fix_stale_backup(issue[:location])
          when /Empty directory/
            fix_empty_directory(issue[:location])
          when /Folder name does not match '\{id\}-\{slug\}' convention/
            fix_folder_naming(issue[:location])
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

        private

        FIXABLE_PATTERNS = [
          /Missing opening '---' delimiter/,
          /Missing closing '---' delimiter/,
          /Missing required field: id/,
          /Missing required field: status/,
          /Missing required field: title/,
          /Missing recommended field: status/,
          /Missing recommended field: title/,
          /Missing recommended field: tags/,
          /Missing recommended field: created_at/,
          /Field 'tags' is not an array/,
          /terminal status.*not in _archive/,
          /in _archive\/ but status is/,
          /in _maybe\/ with terminal status/,
          /Stale backup file/,
          /Empty directory/,
          /Folder name does not match '\{id\}-\{slug\}' convention/
        ].freeze

        def fix_missing_closing_delimiter(file_path)
          return false unless File.exist?(file_path)

          content = File.read(file_path)
          # Append closing delimiter after frontmatter content
          lines = content.lines
          # Find where frontmatter content ends (first blank line or markdown heading)
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

        def fix_missing_id(file_path)
          return false unless File.exist?(file_path)

          # Extract ID from folder name
          dir_name = File.basename(File.dirname(file_path))
          id_match = dir_name.match(/^([0-9a-z]{6})/)
          return (@skipped_count += 1; false) unless id_match

          id = id_match[1]
          update_frontmatter_field(file_path, "id", id, "Added missing 'id' field from folder name")
        end

        def fix_missing_status(file_path)
          update_frontmatter_field(file_path, "status", "pending", "Added missing 'status' field with default 'pending'")
        end

        def fix_missing_title(file_path)
          return false unless File.exist?(file_path)

          content = File.read(file_path)
          # Try to extract title from body H1
          title = nil
          _fm, body = Ace::Support::Items::Atoms::FrontmatterParser.parse(content)
          if body
            h1_match = body.match(/^#\s+(.+)/)
            title = h1_match[1].strip if h1_match
          end

          # Fallback: extract from folder slug
          unless title
            dir_name = File.basename(File.dirname(file_path))
            slug_match = dir_name.match(/^[0-9a-z]{6}-(.+)$/)
            title = slug_match ? slug_match[1].tr("-", " ").capitalize : "Untitled"
          end

          update_frontmatter_field(file_path, "title", title, "Added missing 'title' field: '#{title}'")
        end

        def fix_tags_not_array(file_path)
          update_frontmatter_field(file_path, "tags", [], "Coerced 'tags' field to empty array")
        end

        def fix_missing_tags(file_path)
          update_frontmatter_field(file_path, "tags", [], "Added missing 'tags' field with empty array")
        end

        def fix_missing_created_at(file_path)
          return false unless File.exist?(file_path)

          # Try to decode time from ID in frontmatter or folder name
          content = File.read(file_path)
          frontmatter, _body = Ace::Support::Items::Atoms::FrontmatterParser.parse(content)

          id = frontmatter&.dig("id")
          unless id
            match = File.basename(File.dirname(file_path)).match(/^([0-9a-z]{6})/)
            id = match[1] if match
          end

          created_at = if id && Atoms::IdeaIdFormatter.valid?(id)
                         Atoms::IdeaIdFormatter.decode_time(id).strftime("%Y-%m-%d %H:%M:%S")
                       else
                         Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")
                       end

          update_frontmatter_field(file_path, "created_at", created_at, "Added missing 'created_at' field decoded from ID")
        end

        def fix_move_to_archive(file_path)
          return false unless file_path && @root_dir

          idea_dir = File.directory?(file_path) ? file_path : File.dirname(file_path)
          folder_name = File.basename(idea_dir)
          archive_dir = File.join(@root_dir, "_archive")
          target = File.join(archive_dir, folder_name)

          if @dry_run
            log_fix(idea_dir, "Would move to _archive/")
            @fixed_count += 1
            return true
          end

          FileUtils.mkdir_p(archive_dir)
          return (@skipped_count += 1; false) if File.exist?(target)

          FileUtils.mv(idea_dir, target)
          log_fix(idea_dir, "Moved to _archive/")
          @fixed_count += 1
          true
        rescue StandardError
          @skipped_count += 1
          false
        end

        def fix_archive_status(file_path)
          update_frontmatter_field(file_path, "status", "done", "Updated status to 'done' (in _archive/)")
        end

        def fix_maybe_terminal(file_path)
          return false unless file_path && @root_dir

          idea_dir = File.directory?(file_path) ? file_path : File.dirname(file_path)
          folder_name = File.basename(idea_dir)
          archive_dir = File.join(@root_dir, "_archive")
          target = File.join(archive_dir, folder_name)

          if @dry_run
            log_fix(idea_dir, "Would move from _maybe/ to _archive/")
            @fixed_count += 1
            return true
          end

          FileUtils.mkdir_p(archive_dir)
          return (@skipped_count += 1; false) if File.exist?(target)

          FileUtils.mv(idea_dir, target)
          log_fix(idea_dir, "Moved from _maybe/ to _archive/")
          @fixed_count += 1
          true
        rescue StandardError
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

          # Safety: only remove if truly empty
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

        def fix_missing_opening_delimiter(file_path)
          return false unless File.exist?(file_path)

          content = File.read(file_path)

          # Extract ID from folder name
          dir_name = File.basename(File.dirname(file_path))
          id_match = dir_name.match(/^([0-9a-z]{6})/)
          id = id_match ? id_match[1] : nil

          # Extract title from first H1 or folder slug
          title = extract_title_from_content(content) || extract_slug_title(dir_name)

          # Build minimal frontmatter
          created_at = if id && Atoms::IdeaIdFormatter.valid?(id)
                         Atoms::IdeaIdFormatter.decode_time(id).strftime("%Y-%m-%d %H:%M:%S")
                       else
                         Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")
                       end

          frontmatter = Atoms::IdeaFrontmatterDefaults.build(
            id: id || Atoms::IdeaIdFormatter.generate,
            title: title,
            status: "pending",
            created_at: Time.now.utc
          )
          frontmatter["id"] = id if id  # Use existing ID if available

          # Prepend proper frontmatter structure
          yaml_block = Atoms::IdeaFrontmatterDefaults.serialize(frontmatter)
          new_content = "#{yaml_block}\n#{content}"

          apply_file_fix(file_path, new_content, "Added opening '---' delimiter and frontmatter")
        end

        def fix_folder_naming(dir_path)
          return false unless Dir.exist?(dir_path)

          # Generate new valid ID
          new_id = Atoms::IdeaIdFormatter.generate

          # Extract slug from old folder name (remove prefix patterns)
          old_name = File.basename(dir_path)
          slug = extract_slug_from_folder_name(old_name)

          # Find spec file
          spec_files = Dir.glob(File.join(dir_path, "*.idea.s.md"))
          return (@skipped_count += 1; false) if spec_files.empty?

          spec_file = spec_files.first

          if @dry_run
            new_folder_name = "#{new_id}-#{slug}"
            log_fix(dir_path, "Would rename folder to #{new_folder_name}")
            @fixed_count += 1
            return true
          end

          # Update frontmatter id in spec file
          editor = Ace::Support::Markdown::Organisms::DocumentEditor.new(spec_file)
          editor.update_frontmatter("id" => new_id)
          editor.save!(backup: true, validate_before: false)

          # Build new names
          new_folder_name = "#{new_id}-#{slug}"
          parent = File.dirname(dir_path)
          new_dir_path = File.join(parent, new_folder_name)

          # Rename spec file
          old_spec_name = File.basename(spec_file)
          new_spec_name = "#{new_folder_name}.idea.s.md"
          new_spec_path = File.join(new_dir_path, new_spec_name)

          # Rename folder
          FileUtils.mv(dir_path, new_dir_path)
          FileUtils.mv(File.join(new_dir_path, old_spec_name), new_spec_path)

          log_fix(dir_path, "Renamed folder to #{new_folder_name}")
          @fixed_count += 1
          true
        rescue StandardError
          @skipped_count += 1
          false
        end

        def extract_title_from_content(content)
          # Try to extract title from first H1
          # Note: don't use /m flag - we only want first line after #, not entire content
          h1_match = content.match(/^#\s+(.+)$/)
          h1_match ? h1_match[1].strip : nil
        end

        def extract_slug_title(dir_name)
          # Extract slug part after ID prefix
          slug_match = dir_name.match(/^[0-9a-z]{6}-(.+)$/)
          slug = slug_match ? slug_match[1] : dir_name
          slug.tr("-", " ").capitalize
        end

        def extract_slug_from_folder_name(name)
          # Remove various prefix patterns:
          # "056-20250930-105556-slug-here" -> "slug-here"
          # "20251013-slug-here" -> "slug-here"
          # "2025111-slug-here" -> "slug-here"

          # Try to find slug after numeric prefixes
          slug = name.sub(/^\d+-\d+-\d+-/, '')   # Remove NNN-YYYYMMDD-HHMMSS-
                   .sub(/^\d{7,}-/, '')          # Remove 7+ digit prefix (like 2025111)
                   .sub(/^\d{6}-/, '')           # Remove 6-digit date prefix (YYYYMM)
                   .sub(/^\d+-/, '')             # Remove issue number prefix

          # Fallback: use the original name cleaned up
          if slug.empty? || slug.match?(/^\d+$/)
            slug = name.gsub(/[^a-zA-Z0-9]+/, "-").downcase
          end

          slug = slug.gsub(/^-+|-+$/, "")  # Strip leading/trailing dashes
          slug = "untitled" if slug.empty?
          slug[0..50]  # Truncate to reasonable length
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
        rescue StandardError
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
        rescue StandardError
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
